import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_tappable.dart';

/// Der Kopf eines Blocks innerhalb eines Abschnitts: **Titel links, ein Weg
/// rechts**.
///
/// ## Eine Grundlinie, Aktion rechtsbündig (seit 17.09.2026)
///
/// Vorher standen Mono-Kopf und Aktion zentriert zueinander; weil beide
/// verschieden gross sind, sass „Alle 4" sichtbar höher als „PLÄNE".
///
/// Passen beide nicht nebeneinander (200 % Schrift auf 320 dp), wird **nicht
/// der Titel gekürzt** — die Aktion rutscht rechtsbündig darunter. Ein
/// abgeschnittener Titel ist ein verlorener Titel; eine Aktion in der zweiten
/// Zeile ist nur eine Zeile mehr.
///
/// Der Baustein lag bis zum 20.09.2026 privat im Workouts-Tab. Mit dem
/// One-Pager brauchen ihn drei Abschnitte — deshalb steht er jetzt im
/// Baukasten.
class AtemBlockHeader extends StatelessWidget {
  const AtemBlockHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.role,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Standard ist der Mono-Kopf ([AtemType.labelMicro], vom Aufrufer in
  /// Versalien gesetzt). Ein Titel mit Zahl übergibt [AtemType.meta], ein
  /// Blocktitel [AtemType.titleMedium] — dann ohne Versalien.
  final AtemTextRole? role;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    final titleStyle = (role ?? AtemType.labelMicro).of(context);
    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
    );
    if (!hasAction) return titleText;

    final actionStyle =
        AtemType.labelUi.of(context).copyWith(color: AtemColors.cyan);
    final action = AtemTappable(
      onTap: onAction,
      semanticLabel: actionLabel!,
      minTapSize: const Size(48, 48),
      alignment: Alignment.centerRight,
      child: Text(
        actionLabel!,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.right,
        style: actionStyle,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(String text, TextStyle style) => (TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout())
                .width;
        final fits = widthOf(title, titleStyle) +
                12 +
                widthOf(actionLabel!, actionStyle) <=
            constraints.maxWidth;

        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleText,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: titleText),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}
