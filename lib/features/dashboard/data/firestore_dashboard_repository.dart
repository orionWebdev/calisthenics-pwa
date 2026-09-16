import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../history/domain/data_sufficiency.dart';
import '../../history/domain/readiness.dart';
import '../../history/domain/session_repository.dart';
import '../../history/domain/training_load.dart';
import '../../history/domain/session_comparison.dart';
import '../../history/domain/training_session.dart';
import '../domain/dashboard_data.dart';
import '../domain/dashboard_repository.dart';

/// Das Dashboard aus echten Daten.
///
/// Drei Quellen laufen hier zusammen: die Trainingshistorie über das
/// [SessionRepository], das Profil aus `userProfiles` (für Anzeigename und
/// Körpergewicht) und der Wochenplan aus `schedule`.
///
/// ## Was hier bewusst leer bleibt
///
/// Ernährung, Regenerationsminuten und Periodisierung liefern `null`. Für sie
/// existiert **keine Datenquelle** — weder in der PWA noch hier, und Health
/// Connect steht ausdrücklich nicht in V1. Ein Platzhalterwert sähe auf dem
/// Bildschirm aus wie eine Messung. Dasselbe gilt für HRV, Ruhepuls und Schlaf
/// im Readiness-Block.
class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository({
    required FirebaseFirestore firestore,
    required SessionRepository sessions,
    required this.userId,
    this.fallbackDisplayName,
    DateTime Function()? now,
  })  : _db = firestore,
        _sessions = sessions,
        _now = now ?? DateTime.now;

  final FirebaseFirestore _db;
  final SessionRepository _sessions;
  final String userId;

  /// Anzeigename aus der Anmeldung — greift, wenn das Profil keinen trägt.
  /// Im Bestand ist genau das bei einem der beiden Konten der Fall.
  final String? fallbackDisplayName;

  /// Einspritzbar, damit Tests einen festen Stichtag setzen können.
  final DateTime Function() _now;

  @override
  Stream<DashboardData> watchDashboard() {
    final sessions = _sessions.watchSessions(userId);
    final profile = _db.collection('userProfiles').doc(userId).snapshots();
    final schedule = _db
        .collection('schedule')
        .where('userId', isEqualTo: userId)
        .snapshots();

    // Drei Ströme, ein Zustand. Jede Quelle löst für sich einen Neubau aus;
    // die anderen beiden liefern ihren zuletzt bekannten Stand.
    return _combine3(sessions, profile, schedule, _build);
  }

  DashboardData _build(
    List<TrainingSession> sessions,
    DocumentSnapshot<Map<String, dynamic>> profile,
    QuerySnapshot<Map<String, dynamic>> schedule,
  ) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final data = profile.data() ?? const <String, dynamic>{};

    // R1 aus Vertrag 4: Das Körpergewicht steht im Bestand einmal als 70
    // (integer) und einmal als 68.5 (double).
    final bodyWeight = (data['bodyWeight'] as num?)?.toDouble() ?? 0;
    final context = LoadContext(bodyWeightKg: bodyWeight);

    final name = _nonEmpty(data['displayName']) ??
        _nonEmpty(fallbackDisplayName) ??
        _nonEmpty(data['email'])?.split('@').first ??
        '';

    final acwr = Readiness.compute(
      sessions,
      today,
      context: context,
      applyFatigue: true,
    );

    // **Die Zone nur zeigen, wenn sie etwas taugt.**
    //
    // Am echten Bestand aufgefallen: Ein halbes Jahr Training, dann fünfzig
    // Tage Pause, dann eine einzige Einheit — und der Bogen meldete
    // „Überreizt". Das Gegenteil der Wahrheit, auf dem Hauptbildschirm.
    //
    // Die chronische Last war über die Pause auf fast null gefallen; die eine
    // Einheit trieb das Verhältnis auf 2,95. Ohne genug Einheiten im akuten
    // Fenster ist der ACWR keine Aussage, sondern eine Division.
    final zone = DataSufficiency.hasAcwr(sessions, today) ? acwr.zone : null;

    return DashboardData(
      user: UserSummary(
        displayName: name,
        // Benachrichtigungen gibt es noch nicht.
        unreadNotifications: 0,
      ),
      readiness: ReadinessSnapshot(
        // Ohne belastbare Grundlage — unter 14 Tagen Historie — liefert die
        // Rechnung bewusst nichts. 0 ist dann kein Messwert, sondern die
        // ehrlichste Anzeige: ein leerer Bogen.
        score: (acwr.score ?? 0).toDouble(),
        zone: zone,
        // Kein Wearable angebunden.
        isLive: false,
      ),
      performance: _weeklyPerformance(sessions, today, context),
      session: _todaySession(schedule, today),
      workoutLog: _lastWorkout(sessions),
      lastSession: _lastSession(sessions, today, context),
      nextSession: _nextSession(schedule, today),
    );
  }

  /// Die letzte Einheit mit der Last ihres Bezugs.
  LastSessionSummary? _lastSession(
    List<TrainingSession> sessions,
    DateTime today,
    LoadContext context,
  ) {
    if (sessions.isEmpty) return null;
    final last = sessions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final comparison =
        SessionComparison.forSession(last, sessions, context: context);

    return LastSessionSummary(
      id: last.id,
      // Der Name kommt aus der Oberfläche — die Datenschicht kennt die
      // Sprache nicht. Hier steht der Planname, wenn es einen gibt.
      name: last is StrengthSession && last.planName != null
          ? last.planName!
          : '',
      daysAgo: DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.date.year, last.date.month, last.date.day))
          .inDays,
      load: comparison.current.load,
      loadBefore: comparison.previous?.load,
    );
  }

  /// Der nächste Termin **nach heute**.
  ///
  /// Der heutige steht schon in der Session-Card darüber; ihn hier zu
  /// wiederholen wäre dieselbe Auskunft zweimal.
  NextSession? _nextSession(
    QuerySnapshot<Map<String, dynamic>> schedule,
    DateTime today,
  ) {
    final from = DateTime(today.year, today.month, today.day);
    DateTime? bestDate;
    Map<String, dynamic>? best;
    String? bestId;

    for (final doc in schedule.docs) {
      final data = doc.data();
      if (data['completed'] == true || data['status'] == 'completed') continue;

      final raw = data['date'];
      final date = switch (raw) {
        String() when raw.length >= 10 => DateTime.tryParse(raw.substring(0, 10)),
        Timestamp(:final toDate) => toDate(),
        _ => null,
      };
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(from) || day == from) continue;
      if (bestDate == null || day.isBefore(bestDate)) {
        bestDate = day;
        best = data;
        bestId = doc.id;
      }
    }

    if (bestDate == null || best == null) return null;
    return NextSession(
      id: bestId!,
      title: _nonEmpty(best['planName']) ?? '',
      date: bestDate,
      daysAhead: bestDate.difference(from).inDays,
      planId: _nonEmpty(best['planId']),
    );
  }

  /// Die Wochenkurve, Montag bis Sonntag.
  ///
  /// Die drei Linien sind nicht drei Messungen, sondern drei Sichten auf
  /// dieselbe Historie:
  ///
  /// * **Last** — die Rohlast des Tages, am Wochenhöchstwert normiert. Ohne
  ///   Normierung wäre die Skala 0..100 bedeutungslos, weil Rohlasten je nach
  ///   Trainingsart um Größenordnungen auseinanderliegen.
  /// * **Belastung** — die akute Last des gleitenden Mittels, ebenso normiert.
  ///   Sie zeigt, was vom Training noch nachwirkt.
  /// * **Erholung** — der Readiness-Wert des Tages. Er ist bereits 0..100.
  WeeklyPerformance _weeklyPerformance(
    List<TrainingSession> sessions,
    DateTime today,
    LoadContext context,
  ) {
    final monday =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));

    final days = <DateTime>[
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];

    final raw = <double>[];
    final acute = <double>[];
    final recovery = <double>[];

    for (final day in days) {
      // Zukünftige Tage der laufenden Woche haben keine Werte.
      if (day.isAfter(today)) {
        raw.add(0);
        acute.add(0);
        recovery.add(0);
        continue;
      }

      final result = Readiness.compute(sessions, day, context: context);
      raw.add(result.todayLoad);
      acute.add(result.acuteLoad);
      recovery.add((result.score ?? 0).toDouble());
    }

    final maxRaw = raw.fold<double>(0, (a, b) => b > a ? b : a);
    final maxAcute = acute.fold<double>(0, (a, b) => b > a ? b : a);

    double scale(double value, double max) =>
        max <= 0 ? 0 : (value / max * 100).clamp(0, 100);

    return WeeklyPerformance(
      days: [
        for (var i = 0; i < 7; i++)
          DailyMetrics(
            date: days[i],
            load: scale(raw[i], maxRaw),
            strain: scale(acute[i], maxAcute),
            recovery: recovery[i],
          ),
      ],
      todayIndex: today.weekday - 1,
    );
  }

  /// Die für heute geplante Einheit aus `schedule`.
  ///
  /// `date` liegt dort als **Zeichenkette** vor, nicht als Zeitstempel — anders
  /// als in `sessions`. Verglichen wird deshalb der Tagesschlüssel.
  TodaySession? _todaySession(
    QuerySnapshot<Map<String, dynamic>> schedule,
    DateTime today,
  ) {
    final key = Readiness.dayKey(today);

    for (final doc in schedule.docs) {
      final data = doc.data();
      final date = data['date'];
      final dayKey = switch (date) {
        String() when date.length >= 10 => date.substring(0, 10),
        Timestamp(:final toDate) => Readiness.dayKey(toDate()),
        _ => null,
      };
      if (dayKey != key) continue;

      // **Beides prüfen.** Im Produktivbestand steht `completed` in allen 77
      // Dokumenten auf `false` — die PWA setzt es nie. Abgeschlossen wird über
      // `status: 'completed'` festgehalten. Ein Filter allein auf `completed`
      // griffe nie und zeigte erledigte Einheiten weiter als offen an.
      if (data['completed'] == true || data['status'] == 'completed') continue;

      final minutes = (data['planDuration'] as num?)?.round() ?? 0;
      final planType = _nonEmpty(data['planType']);

      return TodaySession(
        id: doc.id,
        // Die Vorgänger-App schreibt ihn beim Anlegen des Termins
        // (`js/views/calendar.js`, `addPlanToDateById`). Nur Schnelleinträge
        // haben keinen.
        planId: _nonEmpty(data['planId']),
        title: _nonEmpty(data['planName']) ?? '',
        duration: Duration(minutes: minutes),
        // Kein Anzeigetext aus der Datenschicht: Das ist der rohe Typ aus
        // Firestore, den das Widget übersetzt.
        intensityLabel: planType ?? '',
        // Blöcke stehen im Plan, nicht im Termin. Bis der Planbuilder da ist,
        // gibt es keine Zahl.
        blockCount: 0,
        isHighIntensity: planType == 'strength' || planType == 'hybrid',
      );
    }
    return null;
  }

  /// Die letzte Einheit mit Satzdaten — für die Kachel „Workout".
  WorkoutLogSummary? _lastWorkout(List<TrainingSession> sessions) {
    for (final session in sessions) {
      if (session is! StrengthSession || !session.hasExerciseData) continue;
      final sets = session.exercises
          .fold<int>(0, (total, exercise) => total + exercise.sets.length);
      return WorkoutLogSummary(totalSets: sets, planName: session.planName);
    }
    return null;
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Verbindet drei Ströme zu einem.
///
/// `rxdart` wäre eine Abhängigkeit für dreißig Zeilen. Der Zustand wird erst
/// ausgegeben, wenn **alle drei** Quellen mindestens einmal geliefert haben —
/// sonst zeigte das Dashboard kurz einen halb gefüllten Zustand.
Stream<R> _combine3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) {
  late StreamController<R> controller;
  final subscriptions = <StreamSubscription<void>>[];

  A? lastA;
  B? lastB;
  C? lastC;
  var hasA = false, hasB = false, hasC = false;

  void emit() {
    if (!hasA || !hasB || !hasC) return;
    try {
      controller.add(combine(lastA as A, lastB as B, lastC as C));
    } catch (error, stack) {
      controller.addError(error, stack);
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptions.addAll([
        a.listen((v) {
          lastA = v;
          hasA = true;
          emit();
        }, onError: controller.addError),
        b.listen((v) {
          lastB = v;
          hasB = true;
          emit();
        }, onError: controller.addError),
        c.listen((v) {
          lastC = v;
          hasC = true;
          emit();
        }, onError: controller.addError),
      ]);
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );

  return controller.stream;
}
