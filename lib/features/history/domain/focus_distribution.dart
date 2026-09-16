import 'training_session.dart';

/// Wie viele Krafteinheiten gegen einen [WorkoutFocus] gingen.
class FocusShare {
  const FocusShare({required this.focus, required this.count});

  final WorkoutFocus focus;
  final int count;
}

/// Die Verteilung der Krafteinheiten auf ihren Fokus.
///
/// Beantwortet „Wogegen trainiere ich — mehr Drücken als Ziehen?".
///
/// ## Der Nenner ist [withFocus], nicht [total]
///
/// `workoutFocus` ist freiwillig und fehlt im gesamten Altbestand. Ein Anteil
/// über alle Krafteinheiten liesse jede Einheit ohne Angabe wie „kein Fokus"
/// aussehen und drückte jeden Anteil nach unten. Die Einheiten ohne Fokus
/// werden deshalb getrennt gezählt und getrennt genannt.
///
/// ## Kein Urteil
///
/// Es gibt kein Sollverhältnis. „40 % Drücken, 20 % Ziehen" ist eine Zählung,
/// keine Aussage darüber, dass zu wenig gezogen wird.
class FocusDistribution {
  const FocusDistribution({
    required this.windowDays,
    required this.shares,
    required this.withFocus,
    required this.withoutFocus,
  });

  /// Ab so vielen Krafteinheiten **mit** Fokus trägt die Verteilung.
  static const minimumWithFocus = 3;

  static const defaultWindowDays = 56;

  final int windowDays;

  /// Nur Fokuswerte mit mindestens einer Einheit, nach Anzahl absteigend,
  /// bei Gleichstand in der Reihenfolge von [WorkoutFocus].
  final List<FocusShare> shares;

  final int withFocus;
  final int withoutFocus;

  int get total => withFocus + withoutFocus;

  bool get hasEnough => withFocus >= minimumWithFocus;

  /// Anteil in ganzen Prozent über [withFocus]; 0, wenn keine Einheit einen
  /// Fokus trägt.
  int percentOf(FocusShare share) =>
      withFocus == 0 ? 0 : (share.count / withFocus * 100).round();

  /// Das Fenster endet einschliesslich am Kalendertag von [reference] und
  /// umfasst [windowDays] Kalendertage. Tagesgrenzen lokal, nie über
  /// Millisekunden — wie `TimeSplit`.
  static FocusDistribution compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int windowDays = defaultWindowDays,
  }) {
    assert(windowDays > 0, 'Ein Fenster hat mindestens einen Tag.');
    final refDay = DateTime(reference.year, reference.month, reference.day);
    final start =
        DateTime(refDay.year, refDay.month, refDay.day - (windowDays - 1));

    final counts = <WorkoutFocus, int>{};
    var withFocus = 0;
    var withoutFocus = 0;

    for (final session in sessions) {
      if (session is! StrengthSession) continue;
      final day =
          DateTime(session.date.year, session.date.month, session.date.day);
      if (day.isBefore(start) || day.isAfter(refDay)) continue;
      final focus = session.workoutFocus;
      if (focus == null) {
        withoutFocus++;
      } else {
        withFocus++;
        counts[focus] = (counts[focus] ?? 0) + 1;
      }
    }

    final shares = [
      for (final focus in WorkoutFocus.values)
        if (counts[focus] case final count?)
          FocusShare(focus: focus, count: count),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.focus.index.compareTo(b.focus.index);
      });

    return FocusDistribution(
      windowDays: windowDays,
      shares: shares,
      withFocus: withFocus,
      withoutFocus: withoutFocus,
    );
  }
}
