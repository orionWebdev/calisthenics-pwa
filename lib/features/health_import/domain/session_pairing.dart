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

/// Kandidaten **ohne Uhrzeit**: Einheiten am selben Tag, deren Startzeit
/// nicht gespeichert ist.
///
/// Hier wird nichts vermutet und nichts gerechnet — es gibt keine Zahl, mit
/// der sich eine Vermutung begründen liesse. Der Mensch wählt, oder er lässt
/// es. Dieselbe Haltung wie bei [PairAmbiguous], nur aus einem anderen Grund:
/// dort sind es zu viele Kandidaten, hier zu wenige Angaben.
///
/// Betrifft jede Einheit aus der Vorgänger-App und jede nachgetragene.
final class PairUndated extends PairVerdict {
  const PairUndated(this.candidates);

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
/// ## Einheiten ohne Startzeit oder ohne Dauer paaren nie
///
/// Verglichen wird `startedAt`, **nicht** `date`: `date` steht im ganzen
/// Bestand auf lokaler Mitternacht (Vertrag 04), und gegen Mitternacht
/// gerechnet liegt jede Uhr-Einheit Stunden daneben. Bis zum 21.09.2026 las
/// diese Regel `date` — und paarte deshalb **nie**. Auf dem Gerät hiess das:
/// Jede Uhr-Einheit wurde eine eigene Cardio-Einheit neben der
/// Krafteinheit, zu der sie gehörte.
///
/// Wer keine Startzeit trägt, paart nicht: alle Einheiten der Vorgänger-App,
/// alle nachgetragenen. Dasselbe gilt ohne Dauer (25 von 136 im Bestand).
/// Das ist richtig so — ein Paar, das auf geratenen Zeiten beruht, wäre
/// schlechter als kein Paar.
abstract final class SessionPairing {
  /// Wie weit die Startzeiten auseinanderliegen dürfen.
  static const startTolerance = Duration(minutes: 20);

  /// Prüft eine Uhr-Einheit gegen den Bestand.
  static PairVerdict verdict({
    required MeasuredSession measured,
    required List<TrainingSession> sessions,
  }) {
    final candidates = <({TrainingSession session, Duration overlap})>[];
    final undated = <TrainingSession>[];

    for (final session in sessions) {
      final overlap = _overlapOf(measured, session);
      if (overlap != null) {
        candidates.add((session: session, overlap: overlap));
      } else if (_sameDayWithoutTime(measured, session)) {
        undated.add(session);
      }
    }

    // **Eine gerechnete Vermutung schlägt jede Auswahl.** Wo es Zahlen gibt,
    // wird die Frage mit ihnen gestellt; die Auswahl von Hand ist der Weg
    // für den Fall, dass es keine gibt. Beides zu mischen hiesse, eine
    // begründete Vermutung neben unbegründete Kandidaten zu stellen.
    return switch (candidates.length) {
      1 => PairSuggested(
          session: candidates.single.session,
          overlap: candidates.single.overlap,
        ),
      0 => undated.isEmpty ? const PairNone() : PairUndated(undated),
      _ => PairAmbiguous([for (final c in candidates) c.session]),
    };
  }

  /// Eine Einheit am selben Tag, deren Startzeit **nicht gespeichert** ist.
  ///
  /// Der Tag ist die einzige Angabe, die beide sicher teilen. Sie genügt für
  /// eine Auswahl, nie für eine Vermutung: Wer morgens läuft und abends
  /// Kraft macht, hat zwei Einheiten an einem Tag, die nichts miteinander zu
  /// tun haben. Deshalb entscheidet hier der Mensch.
  ///
  /// Ohne Dauer bleibt es dabei aussen vor — eine Einheit, von der weder
  /// Beginn noch Länge bekannt ist, trägt zu wenig, um sie überhaupt
  /// anzubieten.
  static bool _sameDayWithoutTime(
      MeasuredSession measured, TrainingSession session) {
    if (session.startedAt != null) return false;
    final duration = session.duration;
    if (duration == null || duration <= Duration.zero) return false;
    final day = session.date;
    return day.year == measured.start.year &&
        day.month == measured.start.month &&
        day.day == measured.start.day;
  }

  /// Die gemeinsame Spanne, wenn beide Bedingungen greifen — sonst `null`.
  static Duration? _overlapOf(
      MeasuredSession measured, TrainingSession session) {
    final duration = session.duration;
    if (duration == null || duration <= Duration.zero) return null;

    final start = session.startedAt;
    if (start == null) return null;
    final end = start.add(duration);

    // Regel 2 zuerst: Sie ist die billigere Prüfung und wirft die
    // Ganztagsaufzeichnungen sofort hinaus.
    if (start.difference(measured.start).abs() > startTolerance) return null;

    final from = start.isAfter(measured.start) ? start : measured.start;
    final to = end.isBefore(measured.end) ? end : measured.end;
    final overlap = to.difference(from);
    if (overlap <= Duration.zero) return null;

    // Regel 1: **mehr** als die Hälfte der kürzeren Dauer — nicht „mindestens".
    final shorter = duration < measured.duration ? duration : measured.duration;
    if (overlap * 2 <= shorter) return null;

    return overlap;
  }
}
