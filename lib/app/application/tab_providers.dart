import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die drei Plätze der Bottom-Bar — Board 11, Sektion A.
///
/// Die Reihenfolge ist die der Leiste: Kraft links, Hybrid rechts. Der
/// Index ist zugleich der Platz im `IndexedStack` der Hülle.
enum AppTab {
  strength,
  cardio,
  hybrid;

  /// Wo die App aufmacht. Hybrid ist der frühere Start-Tab — „Wie steht es um
  /// mich" ist die erste Frage, nicht „was trainiere ich".
  static const initial = AppTab.hybrid;
}

/// Die zwei Segmente des Kraft-Tabs.
enum StrengthSegment { train, history }

/// Die zwei Segmente des Cardio-Tabs.
enum CardioSegment { sessions, analysis }

/// Wo die Navigation gerade steht.
@immutable
class AppTabsState {
  const AppTabsState({
    this.tab = AppTab.initial,
    this.strengthSegment = StrengthSegment.train,
    this.cardioSegment = CardioSegment.sessions,
    this.returnTo,
  });

  final AppTab tab;
  final StrengthSegment strengthSegment;
  final CardioSegment cardioSegment;

  /// Wohin Systemzurück nach einem Tabsprung führt (Board 11, Weg 3).
  ///
  /// Gesetzt nur, wenn der Wechsel **aus einer Zeile** kam — die Kraft- oder
  /// Ausdauerzeile im Verhältnisblock. Ein Tap in der Leiste setzt es zurück:
  /// Wer die Leiste benutzt, hat die Tabs als gleichrangig gewählt, und
  /// Zurück soll ihn nicht in einen Tab schicken, den er nicht gemeint hat.
  final AppTab? returnTo;

  AppTabsState copyWith({
    AppTab? tab,
    StrengthSegment? strengthSegment,
    CardioSegment? cardioSegment,
    AppTab? returnTo,
    bool clearReturn = false,
  }) =>
      AppTabsState(
        tab: tab ?? this.tab,
        strengthSegment: strengthSegment ?? this.strengthSegment,
        cardioSegment: cardioSegment ?? this.cardioSegment,
        returnTo: clearReturn ? null : (returnTo ?? this.returnTo),
      );
}

/// Der eine Ort, an dem Tab und Segment gewechselt werden.
///
/// ## Warum ein Provider und kein Rückruf mehr
///
/// Vorher trug der Start-Tab einen `onSelectTab`, den die Hülle hineinreichte.
/// Modul 11 bringt Wege, die **Tab und Segment** setzen — „Kraft, Segment
/// Verlauf" aus der Verhältniszeile. Ein Rückruf mit einem Index kann das
/// nicht ausdrücken, und drei Rückrufe durch drei Bildschirme wären dieselbe
/// Navigation dreimal.
class AppTabsController extends Notifier<AppTabsState> {
  @override
  AppTabsState build() => const AppTabsState();

  /// Tap in der Leiste.
  void select(AppTab tab) =>
      state = state.copyWith(tab: tab, clearReturn: true);

  /// Sprung aus einer Zeile: wechselt Tab und Segment und merkt sich den
  /// Rückweg (Board 11, Weg 1 bis 3).
  void jump(
    AppTab tab, {
    StrengthSegment? strengthSegment,
    CardioSegment? cardioSegment,
  }) {
    if (tab == state.tab) {
      state = state.copyWith(
        strengthSegment: strengthSegment,
        cardioSegment: cardioSegment,
      );
      return;
    }
    state = state.copyWith(
      tab: tab,
      strengthSegment: strengthSegment,
      cardioSegment: cardioSegment,
      returnTo: state.tab,
    );
  }

  void setStrengthSegment(StrengthSegment segment) =>
      state = state.copyWith(strengthSegment: segment);

  void setCardioSegment(CardioSegment segment) =>
      state = state.copyWith(cardioSegment: segment);

  /// Systemzurück nach einem Sprung. `false`, wenn es nichts zurückzugehen
  /// gibt — dann darf die App schliessen.
  bool goBack() {
    final target = state.returnTo;
    if (target == null) return false;
    state = state.copyWith(tab: target, clearReturn: true);
    return true;
  }
}

final appTabsProvider =
    NotifierProvider<AppTabsController, AppTabsState>(AppTabsController.new);
