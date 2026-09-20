import 'weight_entry.dart';

/// Das Fenster, das die Verlaufsansicht zeigt (Board 14, C1).
///
/// Drei Monate ist die Vorgabe und das einzige Fenster der Karte
/// (Entscheidung 3): kurz genug, dass die Frage „wie stehe ich gerade" eine
/// Antwort bekommt, lang genug, dass nicht das Tagesrauschen die Kurve macht.
enum WeightRange {
  threeMonths(90),
  sixMonths(182),
  year(365),

  /// Alles, was es gibt.
  all(null);

  const WeightRange(this.days);

  final int? days;

  /// Der erste Tag, der noch dazugehört. `null` bei [all].
  DateTime? startFrom(DateTime reference) {
    final span = days;
    if (span == null) return null;
    final day = WeightEntry.dayOf(reference);
    return DateTime(day.year, day.month, day.day - span + 1);
  }
}

/// Eine Veränderung zwischen zwei Einträgen — **eine Tatsache, kein Urteil**.
///
/// Richtung trägt der Glyph und das Wort, nie die Farbe (Entscheidung 4).
/// „Mehr" ist nicht „besser", und diese Klasse weiss deshalb nichts über gut
/// und schlecht: Sie nennt Betrag, Richtung, Vergleichsdatum und Abstand.
class WeightChange {
  const WeightChange({
    required this.deltaKg,
    required this.from,
    required this.days,
  });

  /// Vorzeichenbehaftet: negativ heisst weniger als beim Vergleichseintrag.
  final double deltaKg;

  /// Der Eintrag, mit dem verglichen wird — immer der **vorherige**, nicht
  /// der Anfang des Fensters. So steht in der Zeile ein Datum, an dem
  /// tatsächlich jemand gemessen hat.
  final WeightEntry from;

  /// Wie viele Tage der Vergleich zurückliegt.
  final int days;

  bool get isUp => deltaKg > 0;

  /// Der Betrag ohne Vorzeichen — die Richtung steht im Glyph und im Wort.
  double get magnitudeKg => deltaKg.abs();
}

/// Eine Zeitspanne ohne Eintrag.
///
/// Eine Lücke ist eine Lücke, keine gerade Linie (Entscheidung 8): Zwischen
/// zwei Einträgen hat niemand gemessen, und eine durchgezogene Linie würde
/// eine Entwicklung an Tagen behaupten, die es nicht gab.
class WeightGap {
  const WeightGap({required this.from, required this.to});

  final WeightEntry from;
  final WeightEntry to;

  int get days => to.date.difference(from.date).inDays;

  /// Ganze Wochen — so steht es in der Bodennotiz („6 Wochen ohne Eintrag").
  int get weeks => days ~/ 7;
}

/// Die Reihe der Gewichtswerte eines Kontos.
///
/// ## Warum eine eigene Klasse und keine Liste
///
/// Fast jede Frage an den Verlauf ist eine Frage nach dem **Abstand** zwischen
/// Einträgen, nicht nach ihrer Zahl: Verbindet die Kurve hier? Welcher Wert
/// galt am Tag dieser Einheit? Worauf wirkt eine Änderung? Eine nackte Liste
/// beantwortet keine davon, und jede Aufrufstelle würde sie anders beantworten.
///
/// ## Die Reihe ist immer sortiert und je Tag eindeutig
///
/// [WeightSeries.of] sortiert aufsteigend und lässt bei zwei Einträgen am
/// selben Tag den zuletzt geschriebenen stehen. Der Bestand kann das
/// theoretisch nicht hergeben — die Dokumentkennung ist das Datum —, aber ein
/// Import aus Health Connect kann es, und dann darf die Kurve nicht zwei
/// Punkte übereinander zeichnen.
class WeightSeries {
  const WeightSeries(this.entries);

  /// Aufsteigend nach Datum, höchstens ein Eintrag je Tag.
  final List<WeightEntry> entries;

  static const empty = WeightSeries(<WeightEntry>[]);

  /// Ab dieser Spanne zwischen zwei Einträgen **verbindet die Kurve nicht
  /// mehr**.
  ///
  /// Drei Wochen, und die Zahl ist eine Entscheidung, keine Messung: Board 14
  /// zeigt in A1 einen Rhythmus von rund zehn Tagen als durchgezogene Kurve
  /// (A1), sechs Wochen als Bruch mit Bodennotiz (A4) und zwei Monate als
  /// reine Punktwolke ohne jede Linie (A3). Drei Wochen ist die erste Spanne,
  /// in der zwischen zwei Punkten mehr Zeit **nicht** gemessen wurde als der
  /// übliche Abstand beträgt.
  static const gapDays = 21;

  factory WeightSeries.of(Iterable<WeightEntry> source) {
    final byDay = <String, WeightEntry>{};
    for (final entry in source) {
      byDay[entry.documentId] = entry;
    }
    final sorted = byDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return WeightSeries(List.unmodifiable(sorted));
  }

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;
  int get length => entries.length;

  WeightEntry? get first => entries.isEmpty ? null : entries.first;
  WeightEntry? get latest => entries.isEmpty ? null : entries.last;

  /// Der Eintrag vor dem jüngsten — die Grundlage der Veränderungszeile.
  WeightEntry? get previous =>
      entries.length < 2 ? null : entries[entries.length - 2];

