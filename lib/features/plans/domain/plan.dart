/// Ein Trainingsplan.
///
/// Die Daten kennen `name`, `icon`, `type` und `items` — **keinen Fortschritt**.
/// Ein Ring oder Balken an der Planzeile würde Präzision behaupten, die es
/// nicht gibt.
class Plan {
  const Plan({
    required this.id,
    required this.name,
    this.icon,
    this.type,
    this.items = const [],
  });

  final String id;
  final String name;

  /// Material-Symbolname aus der Vorgänger-App, etwa `sports_gymnastics`.
  final String? icon;

  /// `bodyweight` oder `strength`, roh. Übersetzt wird in der Oberfläche.
  final String? type;

  final List<PlanItem> items;

  int get exerciseCount => items.length;

  /// Geschätzte Dauer.
  ///
  /// Aus Sätzen und Pausen gerechnet, mit 45 Sekunden je Satz Arbeitszeit.
  /// Bewusst grob und nur als „~45 min" angezeigt: Eine Minutenangabe auf zwei
  /// Stellen wäre eine Genauigkeit, die die Daten nicht hergeben.
  Duration get estimatedDuration {
    var seconds = 0;
    for (final item in items) {
      final sets = item.sets ?? 3;
      seconds += sets * 45;
      seconds += (sets - 1).clamp(0, 99) * (item.restSeconds ?? 90);
      seconds += (item.holdSeconds ?? 0) * sets;
    }
    return Duration(seconds: seconds);
  }
}

/// Eine Übung im Plan, mit ihrer Zielvorgabe.
class PlanItem {
  const PlanItem({
    required this.exerciseId,
    this.sets,
    this.reps,
    this.holdSeconds,
    this.restSeconds,
  });

  final String exerciseId;
  final int? sets;

  /// **Zeichenkette, keine Zahl.** Im Bestand stehen Werte wie `25`, aber das
  /// Feld ist als Text angelegt und trägt damit auch Bereiche wie `8-12`. Ein
  /// `int` würde die verlieren.
  final String? reps;

  final int? holdSeconds;
  final int? restSeconds;
}
