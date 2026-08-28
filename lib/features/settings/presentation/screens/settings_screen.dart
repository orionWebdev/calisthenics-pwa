import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/auth_user.dart';
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

    final l10n = AppL10n.of(context);
    final sessions = ref.read(sessionsProvider).value ?? const [];
    final preview = BodyWeightPreview.compute(
      sessions,
      ref.read(historyReferenceProvider),
      currentKg: settings.bodyWeightKg ?? 0,
      candidateKg: kg,
    );

    ref
        .read(pendingWeightProvider.notifier)
        .begin(previousKg: settings.bodyWeightKg, newKg: kg);

    await ref
        .read(settingsControllerProvider.notifier)
        .update(settings.copyWith(bodyWeightKg: kg));

    if (!mounted) return;
    // Die Vorschau ist damit erfüllt: Was sie angekündigt hat, steht jetzt in
    // der App. Sie verschwindet, die Meldung tritt an ihre Stelle — und nennt
    // die Folge, nicht nur die Tat.
    setState(() => _candidateKg = null);

    final message = l10n.weightSavedSnack(
      AtemNumberField.format(context, kg),
      preview.formBefore?.toString() ?? l10n.commonNotAvailable,
      preview.formAfter?.toString() ?? l10n.commonNotAvailable,
    );
    ref.read(snackbarProvider.notifier).show(
          AtemSnack(
            message: message,
            semanticLabel: message,
            tone: AtemSnackTone.success,
            actionLabel: l10n.commonUndo,
            onAction: () =>
                ref.read(pendingWeightProvider.notifier).undo(),
          ),
        );
  }

  Future<void> _open(Uri url) async {
    final l10n = AppL10n.of(context);
    final opened =
        await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) setState(() => _notice = l10n.legalError);
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
            _ProfileHeader(user: user),
            const SizedBox(height: 22),
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
              title: l10n.sectionApp,
              children: [
                // Pausenzeit und Einheitensystem stehen im Board auf einem
                // Artboard — beide wirken auf die Anzeige, keines auf die
                // Bewertung.
                AtemFieldLabel(label: l10n.restTitle, hint: l10n.restBody),
                AtemNumberField(
                  controller: _rest,
                  semanticLabel: l10n.restTitle,
                  width: null,
                  suffix: l10n.unitSuffixSeconds,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                Text(l10n.restRunning,
                    style: AtemType.labelMicro.of(context)),
                const SizedBox(height: 10),
                AtemButton.outline(
                  label: l10n.commonSave,
                  semanticLabel: '${l10n.commonSave}: ${l10n.restTitle}',
                  onPressed: () => _saveRest(settings),
                ),
                const SizedBox(height: 22),
                AtemFieldLabel(
                  label: l10n.unitsTitle,
                  hint: l10n.unitsNote,
                ),
                AtemSegmented<UnitSystem>(
                  value: settings.unitSystem,
                  groupSemanticLabel: l10n.unitsTitle,
                  onChanged: (value) => _saveUnits(settings, value),
                  segments: [
                    AtemSegment(
                      value: UnitSystem.metric,
                      label: l10n.unitsMetric,
                      semanticLabel: l10n.unitsMetric,
                    ),
                    AtemSegment(
                      value: UnitSystem.imperial,
                      label: l10n.unitsImperial,
                      semanticLabel: l10n.unitsImperial,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AtemFieldLabel(label: l10n.languageTitle),
                AtemSegmented<AppLanguage>(
                  // Ist noch nichts gewählt, gilt die Systemsprache — und der
                  // Haken steht da, wo die App gerade steht.
                  value: settings.language ??
                      AppLanguage.forSystem(
                          Localizations.localeOf(context).languageCode),
                  groupSemanticLabel: l10n.languageTitle,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(language: value)),
                  segments: [
                    AtemSegment(
                      value: AppLanguage.german,
                      label: l10n.languageDe,
                      semanticLabel: l10n.languageDe,
                    ),
                    AtemSegment(
                      value: AppLanguage.english,
                      label: l10n.languageEn,
                      semanticLabel: l10n.languageEn,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SettingsSwitch(
                  label: l10n.hapticsTitle,
                  hint: l10n.hapticsSub,
                  value: settings.hapticsEnabled,
                  semanticLabel: '${l10n.hapticsTitle}, '
                      '${settings.hapticsEnabled ? l10n.switchOn : l10n.switchOff}',
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(hapticsEnabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.sectionData,
              children: [
                SettingsRow(
                  label: l10n.exportTitle,
                  hint: l10n.exportBody,
                  onTap: _openExport,
                ),
                SettingsRow(
                  label: l10n.settingsSignOut,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
            const SizedBox(height: 26),
            // **Eigene Karte, unten.** Board 08, Zustand „gefährlich": Der
            // einzige Weg, der Jahre vernichtet, steht nicht zwischen
            // Abmelden und Datenausgabe, sondern für sich.
            _DangerCard(onTap: _confirmDelete),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.sectionLegal,
              children: [
                SettingsRow(
                  label: l10n.legalPrivacy,
                  hint: l10n.legalExternal,
                  onTap: () => _open(LegalLinks.privacy(
                      Localizations.localeOf(context).languageCode)),
                ),
                SettingsRow(
                  label: l10n.legalTerms,
                  hint: l10n.legalExternal,
                  onTap: () => _open(LegalLinks.terms(
                      Localizations.localeOf(context).languageCode)),
                ),
                SettingsRow(
                  label: l10n.legalImprint,
                  hint: l10n.legalExternal,
                  onTap: () => _open(LegalLinks.imprint),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SettingsSection(
              title: l10n.sectionAbout,
              children: [
                _AboutRow(label: l10n.aboutVersionLabel, value: _version),
                // Die Zeile steht dort, wo in der Vorgänger-App ein
                // Themenschalter war. Für ATEM existiert keine helle Palette;
                // ein Schalter, der nichts tut, wäre schlimmer als keiner —
                // eine Auskunft dagegen beantwortet die Frage.
                _AboutRow(
                  label: l10n.aboutDisplayLabel,
                  value: l10n.aboutDisplayValue,
                ),
                _AboutRow(
                  label: l10n.aboutLanguagesLabel,
                  value: l10n.aboutLanguagesValue,
                ),
                _AboutRow(
                  label: l10n.aboutAccessLabel,
                  value: l10n.aboutAccessValue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _version = '1.0.0';

  /// Nur noch Fehlermeldungen — der Widerruf liegt seit Modul 7 in der
  /// Hülle, wo er den Bildschirmwechsel überlebt.
  AtemNotice? _slotNotice(AppL10n l10n) {
    if (_notice case final text?) {
      return AtemNotice(
        tone: AtemNoticeTone.error,
        title: text,
        body: l10n.legalExternal,
        semanticLabel: '$text. ${l10n.legalExternal}',
      );
    }
    return null;
  }



  Future<void> _saveRest(UserSettings settings) async {
    final value = int.tryParse(_rest.text.trim());
    if (value == null) return;
    await ref.read(settingsControllerProvider.notifier).update(
          settings.copyWith(
            restSeconds: value.clamp(
              UserSettings.minRestSeconds,
              UserSettings.maxRestSeconds,
            ),
          ),
        );
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
      title: l10n.sectionTraining,
      children: [
        AtemFieldLabel(label: l10n.weightTitle, hint: l10n.weightBody),
        AtemNumberField(
          controller: controller,
          semanticLabel: l10n.weightTitle,
          width: null,
          decimal: true,
          hasError: fault,
          suffix: settings.unitSystem == UnitSystem.metric
              ? l10n.unitSuffixKilograms
              : l10n.unitSuffixPounds,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 6),
        Text(
          fault ? l10n.weightErrorRange : l10n.weightHint,
          style: AtemType.labelMicro.of(context).copyWith(
                letterSpacing: 0,
                color: fault ? AtemColors.magenta : AtemColors.textSecondary,
              ),
        ),
        if (current != null && changed) ...[
          const SizedBox(height: 6),
          Text(
            l10n.weightPrevious(AtemNumberField.format(context, current)),
            style: AtemType.labelMicro.of(context),
          ),
        ],
        if (changed && !fault) ...[
          const SizedBox(height: 18),
          if (async.isLoading)
            Text(l10n.weightSaveBusy,
                style: AtemType.labelSmall.of(context))
          else
            WeightPreview(
              sessions: sessions,
              reference: ref.watch(historyReferenceProvider),
              currentKg: current ?? 0,
              candidateKg: candidateKg!,
            ),
        ],
        const SizedBox(height: 14),
        AtemButton.gradient(
          label: changed
              ? (ref.watch(settingsControllerProvider).isLoading
                  ? l10n.weightSaveBusy
                  : l10n.weightSave)
              : l10n.weightSaveNone,
          semanticLabel: changed ? l10n.weightSave : l10n.weightSaveNone,
          size: AtemButtonSize.compact,
          busy: ref.watch(settingsControllerProvider).isLoading,
          onPressed: fault || !changed ? null : onSubmit,
        ),
      ],
    );
  }
}

/// Der Profilkopf — **eine Tatsache, kein Formular**.
///
/// Board 08, Entscheidung: Name und E-Mail kommen von Google und sind hier
/// nicht änderbar. Ein gesperrtes Eingabefeld sähe aus wie ein Defekt; ein
/// Chip mit „Über Google · fest" sagt dasselbe als Auskunft.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final email = user?.email ?? l10n.commonNotAvailable;

    return Semantics(
      label: '${user?.displayName ?? ''} $email. ${l10n.profileLockedWhy}',
      child: ExcludeSemantics(
        child: AtemCard.list(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.displayName case final name? when name.isNotEmpty) ...[
                Text(name, style: AtemType.titleMedium.of(context)),
                const SizedBox(height: 4),
              ],
              Text(email, style: AtemType.body.of(context)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AtemRadii.pill),
                  border: Border.all(color: AtemColors.border),
                ),
                // Nachgiebig: „Über Google · fest" ist bei 320 dp länger als
                // der Platz, den die Karte dem Chip lässt — die Prüfmatrix
                // hat 38 px Überlauf gefunden, schon bei einfacher Schrift.
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 13, color: AtemColors.textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.profileLocked,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.labelMicro.of(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.profileLockedWhy,
                  style: AtemType.labelMicro.of(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der einzige Weg, der Jahre vernichtet — **für sich, ganz unten**.
class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: '${l10n.accountDelete}. ${l10n.accountDeleteSub}',
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: BorderRadius.circular(AtemRadii.card),
          border: Border.all(color: AtemColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.accountDelete,
                    style: AtemType.body
                        .of(context)
                        .copyWith(color: AtemColors.magenta),
                  ),
                  const SizedBox(height: 3),
                  Text(l10n.accountDeleteSub,
                      style: AtemType.labelMicro.of(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AtemColors.magenta),
          ],
        ),
      ),
    );
  }
}

/// Eine Auskunftszeile im Abschnitt „Über die App".
///
/// Beschriftung links, Wert rechts in Mono — kein Weg dahinter. Was hier
/// steht, beantwortet eine Frage, statt eine Einstellung anzubieten.
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label,
                      style: AtemType.labelSmall.of(context)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
