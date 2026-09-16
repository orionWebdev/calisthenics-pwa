import 'package:atem/features/dashboard/data/firestore_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/history/data/firestore_session_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Stichtag ist fest — sonst hinge jeder erwartete Wert am Kalender des
/// Rechners, auf dem der Test läuft.
final _today = DateTime(2026, 3, 11, 14, 30); // ein Mittwoch

FakeFirebaseFirestore _db() => FakeFirebaseFirestore();

FirestoreDashboardRepository _repo(
  FakeFirebaseFirestore db, {
  String? fallbackDisplayName,
}) =>
    FirestoreDashboardRepository(
      firestore: db,
      sessions: FirestoreSessionRepository(db),
      userId: 'u1',
      fallbackDisplayName: fallbackDisplayName,
      now: () => _today,
    );

Future<void> _addSession(
  FakeFirebaseFirestore db, {
  required DateTime date,
  String type = 'strength',
  Object? duration = 45,
  int? rpe,
  List<Map<String, dynamic>>? exercises,
  String? planName,
  String userId = 'u1',
}) =>
    db.collection('sessions').add({
      'userId': userId,
      'type': type,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date),
      if (duration != null) 'duration': duration,
      if (rpe != null) 'rpe': rpe,
      if (exercises != null) 'exercises': exercises,
      if (planName != null) 'planName': planName,
    });

/// Genug Historie, damit die Readiness-Rechnung überhaupt einen Wert liefert:
/// Sie verlangt mindestens 14 Tage Spanne.
Future<void> _seedHistory(FakeFirebaseFirestore db, {int days = 40}) async {
  for (var i = days; i >= 0; i -= 2) {
    await _addSession(
      db,
      date: _today.subtract(Duration(days: i)),
      type: i % 4 == 0 ? 'cardio' : 'strength',
      duration: 40 + (i % 20),
      rpe: 2 + (i % 3),
    );
  }
}

