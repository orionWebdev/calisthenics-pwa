import 'package:atem/features/history/domain/session_consequence.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Bezugstag aller Rechnungen hier.
final _heute = DateTime(2026, 8, 27);

StrengthSession _s(String id, DateTime date, {int minutes = 45}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: false,
      duration: Duration(minutes: minutes),
      rpe: 3,
    );

/// Eine dichte Historie: 40 Einheiten alle drei Tage bis heute.
List<TrainingSession> _dicht() => [
      for (var i = 0; i < 40; i++)
        _s('s$i', _heute.subtract(Duration(days: i * 3))),
    ];

void main() {
  group('Löschen', () {
    test('die letzte Einheit zu löschen verlängert die Pause', () {
      final sessions = _dicht();
      final c = SessionConsequence.ofDeleting(sessions, 's0', _heute);

      expect(c.pauseBefore, 0);
      expect(c.pauseAfter, 3, reason: 'dann ist die vorletzte die letzte');
      expect(c.pauseChanges, isTrue);
      expect(c.isVisible, isTrue);
    });

    test('eine Einheit weniger ist eine Einheit weniger', () {
      final c = SessionConsequence.ofDeleting(_dicht(), 's5', _heute);
      expect(c.sessionsBefore, 40);
      expect(c.sessionsAfter, 39);
    });

    test('eine mittlere Einheit lässt die Pause unberührt', () {
      final c = SessionConsequence.ofDeleting(_dicht(), 's20', _heute);
      expect(c.pauseBefore, c.pauseAfter);
      expect(c.pauseChanges, isFalse);
    });

    test('der Formwert ändert sich, wenn Belastung wegfällt', () {
      final c = SessionConsequence.ofDeleting(_dicht(), 's0', _heute);
      expect(c.formBefore, isNotNull);
      expect(c.formAfter, isNotNull);
      expect(c.formChanges, isTrue);
      expect(c.formAfter, lessThan(c.formBefore!),
          reason: 'weniger Aktualität und weniger Tageszuschlag');
    });

    test('eine Einheit von vor Jahren zu löschen ist folgenlos', () {
      // Die Auskunft „das ändert nichts" ist selbst eine Auskunft.
      final sessions = [
        ..._dicht(),
        _s('uralt', DateTime(2023, 1, 5)),
      ];
      final c = SessionConsequence.ofDeleting(sessions, 'uralt', _heute);
      expect(c.pauseChanges, isFalse);
      expect(c.isVisible, isFalse);
    });

    test('die achte Einheit im akuten Fenster nimmt den ACWR mit', () {
      // Der ACWR verlangt acht Einheiten in den letzten 28 Tagen und eine
      // Historie von mindestens 28 Tagen — die Schranke, die den
      // „Überreizt"-Fehler behoben hat. Hier stehen **genau acht** im
      // Fenster; eine davon zu löschen unterschreitet sie.
      final sessions = <TrainingSession>[
        for (var i = 0; i < 8; i++)
          _s('akut$i', _heute.subtract(Duration(days: i * 3))),
        for (var i = 0; i < 20; i++)
          _s('alt$i', _heute.subtract(Duration(days: 40 + i * 4))),
      ];

      final c = SessionConsequence.ofDeleting(sessions, 'akut7', _heute);
      expect(c.acwrBefore, isNotNull, reason: 'acht reichen');
      expect(c.acwrAfter, isNull,
          reason: 'sieben reichen nicht — der ACWR entfällt, '
              'statt aus zwei dünnen Fenstern eine Zahl zu bilden');
      expect(c.acwrDisappears, isTrue);
      expect(c.acwrChanges, isTrue);
      expect(c.isVisible, isTrue);
    });

    test('eine neunte Einheit zu löschen lässt den ACWR stehen', () {
      final sessions = <TrainingSession>[
        for (var i = 0; i < 9; i++)
          _s('akut$i', _heute.subtract(Duration(days: i * 3))),
        for (var i = 0; i < 20; i++)
          _s('alt$i', _heute.subtract(Duration(days: 40 + i * 4))),
      ];

      final c = SessionConsequence.ofDeleting(sessions, 'akut8', _heute);
      expect(c.acwrBefore, isNotNull);
      expect(c.acwrAfter, isNotNull);
      expect(c.acwrDisappears, isFalse);
    });
  });

  group('Bearbeiten', () {
    test('das Datum nach vorn zu ziehen verkürzt die Pause', () {
      // Letzte Einheit vor 50 Tagen, sonst nichts in der Nähe.
      final sessions = <TrainingSession>[
        for (var i = 0; i < 20; i++)
          _s('s$i', _heute.subtract(Duration(days: 50 + i * 4))),
      ];

      final vorher = SessionConsequence.ofDeleting(sessions, 'gibtsnicht', _heute);
      expect(vorher.pauseBefore, 50);

      final c = SessionConsequence.ofEditing(
        sessions,
        's0',
        _heute,
        date: _heute.subtract(const Duration(days: 32)),
      );
      expect(c.pauseBefore, 50);
      expect(c.pauseAfter, 32);
      expect(c.pauseChanges, isTrue);
    });

    test('eine Änderung der Dauer verschiebt die Last, nicht die Pause', () {
      final c = SessionConsequence.ofEditing(
        _dicht(),
        's0',
        _heute,
        date: _heute,
        duration: const Duration(minutes: 120),
      );
      expect(c.pauseChanges, isFalse);
      expect(c.formChanges || c.acwrChanges, isTrue,
          reason: 'mehr Dauer heisst mehr Last');
    });

    test('ohne Änderung ändert sich nichts', () {
      final c = SessionConsequence.ofEditing(
        _dicht(),
        's0',
        _heute,
        date: _heute,
        duration: const Duration(minutes: 45),
      );
      expect(c.isVisible, isFalse);
    });

    test('beide Seiten werden gegen denselben Tag gerechnet', () {
      // Sonst wären es zwei Messungen und keine Folge.
      final c = SessionConsequence.ofEditing(
        _dicht(),
        's0',
        _heute,
        date: _heute.subtract(const Duration(days: 10)),
      );
      expect(c.before.sessions, c.after.sessions,
          reason: 'bearbeiten entfernt nichts');
    });
  });

  group('copyWith', () {
    test('ändert Datum und Dauer und sonst nichts', () {
      final original = _s('x', DateTime(2026, 5, 5));
      final moved = original.copyWith(
        date: DateTime(2026, 6, 6),
        duration: const Duration(minutes: 90),
      );

      expect(moved.date, DateTime(2026, 6, 6));
      expect(moved.duration, const Duration(minutes: 90));
      expect(moved.id, original.id);
      expect(moved.createdAt, original.createdAt,
          reason: 'wann der Eintrag entstand, ändert sich beim '
              'Verschieben des Trainingstags gerade nicht');
      expect(moved.rpe, original.rpe);
      expect(moved.bodyweight, original.bodyweight);
    });

    test('ohne Argumente bleibt alles, wie es war', () {
      final original = _s('x', DateTime(2026, 5, 5));
      final same = original.copyWith();
      expect(same.date, original.date);
      expect(same.duration, original.duration);
    });

    test('gilt für jede der vier Arten', () {
      final date = DateTime(2026, 1, 1);
      final neu = DateTime(2026, 2, 2);
      final sessions = <TrainingSession>[
        _s('a', date),
        CardioSession(
            id: 'b', userId: 'u', date: date, createdAt: date, distanceKm: 5),
        RecoverySession(id: 'c', userId: 'u', date: date, createdAt: date),
        UnknownSession(
            id: 'd', userId: 'u', date: date, createdAt: date, rawType: '?'),
      ];

      for (final session in sessions) {
        final moved = session.copyWith(date: neu);
        expect(moved.date, neu, reason: session.runtimeType.toString());
        expect(moved.id, session.id);
        expect(moved.kind, session.kind);
      }
    });

    test('Cardio behält seine eigenen Felder', () {
      final date = DateTime(2026, 1, 1);
      final moved = CardioSession(
        id: 'b',
        userId: 'u',
        date: date,
        createdAt: date,
        distanceKm: 5,
        duration: const Duration(minutes: 27, seconds: 30),
        avgHr: 140,
      ).copyWith(date: DateTime(2026, 2, 2));

      expect(moved.distanceKm, 5);
      // Gerechnet, nicht kopiert: 27:30 auf 5 km sind 5,5 min/km.
      expect(moved.pace, closeTo(5.5, 1e-9));
      expect(moved.avgHr, 140);
    });
  });
}
