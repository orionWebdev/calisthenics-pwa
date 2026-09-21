/// Fünf Herzfrequenzzonen, festgelegt über **vier Grenzen**.
///
/// ## Warum vier Grenzen und nicht fünf Bereiche
///
/// Fünf frei eingegebene Bereiche erlauben Lücken („131–148" und „152–167")
/// und Überlappungen — einen ungültigen Zustand, den die App prüfen, melden
/// und erklären müsste. Vier Grenzen zwischen fünf Zonen können nicht
/// ungültig sein: Jeder Wert liegt in genau einer Zone (Board 16,
/// Entscheidung 12). Ein Fehlerzustand, den es durch Konstruktion nicht
/// gibt, braucht keinen Bildschirm.
///
/// ## Was eine Grenze ist
///
/// Der **erste bpm-Wert der oberen Zone**. Bei 112, 131, 149, 168 reicht
/// Zone 1 bis 111, Zone 2 von 112 bis 130, Zone 5 ab 168.
class HeartRateZones {
  /// Prüft nichts: Wer Grenzen aus dem Speicher liest, nimmt [tryFrom].
  const HeartRateZones._(this.bounds);

  /// Aus vier Grenzen — oder `null`, wenn sie keine gültige Folge sind.
  static HeartRateZones? tryFrom(List<int> bounds) {
    if (bounds.length != boundaryCount) return null;
    if (bounds.first < minBoundary) return null;
    if (bounds.last > maxBoundary) return null;
    for (var i = 1; i < bounds.length; i++) {
      if (bounds[i] <= bounds[i - 1]) return null;
    }
    return HeartRateZones._(List.unmodifiable(bounds));
  }

  /// Der Vorschlag aus HFmax: 60 / 70 / 80 / 90 Prozent, **aufgerundet**.
  ///
  /// ## Ein Startpunkt, keine Empfehlung
  ///
  /// Prozentgrenzen sind die bekannteste Konvention, mehr nicht. Niemand tippt
  /// vier Grenzen von Hand, wenn er nichts hat — aber die App weiss nicht,
  /// welche Zonen für diesen Menschen stimmen. Gegen die Regel „kein
  /// Sollverhältnis" verstösst nicht das Rechnen, sondern das Bewerten
  /// (Entscheidung 13). Deshalb erscheint der Vorschlag nie im
  /// Einheitendetail als Norm.
  ///
  /// Aufgerundet, weil eine Grenze der **erste** Wert der oberen Zone ist:
  /// 60 % von 186 sind 111,6 — Zone 2 beginnt bei 112.
  static HeartRateZones? proposalFor(int hrMax) {
    if (hrMax < minHrMax || hrMax > maxHrMax) return null;
    return tryFrom([
      for (final pct in const [60, 70, 80, 90]) (hrMax * pct / 100).ceil(),
    ]);
  }

  static const zoneCount = 5;
  static const boundaryCount = 4;

  /// Plausible Grenzen, keine medizinischen. Sie fangen den Vertipper.
  static const minBoundary = 30;
  static const maxBoundary = 250;
  static const minHrMax = 100;
  static const maxHrMax = 250;

  /// Die vier Grenzen, aufsteigend.
  final List<int> bounds;

  /// In welcher Zone (1–5) ein Pulswert liegt.
  int zoneOf(int bpm) {
    for (var i = 0; i < bounds.length; i++) {
      if (bpm < bounds[i]) return i + 1;
    }
    return zoneCount;
  }

  /// Der erste bpm-Wert einer Zone — `null` für Zone 1, die nach unten offen ist.
  int? lowerOf(int zone) => zone <= 1 ? null : bounds[zone - 2];

  /// Der letzte bpm-Wert einer Zone — `null` für Zone 5, die nach oben offen ist.
  int? upperOf(int zone) => zone >= zoneCount ? null : bounds[zone - 1] - 1;

  /// Wie weit Grenze [index] (0–3) nach unten verschoben werden darf.
  ///
  /// Eine Grenze darf nicht auf oder unter die vorige rücken — sonst wäre eine
  /// Zone leer. Die untere Schranke steht als Satz im Blatt, nicht als
  /// gesperrter Knopf: Der Grund steht da, bevor man ihn braucht.
  int minFor(int index) => index == 0 ? minBoundary : bounds[index - 1] + 1;

  /// Wie weit Grenze [index] nach oben darf: höchstens 1 unter der nächsten.
  int maxFor(int index) =>
      index == boundaryCount - 1 ? maxBoundary : bounds[index + 1] - 1;

  /// Eine Kopie mit verschobener Grenze — oder diese hier selbst, wenn der
  /// Wert ausserhalb dessen liegt, was [minFor] und [maxFor] erlauben.
  HeartRateZones withBoundary(int index, int value) {
    if (value < minFor(index) || value > maxFor(index)) return this;
    final next = [...bounds]..[index] = value;
    return HeartRateZones._(List.unmodifiable(next));
  }

  @override
  bool operator ==(Object other) =>
      other is HeartRateZones && _same(other.bounds, bounds);

  @override
  int get hashCode => Object.hashAll(bounds);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Wie viele Sekunden in jeder der fünf Zonen lagen.
///
/// **Beschreibt, bewertet nicht.** Mehr Zeit in einer hohen Zone ist nicht
/// besser, und die App weiss nicht, wie viel Zone 4 richtig ist. Deshalb gibt
/// es hier keinen Anteil in Prozent: Prozentwerte verführen zum Vergleich mit
/// einem Soll, das nicht existiert (Entscheidung 9). Jede Zone trägt Minuten,
/// der Anteil steht nur als Balkenlänge.
class ZoneDistribution {
  const ZoneDistribution({
    required this.secondsPerZone,
    required this.recordedSeconds,
    required this.windowSeconds,
  });

  factory ZoneDistribution.of({
    required Map<int, int> secondsByBpm,
    required int windowSeconds,
    required HeartRateZones zones,
  }) {
    final perZone = List<int>.filled(HeartRateZones.zoneCount, 0);
    var recorded = 0;
    for (final entry in secondsByBpm.entries) {
      perZone[zones.zoneOf(entry.key) - 1] += entry.value;
      recorded += entry.value;
    }
    return ZoneDistribution(
      secondsPerZone: List.unmodifiable(perZone),
      recordedSeconds: recorded,
      windowSeconds: windowSeconds,
    );
  }

  /// Sekunden je Zone, Index 0 ist Zone 1.
  final List<int> secondsPerZone;

  /// Der Zähler: wie viel Aufzeichnung dahintersteht.
  final int recordedSeconds;

  /// Der Nenner: wie lang die Einheit war.
  final int windowSeconds;

  /// Breite eines Balkens, 0 bis 1: der Anteil dieser Zone an der
  /// **aufgezeichneten** Zeit.
  ///
  /// Die fünf Balken ergeben zusammen die volle Breite. Bezogen auf die
  /// aufgezeichnete Zeit, nicht auf die Einheit: Bei 21 von 52 Minuten
  /// Aufzeichnung füllte sonst nichts die Spur, und der Nenner steht ohnehin
  /// als Satz über den Balken (Board 16, Entscheidung 9/10). Der Anteil ist
  /// nur Länge — nie eine Prozentzahl.
  double shareOfRecorded(int zone) =>
      recordedSeconds == 0 ? 0 : secondsPerZone[zone - 1] / recordedSeconds;

  bool get isPartial =>
      windowSeconds > 0 && recordedSeconds < windowSeconds - 30;
}
