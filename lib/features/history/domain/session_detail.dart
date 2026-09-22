import 'training_load.dart';
import '../../../core/domain/pulse_profile.dart';
import 'training_session.dart';

/// Was das Einheitendetail über eine Einheit sagt — **nach Daten gebaut, nicht
/// nach Art** (Board 16).
///
/// ## Der Satz, an dem alles gemessen wird
///
/// Die Art einer Einheit wählt nie das Layout. Sie füllt einen Katalog von
/// Grössen und eine feste Reihe von Blockplätzen. Oben steht genau eine Zahl,
/// die sagt, was das war; jede weitere Zahl nennt ihre Grundlage; und was
/// keine Daten hat, ist nicht leer, sondern nicht da.
///
/// Diese Datei ist der rechnende Teil davon. Sie kennt kein Flutter und keine
/// Zeichenkette — was hier steht, ist ohne Gerät und ohne Übersetzung
/// prüfbar.

/// Woher eine Grösse kommt.
///
/// Die Fläche **ist** die Quelle (Board 15, Protokoll „keine Grösse hat zwei
/// Quellen"): Was aus der Uhr kommt, steht violett hinterlegt, mit
/// zusätzlichem Ring-Glyph — Farbe allein trüge es nicht.
enum MetricSource { app, watch }

/// Die Grössen, aus denen die Kacheln bestehen.
///
/// Ein Katalog, keine Layouts: Watt, Bahnlängen oder Trittfrequenz kommen als
/// Eintrag dazu, nicht als Bildschirm (Entscheidung 2).
enum MetricKind {
  duration,
  volume,
  load,
  heartRateAvg,
  calories,
  elevation,
}

/// Was die Uhr an einer Einheit gemessen hat — als reine Werte.
///
/// **Ein neutraler Typ**, nicht der Datensatz aus dem Import: Die Verlaufs-
/// Domäne kennt den Import nicht, denn der Import kennt sie (die
/// Paarungsregel liest den Verlauf). Zwei Domänen, die einander kennen, sind
/// ein Kreis, den man später nicht mehr aufbekommt.
class WatchFigures {
  const WatchFigures({
    required this.start,
    required this.end,
    this.pulse,
    this.averageHeartRate,
    this.maxHeartRate,
    this.calories,
    this.distanceKm,
    this.deviceName,
  });

  final DateTime start;
  final DateTime end;

  /// Der Pulsverlauf als Sekunden je bpm — die Quelle für Ø, Maximum, Minimum
  /// und Zonen. `null` an Datensätzen, die noch nicht nachgetragen sind.
  final PulseProfile? pulse;

  /// Was der Datensatz selbst trägt, falls [pulse] fehlt.
  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? calories;
  final double? distanceKm;
  final String? deviceName;

  Duration get duration => end.difference(start);

  /// Ø-Puls — aus dem Verlauf, wenn er da ist. **Eine Quelle**: Zwei Werte für
  /// dieselbe Grösse wären zwei Wahrheiten.
  int? get heartRateAvg => pulse?.average ?? averageHeartRate;
  int? get heartRateMax => pulse?.max ?? maxHeartRate;
  int? get heartRateMin => pulse?.min;
}

/// Die eine grosse Zahl im Kopf.
enum LeadKind { sets, volume, distance, duration }

class SessionLead {
  const SessionLead(this.kind, this.value);

  final LeadKind kind;

  /// Sätze als ganze Zahl, Volumen in kg, Strecke in km, Dauer in Minuten.
  final num value;
}

/// Eine Kennzahlkachel: Grösse, Wert, Quelle.
/// Woher die Anstrengung kam, mit der die Last gerechnet wurde.
///
/// **Die dritte Grundlage steht nicht in [MetricSource]** (Board 16,
/// Nachtrag, Sektion M). Die Last ist und bleibt eine App-Rechnung — sie
/// trägt deshalb weiter keinen Herkunftspunkt. Gemessen ist nicht die Zahl,
/// sondern eine ihrer Eingangsgrössen, und das gehört in die Grundlagenzeile
/// darunter, nicht in den Punkt darüber.
enum EffortBasis {
  /// Eingetragen — die Aussage eines Menschen.
  entered,

