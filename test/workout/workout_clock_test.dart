import 'package:atem/features/workout/domain/workout_clock.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026, 8, 28, 18, 0);

void main() {
  group('Die verstrichene Zeit', () {
    test('kommt aus der Wanduhr, nicht aus Ticks', () {
      // Der eigentliche Fehler: Ein Zähler in einem `Timer.periodic` steht
      // still, wenn die App im Hintergrund ist. 43 Minuten Training wurden
      // als 15 gespeichert — dauerhaft, weil die Dauer in Last, ACWR und
      // Formwert eingeht.
      final clock = WorkoutClock.startingAt(_start);
      expect(
        clock.elapsed(_start.add(const Duration(minutes: 43))),
        const Duration(minutes: 43),
      );
    });

    test('eine Pause zählt nicht mit', () {
      var clock = WorkoutClock.startingAt(_start);
      clock = clock.pause(_start.add(const Duration(minutes: 10)));
      clock = clock.resume(_start.add(const Duration(minutes: 25)));

      expect(
        clock.elapsed(_start.add(const Duration(minutes: 30))),
        const Duration(minutes: 15),
        reason: '30 Minuten Wanduhr minus 15 Minuten Pause',
      );
    });

    test('während der Pause steht sie still', () {
      var clock = WorkoutClock.startingAt(_start);
      clock = clock.pause(_start.add(const Duration(minutes: 10)));

      expect(clock.elapsed(_start.add(const Duration(minutes: 20))),
          const Duration(minutes: 10));
      expect(clock.elapsed(_start.add(const Duration(minutes: 40))),
          const Duration(minutes: 10),
          reason: 'egal wie lange pausiert wird');
    });

    test('zweimal pausieren ist einmal pausieren', () {
      var clock = WorkoutClock.startingAt(_start);
      clock = clock.pause(_start.add(const Duration(minutes: 5)));
      clock = clock.pause(_start.add(const Duration(minutes: 8)));
      clock = clock.resume(_start.add(const Duration(minutes: 10)));

      expect(clock.elapsed(_start.add(const Duration(minutes: 10))),
          const Duration(minutes: 5));
    });

    test('eine zurückgestellte Systemuhr ergibt null, keine Minuszeit', () {
      final clock = WorkoutClock.startingAt(_start);
      expect(clock.elapsed(_start.subtract(const Duration(hours: 1))),
          Duration.zero);
    });
  });

  group('Die Satzpause', () {
    test('läuft an der Uhr weiter, auch im Hintergrund', () {
      final clock = WorkoutClock.startingAt(_start)
          .startRest(_start, const Duration(seconds: 90));

      expect(clock.restRemaining(_start.add(const Duration(seconds: 30))),
          const Duration(seconds: 60));
      // Wer die App weglegt und nach zwei Minuten zurückkommt, bekommt keine
      // Pause, die noch neunzig Sekunden zu laufen glaubt.
      expect(clock.restRemaining(_start.add(const Duration(minutes: 2))),
          Duration.zero);
      expect(clock.restElapsed(_start.add(const Duration(minutes: 2))), isTrue);
    });

    test('verlängern und verkürzen verschieben das Ende', () {
      var clock = WorkoutClock.startingAt(_start)
          .startRest(_start, const Duration(seconds: 90));

      clock = clock.shiftRest(const Duration(seconds: 30));
      expect(clock.restRemaining(_start), const Duration(seconds: 120));
      expect(clock.restTotal, const Duration(seconds: 120),
          reason: 'der Ring braucht den neuen Gesamtwert');

      clock = clock.shiftRest(const Duration(seconds: -15));
      expect(clock.restRemaining(_start), const Duration(seconds: 105));
    });

    test('überspringen beendet sie sofort', () {
      final clock = WorkoutClock.startingAt(_start)
          .startRest(_start, const Duration(seconds: 90))
          .stopRest();
      expect(clock.isResting, isFalse);
      expect(clock.restRemaining(_start), Duration.zero);
    });

    test('eine Pause ändert die Trainingszeit nicht', () {
      // Sie gehört zum Training, nicht daneben.
      final clock = WorkoutClock.startingAt(_start)
          .startRest(_start, const Duration(seconds: 90));
      expect(clock.elapsed(_start.add(const Duration(minutes: 5))),
          const Duration(minutes: 5));
    });
  });

  group('Sichern und Wiederherstellen', () {
    test('überlebt den Weg durch JSON', () {
      final clock = WorkoutClock.startingAt(_start)
          .pause(_start.add(const Duration(minutes: 3)))
          .resume(_start.add(const Duration(minutes: 5)))
          .startRest(_start.add(const Duration(minutes: 5)),
              const Duration(seconds: 90));

      final back = WorkoutClock.fromJson(clock.toJson())!;
      expect(back.startedAt, clock.startedAt);
      expect(back.paused, clock.paused);
      expect(back.restEndsAt, clock.restEndsAt);
      expect(back.restTotal, clock.restTotal);
      expect(
        back.elapsed(_start.add(const Duration(minutes: 20))),
        clock.elapsed(_start.add(const Duration(minutes: 20))),
      );
    });

    test('eine laufende Pause überlebt mit', () {
      final clock = WorkoutClock.startingAt(_start)
          .pause(_start.add(const Duration(minutes: 3)));
      final back = WorkoutClock.fromJson(clock.toJson())!;
      expect(back.isPaused, isTrue);
      expect(back.elapsed(_start.add(const Duration(minutes: 30))),
          const Duration(minutes: 3));
    });

    test('ohne Startzeitpunkt gibt es nichts wiederherzustellen', () {
      expect(WorkoutClock.fromJson(const {}), isNull);
      expect(WorkoutClock.fromJson(const {'startedAt': 'kaputt'}), isNull);
    });
  });
}
