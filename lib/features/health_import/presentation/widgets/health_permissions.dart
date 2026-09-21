import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../settings/domain/user_settings.dart';
import '../../../settings/presentation/widgets/settings_bits.dart';
import '../../../weight/application/weight_sync_providers.dart';
import '../../application/health_import_providers.dart';
import '../../domain/health_access.dart';

/// Der Zugang zu Health Connect — **zwei Schalter, weil Google zwei Fragen
/// stellt** (Board 15, D).
///
/// ## Was ein Schalter hier heisst
///
/// Health Connect kennt für eine App nur „alles entziehen", nicht je
/// Datentyp. Ein Schalter, der wirklich schaltet, sitzt deshalb in ATEM:
/// **Aus heisst, ATEM liest und schreibt diesen Typ nicht mehr.** Die Freigabe
/// des Systems bleibt bestehen und lässt sich in Health Connect ganz
/// entziehen.
///
/// **An** ist er, wenn beides stimmt: Das System hat freigegeben *und* der
/// Schalter steht an. Wer ihn anschaltet, ohne dass freigegeben ist, bekommt
/// die Systemabfrage; lehnt er sie ab, steht der Schalter wieder aus.
///
/// ## Kein Sammelknopf, keine Unterzeilen
///
/// „Alles erlauben" würde eine Systemabfrage verdecken, die ohnehin einzeln
/// kommt. Und der Zustand steht im Schalter selbst (AN/AUS mit Glyph): Eine
/// Zeile darunter, die ihn noch einmal in Worten sagt, ist Unruhe, keine
/// Auskunft. Nur wo Health Connect fehlt, steht ein Satz da — dort erklärt er,
/// warum es keinen Schalter gibt.
class HealthPermissionsSection extends ConsumerWidget {
  const HealthPermissionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final access = ref.watch(healthAccessProvider);
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();

    // Solange gefragt wird, steht nichts da: Ein Abschnitt, der erst „aus"
    // zeigt und dann umspringt, hätte einen Zustand behauptet.
    final state = access.value;
    if (state == null) return const SizedBox.shrink();

    if (state.isMissing) {
      return SettingsSection(
        title: l10n.hcPermSection,
        children: [
          Text(l10n.hcPermMissingNote, style: AtemType.meta.of(context)),
          const SizedBox(height: 12),
          AtemButton.outline(
            label: l10n.hcPermInstall,
            semanticLabel: l10n.hcPermInstall,
            expand: false,
            onPressed: () => ref.read(healthGatewayProvider).openInstall(),
          ),
        ],
      );
    }

    final weightOn =
        state.weight == HealthAccess.granted && settings.healthWeightEnabled;
    final sessionsOn = state.sessions == HealthAccess.granted &&
        settings.healthSessionsEnabled;

    return SettingsSection(
      title: l10n.hcPermSection,
      children: [
        SettingsSwitch(
          label: l10n.hcPermWeight,
          value: weightOn,
          semanticLabel: _label(l10n, l10n.hcPermWeight, weightOn),
          onChanged: (on) => _setWeight(ref, settings, state, on),
        ),
        const SettingsRule(),
        SettingsSwitch(
          label: l10n.hcPermSessions,
          value: sessionsOn,
          semanticLabel: _label(l10n, l10n.hcPermSessions, sessionsOn),
          onChanged: (on) => _setSessions(ref, settings, state, on),
        ),
      ],
    );
  }

  static String _label(AppL10n l10n, String type, bool on) =>
      '$type, ${on ? l10n.switchOn : l10n.switchOff}';

  Future<void> _write(WidgetRef ref, UserSettings next) =>
      ref.read(settingsControllerProvider.notifier).update(next);

  Future<void> _setWeight(
    WidgetRef ref,
    UserSettings settings,
    HealthAccessState state,
    bool on,
  ) async {
    if (!on) {
      await _write(ref, settings.copyWith(healthWeightEnabled: false));
      return;
    }
    // Zuerst die Freigabe, dann der Schalter: Wer den Dialog ablehnt, soll
    // keinen Schalter auf „an" zurücklassen, der nichts tut.
    if (state.weight != HealthAccess.granted) {
      final granted =
          await ref.read(healthGatewayProvider).requestWeightAccess();
      ref.invalidate(healthAccessProvider);
      if (!granted) return;
    }
    await _write(ref, settings.copyWith(healthWeightEnabled: true));
    await ref.read(weightSyncProvider.notifier).run();
    ref.invalidate(healthAccessProvider);
  }

  Future<void> _setSessions(
    WidgetRef ref,
    UserSettings settings,
    HealthAccessState state,
    bool on,
  ) async {
    if (!on) {
      await _write(ref, settings.copyWith(healthSessionsEnabled: false));
      return;
    }
    // Erst anschalten, dann lesen lassen: Das Lesen fragt den Schalter und
    // liesse sich sonst nicht zum Fragen bewegen.
    await _write(ref, settings.copyWith(healthSessionsEnabled: true));
    await ref
        .read(healthImportControllerProvider.notifier)
        .refresh(askForAccess: true);
    ref.invalidate(healthAccessProvider);
  }
}