  /// Aus dem Pulsverlauf gemessen, weil nichts eingetragen war.
  measured,

  /// Weder noch: der Ersatzwert.
  fallback,
}

class MetricTile {
  const MetricTile(
    this.kind,
    this.value,
    this.source, {
    this.effortBasis,
    this.effort,
  });

  final MetricKind kind;
  final num value;
  final MetricSource source;

  /// Nur an [MetricKind.load]: womit gerechnet wurde.
  final EffortBasis? effortBasis;

  /// Die Anstrengung 1–5, die in die Rechnung ging.
  final int? effort;
}

/// Wie ein Vergleich mit der letzten Ausführung derselben Übung ausgeht.
enum DeltaKind {
  /// Es gibt keine frühere Ausführung — **kein** Delta, kein „—" als Wert.
  none,

  /// Das schwerste Gewicht hat sich verschoben.
  weight,

  /// Gleiches Gewicht, andere Wiederholungen.
  reps,

  /// Beides gleich.
  same,
}

/// Ein Vergleich in der Übungszeile — **eine Tatsache, kein Urteil**.
///
/// „Mehr" ist nicht „besser": Das Delta steht in der zweiten Textstufe mit
/// Richtungsglyph, ohne Ampelfarbe (Entscheidung 19). Und nur hier, nie im
/// Kopf: Ein Delta neben der Leitzahl wäre ein zweiter Blickfang und stellte
/// eine Einheit gegen eine willkürliche Vorgängerin.
class ExerciseDelta {
  const ExerciseDelta.none()
      : kind = DeltaKind.none,
        amount = 0,
        against = null;

  const ExerciseDelta(this.kind, this.amount, this.against);

  final DeltaKind kind;

  /// Mit Vorzeichen: positiv heisst mehr als beim letzten Mal.
  final double amount;

  /// Der Tag der früheren Ausführung — der Bezug, ohne den kein Delta gilt.
  final DateTime? against;
}

/// Eine Übung einer Krafteinheit, wie die Zeile sie zeigt.
class ExerciseSummary {
  const ExerciseSummary({
    required this.exerciseId,
    required this.sets,
    required this.allSets,
    required this.delta,
    this.reps,
    this.weightKg,
    this.holdSeconds,
  });

  final String exerciseId;

  /// Arbeitssätze — Aufwärmsätze zählen hier nicht mit.
  final int sets;

  /// Alle Sätze, wie erfasst — für die aufgeklappte Zeile.
  final List<LoggedSet> allSets;

  /// Wiederholungen des **schwersten** Satzes.
  final int? reps;

  /// Gewicht des schwersten Satzes. `null` heisst: Körpergewicht.
  final double? weightKg;

  final int? holdSeconds;

  final ExerciseDelta delta;

  bool get isBodyweight => weightKg == null || weightKg == 0;
}

/// Der rechnende Teil des Einheitendetails.
abstract final class SessionDetail {
  /// Wie viele Kacheln im Kopf höchstens stehen.
  static const maxTiles = 4;

  /// Zeilen, die vor dem „+ n weitere" stehen.
  static const visibleExercises = 3;

  // ---- Leitwert --------------------------------------------------------

  /// Die erste Grösse der Kette, die vorhanden ist.
  ///
  /// Kraft: Sätze → Volumen → Dauer. Ausdauer: Strecke → Dauer.
  /// Regeneration: Dauer. **Läuft die Kette leer, gibt es keine Zahl** — und
  /// der Kopf bleibt gültig (Entscheidung 4: „eine Zahl, die lügt, ist
  /// schlechter als eine, die fehlt").
  ///
  /// Sätze schlagen Volumen, weil 16 von 63 Krafteinheiten gar keine Übung
  /// tragen und Volumen ohne Gewichtsangaben zu 0 kg würde.
  static SessionLead? leadOf(TrainingSession session) {
    final minutes = _minutes(session);

    switch (session) {
      case StrengthSession():
        final sets = setCount(session);
        if (sets > 0) return SessionLead(LeadKind.sets, sets);
        final volume = volumeKg(session);
        if (volume != null) return SessionLead(LeadKind.volume, volume);
      case CardioSession(distanceKm: final km?) when km > 0:
        return SessionLead(LeadKind.distance, km);
      default:
        break;
    }
    return minutes == null ? null : SessionLead(LeadKind.duration, minutes);
  }

