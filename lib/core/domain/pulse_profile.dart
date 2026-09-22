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
/// ## [curveBpmByMinute] — die Zeitachse (Board 16, offene Frage 1, gelöst
/// am 22.09.2026)
///
/// Das Histogramm allein trägt keine Zeitachse — eine Pulskurve über die
/// Einheit liesse sich daraus nicht zeichnen. Deshalb hält [fromSamples]
/// zusätzlich einen **zeitgewichteten Minutenmittelwert**: bpm je Minute seit
/// [PulseProfile]-Beginn, nur für Minuten mit tatsächlicher Messung. Eine
/// Minute ohne Eintrag ist eine echte Lücke, nie interpoliert — dieselbe
/// Regel wie bei jeder anderen Zahl in dieser App. Für Einheiten, die vor
/// diesem Datum importiert wurden, bleibt die Karte leer: Ihre Rohdaten sind
/// nicht mehr da, nur noch das Histogramm.
class PulseProfile {
  const PulseProfile({
    required this.secondsByBpm,
    required this.windowSeconds,
    this.curveBpmByMinute = const {},
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
    final curveWeightedSum = <int, int>{};
    final curveWeight = <int, int>{};
    for (var i = 0; i < inside.length; i++) {
      final until = i + 1 < inside.length ? inside[i + 1].at : end;
      var held = until.difference(inside[i].at).inSeconds;
      if (held > maxGapSeconds) held = maxGapSeconds;
      if (held <= 0) continue;
      final bpm = inside[i].bpm;
      seconds.update(bpm, (v) => v + held, ifAbsent: () => held);

      final minute = inside[i].at.difference(start).inSeconds ~/ 60;
      curveWeightedSum.update(minute, (v) => v + bpm * held,
          ifAbsent: () => bpm * held);
      curveWeight.update(minute, (v) => v + held, ifAbsent: () => held);
    }

    return PulseProfile(
      secondsByBpm: seconds,
      windowSeconds: end.difference(start).inSeconds,
      curveBpmByMinute: {
        for (final entry in curveWeight.entries)
          entry.key: (curveWeightedSum[entry.key]! / entry.value).round(),
      },
    );
  }

  /// Wie lange ein Messwert höchstens gilt, ohne dass ein neuer kommt.
  static const maxGapSeconds = 60;

  /// Sekunden, die jeder bpm-Wert gegolten hat.
  final Map<int, int> secondsByBpm;

  /// Die Länge der Einheit — der Nenner, gegen den „aufgezeichnet" steht.
  final int windowSeconds;

  /// bpm je Minute seit Beginn — nur Minuten mit Messung, siehe Klassenkopf.
  final Map<int, int> curveBpmByMinute;

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

  /// Für Firestore: Schlüssel sind Minuten seit Beginn als String, Werte bpm.
  /// Leer, wenn keine Minute erfasst wurde — dann schreibt der Aufrufer das
  /// Feld gar nicht erst.
  Map<String, int> curveToWire() => {
        for (final e in curveBpmByMinute.entries) '${e.key}': e.value,
      };

  static PulseProfile? fromWire(
    Object? histogram,
    Object? windowSeconds, [
    Object? curve,
  ]) {
    if (histogram is! Map) return null;
    final result = <int, int>{};
    for (final entry in histogram.entries) {
      final bpm = int.tryParse('${entry.key}');
      final seconds = entry.value;
      if (bpm == null || bpm <= 0 || seconds is! num || seconds <= 0) continue;
      result[bpm] = seconds.round();
    }
    if (result.isEmpty) return null;

    final curveResult = <int, int>{};
    if (curve is Map) {
      for (final entry in curve.entries) {
        final minute = int.tryParse('${entry.key}');
        final bpm = entry.value;
        if (minute == null || minute < 0 || bpm is! num || bpm <= 0) continue;
        curveResult[minute] = bpm.round();
      }
    }

    return PulseProfile(
      secondsByBpm: result,
      windowSeconds: windowSeconds is num ? windowSeconds.round() : 0,
      curveBpmByMinute: curveResult,
    );
  }
}
