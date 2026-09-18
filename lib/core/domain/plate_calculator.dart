/// Welche Scheiben auf eine Langhantel gehören — Punkt 2.4 der
/// Gemini-Produktstrategie vom 18.09.2026.
///
/// ## Warum in Gramm
///
/// `2,5 + 1,25` ist in Gleitkomma nicht immer `3,75`. Ein Rest von
/// `0,0000000001 kg` wäre eine Scheibe, die sich „nicht stecken lässt". Die
/// Rechnung läuft deshalb in ganzen Gramm; nach aussen gehen wieder
/// Kilogramm.
///
/// ## Gierig, schwerste zuerst
///
/// Mit den üblichen Scheiben (25 · 20 · 15 · 10 · 5 · 2,5 · 1,25) ist das die
/// Belegung, die man im Studio auch wirklich steckt — die wenigsten Scheiben
/// und die schweren innen. Ein Ziel, das nicht aufgeht, bekommt die grösste
/// Belegung darunter und einen ausgewiesenen Rest, nie eine erfundene Scheibe.
library;

/// Eine Scheibengrösse und wie oft sie **je Seite** steckt.
typedef PlateCount = ({double plateKg, int count});

class PlateLoading {
  const PlateLoading({
    required this.targetKg,
    required this.barKg,
    required this.perSide,
    required this.loadedKg,
    required this.remainderKg,
    required this.belowBar,
  });

  final double targetKg;
  final double barKg;

  /// Je Seite, schwerste zuerst. Leer bei leerer Stange oder [belowBar].
  final List<PlateCount> perSide;

  /// Was mit dieser Belegung tatsächlich auf der Stange liegt, Stange
  /// eingerechnet.
  final double loadedKg;

  /// Was vom Ziel nicht aufgeht — `targetKg − loadedKg`. `0` heisst: passt.
  final double remainderKg;

  /// Das Ziel ist leichter als die Stange allein.
  final bool belowBar;

  bool get isExact => !belowBar && remainderKg == 0;

  bool get isEmptyBar => !belowBar && perSide.isEmpty;

  /// Alle Scheiben einer Seite einzeln, schwerste zuerst — für die Grafik.
  List<double> get sidePlates => [
        for (final p in perSide)
          for (var i = 0; i < p.count; i++) p.plateKg,
      ];
}

abstract final class PlateCalculator {
  static const defaultPlates = <double>[25, 20, 15, 10, 5, 2.5, 1.25];

  /// Die üblichen Stangen: Männer 20 kg, Frauen 15 kg, Technik 10 kg.
  static const bars = <double>[20, 15, 10];

  static int _g(double kg) => (kg * 1000).round();
  static double _kg(int g) => g / 1000;

  static PlateLoading solve(
    double targetKg, {
    double barKg = 20,
    List<double> plates = defaultPlates,
  }) {
    final target = _g(targetKg);
    final bar = _g(barKg);

    if (target < bar) {
      return PlateLoading(
        targetKg: targetKg,
        barKg: barKg,
        perSide: const [],
        loadedKg: barKg,
        remainderKg: 0,
        belowBar: true,
      );
    }

    // Je Seite die Hälfte des Rests; ein ungerades Gramm geht nicht auf.
    var side = (target - bar) ~/ 2;
    final sorted = [...plates.map(_g)]..sort((a, b) => b.compareTo(a));
    final perSide = <PlateCount>[];
    var loadedSide = 0;
    for (final plate in sorted) {
      if (plate <= 0) continue;
      final count = side ~/ plate;
      if (count == 0) continue;
      perSide.add((plateKg: _kg(plate), count: count));
      side -= count * plate;
      loadedSide += count * plate;
    }

    final loaded = bar + 2 * loadedSide;
    return PlateLoading(
      targetKg: targetKg,
      barKg: barKg,
      perSide: perSide,
      loadedKg: _kg(loaded),
      remainderKg: _kg(target - loaded),
      belowBar: false,
    );
  }
}
