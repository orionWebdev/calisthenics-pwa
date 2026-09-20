import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/presentation/session_ui.dart';
import '../../../settings/presentation/widgets/settings_bits.dart';
import '../../../weight/application/weight_sync_providers.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_access.dart';

/// Der Zugang zu Health Connect — **zwei Zeilen, weil Google zwei Fragen
/// stellt** (Board 15, D).
///
/// ## Kein Sammelknopf
///
/// „Alles erlauben" würde eine Systemabfrage verdecken, die ohnehin einzeln
/// kommt — und im Ablehnungsfall eine halbe Freigabe hinterlassen, die
/// niemand versteht.
///
/// ## Zustand vor Aktion
///
/// Jede Zeile nennt zuerst, was gilt, und erst dann, was man tun kann. Beim
/// Entzug nennt sie zuerst, **was bleibt**: keine Drohung, kein Countdown,
/// kein Weg, der zurückdrängt (Entscheidung 21).
class HealthPermissionsSection extends ConsumerWidget {
  const HealthPermissionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final access = ref.watch(healthAccessProvider);

    // Solange gefragt wird, steht nichts da: Ein Abschnitt, der erst „nicht
    // freigegeben" zeigt und dann umspringt, hätte einen Zustand behauptet.
    final state = access.value;
    if (state == null) return const SizedBox.shrink();

    return SettingsSection(
      title: l10n.hcPermSection,
      children: [
        _PermissionRow(
          type: l10n.hcPermWeight,
          access: state.weight,
          stateText: _stateText(l10n, state, state.weight, weight: true),
          onGrant: () async {
            await ref.read(healthGatewayProvider).requestWeightAccess();
            ref.invalidate(healthAccessProvider);
          },
        ),
        const SettingsRule(),
        _PermissionRow(
          type: l10n.hcPermSessions,
          access: state.sessions,
          stateText: _stateText(l10n, state, state.sessions, weight: false),
          onGrant: () async {
            await ref
                .read(healthImportControllerProvider.notifier)
                .refresh(askForAccess: true);
            ref.invalidate(healthAccessProvider);
          },
        ),
        const SizedBox(height: 12),
        Text(_note(context, l10n, state), style: AtemType.meta.of(context)),
        if (state.isMissing) ...[
          const SizedBox(height: 12),
          AtemButton.outline(
            label: l10n.hcPermInstall,
            semanticLabel: l10n.hcPermInstall,
            expand: false,
            onPressed: () => ref.read(healthGatewayProvider).openInstall(),
          ),
        ],
      ],
    );
  }

  /// Der Zustand einer Zeile — **zuerst, was gilt**.
  static String _stateText(
    AppL10n l10n,
    HealthAccessState state,
    HealthAccess access, {
    required bool weight,
  }) =>
      switch (access) {
        HealthAccess.missing => l10n.hcStateMissing,
        HealthAccess.denied => l10n.hcStateDenied,
        HealthAccess.revoked => weight
            ? l10n.hcStateRevoked
            : l10n.hcStateRevokedKept(state.importedSessions),
        HealthAccess.granted => weight || state.lastRead == null
            ? l10n.hcStateGranted
            : state.importedSessions == 0
                ? l10n.hcStateGrantedEmpty
                : l10n.hcStateGranted,
      };

  /// Die eine Notiz unter beiden Zeilen.
  static String _note(
      BuildContext context, AppL10n l10n, HealthAccessState state) {
    if (state.isMissing) return l10n.hcPermMissingNote;
    if (state.weight == HealthAccess.revoked ||
        state.sessions == HealthAccess.revoked) {
      return l10n.hcPermRevokedNote(state.importedSessions);
    }
    if (state.weight == HealthAccess.granted &&
        state.sessions != HealthAccess.granted) {
      return l10n.hcPermPartialNote;
    }
    if (state.sessions == HealthAccess.granted) {
      final at = state.lastRead;
      if (at == null) return l10n.hcPermNoneNote;
      return l10n.hcPermEmptyNote(
        DateFormat('d. MMM HH:mm', languageTag(context)).format(at),
      );
    }
    return l10n.hcPermNoneNote;
  }
}

/// Eine Zeile je Datentyp.
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.type,
    required this.access,
    required this.stateText,
    required this.onGrant,
  });

  final String type;
  final HealthAccess access;
  final String stateText;
  final VoidCallback onGrant;

  /// Freigeben ist ein **Eingriff** — Magenta, wie jede Primäraktion.
  bool get _canGrant =>
      access == HealthAccess.denied || access == HealthAccess.revoked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tint = switch (access) {
      HealthAccess.granted => AtemColors.cyan,
      HealthAccess.revoked => AtemColors.magenta,
      HealthAccess.missing || HealthAccess.denied => AtemColors.textSecondary,
    };

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type, style: AtemType.labelSmall.of(context)),
                const SizedBox(height: 3),
                // Das Wort trägt den Zustand, die Farbe bestätigt ihn nur.
                Text(stateText.toUpperCase(),
                    style:
                        AtemType.labelMicro.of(context).copyWith(color: tint)),
              ],
            ),
          ),
          if (_canGrant) ...[
            const SizedBox(width: 12),
            Text(
              l10n.hcPermGrant,
              style: AtemType.labelUi
                  .of(context)
                  .copyWith(color: AtemColors.magenta),
            ),
          ],
        ],
      ),
    );

    if (!_canGrant) {
      // Kein ausgegrauter Knopf ohne Erklärung: Die Zeile trägt den Grund
      // im Zustand und ist schlicht nicht bedienbar.
      return Semantics(
        label: '$type, $stateText',
        child: ExcludeSemantics(child: row),
      );
    }

    return AtemTappable(
      onTap: onGrant,
      semanticLabel: l10n.hcPermRowA11y(type, stateText, l10n.hcPermGrant),
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: row,
    );
  }
}
