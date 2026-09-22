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
    this.curve = const {},
    this.slotSeconds = legacySlotSeconds,
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

      final slot =
          inside[i].at.difference(start).inSeconds ~/ fineSlotSeconds;
      curveWeightedSum.update(slot, (v) => v + bpm * held,
          ifAbsent: () => bpm * held);
      curveWeight.update(slot, (v) => v + held, ifAbsent: () => held);
    }

    return PulseProfile(
      secondsByBpm: seconds,
      windowSeconds: end.difference(start).inSeconds,
      slotSeconds: fineSlotSeconds,
      curve: {
        for (final entry in curveWeight.entries)
          entry.key: (curveWeightedSum[entry.key]! / entry.value).round(),
      },
    );
  }

  /// Wie lang ein Schlitz der Kurve ist — **zehn Sekunden** seit dem
  /// 22.09.2026 (Board 16, Nachtrag, P).
  ///
  /// Vorher war es eine Minute, und ein Intervall von 40/20 verschwand im
  /// Mittel: Genau die Struktur, die man sehen will, war weggerechnet.
  ///
  /// **Sechsmal so viele Einträge je Einheit** — für eine Stunde rund 360
  /// statt 60, gut drei Kilobyte mehr im Dokument. Das Fenster von dreissig
  /// Tagen bleibt, das Histogramm `secondsByBpm` bleibt, und was vorher
  /// abgelegt wurde, bleibt minutengenau: Dieses Raster gilt ab dem nächsten
  /// Lesen, es rechnet nichts um.
  static const fineSlotSeconds = 10;

  /// Das Raster von vor dem 22.09.2026. Dokumente ohne `pulseCurveSlot`
  /// tragen es — kein Feld heisst hier „eine Minute", nicht „unbekannt".
  static const legacySlotSeconds = 60;

  /// Wie lange ein Messwert höchstens gilt, ohne dass ein neuer kommt.
  static const maxGapSeconds = 60;

  /// Sekunden, die jeder bpm-Wert gegolten hat.
  final Map<int, int> secondsByBpm;

  /// Die Länge der Einheit — der Nenner, gegen den „aufgezeichnet" steht.
  final int windowSeconds;

  /// bpm je Schlitz seit Beginn — nur Schlitze mit Messung.
  ///
  /// Wie lang ein Schlitz ist, sagt [slotSeconds]. Der Schlüssel ist ein
  /// Index, keine Minute: Wer ihn als Minute liest, bekommt seit dem
  /// 22.09.2026 das Sechsfache.
  final Map<int, int> curve;

  /// Die Länge eines Schlitzes dieser Kurve in Sekunden.
  ///
  /// Nicht global, sondern **je Datensatz**: Was vor dem 22.09.2026 abgelegt
  /// wurde, trägt 60 und bleibt dabei.
  ///
  /// **Der Standard ist die Minute, nicht die feine Ablage.** Wer ein Profil
  /// von Hand baut, meint fast immer eine Kurve alten Zuschnitts; ein
  /// stillschweigend feines Raster stauchte sie auf ein Sechstel der Einheit
  /// zusammen. Neu gelesene Kurven kommen aus [PulseProfile.fromSamples] und
  /// setzen [fineSlotSeconds] ausdrücklich.
  final int slotSeconds;

  /// Die **zusammenhängenden Abschnitte** der Kurve, als Listen von Schlitzen.
  ///
  /// Zusammenhängend heisst **zeitlich**, nicht schlitzweise: Ein Wert gilt
  /// bis zum nächsten, höchstens [maxGapSeconds] lang. Liegen zwei Werte
  /// sechzig Sekunden auseinander, ist das kein Loch — die Linie läuft
  /// durch. Erst darüber beginnt ein neuer Abschnitt.
  ///
  /// **Das ist der Unterschied zwischen einer Lücke und einer gröberen
  /// Stelle** (Board 16, Nachtrag, „Wechselmarke · Regel"): Über eine Lücke
  /// läuft die Linie nicht, über eine gröbere Stelle schon. Eine Uhr, die
  /// minütlich misst, füllt im Zehn-Sekunden-Raster jeden sechsten Schlitz —
  /// würde man Abschnitte an der Schlitznachbarschaft festmachen, zerfiele
  /// ihre Kurve in lauter Einzelpunkte und verschwände.
  List<List<int>> get curveSections {
    if (curve.isEmpty) return const [];
    final slots = curve.keys.toList()..sort();
    final sections = <List<int>>[];
    var current = <int>[slots.first];
    for (final slot in slots.skip(1)) {
      if ((slot - current.last) * slotSeconds <= maxGapSeconds) {
        current.add(slot);
      } else {
        sections.add(current);
        current = [slot];
      }
    }
    return [...sections, current];
  }

  /// Der typische Abstand zwischen zwei gespeicherten Werten, in Sekunden.
  ///
  /// **Er beschreibt, was dasteht — nicht, wie fein das Raster ist.** Eine
  /// Uhr, die nur jede Minute misst, füllt auch im Zehn-Sekunden-Raster nur
  /// jeden sechsten Schlitz; „je 10 Sekunden ein Wert" wäre dann gelogen.
  /// Deshalb der Median der tatsächlichen Abstände und nicht [slotSeconds].
  ///
  /// `null` unter zwei Werten — aus einem Punkt folgt kein Abstand.
  int? get curveStepSeconds {
    if (curve.length < 2) return null;
    final slots = curve.keys.toList()..sort();
    final gaps = [
      for (var i = 0; i < slots.length - 1; i++) slots[i + 1] - slots[i],
    ]..sort();
    return gaps[gaps.length ~/ 2] * slotSeconds;
  }

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

  /// Für Firestore: Schlüssel sind Schlitze seit Beginn als String, Werte
  /// bpm. Leer, wenn nichts erfasst wurde — dann schreibt der Aufrufer das
  /// Feld gar nicht erst. Die Länge eines Schlitzes steht daneben.
  Map<String, int> curveToWire() => {
        for (final e in curve.entries) '${e.key}': e.value,
      };

  static PulseProfile? fromWire(
    Object? histogram,
    Object? windowSeconds, [
    Object? curve,
    Object? slotSeconds,
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
        final slot = int.tryParse('${entry.key}');
        final bpm = entry.value;
        if (slot == null || slot < 0 || bpm is! num || bpm <= 0) continue;
        curveResult[slot] = bpm.round();
      }
    }

    return PulseProfile(
      secondsByBpm: result,
      windowSeconds: windowSeconds is num ? windowSeconds.round() : 0,
      curve: curveResult,
      // **Fehlt das Feld, gilt die Minute.** Ein Dokument von vor dem
      // 22.09.2026 trägt es nicht, und seine Schlüssel sind Minuten. Es als
      // Zehn-Sekunden-Kurve zu lesen, stauchte sie auf ein Sechstel der
      // Einheit zusammen.
      slotSeconds: slotSeconds is num && slotSeconds > 0
          ? slotSeconds.round()
          : legacySlotSeconds,
    );
  }
}
