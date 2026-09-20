import '../../../core/domain/health_gateway.dart';
import '../../history/domain/training_session.dart';

/// Was der Abgleich über eine Uhr-Einheit sagen kann.
///
/// Drei Ausgänge, und **keiner davon ist eine Tatsache** — alle drei führen zu
/// einer Frage an den Menschen (Board 15, Entscheidung 10: eine Einheit im
/// Bestand ändert sich nie ohne ein Ja).
sealed class PairVerdict {
  const PairVerdict();
}

/// Genau ein Kandidat erfüllt die Regel: Die Vermutung wird als Frage
/// gestellt („Gehört das zu deiner Krafteinheit?", B1).
final class PairSuggested extends PairVerdict {
  const PairSuggested({required this.session, required this.overlap});

  final TrainingSession session;

  /// Die gemeinsame Spanne — die Begründung der Vermutung, in Zahlen.
  final Duration overlap;
}

/// Mehrere Kandidaten: **keine Vermutung.** Die Zuordnung wird von Hand
/// gewählt, mit allen Kandidaten sichtbar (B5, Entscheidung 7).
final class PairAmbiguous extends PairVerdict {
  const PairAmbiguous(this.candidates);

  final List<TrainingSession> candidates;
}

/// Kein Kandidat: Die Uhr-Einheit wird eine eigene Einheit (A2).
final class PairNone extends PairVerdict {
  const PairNone();
}

/// Ob eine Uhr-Einheit zu einer App-Einheit gehört.
///
/// ## Die Regel, dreifach
///
/// 1. Die **Überlappung** beträgt mehr als die Hälfte der kürzeren Dauer.
/// 2. Die **Startzeiten** liegen höchstens 20 Minuten auseinander.
/// 3. Es gibt **genau einen** Kandidaten.
///
/// ## Warum die Überlappung allein nicht genügt
///
/// Eine 90-minütige Uhr-Aufzeichnung („Ganztagsaktivität") verschluckt jede
/// 20-Minuten-Krafteinheit mit 100 % Überlappung, ohne dasselbe Training zu
/// sein. Die Startzeitnähe schliesst das aus (Board 15, Entscheidung 5).
///
/// ## Warum die Art nicht geprüft wird
///
/// Uhren melden Krafttraining regelmässig als „Andere", „Cardio" oder „HIIT".
/// Eine Artprüfung würde mehr echte Paare verwerfen, als sie falsche
/// verhindert — und „zwei Einheiten für ein Training" ist der teurere Fehler
/// (Entscheidung 6).
///
/// ## Einheiten ohne Dauer paaren nie
///
/// 25 von 136 Einheiten im Bestand tragen keine Dauer, und ältere aus der
/// Vorgänger-App stehen auf Mitternacht statt auf ihrer Uhrzeit. Beide
/// scheitern an Regel 1 oder 2 — und das ist richtig so: Ein Paar, das auf
/// geratenen Zeiten beruht, wäre schlechter als kein Paar.
abstract final class SessionPairing {
  /// Wie weit die Startzeiten auseinanderliegen dürfen.
  static const startTolerance = Duration(minutes: 20);

  /// Prüft eine Uhr-Einheit gegen den Bestand.
  static PairVerdict verdict({
    required MeasuredSession measured,
    required List<TrainingSession> sessions,
  }) {
    final candidates = <({TrainingSession session, Duration overlap})>[];

    for (final session in sessions) {
      final overlap = _overlapOf(measured, session);
      if (overlap == null) continue;
      candidates.add((session: session, overlap: overlap));
    }

    return switch (candidates.length) {
      0 => const PairNone(),
      1 => PairSuggested(
          session: candidates.single.session,
          overlap: candidates.single.overlap,
        ),
      _ => PairAmbiguous([for (final c in candidates) c.session]),
    };
  }

  /// Die gemeinsame Spanne, wenn beide Bedingungen greifen — sonst `null`.
  static Duration? _overlapOf(
      MeasuredSession measured, TrainingSession session) {
    final duration = session.duration;
    if (duration == null || duration <= Duration.zero) return null;

    final start = session.date;
    final end = start.add(duration);

    // Regel 2 zuerst: Sie ist die billigere Prüfung und wirft die
    // Ganztagsaufzeichnungen sofort hinaus.
    if (start.difference(measured.start).abs() > startTolerance) return null;

    final from = start.isAfter(measured.start) ? start : measured.start;
    final to = end.isBefore(measured.end) ? end : measured.end;
    final overlap = to.difference(from);
    if (overlap <= Duration.zero) return null;

    // Regel 1: **mehr** als die Hälfte der kürzeren Dauer — nicht „mindestens".
    final shorter =
        duration < measured.duration ? duration : measured.duration;
    if (overlap * 2 <= shorter) return null;

    return overlap;
  }
}
