import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/merge_preview.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Was eine Zusammenführung ändert (Board 15, B2 und B4).
void main() {
  final start = DateTime(2026, 9, 18, 18, 2);

  HealthSession watch({int? avg = 118, int? max = 164}) =>
      HealthSession.pending(
        MeasuredSession(
          id: 'hc-1',
          // 18:00–18:58, also 58 Minuten.
          start: DateTime(2026, 9, 18, 18),
          end: DateTime(2026, 9, 18, 18, 58),
          sourceId: 'garmin',
          averageHeartRate: avg,
          maxHeartRate: max,
        ),
        start,
      );

  StrengthSession app({int sets = 24, int? rpe = 4}) => StrengthSession(
        id: 'a1',
        userId: 'u',
        date: start,
        createdAt: start,
        duration: const Duration(minutes: 52),
        rpe: rpe,
        bodyweight: false,
        exercises: [
          LoggedExercise(
            exerciseId: 'e1',
            sets: [for (var i = 0; i < sets; i++) const LoggedSet(reps: 8)],
          ),
        ],
      );

  MergeEffect? effectOf(MergePreview p, MergeField field) {
    for (final line in p.lines) {
      if (line.field == field) return line.effect;
    }
    return null;
  }

  String? valueOf(MergePreview p, MergeField field) {
    for (final line in p.lines) {
      if (line.field == field) return line.value;
    }
    return null;
  }

  group('Zusammenführen', () {
    test('der Puls kommt hinzu, alles andere bleibt', () {
      final preview =
          MergePreview.merging(session: app(), measured: watch());

      expect(effectOf(preview, MergeField.averageHeartRate),
          MergeEffect.gained);
      expect(valueOf(preview, MergeField.averageHeartRate), '118');
      expect(effectOf(preview, MergeField.maxHeartRate), MergeEffect.gained);

      // Drei Zeilen sagen ausdrücklich „bleibt".
      expect(effectOf(preview, MergeField.sets), MergeEffect.stays);
      expect(valueOf(preview, MergeField.sets), '24');
      expect(effectOf(preview, MergeField.duration), MergeEffect.stays);
      expect(valueOf(preview, MergeField.duration), '52');
      expect(effectOf(preview, MergeField.effort), MergeEffect.stays);
    });

    test('bei Widerspruch gewinnt die App, der Uhr-Wert bleibt sichtbar', () {
      final preview =
          MergePreview.merging(session: app(), measured: watch());

      expect(preview.durationDiffers, isTrue);
      expect(preview.appDuration, const Duration(minutes: 52));
      expect(preview.watchDuration, const Duration(minutes: 58));
      // Die gültige Dauer ist die der App — sie steht als „bleibt".
      expect(valueOf(preview, MergeField.duration), '52');
    });

    test('ohne Puls bleibt die Vorschau ehrlich leer', () {
      final preview = MergePreview.merging(
        session: app(),
        measured: watch(avg: null, max: null),
      );
      expect(effectOf(preview, MergeField.averageHeartRate), isNull);
      expect(effectOf(preview, MergeField.duration), MergeEffect.stays);
    });

    test('ohne Anstrengung steht keine Anstrengungszeile', () {
      final preview =
          MergePreview.merging(session: app(rpe: null), measured: watch());
      expect(effectOf(preview, MergeField.effort), isNull);
    });
  });

  group('Lösen', () {
    test('der Puls entfällt, der Rest bleibt, die Uhr-Einheit kehrt zurück',
        () {
      final preview =
          MergePreview.unlinking(session: app(), measured: watch());

      expect(effectOf(preview, MergeField.averageHeartRate), MergeEffect.lost);
      expect(effectOf(preview, MergeField.sets), MergeEffect.stays);
      expect(effectOf(preview, MergeField.duration), MergeEffect.stays);
      expect(effectOf(preview, MergeField.effort), MergeEffect.stays);
      // Verlustfrei: Sie geht in den Eingang, nicht in den Müll.
      expect(effectOf(preview, MergeField.watchSession), MergeEffect.gained);
    });

    test('ohne Puls gibt es nichts zu verlieren', () {
      final preview = MergePreview.unlinking(
        session: app(),
        measured: watch(avg: null, max: null),
      );
      expect(effectOf(preview, MergeField.averageHeartRate), isNull);
    });
  });
}
