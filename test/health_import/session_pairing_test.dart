import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/session_pairing.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Paar-Regel aus Board 15, Abschnitt B — reine Rechnung, ohne Gerät.
void main() {
  DateTime at(int hour, int minute) => DateTime(2026, 9, 18, hour, minute);

  MeasuredSession watch({
    required DateTime start,
    required DateTime end,
    String id = 'hc-1',
    String activity = 'OTHER',
  }) =>
      MeasuredSession(
        id: id,
        start: start,
        end: end,
        sourceId: 'com.garmin.android.apps.connectmobile',
        activity: activity,
        deviceName: 'Garmin',
        averageHeartRate: 118,
        maxHeartRate: 164,
      );

  TrainingSession app({
    required DateTime start,
    required Duration? duration,
    String id = 'app-1',
  }) =>
      StrengthSession(
        id: id,
        userId: 'u',
        date: start,
        createdAt: start,
        duration: duration,
        bodyweight: false,
        exercises: const [],
      );

  group('der Fall aus dem Auftrag', () {
    test('App 18:02–18:54 und Uhr 18:00–18:58 sind ein Paar', () {
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 0), end: at(18, 58)),
        sessions: [app(start: at(18, 2), duration: const Duration(minutes: 52))],
      );

      expect(verdict, isA<PairSuggested>());
      // Überlappung 52 von 52 min der kürzeren Einheit, Start 2 min
      // auseinander — die Regel greift dreifach.
      expect((verdict as PairSuggested).overlap, const Duration(minutes: 52));
    });
  });

  group('Regel 1 — mehr als die Hälfte der kürzeren Dauer', () {
    // Beide Fälle halten den Startabstand bei höchstens 20 Minuten, damit
    // allein Regel 1 entscheidet.
    test('genau die Hälfte genügt nicht', () {
      // App 18:00–18:40 (40 min), Uhr 18:20–19:20: Überlappung 20 von 40.
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 20), end: at(19, 20)),
        sessions: [
          app(start: at(18, 0), duration: const Duration(minutes: 40)),
        ],
      );
      expect(verdict, isA<PairNone>());
    });

    test('eine Minute mehr als die Hälfte genügt', () {
      // Dieselbe App-Einheit, Uhr eine Minute früher: 21 von 40.
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 19), end: at(19, 20)),
        sessions: [
          app(start: at(18, 0), duration: const Duration(minutes: 40)),
        ],
      );
      expect(verdict, isA<PairSuggested>());
      expect((verdict as PairSuggested).overlap, const Duration(minutes: 21));
    });
  });

  group('Regel 2 — Startzeiten höchstens 20 Minuten auseinander', () {
    test('die Ganztagsaufzeichnung verschluckt keine Krafteinheit', () {
      // 90 Minuten Uhr, 20 Minuten App, 100 % Überlappung — und trotzdem
      // kein Paar, weil die Starts 40 Minuten auseinanderliegen.
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(17, 0), end: at(18, 30)),
        sessions: [
          app(start: at(17, 40), duration: const Duration(minutes: 20)),
        ],
      );
      expect(verdict, isA<PairNone>());
    });

    test('genau 20 Minuten Abstand ist noch erlaubt', () {
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 0), end: at(19, 30)),
        sessions: [
          app(start: at(18, 20), duration: const Duration(minutes: 60)),
        ],
      );
      expect(verdict, isA<PairSuggested>());
    });
  });

  group('Regel 3 — genau ein Kandidat', () {
    test('zwei Kandidaten ergeben keine Vermutung, sondern eine Auswahl', () {
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 0), end: at(18, 40)),
        sessions: [
          app(id: 'a', start: at(18, 0), duration: const Duration(minutes: 30)),
          app(id: 'b', start: at(18, 5), duration: const Duration(minutes: 30)),
        ],
      );
      expect(verdict, isA<PairAmbiguous>());
      expect((verdict as PairAmbiguous).candidates, hasLength(2));
    });

    test('ohne Kandidat wird die Uhr-Einheit eine eigene Einheit', () {
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(9, 14), end: at(9, 56)),
        sessions: [app(start: at(18, 2), duration: const Duration(minutes: 52))],
      );
      expect(verdict, isA<PairNone>());
    });
  });

  test('die Art ist keine Bedingung — „Andere" paart mit einer Krafteinheit',
      () {
    final verdict = SessionPairing.verdict(
      measured:
          watch(start: at(18, 0), end: at(18, 58), activity: 'OTHER'),
      sessions: [app(start: at(18, 2), duration: const Duration(minutes: 52))],
    );
    expect(verdict, isA<PairSuggested>());
  });

  group('Einheiten ohne verwertbare Zeit paaren nie', () {
    test('ohne Dauer kein Paar', () {
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 0), end: at(18, 58)),
        sessions: [app(start: at(18, 2), duration: null)],
      );
      expect(verdict, isA<PairNone>());
    });

    test('eine Einheit auf Mitternacht paart nicht mit dem Abendtraining', () {
      // Der Bestand aus der Vorgänger-App trägt oft nur das Datum.
      final verdict = SessionPairing.verdict(
        measured: watch(start: at(18, 0), end: at(18, 58)),
        sessions: [
          app(
            start: DateTime(2026, 9, 18),
            duration: const Duration(minutes: 52),
          ),
        ],
      );
      expect(verdict, isA<PairNone>());
    });
  });
}
