import '../../history/domain/history_summary.dart';
import '../../history/domain/training_load.dart';
import '../../history/domain/training_session.dart';

/// Was ein anderes Körpergewicht an den Auswertungen ändert.
///
/// ## Warum eine Einstellung eine Vorschau braucht
///
/// Das Körpergewicht ist die einzige Einstellung, die **rückwirkend rechnet**.
/// Jede Körpergewichtsübung im gesamten Verlauf wird damit bewertet: Wer von
/// 78 auf 82 geht, verschiebt Trainingslast, ACWR und Formwert über Jahre
/// zurück — ohne dass eine einzige Einheit sich geändert hätte.
///
/// Modul 6 und 7 haben dafür die Antwort etabliert: **rechnen, nicht warnen**.
/// Eine Warnung („das wirkt sich auf deine Auswertung aus") nennt weder
/// Richtung noch Größe und wird weggetippt. Vier Zahlen mit Vorher und Nachher
/// lassen abwägen.
///
/// Der Unterschied zu [SessionConsequence]: Dort ändert sich der **Bestand**,
/// hier der **Maßstab**. Deshalb stehen hier auch Werte, die dort fehlen — die
/// Last der letzten Einheit etwa ist genau die Zahl, an der man den neuen
/// Maßstab am unmittelbarsten sieht.
class BodyWeightPreview {
  const BodyWeightPreview({required this.before, required this.after});

  final HistorySummary before;
  final HistorySummary after;

  int? get formBefore => before.form.score;
  int? get formAfter => after.form.score;

  double? get acwrBefore => before.acwr?.acwr;
  double? get acwrAfter => after.acwr?.acwr;

  /// Die Komponente „Fitness gegenüber Höchststand", 0 bis 15.
  int get fitnessBefore => before.form.fitnessVsPeak;
  int get fitnessAfter => after.form.fitnessVsPeak;

  bool get formChanges => formBefore != formAfter;
  bool get fitnessChanges => fitnessBefore != fitnessAfter;
  bool get acwrChanges =>
      (acwrBefore == null) != (acwrAfter == null) ||
      (acwrBefore != null &&
          acwrAfter != null &&
          (acwrBefore! - acwrAfter!).abs() >= 0.005);

  static BodyWeightPreview compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    required double currentKg,
    required double candidateKg,
  }) =>
      BodyWeightPreview(
        before: HistorySummary.from(sessions, reference,
            context: LoadContext(bodyWeightKg: currentKg)),
        after: HistorySummary.from(sessions, reference,
            context: LoadContext(bodyWeightKg: candidateKg)),
      );

  /// Die Last der letzten Einheit unter beiden Maßstäben.
  static (double, double) lastSessionLoad(
    List<TrainingSession> sessions, {
    required double currentKg,
    required double candidateKg,
  }) {
    if (sessions.isEmpty) return (0, 0);
    final last = sessions.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    return (
      TrainingLoad.of(last, LoadContext(bodyWeightKg: currentKg)),
      TrainingLoad.of(last, LoadContext(bodyWeightKg: candidateKg)),
    );
  }
}
