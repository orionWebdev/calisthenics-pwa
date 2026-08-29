import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../cardio_ui.dart';

/// Die RPE-Auswahl 1–5 — **die Schwierigkeitsauswahl aus Modul 7 mit anderer
/// Beschriftung** (Board 11, Sektion I).
///
/// Gleiche fünf Kacheln, gleiche Reihe, gleiche Regel: keine Vorbelegung.
/// Sichtbar 44 dp hoch (Spezifikation F), Trefferfläche 48. Die Zahl steht
/// oben, das Wort darunter — bei 2 und 4 auch, obwohl das Board nur 1, 3 und
/// 5 beschriftet: Ein Feld ohne Wort neben vier mit Wort sähe kaputt aus.
class RpeChoice extends StatelessWidget {
  const RpeChoice({super.key, required this.value, required this.onChanged});

  /// `null` heisst: nichts gewählt. Puls und RPE sind optional — leer lassen
  /// ist der Normalfall.
  final int? value;
  final ValueChanged<int?> onChanged;

  static const _visible = 44.0;
  static const _gap = 5.0;
  static const _minWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final width = math.max(_minWidth, _widest(context, l10n, scaler) + 16);
    final height = math.max(48.0, scaler.scale(28) + 26);

    return Semantics(
      container: true,
      label: l10n.formRpe,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: _gap),
          itemBuilder: (context, i) {
            final level = i + 1;
            final selected = level == value;
            return SizedBox(
              width: width,
              child: AtemTappable(
                // Nochmal antippen hebt auf — RPE ist optional, und ein
                // Wert, den man nicht mehr loswird, wäre eine Vorbelegung
                // durch die Hintertür.
                onTap: () => onChanged(selected ? null : level),
                semanticLabel:
                    '${l10n.formRpe} $level, ${rpeWord(l10n, level)}, '
                    '$level ${l10n.commonOf} 5',
                selected: selected,
                inMutuallyExclusiveGroup: true,
                minTapSize: const Size(0, 48),
                child: Container(
                  constraints: const BoxConstraints(minHeight: _visible),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AtemColors.cyan.withValues(alpha: 0.10)
                        : AtemColors.surfaceSolid,
                    borderRadius: BorderRadius.circular(AtemRadii.statBox),
                    border: Border.all(
                      color: selected
                          ? AtemColors.cyan.withValues(alpha: 0.35)
                          : AtemColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$level',
                        style: AtemType.valueMedium.of(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AtemColors.cyan
                                  : AtemColors.textPrimary,
                            ),
                      ),
                      Text(
                        rpeWord(l10n, level),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AtemType.labelMicro.of(context).copyWith(
                              letterSpacing: 0,
                              color: selected
                                  ? AtemColors.cyan
                                  : AtemColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _widest(
      BuildContext context, AppL10n l10n, TextScaler scaler) {
    var widest = 0.0;
    for (var level = 1; level <= 5; level++) {
      final painter = TextPainter(
        text: TextSpan(
            text: rpeWord(l10n, level), style: AtemType.labelMicro.base),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return widest;
  }
}
