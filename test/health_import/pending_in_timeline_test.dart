import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/presentation/pending_in_timeline.dart';
import 'package:atem/features/history/domain/history_timeline.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wartende Uhr-Einheiten stehen an ihrem echten Datum in der Liste
/// (Board 15, Entscheidung 4).
void main() {
  HealthSession pending(String id, DateTime start) => HealthSession.pending(
        MeasuredSession(
          id: id,
          start: start,
          end: start.add(const Duration(minutes: 42)),
          sourceId: 'garmin',
        ),
        start,
      );

  TimelineSession app(DateTime date) => TimelineSession(
        session: StrengthSession(
          id: 'a-${date.day}',
          userId: 'u',
          date: date,
          createdAt: date,
          bodyweight: false,
        ),
      );

  const header = MonthHeader(year: 2026, month: 9, sessions: 2, load: 100);

  List<String> shape(List<ListedEntry> merged) => [
        for (final e in merged)
          switch (e) {
            ListedPending(:final session) => 'P${session.externalId}',
            ListedTimeline(:final entry) => switch (entry) {
                MonthHeader() => 'MONAT',
                TimelineSession(:final session) => 'S${session.date.day}',
                _ => '?',
              },
          },
      ];

  test('die wartende Zeile steht zwischen den Einheiten, nach Datum', () {
    final merged = mergePendingIntoTimeline(
      [header, app(DateTime(2026, 9, 22)), app(DateTime(2026, 9, 18))],
      [pending('x', DateTime(2026, 9, 20, 9, 14))],
    );
    expect(shape(merged), ['MONAT', 'S22', 'Px', 'S18']);
  });

  test('nie vor einem Monatskopf — der eröffnet seinen Monat', () {
    // Die wartende Einheit ist jünger als alles in der Liste.
    final merged = mergePendingIntoTimeline(
      [header, app(DateTime(2026, 9, 18))],
      [pending('x', DateTime(2026, 9, 25))],
    );
    expect(shape(merged), ['MONAT', 'Px', 'S18']);
  });

  test('was älter ist als jede Einheit, steht am Schluss', () {
    final merged = mergePendingIntoTimeline(
      [header, app(DateTime(2026, 9, 18))],
      [pending('x', DateTime(2026, 9, 2))],
    );
    expect(shape(merged), ['MONAT', 'S18', 'Px']);
  });

  test('mehrere warten in ihrer eigenen Reihenfolge', () {
    final merged = mergePendingIntoTimeline(
      [app(DateTime(2026, 9, 22)), app(DateTime(2026, 9, 10))],
      [
        pending('alt', DateTime(2026, 9, 12)),
        pending('neu', DateTime(2026, 9, 20)),
      ],
    );
    expect(shape(merged), ['S22', 'Pneu', 'Palt', 'S10']);
  });

  test('ohne Wartende bleibt die Liste, wie sie war', () {
    final merged = mergePendingIntoTimeline([header, app(DateTime(2026, 9, 18))], []);
    expect(shape(merged), ['MONAT', 'S18']);
  });

  test('eine leere Liste trägt die Wartenden trotzdem', () {
    final merged = mergePendingIntoTimeline([], [pending('x', DateTime(2026, 9, 2))]);
    expect(shape(merged), ['Px']);
  });
}