void main() {
  test('ohne jede Historie steht das Dashboard, statt zu scheitern', () async {
    final db = _db();
    final data = await _repo(db).watchDashboard().first;

    expect(data.readiness.score, 0);
    expect(data.performance.days, hasLength(7));
    expect(data.session, isNull);
    expect(data.workoutLog, isNull);
  });

  test('die Readiness kommt aus der echten Historie', () async {
    final db = _db();
    await _seedHistory(db);

    final data = await _repo(db).watchDashboard().first;

    expect(data.readiness.score, greaterThan(0));
    expect(data.readiness.score, lessThanOrEqualTo(100));
    // Kein Wearable angebunden — diese drei müssen leer bleiben, sonst wäre
    // eine Erfindung auf dem Bildschirm.
    expect(data.readiness.hrvMs, isNull);
    expect(data.readiness.restingHeartRate, isNull);
    expect(data.readiness.sleepDuration, isNull);
    expect(data.readiness.isLive, isFalse);
  });

  test('was keine Quelle hat, erscheint gar nicht mehr', () async {
    // Ernährung, HRV und Periodisierung standen als Kacheln da und sagten
    // dauerhaft „Noch keine Daten" — drei leere Felder auf der halben
    // Dashboard-Fläche. Sie sind entfallen, samt ihren Modellen.
    final db = _db();
    await _seedHistory(db);

    final data = await _repo(db).watchDashboard().first;
    expect(data.user.unreadNotifications, 0);
  });

  group('Die Kacheln zeigen, was die App weiss', () {
    test('die letzte Einheit mit ihrer Last', () async {
      final db = _db();
      await _seedHistory(db);

      final data = await _repo(db).watchDashboard().first;
      expect(data.lastSession, isNotNull);
      expect(data.lastSession!.load, greaterThan(0));
      expect(data.lastSession!.daysAgo, greaterThanOrEqualTo(0));
    });

    test('ohne Einheiten bleiben beide leer, statt null zu behaupten',
        () async {
      final db = _db();
      final data = await _repo(db).watchDashboard().first;
      expect(data.lastSession, isNull,
          reason: '„Form 0" wäre eine Aussage über jemanden, der nie '
              'trainiert hat');
    });

    test('ohne Termin in der Zukunft bleibt die Kachel leer', () async {
      final db = _db();
      await _seedHistory(db);
      final data = await _repo(db).watchDashboard().first;
      expect(data.nextSession, isNull);
    });
  });

  group('Wochenkurve', () {
    test('sieben Tage, Montag bis Sonntag, heute an der richtigen Stelle',
        () async {
      final db = _db();
      await _seedHistory(db);

      final data = await _repo(db).watchDashboard().first;
      final days = data.performance.days;

      expect(days, hasLength(7));
      expect(days.first.date.weekday, DateTime.monday);
      expect(days.last.date.weekday, DateTime.sunday);
      // Der 11.03.2026 ist ein Mittwoch — Index 2.
      expect(data.performance.todayIndex, 2);
      expect(data.performance.today, isNotNull);
    });

    test('künftige Tage der laufenden Woche tragen keine Werte', () async {
      final db = _db();
      await _seedHistory(db);

      final days = (await _repo(db).watchDashboard().first).performance.days;

      for (var i = 3; i < 7; i++) {
        expect(days[i].load, 0, reason: 'Tag $i liegt in der Zukunft');
        expect(days[i].strain, 0);
        expect(days[i].recovery, 0);
      }
    });

    test('alle Werte liegen im Bereich, den der Chart erwartet', () async {
      final db = _db();
      await _seedHistory(db);

      for (final day
          in (await _repo(db).watchDashboard().first).performance.days) {
        expect(day.load, inInclusiveRange(0, 100));
        expect(day.strain, inInclusiveRange(0, 100));
        expect(day.recovery, inInclusiveRange(0, 100));
      }
    });
  });

  group('geplante Einheit aus schedule', () {
    Future<void> add(
      FakeFirebaseFirestore db, {
      required String date,
      bool completed = false,
      String userId = 'u1',
    }) =>
        db.collection('schedule').add({
          'userId': userId,
          'date': date,
          'completed': completed,
          'planName': 'Upper Body Power',
          'planType': 'strength',
          'planDuration': 48,
        });

    test('der Termin von heute wird gefunden — Datum als Zeichenkette',
        () async {
      final db = _db();
      await add(db, date: '2026-03-11');

      final session = (await _repo(db).watchDashboard().first).session;

      expect(session, isNotNull);
      expect(session!.title, 'Upper Body Power');
      expect(session.duration, const Duration(minutes: 48));
      expect(session.isHighIntensity, isTrue);
    });

    test('ein Termin an einem anderen Tag zählt nicht', () async {
      final db = _db();
      await add(db, date: '2026-03-12');

      expect((await _repo(db).watchDashboard().first).session, isNull);
    });

    test('ein bereits erledigter Termin zählt nicht', () async {
      final db = _db();
      await add(db, date: '2026-03-11', completed: true);

      expect((await _repo(db).watchDashboard().first).session, isNull);
    });

    test('der Termin eines anderen Nutzers zählt nicht', () async {
      final db = _db();
      await add(db, date: '2026-03-11', userId: 'jemand-anders');

      expect((await _repo(db).watchDashboard().first).session, isNull);
    });
  });

  group('letzte Einheit für die Workout-Kachel', () {
    test('Sätze werden gezählt, der Planname übernommen', () async {
      final db = _db();
      await _addSession(
        db,
        date: _today.subtract(const Duration(days: 1)),
        planName: 'Pull Day',
        exercises: [
          {
            'exerciseId': 'pull_up',
            'sets': [
              {'reps': 8},
              {'reps': 7},
            ],
          },
          {
            'exerciseId': 'row',
            'sets': [
              {'reps': 10, 'weight': 60},
            ],
          },
        ],
      );

      final log = (await _repo(db).watchDashboard().first).workoutLog;

      expect(log, isNotNull);
      expect(log!.totalSets, 3);
      expect(log.planName, 'Pull Day');
    });

    test('eine Einheit ohne Übungen liefert keine Kachel', () async {
      final db = _db();
      await _addSession(db, date: _today, type: 'cardio');

      expect((await _repo(db).watchDashboard().first).workoutLog, isNull);
    });
  });

  group('Anzeigename', () {
    Future<DashboardData> read(
      FakeFirebaseFirestore db, {
      String? fallback,
    }) =>
        _repo(db, fallbackDisplayName: fallback).watchDashboard().first;

    test('das Profil hat Vorrang', () async {
      final db = _db();
      await db.collection('userProfiles').doc('u1').set({
        'displayName': 'Christian Müller',
        'email': 'c@example.com',
      });

      expect((await read(db, fallback: 'Aus der Anmeldung')).user.displayName,
          'Christian Müller');
    });

    test('ein leerer Profilname fällt auf die Anmeldung zurück', () async {
      // Genau dieser Fall liegt im Produktivbestand vor: ein Konto mit
      // displayName = ''.
      final db = _db();
      await db.collection('userProfiles').doc('u1').set({'displayName': ''});

      expect((await read(db, fallback: 'Aus der Anmeldung')).user.displayName,
          'Aus der Anmeldung');
    });

    test('ohne beides bleibt der Teil vor dem @ der E-Mail', () async {
      final db = _db();
      await db
          .collection('userProfiles')
          .doc('u1')
          .set({'displayName': '', 'email': 'christian@example.com'});

      expect((await read(db)).user.displayName, 'christian');
    });
  });

  test('das Körpergewicht wird als Zahl gelesen, nicht als int', () async {
    // R1 aus Vertrag 4: Im Bestand steht einmal 70 und einmal 68.5.
    for (final weight in <Object>[70, 68.5]) {
      final db = _db();
      await db.collection('userProfiles').doc('u1').set({'bodyWeight': weight});
      await _seedHistory(db);

      // Es geht nur darum, dass nichts wirft.
      final data = await _repo(db).watchDashboard().first;
      expect(data.readiness.score, isNotNull);
    }
  });

  test('nach langer Pause meldet der Bogen keine Überlastung', () async {
    // Der Fall, der auf dem Gerät auffiel: ein halbes Jahr Training, fünfzig
    // Tage Pause, dann eine einzige Einheit. Die Formel liefert dafür ACWR 2,95
    // und damit „überreizt" — das Gegenteil der Wahrheit.
    final db = _db();
    for (var d = 230; d >= 50; d -= 3) {
      await _addSession(db,
          date: _today.subtract(Duration(days: d)), duration: 45, rpe: 3);
    }
    await _addSession(db, date: _today, duration: 45, rpe: 3);

    final data = await _repo(db).watchDashboard().first;

    expect(data.readiness.zone, isNull,
        reason: 'Ohne genug Einheiten im akuten Fenster ist der ACWR keine '
            'Aussage, sondern eine Division.');
  });

  test('mit dichtem Training kommt die Zone zurück', () async {
    final db = _db();
    for (var d = 60; d >= 0; d -= 3) {
      await _addSession(db,
          date: _today.subtract(Duration(days: d)), duration: 45, rpe: 3);
    }

    final data = await _repo(db).watchDashboard().first;
    expect(data.readiness.zone, isNotNull);
  });

  test('der Strom meldet, wenn eine Einheit dazukommt', () async {
    final db = _db();
    await _seedHistory(db);

    final seen = <int>[];
    final sub = _repo(db)
        .watchDashboard()
        .listen((d) => seen.add(d.performance.days.length));

    await Future<void>.delayed(Duration.zero);
    await _addSession(db, date: _today);
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(seen.length, greaterThanOrEqualTo(2));
  });
}
