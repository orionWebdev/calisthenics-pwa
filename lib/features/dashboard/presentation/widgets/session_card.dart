import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/dashboard_data.dart';

/// Die eine hervorgehobene Karte des Screens.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.elapsed,
    required this.onToggle,
  });

  final TodaySession session;

  /// `null`, solange nichts läuft.
  final Duration? elapsed;

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final running = elapsed != null;
    final clock = running
        ? '${elapsed!.inMinutes.toString().padLeft(2, '0')}'
            ':${(elapsed!.inSeconds % 60).toString().padLeft(2, '0')}'
        : '';

    return AtemCard.gradientBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardSessionSection,
            style: AtemType.labelMicro
                .of(context)
                .copyWith(color: AtemColors.cyan),
          ),
          const SizedBox(height: 7),
          Text(session.title, style: AtemType.titleMedium.of(context)),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AtemBadge(
                label:
                    l10n.dashboardDurationMinutes(session.duration.inMinutes),
                style: AtemType.labelSmall,
              ),
              AtemBadge(
                label: session.intensityLabel,
                accent: session.isHighIntensity ? AtemColors.magenta : null,
                // Raute als Kategoriemerkmal: "48 Min" trägt keins, ein
                // Intensitäts-Badge immer. Farbe allein trüge es sonst.
                leadingIcon: session.isHighIntensity ? const _Diamond() : null,
                style: AtemType.labelSmall,
              ),
              AtemBadge(
                label: l10n.dashboardBlocks(session.blockCount),
                style: AtemType.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (running)
            AtemButton.outline(
              label: l10n.dashboardSessionRunning(clock),
              semanticLabel: l10n.dashboardSessionRunningA11y(clock),
              accent: AtemColors.green,
              size: AtemButtonSize.regular,
              glow: AtemColors.green,
              leading:
                  const AtemStatusDot(color: AtemColors.green, pulsing: true),
              onPressed: onToggle,
            )
          else
            AtemButton.gradient(
              label: l10n.dashboardSessionStart,
              semanticLabel: l10n.dashboardSessionStartA11y,
              glow: AtemColors.magenta,
              leading: const _PlayTriangle(),
              onPressed: onToggle,
            ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: 0.785,
        child: Container(
          width: 7,
          height: 7,
          color: AtemColors.magenta,
        ),
      );
}

class _PlayTriangle extends StatelessWidget {
  const _PlayTriangle();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(11, 13),
        painter: _TrianglePainter(),
      );
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close(),
        Paint()..color = AtemColors.textPrimary,
      );

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