  /// Alle erfassten Sätze der Einheit — leere Einträge zählen nicht.
  static int setCount(TrainingSession session) {
    if (session is! StrengthSession) return 0;
    return session.exercises
        .fold<int>(0, (n, e) => n + e.sets.where((s) => !s.isEmpty).length);
  }

  /// Bewegtes Gewicht — **oder `null`**, wenn keine Gewichtsangabe existiert.
  ///
  /// Nicht 0: Ein Satz ohne Gewicht fehlt im Volumen. Das steht hinter dem ⓘ
  /// („Sätze ohne Gewicht fehlen im Volumen und stehen im Nenner").
  static double? volumeKg(TrainingSession session) {
    if (session is! StrengthSession) return null;
    var moved = 0.0;
    var any = false;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        final reps = set.reps;
        final weight = set.weight;
        if (reps == null || weight == null || weight <= 0) continue;
        moved += reps * weight;
        any = true;
      }
    }
    return any ? moved : null;
  }

  static int? _minutes(TrainingSession session) {
    final duration = session.duration;
    if (duration == null || duration <= Duration.zero) return null;
    return duration.inMinutes;
  }

  // ---- Kacheln ---------------------------------------------------------

  /// Höchstens vier Kacheln aus dem Katalog — **die ersten, die Daten haben**.
  ///
  /// Eine Kachel, die dieselbe Zahl wie die Leitzahl trüge, entfällt: Bei
  /// Regeneration wäre die Dauer sonst zweimal da.
  static List<MetricTile> tilesOf(
    TrainingSession session, {
    WatchFigures? watch,
    double load = 0,
    LoadContext context = const LoadContext(),
  }) {
    final lead = leadOf(session);
    final origin = session.origin;
    // Aus einer Einheit, die **aus** der Uhr entstanden ist, kommt alles aus
    // der Uhr; in einer zusammengeführten liefert die App Sätze und Dauer,
    // die Uhr Puls und Kalorien.
    final wholeFromWatch = origin == SessionOrigin.watch;

    MetricSource sourceOf(bool watchOwns) =>
        wholeFromWatch || watchOwns ? MetricSource.watch : MetricSource.app;

    final minutes = _minutes(session);
    final volume = volumeKg(session);
    final hrAvg = watch?.heartRateAvg ??
        (session is CardioSession ? session.avgHr : null);
    final calories = watch?.calories;

    final catalog = <MetricTile?>[
      if (minutes != null && lead?.kind != LeadKind.duration)
        MetricTile(MetricKind.duration, minutes, sourceOf(false)),
      if (volume != null && lead?.kind != LeadKind.volume)
        MetricTile(MetricKind.volume, volume, MetricSource.app),
      if (hrAvg != null)
        MetricTile(
          MetricKind.heartRateAvg,
          hrAvg,
          // Steht der Puls in der Einheit selbst (von Hand erfasst), gehört er
          // der App; sonst kommt er aus der Uhr.
          watch?.heartRateAvg != null ? MetricSource.watch : sourceOf(false),
        ),
      if (calories != null)
        MetricTile(MetricKind.calories, calories, MetricSource.watch),
      // Last steht **zuletzt**: Sie ist eine App-Rechnung, keine Messung, und
      // rückt nur nach, wo weniger als vier andere Grössen da sind.
      //
      // Seit dem 22.09.2026 nennt sie zusätzlich, **womit** gerechnet wurde.
      // Die Reihenfolge ist die von `LoadContext.effortFor`; hier wird sie
      // nur nachgelesen, nicht ein zweites Mal entschieden.
      if (load > 0)
        MetricTile(
          MetricKind.load,
          load.round(),
          MetricSource.app,
          effortBasis: session.rpe != null
              ? EffortBasis.entered
              : context.measuredEffortOf?.call(session) != null
                  ? EffortBasis.measured
                  : EffortBasis.fallback,
          effort: context.effortFor(session),
        ),
    ];

    return [
      for (final tile in catalog)
        if (tile != null) tile,
    ].take(maxTiles).toList();
  }

  // ---- Übungen ---------------------------------------------------------

  /// Die Übungszeilen einer Krafteinheit — mit Vergleich zur letzten
  /// Ausführung **derselben** Übung.
  ///
  /// [sessions] ist der ganze Bestand; gesucht wird die jüngste frühere
  /// Einheit, die die Übung mit mindestens einem Arbeitssatz trägt. Kein
  /// Delta gegen eine „vorige Einheit" schlechthin: Ein Bezug gilt nur, wo
  /// es dieselbe Übung ist und ein genanntes Datum.
  static List<ExerciseSummary> exercisesOf(
    TrainingSession session,
    List<TrainingSession> sessions,
  ) {
    if (session is! StrengthSession) return const [];

    return [
      for (final exercise in session.exercises)
        if (exercise.sets.any((s) => !s.isEmpty))
          _summarise(exercise, session, sessions),
    ];
  }

  static ExerciseSummary _summarise(
    LoggedExercise exercise,
    StrengthSession session,
    List<TrainingSession> sessions,
  ) {
    final working = _working(exercise.sets);
    final top = _top(working);

    return ExerciseSummary(
      exerciseId: exercise.exerciseId,
      sets: working.length,
      allSets: [
        for (final s in exercise.sets)
          if (!s.isEmpty) s,
      ],
      reps: top?.reps,
      weightKg: top?.weight != null && top!.weight! > 0 ? top.weight : null,
      holdSeconds: top?.holdSeconds,
      delta: _delta(exercise.exerciseId, top, session, sessions),
    );
  }

  /// Arbeitssätze: nicht leer, nicht Aufwärmen.
  static List<LoggedSet> _working(List<LoggedSet> sets) => [
        for (final s in sets)
          if (!s.isEmpty && s.rawType != 'warmup') s,
      ];

  /// Der schwerste Satz; bei gleichem Gewicht der mit den meisten Wdh.
  static LoggedSet? _top(List<LoggedSet> sets) {
    LoggedSet? best;
    for (final s in sets) {
      if (best == null) {
        best = s;
        continue;
      }
      final w = s.weight ?? 0;
      final bw = best.weight ?? 0;
      if (w > bw || (w == bw && (s.reps ?? 0) > (best.reps ?? 0))) best = s;
    }
    return best;
  }

  static ExerciseDelta _delta(
    String exerciseId,
    LoggedSet? top,
    StrengthSession session,
    List<TrainingSession> sessions,
  ) {
    if (top == null) return const ExerciseDelta.none();

    StrengthSession? before;
    LoggedSet? beforeTop;
    for (final s in sessions) {
      if (s is! StrengthSession || s.id == session.id) continue;
      if (!_isEarlier(s, session)) continue;
      for (final e in s.exercises) {
        if (e.exerciseId != exerciseId) continue;
        final candidate = _top(_working(e.sets));
        if (candidate == null) continue;
        if (before == null || _isEarlier(before, s)) {
          before = s;
          beforeTop = candidate;
        }
      }
    }
    if (before == null || beforeTop == null) {
      return const ExerciseDelta.none();
    }

    final w = top.weight ?? 0;
    final bw = beforeTop.weight ?? 0;
    if (w > 0 && bw > 0 && w != bw) {
      return ExerciseDelta(DeltaKind.weight, w - bw, before.date);
    }
    final r = top.reps;
    final br = beforeTop.reps;
    if (r != null && br != null && r != br) {
      return ExerciseDelta(DeltaKind.reps, (r - br).toDouble(), before.date);
    }
    return ExerciseDelta(DeltaKind.same, 0, before.date);
  }

  /// Ob [a] vor [b] liegt — nach Tag, bei gleichem Tag nach Anlegen.
  static bool _isEarlier(TrainingSession a, TrainingSession b) {
    final byDay = a.date.compareTo(b.date);
    if (byDay != 0) return byDay < 0;
    return a.createdAt.isBefore(b.createdAt);
  }
}
