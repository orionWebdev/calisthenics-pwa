import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/import_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Eingang aus Board 15, Abschnitt A — reine Rechnung, ohne Gerät.
void main() {
  final now = DateTime(2026, 9, 20, 8);

  MeasuredSession watch(String id, DateTime start, {String source = 'garmin'}) =>
      MeasuredSession(
        id: id,
        start: start,
        end: start.add(const Duration(minutes: 42)),
        sourceId: source,
      );

  group('Lesefenster', () {
    test('beim ersten Mal dreissig Tage zurück', () {
      expect(ImportInbox.readFrom(now),
          DateTime(2026, 9, 20, 8).subtract(const Duration(days: 30)));
    });

    test('danach ab der letzten Lesemarke', () {
      final mark = DateTime(2026, 9, 19, 8, 3);
      expect(ImportInbox.readFrom(now, lastRead: mark), mark);
    });

    test('eine zu alte Marke wird auf das Fenster angehoben', () {
      // Was davor liegt, gibt Health Connect ohne die Historien-Berechtigung
      // ohnehin nicht heraus.
      final ancient = DateTime(2025, 1, 1);
      expect(ImportInbox.readFrom(now, lastRead: ancient),
          now.subtract(const Duration(days: 30)));
    });
  });

  group('was wartet', () {
    final a = watch('hc-a', DateTime(2026, 9, 18, 18));
    final b = watch('hc-b', DateTime(2026, 9, 20, 9, 14));
    final c = watch('hc-c', DateTime(2026, 9, 19, 7));

    List<MeasuredSession> pending({
      Set<String> imported = const {},
      Set<String> rejected = const {},
      List<MeasuredSession>? measured,
    }) =>
        ImportInbox.pending(
          measured: measured ?? [a, b, c],
          importedIds: imported,
          rejectedIds: rejected,
          ownSourceId: 'com.atemhybrid.app',
        );

    test('jüngste zuerst', () {
      expect([for (final s in pending()) s.id], ['hc-b', 'hc-c', 'hc-a']);
    });

    test('schon übernommene kommen nicht zurück', () {
      expect([for (final s in pending(imported: {'hc-b'})) s.id],
          ['hc-c', 'hc-a']);
    });

    test('abgelehnte kommen nicht wieder', () {
      // Ohne dieses Gedächtnis läge derselbe Datensatz am nächsten Morgen
      // wieder im Eingang.
      expect([for (final s in pending(rejected: {'hc-a', 'hc-c'})) s.id],
          ['hc-b']);
    });

    test('was ATEM selbst geschrieben hat, kommt nicht als fremd herein', () {
      final own = watch('hc-own', DateTime(2026, 9, 20, 6),
          source: 'com.atemhybrid.app');
      expect([for (final s in pending(measured: [own, a])) s.id], ['hc-a']);
    });

    test('nichts offen heisst leerer Eingang', () {
      expect(pending(imported: {'hc-a', 'hc-b', 'hc-c'}), isEmpty);
    });
  });
}
