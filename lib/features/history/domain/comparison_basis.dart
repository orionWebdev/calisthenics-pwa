import 'training_session.dart';

/// Worauf ein Vergleich beruht — **drei Stufen, jede benannt**.
///
/// ## Warum eine Kaskade und nicht eine Regel
///
/// Die stärkste Regel — derselbe Plan — trifft im Bestand auf 52 von 136
/// Einheiten. Bei zwei Dritteln stünde also „kein Vergleich", und ein Block,
/// der meistens leer ist, ist kein Block.
///
/// Die schwächste Regel — dieselbe Art — trifft immer, sagt aber weniger:
/// Zwei Krafteinheiten mit völlig verschiedenen Übungen haben kein
/// vergleichbares Volumen. Sie trägt deshalb nur Dauer und Last.
///
/// Dazwischen liegt die Überdeckung der Übungsmenge. Sie greift beim freien
/// Training, wo kein Plan dahintersteht, die Auswahl aber trotzdem stabil ist.
///
/// **Die Stufe steht sichtbar dabei.** Ein Vergleich, dessen Grundlage man
/// nicht kennt, ist eine Zahl ohne Herkunft.
enum ComparisonBasis {
  /// Derselbe Plan, jüngste Einheit davor. Alle vier Werte.
  samePlan,

  /// Übungsüberdeckung ≥ 60 % innerhalb von 90 Tagen. Alle vier Werte.
  sameExercises,

  /// Dieselbe Art, Median der letzten fünf. **Nur Dauer und Last** — Volumen
  /// und Sätze hängen an den Übungen und wären hier irreführend.
  sameKind;

  /// Trägt diese Stufe auch Volumen und Sätze?
  bool get comparesVolume => this != ComparisonBasis.sameKind;
}

/// Sucht die Bezugseinheit nach der Kaskade.
abstract final class ComparisonResolver {
  /// Die Überdeckungsschwelle für Stufe B.
  ///
  /// **Eine Konstante, kein verstreuter Wert.** Sie ist gesetzt und nicht am
  /// Bestand geprüft: Bei zu hoher Schwelle fällt freies Training fast immer
  /// auf Stufe C, bei zu niedriger vergleicht die App Rücken- mit Brusttag.
  /// Nach einer Woche Produktivbetrieb an der Verteilung nachzuziehen — dafür
  /// steht sie hier und nur hier.
  static const overlapThreshold = 0.6;

  /// Wie weit Stufe B zurückblickt.
  static const overlapWindowDays = 90;

  /// Wie viele Einheiten in den Median von Stufe C eingehen.
  static const medianCount = 5;

  /// Findet Stufe und Bezug. `null`, wenn es keinen gibt.
  static ComparisonMatch? resolve(
    TrainingSession session,
    List<TrainingSession> all,
  ) {
    // Regeneration bekommt keinen Vergleich: 8 Einheiten im ganzen Bestand,
    // und sie tragen ausser der Dauer keine Kennzahl.
    if (session is RecoverySession) return null;

    final earlier = [
      for (final candidate in all)
        if (candidate.id != session.id && candidate.date.isBefore(session.date))
          candidate,
    ]..sort((a, b) => b.date.compareTo(a.date));

    // Stufe A — derselbe Plan.
    final planId = session is StrengthSession ? session.planId : null;
    if (planId != null) {
      for (final candidate in earlier) {
        if (candidate is StrengthSession && candidate.planId == planId) {
          return ComparisonMatch(
            basis: ComparisonBasis.samePlan,
            reference: candidate,
          );
        }
      }
    }

    // Stufe B — dieselben Übungen, zu mindestens 60 %.
    final own = _exerciseIds(session);
    if (own.isNotEmpty) {
      final from = session.date.subtract(
        const Duration(days: overlapWindowDays),
      );
      for (final candidate in earlier) {
        if (candidate.date.isBefore(from)) break;
        final other = _exerciseIds(candidate);
        if (other.isEmpty) continue;
        if (jaccard(own, other) >= overlapThreshold) {
          return ComparisonMatch(
            basis: ComparisonBasis.sameExercises,
            reference: candidate,
          );
        }
      }
    }

    // Stufe C — dieselbe Art, Median der letzten fünf.
    final sameKind = [
      for (final candidate in earlier)
        if (candidate.kind == session.kind) candidate,
    ].take(medianCount).toList();
    if (sameKind.isEmpty) return null;

    return ComparisonMatch(
      basis: ComparisonBasis.sameKind,
      median: sameKind,
    );
  }

  /// Überdeckung zweier Mengen: gemeinsam durch gesamt.
  ///
  /// Nicht „wie viele der eigenen kommen vor" — das wäre bei einer Einheit
  /// mit zwei Übungen gegen eine mit zwanzig immer 100 Prozent.
  static double jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final shared = a.intersection(b).length;
    final total = a.union(b).length;
    return shared / total;
  }

  static Set<String> _exerciseIds(TrainingSession session) =>
      session is StrengthSession
          ? {for (final exercise in session.exercises) exercise.exerciseId}
          : const {};
}

/// Das Ergebnis der Suche: eine Stufe und entweder eine Einheit oder ein
/// Bündel, aus dem der Median gebildet wird.
class ComparisonMatch {
  const ComparisonMatch({
    required this.basis,
    this.reference,
    this.median = const [],
  });

  final ComparisonBasis basis;

  /// Die eine Bezugseinheit — bei Stufe A und B.
  final TrainingSession? reference;

  /// Die Einheiten, aus denen der Median gebildet wird — bei Stufe C.
  final List<TrainingSession> median;

  /// Das Datum, auf das sich der Vergleich bezieht. Bei Stufe C das der
  /// jüngsten im Bündel.
  DateTime? get date => reference?.date ?? median.firstOrNull?.date;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
