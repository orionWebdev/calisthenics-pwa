import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Weighted-Calisthenics-Fix vom 18.09.2026, isoliert vom Testorakel.
///
/// `scoring_oracle_test.dart` beweist die Übereinstimmung mit einer
/// entsprechend korrigierten Fassung der PWA an hunderten zufälligen Fällen —
/// aber nur dort, verborgen zwischen vielen anderen Zahlen. Dieser Test sagt
/// in Worten, was der Fix eigentlich tut: ein Klimmzug mit Zusatzgewicht trägt
/// Körpergewicht **und** Zusatzlast, nicht nur eines von beiden.
void main() {
  final date = DateTime(2026, 9, 18);
  const context = LoadContext(bodyWeightKg: 80);

  StrengthSession weighted(double? extraKg) => StrengthSession(
        id: 's',
        userId: 'u',
        date: date,
        createdAt: date,
        bodyweight: true,
        exercises: [
          LoggedExercise(
            exerciseId: 'pull_up',
            usesBodyweight: true,
            sets: [LoggedSet(reps: 8, weight: extraKg)],
          ),
        ],
      );

  StrengthSession barbell(double kg) => StrengthSession(
        id: 's2',
        userId: 'u',
        date: date,
        createdAt: date,
        bodyweight: false,
        exercises: [
          LoggedExercise(
            exerciseId: 'bench_press',
            usesBodyweight: false,
            sets: [LoggedSet(reps: 8, weight: kg)],
          ),
        ],
      );

  test('Klimmzug mit 20 kg Zusatzgewicht trägt Körpergewicht plus Zusatzlast',
      () {
    final withExtra = TrainingLoad.of(weighted(20), context);
    final withoutExtra = TrainingLoad.of(weighted(null), context);

    // 80 kg Körpergewicht + 20 kg Zusatzlast = 100 kg, wie ein Hantelsatz
    // mit 100 kg bei denselben Wiederholungen und derselben RPE.
    final asHundredKgBarbell = TrainingLoad.of(barbell(100), context);

    expect(withExtra, equals(asHundredKgBarbell));
    expect(withExtra, greaterThan(withoutExtra),
        reason:
            'Zusatzgewicht muss die Last erhöhen, nicht wie zuvor verwerfen');
  });

  test('ohne Zusatzgewicht zählt weiterhin nur das Körpergewicht', () {
    final load = TrainingLoad.of(weighted(null), context);
    final expected = TrainingLoad.of(barbell(80), context);
    expect(load, equals(expected));
  });

  test('Zusatzgewicht 0 kg verändert nichts gegenüber ganz ohne Angabe', () {
    expect(TrainingLoad.of(weighted(0), context),
        equals(TrainingLoad.of(weighted(null), context)));
  });
}
