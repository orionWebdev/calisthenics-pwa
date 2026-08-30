import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Eine Zahl, die zu ihrem neuen Wert läuft statt zu springen.
///
/// ## Wofür
///
/// Messwerte, die sich sichtbar ändern: die Bereitschaft nach einer Einheit,
/// die Wochenkilometer nach dem Erfassen, die Last im Detail. Der Lauf sagt
/// **dass** sich etwas geändert hat und in welche Richtung — ein Sprung sagt
/// nur, dass jetzt eine andere Zahl dasteht.
///
/// ## Wofür nicht
///
/// Zahlen, die nur einmal erscheinen und dann stehen (ein Datum, eine
/// Satzzahl in einer Liste). Dort ist der Lauf Zierde, und Zierde an
/// dreissig Stellen ist Unruhe.
///
/// Die Dauer richtet sich nach der Grösse des Sprungs: Ein Wechsel um zwei
/// Punkte darf nicht so lange laufen wie einer um achtzig.
class AtemAnimatedNumber extends StatelessWidget {
  const AtemAnimatedNumber({
    super.key,
    required this.value,
    required this.builder,
    this.maxDuration = const Duration(milliseconds: 900),
  });

  /// Der Zielwert.
  final double value;

  /// Baut die Darstellung aus dem laufenden Wert.
  final Widget Function(BuildContext context, double value) builder;

  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: AtemMotion.duration(context, maxDuration),
      curve: AtemMotion.curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}
