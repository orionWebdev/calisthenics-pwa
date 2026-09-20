import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/import_action.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Was aus einer angenommenen Uhr-Einheit im Bestand wird (Board 15).
void main() {
  final start = DateTime(2026, 9, 20, 9, 14);

  HealthSession session({String? activity = 'RUNNING', int? avg = 148}) =>
      HealthSession.pending(
        MeasuredSession(
          id: 'hc-1',
          start: start,
          end: start.add(const Duration(minutes: 42)),
          sourceId: 'garmin',
          activity: activity,
          deviceName: 'Garmin',
          averageHeartRate: avg,
          maxHeartRate: 171,
          calories: 412,
          distanceKm: 8.2,
        ),
        DateTime(2026, 9, 20, 10),
      );

  test('keine Grösse hat zwei Quellen', () {
    final draft = ImportAction.draftOf(
      session: session(),
      userId: 'u',
      rpe: 4,
      note: 'Lief gut',
    );

    // Aus der Uhr:
    expect(draft.duration, const Duration(minutes: 42));
    expect(draft.avgHr, 148);
    expect(draft.maxHr, 171);
    expect(draft.distanceKm, 8.2);
    // Vom Menschen:
    expect(draft.rpe, 4);
    expect(draft.notes, 'Lief gut');
    // Der Verweis bleibt, die Uhr-Einheit liegt daneben.
    expect(draft.healthSessionId, 'hc-1');
    expect(draft.fromHealth, isTrue);
  });

  test('die Sekunden sind echt, sie kommen aus einer Uhr', () {
    expect(ImportAction.draftOf(session: session(), userId: 'u')
        .durationHasSeconds, isTrue);
  });

  test('ohne Anstrengung wird nichts erfunden', () {
    // Entscheidung 13: kein Ersatzwert. Die Einheit fehlt dann im Nenner der
    // Last — sichtbar dünn statt glatt gerechnet.
    final draft = ImportAction.draftOf(session: session(), userId: 'u');
    expect(draft.rpe, isNull);
    expect(draft.notes, isNull);
  });

  group('Artzuordnung', () {
    test('bekannte Aktivitäten werden übersetzt', () {
      expect(ImportAction.activityOf('RUNNING'), CardioActivity.run);
      expect(ImportAction.activityOf('BIKING_STATIONARY'),
          CardioActivity.bikeIndoor);
      expect(ImportAction.activityOf('rowing'), CardioActivity.row);
    });

    test('was die Uhr „Andere" nennt, bleibt leer statt geraten', () {
      expect(ImportAction.activityOf('OTHER'), isNull);
      expect(ImportAction.activityOf(null), isNull);
      expect(ImportAction.activityOf('HIGH_INTENSITY_INTERVAL_TRAINING'),
          isNull);
    });

    test('die Art ist immer Ausdauer, solange die Zuordnungstabelle fehlt',
        () {
      // Offene Frage 4 des Boards. Eine falsch einsortierte Regeneration
      // trüge Last, die sie nicht hat.
      final yoga = ImportAction.draftOf(
          session: session(activity: 'YOGA'), userId: 'u');
      expect(yoga.kind, SessionKind.cardio);
      expect(yoga.activity, isNull);
    });
  });
}