  WeightEntry? entryOn(DateTime day) {
    final id = WeightEntry.idFor(day);
    for (final entry in entries) {
      if (entry.documentId == id) return entry;
    }
    return null;
  }

  /// Das Gewicht, das an [day] zuletzt bekannt war.
  ///
  /// ## Was vor dem ersten Eintrag gilt
  ///
  /// Der **früheste** bekannte Wert, nicht null und nicht 0. Ein Verlauf, der
  /// vor seinem ersten Eintrag mit 0 rechnete, setzte die Trainingslast jeder
  /// älteren Körpergewichtseinheit auf null — die gesamte Vergangenheit einer
  /// App, die seit 245 Tagen Bestand führt, verschwände in dem Moment, in dem
  /// die Reihe eingeführt wird. Der früheste bekannte Wert ist die ehrlichste
  /// Schätzung, die keine Zahl erfindet.
  double? kgOn(DateTime day) {
    if (entries.isEmpty) return null;
    final target = WeightEntry.dayOf(day);
    double? result;
    for (final entry in entries) {
      if (entry.date.isAfter(target)) break;
      result = entry.kg;
    }
    return result ?? entries.first.kg;
  }

  /// Die Reihe, beschnitten auf ein Fenster.
  WeightSeries within(WeightRange range, DateTime reference) {
    final from = range.startFrom(reference);
    if (from == null) return this;
    return WeightSeries([
      for (final entry in entries)
        if (!entry.date.isBefore(from)) entry,
    ]);
  }

  /// Die Veränderung des jüngsten Eintrags gegen den vorherigen.
  ///
  /// `null` bei weniger als zwei Einträgen — aus einem Wert folgt keine Reihe
  /// (Board 14, A2).
  WeightChange? get change {
    final last = latest;
    final before = previous;
    if (last == null || before == null) return null;
    return WeightChange(
      deltaKg: last.kg - before.kg,
      from: before,
      days: last.date.difference(before.date).inDays,
    );
  }

  /// Die zusammenhängenden Stücke der Kurve.
  ///
  /// Zwei aufeinanderfolgende Einträge gehören zum selben Stück, solange
  /// weniger als [gapDays] Tage dazwischen liegen. Ein Stück mit einem
  /// einzigen Punkt wird als Punkt gezeichnet, nicht als Linie.
  List<List<WeightEntry>> get segments {
    if (entries.isEmpty) return const [];
    final result = <List<WeightEntry>>[];
    var current = <WeightEntry>[entries.first];
    for (var i = 1; i < entries.length; i++) {
      final gap = entries[i].date.difference(entries[i - 1].date).inDays;
      if (gap >= gapDays) {
        result.add(current);
        current = <WeightEntry>[];
      }
      current.add(entries[i]);
    }
    result.add(current);
    return result;
  }

  /// Alle Lücken der Reihe, in zeitlicher Folge.
  List<WeightGap> get gaps {
    final result = <WeightGap>[];
    for (var i = 1; i < entries.length; i++) {
      final days = entries[i].date.difference(entries[i - 1].date).inDays;
      if (days >= gapDays) {
        result.add(WeightGap(from: entries[i - 1], to: entries[i]));
      }
    }
    return result;
  }

  /// Ob überhaupt eine Linie gezeichnet wird.
  ///
  /// Bei drei Einträgen über vier Monate ist **jeder** Abstand eine Lücke —
  /// dann steht eine Punktwolke da und keine Bodennotiz (Board 14, A3). Eine
  /// Notiz je Zwischenraum wäre in diesem Fall die Beschriftung der ganzen
  /// Fläche.
  bool get hasLine => segments.any((segment) => segment.length > 1);

  /// Die Lücke, die benannt wird — **genau dann, wenn es eine einzige gibt**.
  ///
  /// Eine Notiz beschreibt eine Lücke. Bei mehreren beschriebe sie eine von
  /// vielen und liesse die anderen unerwähnt — dann ist die Punktwolke selbst
  /// die Aussage (Board 14, A3: drei Punkte über vier Monate, keine Notiz).
  WeightGap? get namedGap {
    final all = gaps;
    return all.length == 1 ? all.single : null;
  }

  double get minKg =>
      entries.map((e) => e.kg).reduce((a, b) => a < b ? a : b);

  double get maxKg =>
      entries.map((e) => e.kg).reduce((a, b) => a > b ? a : b);

  /// Auf welche Tage sich ein Eintrag auswirkt: von seinem Datum **bis zum
  /// nächsten Eintrag**, nicht über den ganzen Verlauf (Entscheidung 11).
  ///
  /// Der letzte Eintrag wirkt bis [reference] — bis heute also. Liegt der
  /// nächste Eintrag am Folgetag, ist das Fenster ein einzelner Tag.
  (DateTime, DateTime) effectFor(WeightEntry entry, DateTime reference) {
    final index = entries.indexWhere((e) => e.documentId == entry.documentId);
    if (index < 0 || index == entries.length - 1) {
      final today = WeightEntry.dayOf(reference);
      return (entry.date, today.isBefore(entry.date) ? entry.date : today);
    }
    final next = entries[index + 1].date;
    final until = DateTime(next.year, next.month, next.day - 1);
    return (entry.date, until.isBefore(entry.date) ? entry.date : until);
  }
}
