import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/import_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Eingang aus Board 15, Abschnitt A — reine Rechnung, ohne Gerät.
void main() {
  final now = DateTime(2026, 9, 20, 8);

  MeasuredSession watch(String id, DateTime start,
          {String source = 'garmin'}) =>
      MeasuredSession(
        id: id,
        start: start,
        end: start.add(const Duration(minutes: 42)),
        sourceId: source,
      );

  group('Lesefenster', () {
    test('immer dreissig Tage zurück', () {
      expect(ImportInbox.readFrom(now),
          DateTime(2026, 9, 20, 8).subtract(const Duration(days: 30)));
    });

    test('ein zweiter Lauf beginnt nicht später als der erste', () {
      // Der Fehler vom 20.09.2026: Das Fenster begann an der letzten
      // Lesemarke. Ein Lauf, der nichts fand — weil eine Berechtigung
      // fehlte und Health Connect still null Einheiten lieferte —, rückte
      // die Marke trotzdem vor. Danach lag alles Ältere für immer davor.
      final erster = ImportInbox.readFrom(now);
      final zweiter = ImportInbox.readFrom(now.add(const Duration(minutes: 2)));
      expect(zweiter.difference(erster), const Duration(minutes: 2),
          reason: 'das Fenster wandert mit der Zeit, es schrumpft nicht');
      expect(now.difference(zweiter).inDays, 29);
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
      expect([
        for (final s in pending(imported: {'hc-b'})) s.id
      ], [
        'hc-c',
        'hc-a'
      ]);
    });

    test('abgelehnte kommen nicht wieder', () {
      // Ohne dieses Gedächtnis läge derselbe Datensatz am nächsten Morgen
      // wieder im Eingang.
      expect([
        for (final s in pending(rejected: {'hc-a', 'hc-c'})) s.id
      ], [
        'hc-b'
      ]);
    });

    test('was ATEM selbst geschrieben hat, kommt nicht als fremd herein', () {
      final own = watch('hc-own', DateTime(2026, 9, 20, 6),
          source: 'com.atemhybrid.app');
      expect([
        for (final s in pending(measured: [own, a])) s.id
      ], [
        'hc-a'
      ]);
    });

    test('nichts offen heisst leerer Eingang', () {
      expect(pending(imported: {'hc-a', 'hc-b', 'hc-c'}), isEmpty);
    });
  });
}
