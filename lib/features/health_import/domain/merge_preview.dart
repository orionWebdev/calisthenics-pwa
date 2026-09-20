import 'package:meta/meta.dart';

import '../../history/domain/training_session.dart';
import 'health_session.dart';

/// Was eine Grösse beim Zusammenführen erfährt.
enum MergeEffect {
  /// Sie kommt hinzu — die App hatte sie nicht.
  gained,

  /// Sie bleibt, wie sie ist.
  stays,

  /// Sie entfällt — nur beim Lösen.
  lost,
}

/// Eine Grösse in der Folgenvorschau.
@immutable
class MergeLine {
  const MergeLine({
    required this.field,
    required this.effect,
    this.value,
  });

  final MergeField field;
  final MergeEffect effect;

  /// Der Wert, um den es geht. `null`, wo es keinen gibt.
  final String? value;
}

/// Welche Grösse eine Zeile meint. Die Beschriftung kommt aus dem ARB —
/// die Domäne kennt keine Sprache.
enum MergeField {
  averageHeartRate,
  maxHeartRate,
  sets,
  duration,
  effort,
  watchSession,
}

/// Was ein Zusammenführen ändert — **gerechnet, nicht gewarnt**.
///
/// ## Keine Grösse hat zwei Quellen
///
/// Sätze, Dauer, Anstrengung und Notiz kommen aus der App; Puls und Kalorien
/// aus der Uhr. Es wird nie gemittelt und nie gewählt, es wird zugeordnet
/// (Board 15, Entscheidung 9). Eine Regel wie „die Uhr gewinnt bei der Dauer"
/// wäre eine Meinung im Code und in keiner Oberfläche erklärbar.
///
/// ## Bei Widerspruch gewinnt die App
///
/// Die App-Dauer ist der protokollierte Satzzeitraum und geht als
/// Trainingsminute in Last und Verhältnis ein. Übernähme man die Uhr,
/// änderten sich rückwirkend Zahlen, die längst gezeigt wurden — für eine
/// Dauer, die zusätzlich Umziehen und Aufwärmen enthält (Entscheidung 8).
///
/// **Der Uhr-Wert verschwindet nicht.** Er steht als Meldung der Uhr in der
/// Quellenkapsel, violett hinterlegt: zwei Zahlen, eine gültig, beide
/// sichtbar.
///
/// ## Drei Zeilen sagen „bleibt"
///
/// Genau das nimmt der eingreifendsten Operation den Schrecken: nicht ein
/// Warnton, sondern die gerechnete Folge. Eine Vorschau, in der nur steht,
/// was sich ändert, lässt offen, was sie sonst noch anfasst.
@immutable
class MergePreview {
  const MergePreview({
    required this.lines,
    required this.appDuration,
    required this.watchDuration,
  });

  final List<MergeLine> lines;

  /// Die Dauer, die gilt.
  final Duration appDuration;

  /// Die Dauer, die die Uhr meldet.
  final Duration watchDuration;

  /// Widersprechen sich die beiden? Dann gehört die Meldung der Uhr daneben.
  bool get durationDiffers =>
      appDuration.inMinutes != watchDuration.inMinutes;

  /// Was eine Zusammenführung ändert.
  static MergePreview merging({
    required TrainingSession session,
    required HealthSession measured,
  }) {
    final duration = session.duration ?? Duration.zero;
    return MergePreview(
      appDuration: duration,
      watchDuration: measured.duration,
      lines: [
        if (measured.averageHeartRate case final bpm?)
          MergeLine(
            field: MergeField.averageHeartRate,
            effect: MergeEffect.gained,
            value: '$bpm',
          ),
        if (measured.maxHeartRate case final bpm?)
          MergeLine(
            field: MergeField.maxHeartRate,
            effect: MergeEffect.gained,
            value: '$bpm',
          ),
        if (_setsOf(session) case final sets? when sets > 0)
          MergeLine(
            field: MergeField.sets,
            effect: MergeEffect.stays,
            value: '$sets',
          ),
        MergeLine(
          field: MergeField.duration,
          effect: MergeEffect.stays,
          value: '${duration.inMinutes}',
        ),
        if (session.rpe case final rpe?)
          MergeLine(
            field: MergeField.effort,
            effect: MergeEffect.stays,
            value: '$rpe',
          ),
      ],
    );
  }

  /// Was ein Lösen ändert — **verlustfrei**, weil die Uhr-Einheit die ganze
  /// Zeit als eigener Datensatz danebenlag.
  static MergePreview unlinking({
    required TrainingSession session,
    required HealthSession measured,
  }) {
    final duration = session.duration ?? Duration.zero;
    return MergePreview(
      appDuration: duration,
      watchDuration: measured.duration,
      lines: [
        if (measured.averageHeartRate != null || measured.maxHeartRate != null)
          const MergeLine(
            field: MergeField.averageHeartRate,
            effect: MergeEffect.lost,
          ),
        if (_setsOf(session) case final sets? when sets > 0)
          MergeLine(
            field: MergeField.sets,
            effect: MergeEffect.stays,
            value: '$sets',
          ),
        MergeLine(
          field: MergeField.duration,
          effect: MergeEffect.stays,
          value: '${duration.inMinutes}',
        ),
        if (session.rpe case final rpe?)
          MergeLine(
            field: MergeField.effort,
            effect: MergeEffect.stays,
            value: '$rpe',
          ),
        // Sie geht zurück in den Eingang, nicht in den Müll.
        const MergeLine(
          field: MergeField.watchSession,
          effect: MergeEffect.gained,
        ),
      ],
    );
  }

  static int? _setsOf(TrainingSession session) => session is StrengthSession
      ? session.exercises.fold<int>(0, (n, e) => n + e.sets.length)
      : null;
}
