import 'training_session.dart';

/// Eine Einheit mit **beiden** Selbstauskünften.
class WellnessPair {
  const WellnessPair({
    required this.date,
    required this.before,
    required this.after,
  });

  final DateTime date;

  /// Bereitschaft vor der Einheit, 1 bis 5.
  final int before;

  /// Gefühl nach der Einheit, 1 bis 5.
  final int after;

  /// Nachher minus vorher. Positiv heisst „nachher höher" — nicht „besser".
  int get difference => after - before;
}

/// Bereitschaft vor und Gefühl nach der Einheit, nebeneinander.
///
/// ## Was hier bewusst fehlt
///
/// **Kein Mittelwert.** „Bereitschaft im Schnitt 3,4" mittelte über Wörter
/// („müde", „okay") — der Abstand zwischen ihnen ist nicht gemessen, sondern
/// gesetzt. Gezählt wird deshalb nur, ob nachher höher, gleich oder niedriger
/// lag.
///
/// **Kein Urteil.** „Höher" ist nicht „besser": Ein Gefühl danach unter der
/// Bereitschaft davor kann genau das sein, was eine harte Einheit tun soll.
/// Die App sagt nicht, was richtig ist, und keine Zahl hier ist eine
/// Gesundheitsaussage.
///
/// **Keine halben Paare.** Eine Einheit mit nur einer Angabe erscheint nicht
/// in der Reihe, wird aber gezählt ([withOnlyOne]) — sonst sähe die Grundlage
/// dichter aus, als sie ist.
class WellnessTrend {
  const WellnessTrend({
    required this.pairs,
    required this.total,
    required this.withOnlyOne,
    required this.windowDays,
  });

  /// Ab so vielen Paaren trägt der Block.
  static const minimumPairs = 5;

  /// Alle Paare im Fenster, älteste zuerst.
  final List<WellnessPair> pairs;

  /// Alle Einheiten der betrachteten Arten im Fenster — der Nenner.
  final int total;

  /// Einheiten mit genau einer der beiden Angaben.
  final int withOnlyOne;

  final int windowDays;

  int get withBoth => pairs.length;
  bool get hasEnough => withBoth >= minimumPairs;

  int get higher => pairs.where((p) => p.difference > 0).length;
  int get same => pairs.where((p) => p.difference == 0).length;
  int get lower => pairs.where((p) => p.difference < 0).length;

  /// Die jüngsten [count] Paare, weiterhin älteste zuerst.
  List<WellnessPair> latest(int count) =>
      pairs.length <= count ? pairs : pairs.sublist(pairs.length - count);

  /// Das Fenster sind die letzten [windowDays] **Kalendertage** bis
  /// einschliesslich [reference], mit lokalen Tagesgrenzen — gerechnet über
  /// `DateTime(y, m, d ± n)`, nie über Millisekunden, damit eine
  /// Zeitumstellung keine Einheit über die Kante schiebt.
  static WellnessTrend compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int windowDays = 56,
    bool strengthOnly = true,
  }) {
    final from = DateTime(
        reference.year, reference.month, reference.day - windowDays + 1);
    final until = DateTime(reference.year, reference.month, reference.day + 1);

    final pairs = <WellnessPair>[];
    var total = 0;
    var onlyOne = 0;
    for (final session in sessions) {
      final kind = session.kind;
      if (kind == null) continue;
      if (strengthOnly &&
          kind != SessionKind.strength &&
          kind != SessionKind.bodyweight) {
        continue;
      }
      if (session.date.isBefore(from) || !session.date.isBefore(until)) {
        continue;
      }
      total++;
      final before = _level(session.preWorkoutReadiness);
      final after = _level(session.postWorkoutFeeling);
      if (before != null && after != null) {
        pairs.add(
            WellnessPair(date: session.date, before: before, after: after));
      } else if (before != null || after != null) {
        onlyOne++;
      }
    }
    pairs.sort((a, b) => a.date.compareTo(b.date));

    return WellnessTrend(
      pairs: pairs,
      total: total,
      withOnlyOne: onlyOne,
      windowDays: windowDays,
    );
  }

  /// Nur 1 bis 5 ist eine Angabe. Alles andere im Bestand ist keine.
  static int? _level(int? value) =>
      value != null && value >= 1 && value <= 5 ? value : null;
}
