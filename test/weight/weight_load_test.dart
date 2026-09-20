import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Trainingslast rechnet zeitgenau (Board 14, Abschnitt E).
///
/// Bis zum 20.09.2026 bewertete **ein** aktuelles Gewicht jede
/// Körpergewichtsübung des gesamten Verlaufs. Mit einer Reihe gilt je Einheit
/// der Wert, der an ihrem Tag zuletzt bekannt war — ein neuer Eintrag
/// verschiebt deshalb nur noch die Spanne bis zum nächsten.

StrengthSession _pullUps(DateTime date) => StrengthSession(
      id: 's',
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      duration: const Duration(minutes: 30),
      rpe: 3,
      exercises: [
        LoggedExercise(
          exerciseId: 'pull_up',
          usesBodyweight: true,
          sets: [for (var i = 0; i < 4; i++) const LoggedSet(reps: 8)],
        ),
      ],
    );

void main() {
  final series = WeightSeries.of([
    WeightEntry(
        date: DateTime(2026, 3, 1), kg: 90, source: WeightSource.manual),
    WeightEntry(
        date: DateTime(2026, 9, 1), kg: 80, source: WeightSource.manual),
  ]);

  LoadContext contextWith({double fallback = 0}) => LoadContext(
        bodyWeightKg: fallback,
        bodyWeightOn: series.kgOn,
      );

  test('eine alte Einheit behält ihren alten Maßstab', () {
    final march = TrainingLoad.of(_pullUps(DateTime(2026, 4, 10)),
        contextWith());
    final september = TrainingLoad.of(_pullUps(DateTime(2026, 9, 10)),
        contextWith());

    // 90 kg gegen 80 kg bei gleichem Satzwerk: Die ältere Einheit wiegt mehr.
    expect(march, greaterThan(september));
    expect(march / september, closeTo(90 / 80, 0.01));
  });

  test('ohne Reihe gilt der Profilwert wie bisher', () {
    final withSeries =
        TrainingLoad.of(_pullUps(DateTime(2026, 9, 10)), contextWith());
    final withoutSeries = TrainingLoad.of(
        _pullUps(DateTime(2026, 9, 10)), const LoadContext(bodyWeightKg: 80));

    expect(withSeries, withoutSeries);
  });

  test('vor dem ersten Eintrag rechnet die Last nicht mit null', () {
    final before =
        TrainingLoad.of(_pullUps(DateTime(2026, 1, 15)), contextWith());

    // Sonst fiele die gesamte Vergangenheit auf die Ersatzrechnung nach Dauer
    // zurück — sichtbar als Sprung in ACWR und Bereitschaft.
    expect(before, greaterThan(0));
    expect(before,
        TrainingLoad.of(_pullUps(DateTime(2026, 4, 10)), contextWith()));
  });
}
