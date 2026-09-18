import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';

/// Die schwebende Pausenleiste.
///
/// Der Fortschritt läuft im **Ablauf-Modus**: streng linear schrumpfend, und
/// er bleibt auch bei reduzierter Bewegung — er ist informationstragend.
///
/// Am Ende blitzt der Track zweimal limefarben. Bisher existierte das Ende nur
/// haptisch und akustisch — für stummgeschaltete Geräte und gehörlose Nutzer
/// unsichtbar.
class RestBar extends StatelessWidget {
  const RestBar({
    super.key,
    required this.remaining,
    required this.total,
    required this.compact,
    required this.finishing,
    required this.onExtend,
    required this.onShorten,
    required this.onSkip,
  });

  final Duration remaining;
  final Duration total;

  /// Beim Scrollen schrumpft die Leiste auf die Zeitangabe.
  final bool compact;

  /// Der Endblitz läuft gerade.
  final bool finishing;

  final VoidCallback onExtend;
  final VoidCallback onShorten;
  final VoidCallback onSkip;

  String get _clock => '${remaining.inMinutes.toString().padLeft(2, '0')}'
      ':${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final value =
        total.inSeconds == 0 ? 0.0 : remaining.inSeconds / total.inSeconds;

    return AnimatedContainer(
      duration: AtemMotion.normal,
      padding: EdgeInsets.symmetric(
          horizontal: AtemSpacing.lg,
          vertical: compact ? AtemSpacing.sm : AtemSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AtemColors.surfaceSolid.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (finishing ? AtemColors.green : AtemColors.cyan)
              .withValues(alpha: 0.4),
        ),
        boxShadow: [
          const BoxShadow(
              color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
          BoxShadow(
            color: (finishing ? AtemColors.green : AtemColors.cyan)
                .withValues(alpha: 0.5),
            blurRadius: 26,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Semantics(
                liveRegion: true,
                label: l10n.workoutA11yRestRemaining(_clock),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.workoutRunnerRestLabel,
                        style: AtemType.labelMicro
                            .of(context)
                            .copyWith(color: AtemColors.cyan),
                      ),
                      Text(_clock, style: AtemType.valueLarge.of(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AtemProgressBar.elapse(
                  value: value,
                  semanticLabel: l10n.workoutA11yRestRemaining(_clock),
                  accent: finishing ? AtemColors.green : AtemColors.cyan,
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AtemSpacing.md),
            // **Drei zu vier statt eins zu zwei.** Bei 361 dp blieben den
            // beiden Knöpfen 73 dp; „+30" brach dort mitten in der Zahl um
            // („+3 / 0"). Flutter trennt eine zu breite Zeichenkette notfalls
            // zeichenweise — sichtbar wurde es erst im Rendering mit den
            // echten Schriften.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AtemButton.outline(
                    label: l10n.workoutRunnerRestMinus,
                    semanticLabel: l10n.workoutA11yRestShorten,
                    onPressed: onShorten,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: AtemButton.outline(
                    label: l10n.workoutRunnerRestPlus,
                    semanticLabel: l10n.workoutA11yRestExtend,
                    onPressed: onExtend,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: AtemButton.gradient(
                    label: l10n.workoutRunnerRestSkip,
                    semanticLabel: l10n.workoutA11yRestSkip,
                    size: AtemButtonSize.compact,
                    gradient: const LinearGradient(
                      colors: [AtemColors.cyan, AtemColors.violet],
                    ),
                    haptic: AtemHaptic.selection,
                    onPressed: onSkip,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
