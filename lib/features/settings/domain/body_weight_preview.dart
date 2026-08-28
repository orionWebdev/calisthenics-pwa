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

  /// Die Trainingslast der letzten sieben Tage, unter beiden Maßstäben.
  ///
  /// Das Board zeigt sie als erste Zeile. Sie ist die unmittelbarste Zahl:
  /// Sie bewegt sich sofort, während Form und ACWR über Wochen glätten.
  static (double, double) weekLoad(
    List<TrainingSession> sessions,
    DateTime reference, {
    required double currentKg,
    required double candidateKg,
  }) {
    final from = DateTime(
      reference.year,
      reference.month,
      reference.day - 6,
    );
    var a = 0.0;
    var b = 0.0;
    for (final session in sessions) {
      if (session.date.isBefore(from)) continue;
      if (session.date.isAfter(reference)) continue;
      a += TrainingLoad.of(session, LoadContext(bodyWeightKg: currentKg));
      b += TrainingLoad.of(session, LoadContext(bodyWeightKg: candidateKg));
    }
    return (a, b);
  }

  /// Worüber die Vorschau überhaupt rechnet: Zeitraum und Anzahl der
  /// Einheiten mit Körpergewichtsübungen.
  ///
  /// **Der Nenner gehört an die Oberfläche.** Ändert sich nichts, liegt das
  /// fast immer daran, dass keine Einheit eine Körpergewichtsübung trägt —
  /// und nicht daran, dass die Rechnung nichts hergibt.
  static (int, int) scope(List<TrainingSession> sessions, DateTime reference) {
    var counted = 0;
    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      final hasBodyweight = session.exercises
          .any((exercise) => exercise.usesBodyweight == true);
      if (hasBodyweight) counted++;
    }
    final days = sessions.isEmpty
        ? 0
        : reference
            .difference(sessions
                .reduce((a, b) => a.date.isBefore(b.date) ? a : b)
                .date)
            .inDays;
    return (days, counted);
  }

  /// Die häufigste Körpergewichtsübung — ihr „Bestwert" **ist** das
  /// Körpergewicht, und genau daran wird die Änderung greifbar.
  ///
  /// `null`, wenn es keine gibt. Dann fehlt die Zeile, statt eine Übung zu
  /// nennen, die nie mit dem Körpergewicht gerechnet wurde.
  static String? bodyweightExercise(List<TrainingSession> sessions) {
    final counts = <String, int>{};
    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      for (final exercise in session.exercises) {
        if (exercise.usesBodyweight != true) continue;
        counts[exercise.exerciseId] = (counts[exercise.exerciseId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

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
