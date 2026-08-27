import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../plans/application/plan_providers.dart';
import '../../application/account_export.dart';
import '../../application/pending_weight_change.dart';
import '../../application/settings_providers.dart';
import '../../domain/body_weight_preview.dart';
import '../../domain/legal_links.dart';
import '../../domain/user_settings.dart';
import '../widgets/settings_bits.dart';
import '../widgets/weight_preview.dart';
import 'account_deletion_screen.dart';

/// Einstellungen und Profil.
///
/// ## Warum kein Platz in der Leiste
///
/// Die schwebende Leiste hat fünf Plätze, und jeder davon ist eine Behauptung
/// darüber, was man oft tut. Einstellungen tut man selten — sie neben Dashboard
/// und Verlauf zu stellen, hiesse ihnen dasselbe Gewicht zu geben wie dem
/// Training.
///
/// Der Weg führt deshalb über das Profilbild im Dashboard-Kopf. Das ist die
/// Stelle, an der man es sucht, und sie kostet keinen Platz.
///
/// ## Die Reihenfolge
///
/// Profil, Training, App, Konto, Rechtliches, Über die App — von dem, was man
/// am ehesten ändert, zu dem, was man einmal liest.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _weight = TextEditingController();
  final _rest = TextEditingController();

  /// Der Kandidat für die Vorschau. `null`, solange nichts Gültiges dasteht.
  double? _candidateKg;

  var _seeded = false;
  String? _notice;

  @override
  void dispose() {
    _weight.dispose();
    _rest.dispose();
    super.dispose();
  }

  /// Die Felder einmal aus dem Bestand füllen.
  ///
  /// **Genau einmal, und erst wenn Daten da sind.** Zwei Fallen liegen hier
  /// dicht beieinander:
  ///
  /// Wer bei jedem Strom-Ereignis neu setzt, überschreibt die Eingabe mitten
  /// im Tippen. Wer beim ersten Aufbau setzt, füllt die Felder mit den
  /// Vorgabewerten — denn beim ersten Aufbau lädt der Strom noch — und sperrt
  /// sich danach selbst aus. Das Gewichtsfeld bliebe dauerhaft leer, obwohl
  /// eins hinterlegt ist.
  void _seed(UserSettings settings, {required bool hasData}) {
    if (_seeded || !hasData) return;
    _seeded = true;
    final kg = settings.bodyWeightKg;
    if (kg != null) {
      _weight.text = AtemNumberField.format(
        context,
        settings.unitSystem.fromKilograms(kg),
      );
    }
    _rest.text = settings.restSeconds.toString();
  }

  double? _parsedWeightKg(UserSettings settings) {
    final raw = AtemNumberField.parse(_weight.text);
    if (raw == null) return null;
    final kg = settings.unitSystem.toKilograms(raw);
    return UserSettings.isPlausibleWeight(kg) ? kg : null;
  }

  Future<void> _saveWeight(UserSettings settings) async {
    final kg = _parsedWeightKg(settings);
    if (kg == null || kg == settings.bodyWeightKg) return;

    ref
        .read(pendingWeightProvider.notifier)
        .begin(previousKg: settings.bodyWeightKg, newKg: kg);

    await ref
        .read(settingsControllerProvider.notifier)
        .update(settings.copyWith(bodyWeightKg: kg));

    // Die Vorschau ist damit erfüllt: Was sie angekündigt hat, steht jetzt in
    // der App. Sie verschwindet, der Widerruf tritt an ihre Stelle.
    if (mounted) setState(() => _candidateKg = null);
  }

  Future<void> _open(Uri url) async {
    final l10n = AppL10n.of(context);
    final opened =
        await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) setState(() => _notice = l10n.settingsLinkFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(settingsProvider);
    final settings = async.value ?? const UserSettings();
    final user = ref.watch(authStateProvider).value;

    _seed(settings, hasData: async.hasValue);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title:
            Text(l10n.settingsTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            // Zwei Meldungen, ein Platz: Der Widerruf hat Vorrang, weil er
            // ausläuft — ein Linkfehler wartet.
            AtemNoticeSlot(notice: _slotNotice(l10n)),
            _WeightSection(
              controller: _weight,
              settings: settings,
              candidateKg: _candidateKg,
              onChanged: (_) =>
                  setState(() => _candidateKg = _parsedWeightKg(settings)),
              onSubmit: () => _saveWeight(settings),
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.settingsSectionTraining,
              children: [
                AtemFieldLabel(
                  label: l10n.settingsRest,
                  hint: l10n.settingsRestHint,
                ),
                AtemNumberField(
                  controller: _rest,
                  semanticLabel: l10n.settingsRest,
                  width: null,
                  suffix: l10n.unitSuffixSeconds,
                  hasError: _restFault(),
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                ),
                if (_restFault()) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.settingsRestFault(UserSettings.minRestSeconds,
                        UserSettings.maxRestSeconds),
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.magenta, letterSpacing: 0),
                  ),
                ],
                const SizedBox(height: 12),
                AtemButton.outline(
                  label: l10n.commonSave,
                  semanticLabel: '${l10n.commonSave}: ${l10n.settingsRest}',
                  onPressed: _restFault() ? null : () => _saveRest(settings),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.settingsSectionApp,
              children: [
                AtemFieldLabel(
                  label: l10n.settingsUnits,
                  hint: l10n.settingsUnitsHint,
                ),
                AtemSegmented<UnitSystem>(
                  value: settings.unitSystem,
                  groupSemanticLabel: l10n.settingsUnits,
                  onChanged: (value) => _saveUnits(settings, value),
                  segments: [
                    AtemSegment(
                      value: UnitSystem.metric,
                      label: l10n.settingsUnitsMetric,
                      semanticLabel: l10n.settingsUnitsMetricA11y,
                    ),
                    AtemSegment(
                      value: UnitSystem.imperial,
                      label: l10n.settingsUnitsImperial,
                      semanticLabel: l10n.settingsUnitsImperialA11y,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AtemFieldLabel(
                  label: l10n.settingsLanguage,
                  hint: l10n.settingsLanguageHint,
                ),
                AtemSegmented<AppLanguage>(
                  // Ist noch nichts gewählt, gilt die Systemsprache — und der
                  // Haken steht da, wo die App gerade steht.
                  value: settings.language ??
                      AppLanguage.forSystem(
                          Localizations.localeOf(context).languageCode),
                  groupSemanticLabel: l10n.settingsLanguage,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(language: value)),
                  segments: [
                    AtemSegment(
                      value: AppLanguage.german,
                      label: l10n.settingsLanguageGerman,
                      semanticLabel: l10n.settingsLanguageGerman,
                    ),
                    AtemSegment(
                      value: AppLanguage.english,
                      label: l10n.settingsLanguageEnglish,
                      semanticLabel: l10n.settingsLanguageEnglish,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SettingsSwitch(
                  label: l10n.settingsHaptics,
                  hint: l10n.settingsHapticsHint,
                  value: settings.hapticsEnabled,
                  semanticLabel: settings.hapticsEnabled
                      ? l10n.settingsHapticsOn
                      : l10n.settingsHapticsOff,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(hapticsEnabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.settingsSectionAccount,
              children: [
                ExcludeSemantics(
                  child: Text(l10n.settingsSignedInAs,
                      style: AtemType.labelMicro.of(context)),
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: '${l10n.settingsSignedInAs}: ${user?.email ?? ''}. '
                      '${l10n.settingsFromGoogle}',
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email ?? l10n.commonNotAvailable,
                            style: AtemType.body.of(context)),
                        const SizedBox(height: 6),
                        // Statt eines gesperrten Formularfelds, das wie ein
                        // Defekt aussähe: ein Satz, der es erklärt.
                        Text(l10n.settingsFromGoogle,
                            style: AtemType.labelMicro.of(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SettingsRow(
                  label: l10n.settingsSignOut,
                  onTap: _confirmSignOut,
                ),
                SettingsRow(
                  label: l10n.settingsExportTitle,
                  hint: l10n.settingsExportBody,
                  onTap: _openExport,
                ),
                SettingsRow(
                  label: l10n.settingsDelete,
                  accent: AtemColors.magenta,
                  onTap: _confirmDelete,
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.settingsSectionLegal,
              children: [
                SettingsRow(
                  label: l10n.settingsPrivacy,
                  hint: l10n.settingsOpensBrowser,
                  onTap: () => _open(LegalLinks.privacy(
                      Localizations.localeOf(context).languageCode)),
                ),
                SettingsRow(
                  label: l10n.settingsTerms,
                  hint: l10n.settingsOpensBrowser,
                  onTap: () => _open(LegalLinks.terms(
                      Localizations.localeOf(context).languageCode)),
                ),
                SettingsRow(
                  label: l10n.settingsImprint,
                  hint: l10n.settingsOpensBrowser,
                  onTap: () => _open(LegalLinks.imprint),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.settingsSectionAbout,
              children: [
                SettingsFact(text: l10n.settingsAboutVersion(_version)),
                // Die Zeile steht dort, wo in der Vorgänger-App ein
                // Themenschalter war. Für ATEM existiert keine helle Palette;
                // ein Schalter, der nichts tut, wäre schlimmer als keiner.
                SettingsFact(text: l10n.settingsAboutTheme),
                SettingsFact(text: l10n.settingsAboutPrivate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _version = '1.0.0';

  /// Der Widerruf steht **hier** und nicht in der Hülle: Die Einstellungen
  /// liegen als eigener Bildschirm darüber, und die Leiste der Hülle ist von
  /// hier aus nicht zu sehen.
  AtemNotice? _slotNotice(AppL10n l10n) {
    final pending = ref.watch(pendingWeightProvider);
    if (pending != null) {
      final weight = AtemNumberField.format(context, pending.newKg);
      return AtemNotice(
        title: l10n.settingsWeightChanged(weight),
        body: l10n.settingsWeightChangedBody(
            PendingWeightController.window.inSeconds),
        semanticLabel: '${l10n.settingsWeightChanged(weight)}. '
            '${l10n.settingsWeightChangedBody(PendingWeightController.window.inSeconds)}',
        actionLabel: l10n.sessionDeletedUndo,
        onAction: () async {
          await ref.read(pendingWeightProvider.notifier).undo();
          if (!mounted) return;
          // Das Feld muss zurückspringen — sonst stünde dort weiter der
          // widerrufene Wert und die Vorschau begänne von vorn.
          final kg = ref.read(settingsProvider).value?.bodyWeightKg;
          setState(() {
            _weight.text = kg == null
                ? ''
                : AtemNumberField.format(
                    context,
                    (ref.read(settingsProvider).value ?? const UserSettings())
                        .unitSystem
                        .fromKilograms(kg),
                  );
            _candidateKg = null;
          });
        },
      );
    }

    if (_notice case final text?) {
      return AtemNotice(
        tone: AtemNoticeTone.error,
        title: text,
        body: l10n.settingsOpensBrowser,
        semanticLabel: '$text. ${l10n.settingsOpensBrowser}',
      );
    }
    return null;
  }

  bool _restFault() {
    final value = int.tryParse(_rest.text.trim());
    return value == null ||
        value < UserSettings.minRestSeconds ||
        value > UserSettings.maxRestSeconds;
  }

  Future<void> _saveRest(UserSettings settings) async {
    final value = int.tryParse(_rest.text.trim());
    if (value == null) return;
    await ref
        .read(settingsControllerProvider.notifier)
        .update(settings.copyWith(restSeconds: value));
  }

  /// Das Einheitensystem wechselt **nur die Anzeige** — das Feld wird
  /// umgerechnet, der gespeicherte Wert bleibt in Kilogramm.
  Future<void> _saveUnits(UserSettings settings, UnitSystem value) async {
    final kg = settings.bodyWeightKg;
    if (kg != null) {
      _weight.text = AtemNumberField.format(context, value.fromKilograms(kg));
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .update(settings.copyWith(unitSystem: value));
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppL10n.of(context);
    final confirmed = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.confirm,
      title: l10n.settingsSignOutTitle,
      message: l10n.settingsSignOutBody,
      confirmLabel: l10n.settingsSignOut,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.settingsSignOutBarrier,
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  /// Stufe 1: Was verschwindet — **in Zahlen** —, und der zweite Ausgang.
  Future<void> _confirmDelete() async {
    final l10n = AppL10n.of(context);

    final sessions = ref.read(sessionsProvider).value?.length ?? 0;
    final plans = ref.read(plansProvider).value?.length ?? 0;
    final own = (ref.read(exercisesProvider).value ?? const [])
        .where((e) => e.isOwn)
        .length;

    final choice = await AtemDialog.show<_DeleteChoice>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.settingsDeleteStep1Title,
      message: l10n.settingsDeleteStep1Body,
      confirmLabel: l10n.commonDelete,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.settingsDeleteBarrier,
      // Der zweite Ausgang ist kein zweites Löschen, sondern die Alternative
      // dazu: erst sichern. Er steht deshalb hier und nicht daneben.
      alternativeLabel: l10n.settingsDeleteExport,
      onAlternative: () => Navigator.of(context).pop(_DeleteChoice.export),
      detail: Text(
        l10n.settingsDeleteCounts(sessions, plans, own),
        style: AtemType.labelSmall.of(context),
      ),
      onConfirm: () => Navigator.of(context).pop(_DeleteChoice.proceed),
    );

    if (!mounted) return;
    switch (choice) {
      case _DeleteChoice.export:
        await _openExport();
      case _DeleteChoice.proceed:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AccountDeletionScreen(),
          ),
        );
      case null:
        break;
    }
  }

  Future<void> _openExport() async {
    final l10n = AppL10n.of(context);
    final count =
        await ref.read(accountExportProvider.notifier).run(ExportFormat.json);
    if (!mounted) return;
    setState(() => _notice =
        count == null ? l10n.settingsExportFailed : null);
  }
}

enum _DeleteChoice { proceed, export }

/// Körpergewicht mit Vorschau.
class _WeightSection extends ConsumerWidget {
  const _WeightSection({
    required this.controller,
    required this.settings,
    required this.candidateKg,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final UserSettings settings;
  final double? candidateKg;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);
    final sessions = async.value ?? const [];
    final current = settings.bodyWeightKg;

    final raw = AtemNumberField.parse(controller.text);
    final typedKg = raw == null ? null : settings.unitSystem.toKilograms(raw);
    final fault = typedKg != null && !UserSettings.isPlausibleWeight(typedKg);

    final changed = candidateKg != null && candidateKg != current;

    return SettingsSection(
      title: l10n.settingsSectionProfile,
      children: [
        AtemFieldLabel(
          label: l10n.settingsBodyWeight,
          hint: l10n.settingsBodyWeightHint,
        ),
        AtemNumberField(
          controller: controller,
          semanticLabel: l10n.settingsBodyWeight,
          width: null,
          decimal: true,
          hasError: fault,
          suffix: settings.unitSystem == UnitSystem.metric
              ? l10n.unitSuffixKilograms
              : l10n.unitSuffixPounds,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
        ),
        if (fault) ...[
          const SizedBox(height: 6),
          Text(
            l10n.settingsBodyWeightFault(
              UserSettings.minBodyWeightKg.round(),
              UserSettings.maxBodyWeightKg.round(),
            ),
            style: AtemType.labelMicro
                .of(context)
                .copyWith(color: AtemColors.magenta, letterSpacing: 0),
          ),
        ],
        if (current == null && !changed) ...[
          const SizedBox(height: 8),
          Text(l10n.settingsBodyWeightNone,
              style: AtemType.labelMicro.of(context)),
        ],
        if (changed) ...[
          const SizedBox(height: 18),
          // Solange die Einheiten laden, steht der Ladezustand da — und nicht
          // eine Vorschau, die auf einer leeren Historie beruht und deshalb
          // „ändert nichts" behaupten würde.
          if (async.isLoading)
            Text(l10n.settingsPreviewComputing,
                style: AtemType.labelSmall.of(context))
          else
            Builder(builder: (context) {
              final reference = ref.watch(historyReferenceProvider);
              final preview = BodyWeightPreview.compute(
                sessions,
                reference,
                currentKg: current ?? 0,
                candidateKg: candidateKg!,
              );
              final (loadBefore, loadAfter) =
                  BodyWeightPreview.lastSessionLoad(
                sessions,
                currentKg: current ?? 0,
                candidateKg: candidateKg!,
              );
              return WeightPreview(
                preview: preview,
                loadBefore: loadBefore,
                loadAfter: loadAfter,
              );
            }),
          const SizedBox(height: 14),
          AtemButton.gradient(
            label: l10n.commonSave,
            semanticLabel: '${l10n.commonSave}: ${l10n.settingsBodyWeight}',
            size: AtemButtonSize.compact,
            busy: ref.watch(settingsControllerProvider).isLoading,
            onPressed: fault ? null : onSubmit,
          ),
        ],
      ],
    );
  }
}
