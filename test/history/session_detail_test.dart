import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/history/domain/session_detail.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der rechnende Teil des Einheitendetails (Board 16).
void main() {
  StrengthSession strength({
    String id = 's',
    DateTime? date,
    Duration? duration = const Duration(minutes: 52),
    List<LoggedExercise> exercises = const [],
    String? healthId,
    bool fromHealth = false,
  }) =>
      StrengthSession(
        id: id,
        userId: 'u',
        date: date ?? DateTime(2026, 9, 18),
        createdAt: date ?? DateTime(2026, 9, 18),
        duration: duration,
        bodyweight: false,
        exercises: exercises,
        healthSessionId: healthId,
        fromHealth: fromHealth,
      );

  LoggedExercise bench(List<LoggedSet> sets, {String id = 'bench'}) =>
      LoggedExercise(exerciseId: id, sets: sets);

  const set80 = LoggedSet(reps: 8, weight: 80);

  group('Leitwertkette', () {
    test('Kraft: Sätze vor Volumen vor Dauer', () {
      final lead = SessionDetail.leadOf(
        strength(exercises: [
          bench([set80, set80, set80]),
        ]),
      )!;
      expect(lead.kind, LeadKind.sets);
      expect(lead.value, 3);
    });

    test('Kraft ohne Übungen: die Dauer', () {
      final lead = SessionDetail.leadOf(strength())!;
      expect(lead.kind, LeadKind.duration);
      expect(lead.value, 52);
    });

    test('Kraft ohne alles: keine Zahl — und das ist gültig', () {
      // 16 von 63 Krafteinheiten im Bestand sehen so aus.
      expect(SessionDetail.leadOf(strength(duration: null)), isNull);
    });

    test('Ausdauer: Strecke vor Dauer', () {
      final run = CardioSession(
        id: 'r',
        userId: 'u',
        date: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
        duration: const Duration(minutes: 48),
        distanceKm: 8.42,
      );
      final lead = SessionDetail.leadOf(run)!;
      expect(lead.kind, LeadKind.distance);
      expect(lead.value, 8.42);
    });

    test('Ausdauer ohne Strecke: die Dauer', () {
      final walk = CardioSession(
        id: 'w',
        userId: 'u',
        date: DateTime(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
        duration: const Duration(minutes: 30),
      );
      expect(SessionDetail.leadOf(walk)!.kind, LeadKind.duration);
    });

    test('Volumen ohne Gewichtsangabe ist kein Volumen, nicht 0 kg', () {
      // „Eine Zahl, die lügt, ist schlechter als eine, die fehlt."
      final session = strength(exercises: [
        bench(const [LoggedSet(reps: 12), LoggedSet(reps: 12)]),
      ]);
      expect(SessionDetail.volumeKg(session), isNull);
      expect(SessionDetail.setCount(session), 2);
    });

    test('leere Sätze zählen nicht', () {
      final session = strength(exercises: [
        bench([set80, const LoggedSet()]),
      ]);
      expect(SessionDetail.setCount(session), 1);
    });
  });

  group('Kacheln', () {
    final watch = WatchFigures(
      start: DateTime(2026, 9, 18, 18, 4),
      end: DateTime(2026, 9, 18, 18, 56),
      averageHeartRate: 118,
      calories: 412,
    );

    test('die ersten vier mit Daten, in der Reihenfolge des Katalogs', () {
      final tiles = SessionDetail.tilesOf(
        strength(
          exercises: [
            bench([set80, set80, set80]),
          ],
          healthId: 'hc',
        ),
        watch: watch,
        load: 400,
      );

      expect(
        tiles.map((t) => t.kind),
        [
          MetricKind.duration,
          MetricKind.volume,
          MetricKind.heartRateAvg,
          MetricKind.calories,
        ],
        reason: 'Last steht zuletzt und rückt nur nach, wo Platz ist',
      );
    });

    test('Puls und Kalorien kommen aus der Uhr, Dauer und Volumen aus der App',
        () {
      final tiles = SessionDetail.tilesOf(
        strength(
          exercises: [
            bench([set80]),
          ],
          healthId: 'hc',
        ),
        watch: watch,
      );

      MetricSource of(MetricKind k) =>
          tiles.firstWhere((t) => t.kind == k).source;
      expect(of(MetricKind.duration), MetricSource.app);
      expect(of(MetricKind.volume), MetricSource.app);
      expect(of(MetricKind.heartRateAvg), MetricSource.watch);
      expect(of(MetricKind.calories), MetricSource.watch);
    });

    test('aus der Uhr entstanden: alles kommt aus der Uhr', () {
      final tiles = SessionDetail.tilesOf(
        strength(fromHealth: true, healthId: 'hc'),
        watch: watch,
      );
      expect(tiles.every((t) => t.source == MetricSource.watch), isTrue);
    });

    test('die Dauer ist nicht zweimal da', () {
      // Regeneration: Die Dauer ist schon die Leitzahl — eine Kachel wäre
      // dieselbe Zahl noch einmal.
      final recovery = RecoverySession(
        id: 'rec',
        userId: 'u',
        date: DateTime(2026, 9, 17),
        createdAt: DateTime(2026, 9, 17),
        duration: const Duration(minutes: 30),
      );
      expect(SessionDetail.leadOf(recovery)!.kind, LeadKind.duration);
      expect(SessionDetail.tilesOf(recovery), isEmpty);
    });

    test('nie mehr als vier', () {
      final tiles = SessionDetail.tilesOf(
        strength(exercises: [
          bench([set80]),
        ]),
        watch: watch,
        load: 400,
      );
      expect(tiles.length, lessThanOrEqualTo(SessionDetail.maxTiles));
    });

    test('der Puls kommt aus dem Verlauf, wenn er da ist', () {
      // Eine Quelle: Ø aus dem Histogramm, nicht ein zweiter gespeicherter
      // Wert daneben.
      final figures = WatchFigures(
        start: DateTime(2026, 9, 18, 18),
        end: DateTime(2026, 9, 18, 18, 10),
        averageHeartRate: 999,
        pulse: const PulseProfile(
          secondsByBpm: {100: 300, 140: 300},
          windowSeconds: 600,
        ),
      );
      expect(figures.heartRateAvg, 120);
      expect(figures.heartRateMax, 140);
      expect(figures.heartRateMin, 100);
    });
  });

  group('Übungen und ihr Vergleich', () {
    final before = strength(
      id: 'vor',
      date: DateTime(2026, 9, 11),
      exercises: [
        bench([const LoggedSet(reps: 8, weight: 77.5)]),
        const LoggedExercise(exerciseId: 'press', sets: [
          LoggedSet(reps: 12, weight: 32),
        ]),
      ],
    );

    test('mehr Gewicht: Delta in kg, mit Datum', () {
      final session = strength(exercises: [
        bench([set80, set80, set80]),
      ]);
      final rows = SessionDetail.exercisesOf(session, [before, session]);

      expect(rows.single.sets, 3);
      expect(rows.single.weightKg, 80);
      expect(rows.single.delta.kind, DeltaKind.weight);
      expect(rows.single.delta.amount, 2.5);
      expect(rows.single.delta.against, DateTime(2026, 9, 11));
    });

    test('gleiches Gewicht, weniger Wiederholungen: Delta in Wdh', () {
      // Das Beispiel des Boards: „▼ 2 Wdh gegen 11. Sep".
      final session = strength(exercises: [
        const LoggedExercise(exerciseId: 'press', sets: [
          LoggedSet(reps: 10, weight: 32),
        ]),
      ]);
      final rows = SessionDetail.exercisesOf(session, [before, session]);

      expect(rows.single.delta.kind, DeltaKind.reps);
      expect(rows.single.delta.amount, -2);
    });

    test('ohne frühere Ausführung kein Delta', () {
      final session = strength(exercises: [
        bench(const [LoggedSet(reps: 12)], id: 'dips'),
      ]);
      final rows = SessionDetail.exercisesOf(session, [before, session]);

      expect(rows.single.delta.kind, DeltaKind.none,
          reason: 'kein „—" als Wert, kein erfundener Bezug');
      expect(rows.single.isBodyweight, isTrue);
    });

    test('der Bezug ist dieselbe Übung, nicht die vorige Einheit', () {
      // Die vorige Einheit trug Bankdrücken. Für Kniebeugen gibt es keinen
      // Bezug, auch wenn es gestern eine Einheit gab.
      final session = strength(exercises: [
        bench([set80], id: 'squat'),
      ]);
      final rows = SessionDetail.exercisesOf(session, [before, session]);
      expect(rows.single.delta.kind, DeltaKind.none);
    });

    test('Aufwärmsätze zählen nicht als Arbeitssätze', () {
      final session = strength(exercises: [
        bench(const [
          LoggedSet(reps: 10, weight: 40, rawType: 'warmup'),
          LoggedSet(reps: 8, weight: 80),
        ]),
      ]);
      final row = SessionDetail.exercisesOf(session, [session]).single;

      expect(row.sets, 1);
      expect(row.weightKg, 80);
      // Für die aufgeklappte Zeile bleiben alle Sätze erhalten.
      expect(row.allSets, hasLength(2));
    });

    test('eine spätere Einheit ist kein Bezug', () {
      final later = strength(
        id: 'spaeter',
        date: DateTime(2026, 9, 25),
        exercises: [
          bench([const LoggedSet(reps: 8, weight: 100)]),
        ],
      );
      final session = strength(exercises: [
        bench([set80]),
      ]);
      final rows = SessionDetail.exercisesOf(session, [later, before, session]);
      expect(rows.single.delta.against, DateTime(2026, 9, 11));
    });
  });
}
