import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die vier Plätze der Bottom-Bar.
///
/// Die Reihenfolge ist die der Leiste: **Hybrid links**, dann Kraft, Cardio,
/// Regeneration. Der Index ist zugleich der Platz im `IndexedStack` der Hülle.
///
/// ## Vier statt drei
///
/// Board 11 gab drei Plätze vor und begründete das ausdrücklich: Regeneration
/// sei eine Eingangsgrösse der Bereitschaft und gehöre als Zeile neben sie,
/// nicht als eigener Bereich. Diese Entscheidung ist bewusst überstimmt
/// worden — sie stand im Entscheidungsprotokoll von Modul 11 unter „VIERTER
/// TAB", und die Begründung dort („zwölf Einheiten im Bestand, elf davon ohne
/// Angabe") ist eine Aussage über den Bestand von damals, nicht über das
/// Vorhaben.
///
/// Was von der alten Entscheidung bleibt: Die Regenerationszeile im
/// Hybrid-Tab **bleibt stehen**. Sie beantwortet dort weiter die Frage „wie
/// steht es um mich"; der Tab beantwortet „was habe ich gemacht".
enum AppTab {
  hybrid,
  strength,
  cardio,
  recovery;

  /// Wo die App aufmacht. „Wie steht es um mich" ist die erste Frage, nicht
  /// „was trainiere ich" — und seit Hybrid links steht, ist es auch der erste
  /// Platz.
  static const initial = AppTab.hybrid;

  /// Die Plätze, die die Leiste gerade zeigt.
  ///
  /// **Drei: Hybrid, Kraft, Cardio** — so verlangt es `CLAUDE.md` („Bottom-Bar
  /// hat genau drei Plätze. Keine neuen Bereiche, keine leeren Slots").
  ///
  /// Vom 15. bis zum 22.09.2026 standen hier nur zwei: Der Kraft-Tab wurde
  /// zuerst rund gemacht, Cardio sollte danach zurückkommen. Es kam zurück,
  /// weil sonst gebaute Dinge unerreichbar blieben — „Zone 5 je Woche" stand
  /// in einer Auswertung, zu der es keinen Weg gab.
  ///
  /// **Regeneration bleibt draussen**, und das ist kein Versehen: Ein vierter
  /// Platz widerspräche der Regel. Regeneration wohnt im Hybrid-Tab, wo die
  /// Zeile „Regeneration" sie erfasst.
  static const visible = [AppTab.hybrid, AppTab.strength, AppTab.cardio];
}

/// Die vier Seiten des Kraft-Tabs, in der Reihenfolge der Reiterleiste.
///
/// Bis zum 16.09.2026 zwei Segmente (Trainieren, Verlauf). Der Index ist die
/// Seite im PageView — die Reihenfolge hier ist deshalb nicht beliebig.
enum StrengthSegment { train, history, analysis, plans }

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
