import 'package:atem/features/history/domain/session_detail.dart';
import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Lastkachel nennt, womit gerechnet wurde (Board 16, Nachtrag, M/N).
void main() {
  final day = DateTime(2026, 9, 20);

  CardioSession run({int? rpe}) => CardioSession(
        id: 'c',
        userId: 'u',
        date: day,
        createdAt: day,
        activity: CardioActivity.run,
        duration: const Duration(minutes: 48),
        rpe: rpe,
        healthSessionId: 'w',
      );

  MetricTile loadTile(TrainingSession s, LoadContext ctx) =>
      SessionDetail.tilesOf(s, load: TrainingLoad.of(s, ctx), context: ctx)
          .firstWhere((t) => t.kind == MetricKind.load);

  test('eingetragen: die Eingabe ist die Grundlage', () {
    final tile = loadTile(run(rpe: 4), const LoadContext());
    expect(tile.effortBasis, EffortBasis.entered);
    expect(tile.effort, 4);
  });

  test('gemessen: die Uhr tritt an die Stelle der Ersatzzahl', () {
    final tile = loadTile(run(), LoadContext(measuredEffortOf: (_) => 3));
    expect(tile.effortBasis, EffortBasis.measured);
    expect(tile.effort, 3);
  });

  test('eine Messung verdrängt die Eingabe auch hier nicht', () {
    final tile =
        loadTile(run(rpe: 4), LoadContext(measuredEffortOf: (_) => 1));
    expect(tile.effortBasis, EffortBasis.entered);
    expect(tile.effort, 4);
  });

  test('ohne beides steht der Ersatzwert — benannt, nicht verschwiegen', () {
    final tile = loadTile(run(), const LoadContext());
    expect(tile.effortBasis, EffortBasis.fallback);
    expect(tile.effort, TrainingLoad.defaultRpe);
  });

  test('die Last trägt weiter keinen Herkunftspunkt', () {
    // Board 16, Nachtrag: Gemessen ist die Eingangsgrösse, nicht die Zahl.
    final tile = loadTile(run(), LoadContext(measuredEffortOf: (_) => 5));
    expect(tile.source, MetricSource.app);
  });
}
