import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/health_access.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die fünf Zustände aus Board 15, Abschnitt D — reine Ableitung.
void main() {
  HealthAccessState state({
    HealthAvailability availability = HealthAvailability.available,
    bool? weight,
    bool? sessions,
    int imported = 0,
    int weights = 0,
  }) =>
      HealthAccessState.of(
        availability: availability,
        weightGranted: weight,
        sessionsGranted: sessions,
        importedSessions: imported,
        measuredWeights: weights,
      );

  test('D1 — ohne Health Connect ist keine Zeile bedienbar', () {
    for (final missing in [
      HealthAvailability.unsupported,
      HealthAvailability.notInstalled,
      HealthAvailability.needsUpdate,
    ]) {
      final s = state(availability: missing, weight: true, sessions: true);
      expect(s.weight, HealthAccess.missing);
      expect(s.sessions, HealthAccess.missing);
      expect(s.isMissing, isTrue);
    }
  });

  test('D2 — nichts freigegeben, nichts im Bestand', () {
    final s = state(weight: false, sessions: false);
    expect(s.weight, HealthAccess.denied);
    expect(s.sessions, HealthAccess.denied);
  });

  test('D3 — Gewicht ja, Einheiten nein', () {
    final s = state(weight: true, sessions: false);
    expect(s.weight, HealthAccess.granted);
    expect(s.sessions, HealthAccess.denied);
  });

  test('D4 — alles frei, nichts gelesen', () {
    final s = HealthAccessState.of(
      availability: HealthAvailability.available,
      weightGranted: true,
      sessionsGranted: true,
      importedSessions: 0,
      measuredWeights: 9,
      lastRead: DateTime(2026, 9, 20, 7, 12),
    );
    expect(s.sessions, HealthAccess.granted);
    expect(s.readNothing, isTrue);
  });

  group('D5 — entzogen, Daten bleiben', () {
    test('was schon da ist, verrät den früheren Zugang', () {
      // Android antwortet bei entzogener Berechtigung wie bei nie erteilter.
      final s = state(weight: false, sessions: false, imported: 14, weights: 9);
      expect(s.weight, HealthAccess.revoked);
      expect(s.sessions, HealthAccess.revoked);
      expect(s.importedSessions, 14);
      expect(s.measuredWeights, 9);
    });

    test('je Datentyp getrennt — Gewicht kann entzogen sein, Einheiten nie '
        'erteilt', () {
      final s = state(weight: false, sessions: false, weights: 9);
      expect(s.weight, HealthAccess.revoked);
      expect(s.sessions, HealthAccess.denied);
    });
  });

  test('„kann nicht antworten" gilt wie „nicht freigegeben"', () {
    // Ein `null` von der Plattform ist kein Zugang — gefragt werden muss so
    // oder so.
    final s = state(weight: null, sessions: null);
    expect(s.weight, HealthAccess.denied);
    expect(s.sessions, HealthAccess.denied);
  });
}
