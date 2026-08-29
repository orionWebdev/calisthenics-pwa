import 'package:atem/features/history/domain/training_form.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regeneration bricht die Pause, trägt aber keine Last.
///
/// Die Abweichung von der Vorgänger-App ist gewollt und steht in
/// [TrainingForm.defaultCountRecoveryAsActivity] begründet. Dieser Test hält
/// beide Hälften der Entscheidung fest — die, die zählt, und die, die nicht
/// zählt. Ohne die zweite wäre „Regeneration zählt" schnell zu „Sauna baut
/// Form auf" geworden.
void main() {
  final ref = DateTime(2026, 6, 1);

  StrengthSession strength(int daysAgo) => StrengthSession(
        id: 's$daysAgo',
        userId: 'u',
        date: ref.subtract(Duration(days: daysAgo)),
        createdAt: ref,
        bodyweight: false,
        duration: const Duration(minutes: 60),
        rpe: 3,
      );

  RecoverySession recovery(int daysAgo) => RecoverySession(
        id: 'r$daysAgo',
        userId: 'u',
        date: ref.subtract(Duration(days: daysAgo)),
        createdAt: ref,
        duration: const Duration(minutes: 30),
      );

  // Genug Geschichte für eine Formrechnung: alle drei Tage eine Einheit,
  // die letzte vor 12 Tagen. Danach nichts mehr.
  final base = [for (var d = 60; d >= 10; d -= 3) strength(d)];

  test('ohne Regeneration bleibt die Pause bestehen', () {
    final result = TrainingForm.compute(base, ref);

    expect(result.daysSinceLastSession, 12);
    expect(result.recency, 0);
    expect(result.lastWasRecovery, isFalse);
    expect(result.inactivityPenalty, greaterThan(0));
  });

  test('eine Regenerationseinheit gestern bricht die Pause', () {
    final result = TrainingForm.compute([...base, recovery(1)], ref);

    expect(result.daysSinceLastSession, 1);
    expect(result.recency, 15);
    expect(result.lastWasRecovery, isTrue);
    expect(result.inactivityPenalty, 0);
  });

  test('sie trägt aber keine Last', () {
    final without = TrainingForm.compute(base, ref);
    final with_ = TrainingForm.compute([...base, recovery(1)], ref);

    // Konstanz zählt Trainingstage, nicht Aktivitätstage.
    expect(with_.consistency, without.consistency);
    // Kein Tageszuschlag, auch wenn die Regeneration heute stattfand.
    expect(TrainingForm.compute([...base, recovery(0)], ref).sessionBonus, 0);
    // Und die Fitnesskurve bleibt unberührt.
    expect(with_.fitnessVsPeak, without.fitnessVsPeak);
  });

  test('eine ältere Regenerationseinheit ändert nichts', () {
    // Regeneration vor der letzten Trainingseinheit ist nicht die letzte
    // Aktivität — die Reihenfolge muss stimmen, nicht bloß das Vorkommen.
    final result = TrainingForm.compute([...base, recovery(40)], ref);

    expect(result.daysSinceLastSession, 12);
    expect(result.lastWasRecovery, isFalse);
  });

  test('der Schalter stellt die Rechnung der Vorgänger-App wieder her', () {
    final result = TrainingForm.compute([...base, recovery(1)], ref,
        countRecoveryAsActivity: false);

    expect(result.daysSinceLastSession, 12);
    expect(result.recency, 0);
    expect(result.lastWasRecovery, isFalse);
  });

  test('ein Bestand aus reiner Regeneration ergibt keinen Formwert', () {
    // Ohne eine einzige Einheit mit Last gibt es nichts zu bewerten. Ein
    // Formwert allein aus Yoga wäre eine Zahl ohne Grundlage.
    final result =
        TrainingForm.compute([for (var d = 60; d >= 0; d -= 2) recovery(d)], ref);

    expect(result.hasScore, isFalse);
  });
}
