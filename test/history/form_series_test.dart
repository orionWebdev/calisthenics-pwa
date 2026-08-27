import 'package:atem/features/history/domain/form_series.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _ref = DateTime(2026, 8, 27);

TrainingSession _s(DateTime date) => StrengthSession(
      id: date.toIso8601String(),
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: const Duration(minutes: 45),
      rpe: 3,
    );

void main() {
  test('ohne Einheiten gibt es keine Kurve', () {
    expect(FormSeries.compute(const [], _ref).isEmpty, isTrue);
  });

  test('ein Punkt je Tag, von der ersten Einheit bis zum Stichtag', () {
    final sessions = [
      for (var i = 0; i < 5; i++) _s(DateTime(2026, 8, 10 + i * 2)),
    ];
    final series = FormSeries.compute(sessions, _ref);

    expect(series.points.first.date, DateTime(2026, 8, 10));
    expect(series.points.last.date, DateTime(2026, 8, 27));
    expect(series.points, hasLength(18));
  });

  test('Trainingstage sind markiert, die dazwischen nicht', () {
    final series = FormSeries.compute(
      [_s(DateTime(2026, 8, 20)), _s(DateTime(2026, 8, 24))],
      _ref,
    );

    final byDate = {for (final p in series.points) p.date: p};
    expect(byDate[DateTime(2026, 8, 20)]!.hasTraining, isTrue);
    expect(byDate[DateTime(2026, 8, 21)]!.hasTraining, isFalse);
    expect(byDate[DateTime(2026, 8, 24)]!.hasTraining, isTrue);
    // Nach der letzten Einheit läuft die Kurve weiter — echt, aber
    // trainingsfrei. Sie endet nicht.
    expect(byDate[DateTime(2026, 8, 27)]!.hasTraining, isFalse);
  });

  test('die Kurve wird nach der letzten Einheit nicht abgeschnitten', () {
    final series = FormSeries.compute([_s(DateTime(2026, 6, 1))], _ref);
    expect(series.points.last.date, DateTime(2026, 8, 27));
  });

  test('Einheiten je Woche, Wochenbeginn Montag', () {
    // Der 24.08.2026 ist ein Montag.
    final series = FormSeries.compute([
      _s(DateTime(2026, 8, 24)),
      _s(DateTime(2026, 8, 26)),
      _s(DateTime(2026, 8, 27)),
    ], _ref);

    expect(series.weeks.last.weekStart.weekday, DateTime.monday);
    expect(series.weeks.last.count, 3);
    expect(series.maxPerWeek, 3);
  });

  test('zwei Einheiten am selben Tag zählen als ein Trainingstag', () {
    final day = DateTime(2026, 8, 25);
    final series = FormSeries.compute([
      _s(day.add(const Duration(hours: 7))),
      _s(day.add(const Duration(hours: 19))),
    ], _ref);

    expect(series.weeks.last.count, 1);
  });

  test('alle Werte liegen im Bereich, den der Chart erwartet', () {
    final sessions = [
      for (var i = 0; i < 40; i++) _s(DateTime(2026, 3, 1 + i * 3)),
    ];
    for (final p in FormSeries.compute(sessions, _ref).points) {
      expect(p.value, inInclusiveRange(0, 100));
    }
  });
}
