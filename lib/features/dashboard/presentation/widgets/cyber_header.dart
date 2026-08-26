import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/dashboard_data.dart';

/// Kopfzeile: Markenpille, Begrüßung, Avatar mit Zähler.
class CyberHeader extends StatelessWidget {
  const CyberHeader({super.key, required this.user, required this.onProfile});

  final UserSummary user;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtemBadge(
                label: l10n.dashboardBrand,
                // Klartext statt Wortmarke plus Punkt.
                semanticLabel: l10n.dashboardBrandA11y,
                accent: AtemColors.green,
                leadingDot: true,
              ),
              const SizedBox(height: 7),
              Text(
                _greeting(l10n, user.displayName),
                style: AtemType.titleLarge.of(context),
              ),
              const SizedBox(height: 2),
              Text(l10n.dashboardSubtitle,
                  style: AtemType.labelSmall.of(context)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(user: user, onTap: onProfile),
      ],
    );
  }

  static String _greeting(AppL10n l10n, String name) {
    final h = DateTime.now().hour;
    if (h < 11) return l10n.dashboardGreetingMorning(name);
    if (h < 18) return l10n.dashboardGreetingDay(name);
    return l10n.dashboardGreetingEvening(name);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onTap});

  final UserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final unread = user.unreadNotifications;

    return AtemTappable(
      onTap: onTap,
      // Profil und Zähler als ein Knoten — sonst hört man zwei Dinge, die
      // demselben Ziel gehören.
      semanticLabel: unread > 0
          ? '${l10n.dashboardAvatarA11y(user.displayName)}. '
              '${l10n.dashboardNotificationsA11y(unread)}'
          : l10n.dashboardAvatarA11y(user.displayName),
      child: SizedBox(
        width: 58,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AtemGradients.avatarRing,
                boxShadow: AtemGlow.soft(AtemColors.cyan, opacity: 0.35),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: AtemColors.base, shape: BoxShape.circle),
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: Color(0xFF10121F), shape: BoxShape.circle),
                  child: Text(user.initial,
                      style: AtemType.titleMedium.of(context)),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 0,
                top: -4,
                child: AtemBadge.counter(
                  label: '$unread',
                  semanticLabel: l10n.dashboardNotificationsA11y(unread),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
