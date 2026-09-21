/// Ein Puls-Messwert der Uhr — Zeitpunkt und Schläge pro Minute.
class PulseSample {
  const PulseSample({required this.at, required this.bpm});

  final DateTime at;
  final int bpm;
}

/// **Wie lange jeder Pulswert gegolten hat** — der Pulsverlauf einer Einheit,
/// auf das reduziert, was sich später noch rechnen lässt.
///
/// ## Warum ein Histogramm und nicht die Punktwolke
///
/// Zonen werden aus dem Pulsverlauf **immer neu** gerechnet, nie beim Import
/// festgeschrieben (Board 16, Entscheidung 15): Wer seine Grenzen ändert,
/// ändert damit jede Verteilung, auch die vergangener Einheiten. Dafür muss
/// gespeichert sein, *wie lange welcher Wert galt* — nicht, wann genau er
/// gemessen wurde. Ein Histogramm (Sekunden je bpm) trägt genau das und
/// verliert nichts, was eine Zonenrechnung braucht. Es hat zudem höchstens
/// ein paar Dutzend Einträge statt tausend Punkte — es passt in ein Dokument.
///
/// Was es **nicht** trägt: die Zeitachse. Eine Pulskurve über die Einheit
/// (Board 16, offene Frage 1) liesse sich daraus nicht zeichnen. Das ist
/// bewusst: Sie ist ein eigener Block mit eigener Entscheidung.
///
/// ## Was „aufgezeichnet" heisst
///
/// Jeder Messwert gilt bis zum nächsten, **höchstens [maxGapSeconds]** lang.
/// Liegt mehr als eine Minute zwischen zwei Werten, hat die Uhr dort nichts
/// gemessen, und die Lücke zählt nicht zur Aufzeichnung. Daraus entsteht der
/// Nenner „aus 21 von 52 min Aufzeichnung": Er sagt, wie viel von der
/// Einheit der Puls überhaupt beschreibt.
class PulseProfile {
  const PulseProfile({
    required this.secondsByBpm,
    required this.windowSeconds,
  });

  /// Aus den Messwerten einer Einheit.
  ///
  /// Nur, was **im Fenster** der Einheit liegt: Ein Wert vor dem Beginn oder
  /// nach dem Ende gehört zu etwas anderem — zum Aufwärmen davor, zum
  /// Ausgehen danach.
  factory PulseProfile.fromSamples(
    List<PulseSample> samples, {
    required DateTime start,
    required DateTime end,
  }) {
    final inside = [
      for (final s in samples)
        if (!s.at.isBefore(start) && s.at.isBefore(end) && s.bpm > 0) s,
    ]..sort((a, b) => a.at.compareTo(b.at));

    final seconds = <int, int>{};
    for (var i = 0; i < inside.length; i++) {
      final until = i + 1 < inside.length ? inside[i + 1].at : end;
      var held = until.difference(inside[i].at).inSeconds;
      if (held > maxGapSeconds) held = maxGapSeconds;
      if (held <= 0) continue;
      seconds.update(inside[i].bpm, (v) => v + held, ifAbsent: () => held);
    }

    return PulseProfile(
      secondsByBpm: seconds,
      windowSeconds: end.difference(start).inSeconds,
    );
  }

  /// Wie lange ein Messwert höchstens gilt, ohne dass ein neuer kommt.
  static const maxGapSeconds = 60;

  /// Sekunden, die jeder bpm-Wert gegolten hat.
  final Map<int, int> secondsByBpm;

  /// Die Länge der Einheit — der Nenner, gegen den „aufgezeichnet" steht.
  final int windowSeconds;

  bool get isEmpty => secondsByBpm.isEmpty;

  /// Wie viele Sekunden der Puls tatsächlich beschreibt.
  int get recordedSeconds =>
      secondsByBpm.values.fold<int>(0, (total, s) => total + s);

  /// Ob der Puls die ganze Einheit beschreibt — oder nur einen Teil.
  bool get isComplete =>
      windowSeconds > 0 && recordedSeconds >= windowSeconds - _tolerance;

  /// Zwei Messwerte à 60 s lassen an einem 52-Minuten-Fenster leicht ein paar
  /// Sekunden Rest. Das ist keine Lücke.
  static const _tolerance = 30;

  /// Zeitgewichteter Durchschnitt, gerundet. `null` ohne Aufzeichnung.
  int? get average {
    final total = recordedSeconds;
    if (total <= 0) return null;
    final sum =
        secondsByBpm.entries.fold<int>(0, (acc, e) => acc + e.key * e.value);
    return (sum / total).round();
  }

  int? get max =>
      isEmpty ? null : secondsByBpm.keys.reduce((a, b) => a > b ? a : b);

  int? get min =>
      isEmpty ? null : secondsByBpm.keys.reduce((a, b) => a < b ? a : b);

  /// Für Firestore: Schlüssel sind Strings, Werte Sekunden.
  Map<String, int> toWire() => {
        for (final e in secondsByBpm.entries) '${e.key}': e.value,
      };

  static PulseProfile? fromWire(Object? histogram, Object? windowSeconds) {
    if (histogram is! Map) return null;
    final result = <int, int>{};
    for (final entry in histogram.entries) {
      final bpm = int.tryParse('${entry.key}');
      final seconds = entry.value;
      if (bpm == null || bpm <= 0 || seconds is! num || seconds <= 0) continue;
      result[bpm] = seconds.round();
    }
    if (result.isEmpty) return null;
    return PulseProfile(
      secondsByBpm: result,
      windowSeconds: windowSeconds is num ? windowSeconds.round() : 0,
    );
  }
}
