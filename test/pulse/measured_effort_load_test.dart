import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/domain/measured_effort.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die gemessene Anstrengung in der Trainingslast (A1, Schritt 2).
///
/// Der Vertrag in einem Satz: **Eine Messung überschreibt keine Eingabe, und
/// ohne Messung ändert sich nichts.** Dieselbe Regel, die `weight_sync.dart`
/// am 20.09.2026 fürs Gewicht getroffen hat — und dieselben drei Prüfungen
/// wie in `test/weight/weight_load_test.dart`.
void main() {
  final zones = HeartRateZones.tryFrom(const [120, 140, 160, 175])!;
  final day = DateTime(2026, 9, 10);

  /// Ein Uhr-Datensatz, dessen Puls ganz in [zone] lag.
  HealthSession watch(
    String externalId,
    int zone, {
    HealthSessionState state = HealthSessionState.accepted,
    PulseProfile? pulse,
    int windowMinutes = 40,
  }) {
    final bpm = <int, int>{1: 100, 2: 130, 3: 150, 4: 168, 5: 185}[zone]!;
    return HealthSession.pending(
      MeasuredSession(
        id: externalId,
        start: day,
        end: day.add(Duration(minutes: windowMinutes)),
        sourceId: 'garmin',
        pulse: pulse ??
            PulseProfile(
              secondsByBpm: {bpm: windowMinutes * 60},
              windowSeconds: windowMinutes * 60,
            ),
      ),
      day,
    ).copyWith(state: state);
  }

  CardioSession run({int? rpe, String? linked}) => CardioSession(
        id: 'c',
        userId: 'u',
        date: day,
        createdAt: day,
        activity: CardioActivity.run,
        duration: const Duration(minutes: 40),
        rpe: rpe,
        healthSessionId: linked,
      );

  LoadContext contextOf(List<HealthSession> records) {
    final efforts =
        MeasuredEfforts.from(records: records, zones: zones);
    return LoadContext(
      measuredEffortOf: efforts.isEmpty ? null : efforts.of,
    );
  }

  group('die Reihenfolge', () {
    test('ohne Messung rechnet die Last wie vorher', () {
      final before = TrainingLoad.of(run(), const LoadContext());
      final after = TrainingLoad.of(run(linked: 'w'), contextOf(const []));
      expect(after, before);
    });

    test('eine Messung überschreibt keine Eingabe', () {
      // Getippt: 1 (sehr leicht). Gemessen: Zone 5. Die Eingabe gewinnt.
      final typed = TrainingLoad.of(
          run(rpe: 1, linked: 'w'), contextOf([watch('w', 5)]));
      final typedAlone =
          TrainingLoad.of(run(rpe: 1), const LoadContext());
      expect(typed, typedAlone);
    });

    test('ohne Eingabe tritt die Messung an die Stelle der Ersatzzahl 3', () {
      final guessed = TrainingLoad.of(run(), const LoadContext());
      final measured = TrainingLoad.of(
          run(linked: 'w'), contextOf([watch('w', 5)]));

      // Zone 5 ⇒ Anstrengung 5 ⇒ Faktor 1,4 statt 1,0.
      expect(measured, greaterThan(guessed));
      expect(measured / guessed, closeTo(1.4 / 1.0, 0.001));
    });

    test('ein ruhiger Lauf fällt unter die Ersatzzahl', () {
      final guessed = TrainingLoad.of(run(), const LoadContext());
      final measured = TrainingLoad.of(
          run(linked: 'w'), contextOf([watch('w', 1)]));

      expect(measured, lessThan(guessed));
      expect(measured / guessed, closeTo(0.6 / 1.0, 0.001));
    });
  });

  group('wann die Tabelle nichts hergibt', () {
    test('ohne festgelegte Zonen gibt es keine Anstrengung', () {
      final efforts =
          MeasuredEfforts.from(records: [watch('w', 5)], zones: null);
      expect(efforts.isEmpty, isTrue);
    });

    test('ein abgelehnter Datensatz zählt nicht', () {
      final efforts = MeasuredEfforts.from(
        records: [watch('w', 5, state: HealthSessionState.rejected)],
        zones: zones,
      );
      expect(efforts.isEmpty, isTrue);
    });

    test('ein wartender Datensatz zählt nicht', () {
      final efforts = MeasuredEfforts.from(
        records: [watch('w', 5, state: HealthSessionState.pending)],
        zones: zones,
      );
      expect(efforts.isEmpty, isTrue);
    });

    test('ein Datensatz ohne Pulsverlauf zählt nicht', () {
      // Alles, was vor dem 21.09.2026 gelesen wurde, trägt keinen.
      final records = [
        HealthSession.pending(
          MeasuredSession(
            id: 'w',
            start: day,
            end: day.add(const Duration(minutes: 40)),
            sourceId: 'garmin',
          ),
          day,
        ).copyWith(state: HealthSessionState.accepted),
      ];
      expect(MeasuredEfforts.from(records: records, zones: zones).isEmpty,
          isTrue);
    });

    test('eine zu dünne Aufzeichnung zählt nicht', () {
      final thin = watch(
        'w',
        5,
        pulse: const PulseProfile(
          secondsByBpm: {185: 600}, // 10 min …
          windowSeconds: 3600, // … von 60
        ),
      );
      expect(MeasuredEfforts.from(records: [thin], zones: zones).isEmpty,
          isTrue);
    });

    test('eine Einheit ohne Verknüpfung fragt gar nicht erst', () {
      final efforts =
          MeasuredEfforts.from(records: [watch('w', 5)], zones: zones);
      expect(efforts.of(run()), isNull);
      expect(efforts.of(run(linked: 'w')), 5);
    });
  });

  group('Kraft bleibt vorerst unberührt', () {
    test('eine Krafteinheit mit Uhr rechnet weiter mit der Ersatzzahl', () {
      StrengthSession lifting({String? linked}) => StrengthSession(
            id: 's',
            userId: 'u',
            date: day,
            createdAt: day,
            bodyweight: false,
            duration: const Duration(minutes: 50),
            healthSessionId: linked,
          );

      // Der Puls misst bei Kraft etwas anderes als bei Ausdauer — eine
      // schwere Kniebeuge treibt ihn kaum, ein Zirkel dafür weit. Solange
      // dafür keine Begründung steht, ändert sich hier nichts. Schlägt
      // dieser Test fehl, war es eine Entscheidung und kein Versehen.
      final withWatch = TrainingLoad.of(
          lifting(linked: 'w'), contextOf([watch('w', 5)]));
      final without = TrainingLoad.of(lifting(), const LoadContext());
      expect(withWatch, without);
    });
  });
}
