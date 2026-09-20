import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../app/application/snackbar_providers.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../history/domain/training_session.dart';
import '../../../plans/application/plan_providers.dart';
import '../../application/pending_weight_change.dart';
import '../../application/settings_providers.dart';
import '../../domain/user_settings.dart';
import '../widgets/settings_bits.dart';
import '../widgets/weight_preview.dart';
import 'account_deletion_screen.dart';
import 'export_screen.dart';
import 'info_screen.dart';

/// Einstellungen und Profil — Board 08.
///
/// ## Der Aufbau
///
/// Profilkopf als Tatsache, dann drei Sektionen — Training, App, Deine
/// Daten —, danach die Zeile „Info". Ganz unten, allein in seiner Karte:
/// Konto löschen. Position ist hier ein Statusträger.
///
/// **Rechtliches und „Über die App" liegen seit 17.09.2026 hinter „Info"**
/// ([InfoScreen]). Zusammen waren das sieben Zeilen, die man einmal im Leben
/// liest, mitten zwischen den Einstellungen, die man tatsächlich ändert. Nur
/// die Versionsnummer blieb — als Fussnote unter dem Konto-Bereich, weil sie
/// beim Melden eines Fehlers gebraucht wird.
///
/// Die rechnenden und wertetragenden Einstellungen (Körpergewicht,
/// Pausenzeit, Einheiten) sind **Zeilen mit Wert**, die ein Sheet öffnen —
/// kein Untermenü-Screen, damit der Rückweg immer dieselbe Geste ist.
/// Vorlieben (Sprache, Haptik) stehen als Segment und Schalter direkt in der
/// Karte: sofort wirksam, jederzeit zurück.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Rechtstexte und Auskünfte stehen seit 17.09.2026 auf einer eigenen
  /// Seite — hier führt nur noch der Weg dorthin.
  Future<void> _openInfo() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const InfoScreen()),
      );

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
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
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

    final span = _spanMonths(ref.read(sessionsProvider).value ?? const []);

    // **Ein Sheet mit gezählten Folgen, kein Dialog mit einem Satz**
    // (Board 08, A4/1). Stufe 1 informiert; sie fragt nicht. Ein Dialog mit
    // „Löschen" als Knopf legt die Entscheidung schon hier an, obwohl sie
    // erst in Stufe 2 fällt.
    final choice = await AtemSheet.show<_DeleteChoice>(
      context,
      title: l10n.accountDelete,
      closeLabel: l10n.commonCancel,
      child: _DeleteFacts(
        sessions: sessions,
        plans: plans,
        own: own,
        spanMonths: span,
      ),
      primaryAction: AtemButton.outline(
        label: l10n.accountDeleteContinue,
        semanticLabel: l10n.accountDeleteContinue,
        accent: AtemColors.magenta,
        onPressed: () => Navigator.of(context, rootNavigator: true)
            .pop(_DeleteChoice.proceed),
      ),
      // Der zweite Ausgang ist kein zweites Löschen, sondern die Alternative
      // dazu: erst sichern.
      secondaryAction: AtemButton.ghost(
        label: l10n.accountDeleteExport,
        semanticLabel: l10n.accountDeleteExport,
        expand: true,
        onPressed: () => Navigator.of(context, rootNavigator: true)
            .pop(_DeleteChoice.export),
      ),
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

  /// Über wie viele Monate sich der Bestand erstreckt.
  static int _spanMonths(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0;
    final first =
        sessions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    final last = sessions.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
    return (last.year - first.year) * 12 + last.month - first.month;
  }

  Future<void> _openExport() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
      );

  /// „Onboarding wiederholen": dieselbe Seite wie beim ersten Start, gepusht.
  Future<void> _repeatOnboarding(AuthUser user) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OnboardingScreen(
            user: user,
            onDone: () => Navigator.of(context).maybePop(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(settingsProvider);
    final settings = async.value ?? const UserSettings();
    final user = ref.watch(authStateProvider).value;
    final language = Localizations.localeOf(context).languageCode;

    // Solange das Paket noch nicht gelesen ist, steht ein Strich da — keine
    // erfundene Nummer.
    final version =
        ref.watch(appVersionProvider).value ?? l10n.commonNotAvailable;

    final kg = settings.bodyWeightKg;
    final weightValue = kg == null
        ? l10n.commonNotAvailable
        : '${AtemNumberField.format(context, settings.unitSystem.fromKilograms(kg))} '
            '${settings.unitSystem == UnitSystem.metric ? l10n.unitSuffixKilograms : l10n.unitSuffixPounds}';

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
            // Der Hinweis „Text nicht geladen" gehört seit 17.09.2026 auf die
            // Info-Seite: Dort wird ein Rechtstext geöffnet, dort scheitert
            // er, dort steht die Meldung.
            const SizedBox(height: 4),
            _ProfileHeader(user: user),
            const SizedBox(height: 22),

            // ---- TRAINING: drei Zeilen mit Wert, je ein Sheet.
            SettingsSection(
              title: l10n.sectionTraining,
              children: [
                SettingsRow(
                  label: l10n.weightTitle,
                  hint: l10n.weightSub,
                  value: async.isLoading ? l10n.commonLoading : weightValue,
                  onTap: () => _WeightSheet.show(context, settings),
                ),
                const SettingsRule(),
                SettingsRow(
                  label: l10n.restTitle,
                  hint: l10n.restSub,
                  value: l10n.restSeconds(settings.restSeconds),
                  valueAccent:
                      settings.restSeconds != UserSettings.defaultRestSeconds,
                  onTap: () => _RestSheet.show(context, settings),
                ),
                const SettingsRule(),
                SettingsRow(
                  label: l10n.unitsTitle,
                  value: settings.unitSystem == UnitSystem.metric
                      ? l10n.unitsMetric
                      : l10n.unitsImperial,
                  valueAccent: settings.unitSystem != UnitSystem.metric,
                  onTap: () => _UnitsSheet.show(context, settings),
                ),
                const SettingsRule(),
                // Zwei Segmente statt einer Zeile mit Blatt: Die Wahl hat
                // genau zwei Werte und wirkt sofort auf jede Anstrengung im
                // Bestand — ein Blatt mit Übernehmen liesse das Gegenteil
                // vermuten. Die Erklärung steht hinter dem ⓘ (Regel vom
                // 17.09.2026).
                AtemExplainHeader(
                  title: l10n.settingsEffortScale,
                  explanation: [l10n.settingsEffortScaleExplain],
                ),
                const SizedBox(height: 8),
                AtemSegmented<EffortScale>(
                  value: settings.effortScale,
                  groupSemanticLabel: l10n.settingsEffortScaleGroupA11y,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(effortScale: value)),
                  segments: [
                    AtemSegment(
                      value: EffortScale.rpe,
                      label: l10n.settingsEffortScaleRpe,
                      semanticLabel: l10n.settingsEffortScaleRpeA11y,
                    ),
                    AtemSegment(
                      value: EffortScale.rir,
                      label: l10n.settingsEffortScaleRir,
                      semanticLabel: l10n.settingsEffortScaleRirA11y,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Die Richtung einmal im Klartext: „hoch ist schwer" gegen
                // „niedrig ist schwer". Ohne sie wäre RIR 2 leicht mit RPE 2
                // zu verwechseln.
                Text(
                  settings.effortScale == EffortScale.rir
                      ? l10n.settingsEffortScaleValueRir
                      : l10n.settingsEffortScaleValue,
                  style: AtemType.meta
                      .of(context)
                      .copyWith(color: AtemColors.textTertiary),
                ),
                const SizedBox(height: 6),
              ],
            ),
            const SizedBox(height: 12),

            // ---- APP: Vorlieben, sofort wirksam.
            SettingsSection(
              title: l10n.sectionApp,
              children: [
                AtemFieldLabel(label: l10n.languageTitle),
                AtemSegmented<AppLanguage>(
                  // Ist noch nichts gewählt, gilt die Systemsprache — und der
                  // Haken steht da, wo die App gerade steht.
                  value: settings.language ?? AppLanguage.forSystem(language),
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
                const SizedBox(height: 14),
                const SettingsRule(),
                SettingsSwitch(
                  label: l10n.hapticsTitle,
                  hint: l10n.hapticsSub,
                  value: settings.hapticsEnabled,
                  semanticLabel: '${l10n.hapticsTitle}, '
                      '${settings.hapticsEnabled ? l10n.switchOn : l10n.switchOff}. ${l10n.hapticsSub}',
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .update(settings.copyWith(hapticsEnabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- DEINE DATEN.
            SettingsSection(
              title: l10n.sectionData,
              children: [
                SettingsRow(
                  label: l10n.exportTitle,
                  hint: l10n.exportSub,
                  onTap: _openExport,
                ),
                const SettingsRule(),
                // Steht bei den Daten, nicht bei den Vorlieben: Es zeigt die
                // vier Einführungsseiten noch einmal (Board 08, A1/2).
                SettingsRow(
                  label: l10n.onboardingRepeat,
                  hint: l10n.onboardingRepeatSub,
                  onTap: user == null ? () {} : () => _repeatOnboarding(user),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- INFO: Rechtliches und die Auskünfte über die App, eine
            // Zeile tiefer. Sieben Zeilen, die man einmal liest, standen
            // vorher zwischen den Einstellungen und dem Konto (17.09.2026).
            // Ohne Abschnittstitel: Ein Kopf „INFO" über einer Zeile „Info"
            // wäre dasselbe Wort zweimal.
            AtemCard.list(
              padding: const EdgeInsets.symmetric(
                  horizontal: AtemSpacing.cardPadding),
              child: SettingsRow(
                label: l10n.infoTitle,
                hint: l10n.infoSub,
                onTap: _openInfo,
              ),
            ),
            const SizedBox(height: 26),

            // **Eigene Karte, ganz unten.** Abmelden und Löschen stehen
            // zusammen — beides verlässt das Konto, und nur nebeneinander
            // ist sichtbar, dass das eine die Daten behält und das andere
            // nicht (Board 08, A1/2). Der zerstörende Weg steht unten.
            _AccountCard(
              onSignOut: _confirmSignOut,
              onDelete: _confirmDelete,
            ),

            // **Die Version als Fussnote.** Sie wird beim Melden eines
            // Fehlers gebraucht und sonst nie — deshalb ganz unten, gedämpft,
            // ohne Karte und ohne Abschnitt.
            const SizedBox(height: 22),
            Semantics(
              label: l10n.infoVersionLine(version),
              child: ExcludeSemantics(
                child: Text(
                  l10n.infoVersionLine(version),
                  textAlign: TextAlign.center,
                  style: AtemType.meta.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DeleteChoice { proceed, export }

/// Stufe 1 der Kontolöschung: **was genau weggeht, in Zahlen**.
///
/// „Deine Daten werden gelöscht" ist eine Behauptung. „110 Einheiten · 10
/// Pläne · 70 eigene Übungen · Zeitraum 2 J 4 M" ist eine Auskunft, an der
/// man die Entscheidung treffen kann. Darunter steht, was **bleibt** — der
/// Zugang —, weil das die häufigste stille Sorge ist.
class _DeleteFacts extends StatelessWidget {
  const _DeleteFacts({
    required this.sessions,
    required this.plans,
    required this.own,
    required this.spanMonths,
  });

  final int sessions;
  final int plans;
  final int own;
  final int spanMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final rows = <(String, String)>[
      (l10n.listTitle, '$sessions'),
      (l10n.navPlans, '$plans'),
      (l10n.exportRowExercises, '$own'),
      (l10n.accountRowProgress, l10n.exportRowDays(spanMonths * 30)),
      (l10n.accountRowProfile, '1'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.accountDeleteBody, style: AtemType.labelSmall.of(context)),
        const SizedBox(height: 14),
        AtemCard.list(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, value) in rows)
                Semantics(
                  label: '$label: $value',
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const AtemStatusDot(color: AtemColors.magenta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtemType.labelSmall.of(context)),
                          ),
                          const SizedBox(width: 10),
                          Text(value,
                              style: AtemType.valueMedium
                                  .of(context)
                                  .copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              const SettingsRule(),
              const SizedBox(height: 6),
              Semantics(
                label: '${l10n.accountDeleteRange}: '
                    '${l10n.accountDeleteSpan(spanMonths ~/ 12, spanMonths % 12)}',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.accountDeleteRange,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtemType.labelMicro.of(context)),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.accountDeleteSpan(spanMonths ~/ 12, spanMonths % 12),
                          style: AtemType.valueMedium
                              .of(context)
                              .copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AtemNotice(
          title: l10n.settingsDeletedAccessTitle,
          body: l10n.accountDeleteAccess,
          semanticLabel:
              '${l10n.settingsDeletedAccessTitle}. ${l10n.accountDeleteAccess}',
        ),
      ],
    );
  }
}

/// Körpergewicht — **die einzige Einstellung, die rückwirkend rechnet**.
///
/// Sheet mit Feld, Hinweis, Vorschau beim Tippen und „Speichern und neu
/// rechnen" (Board 08, A2). Ohne Änderung keine Vorschau und kein aktiver
/// Knopf.
class _WeightSheet extends ConsumerStatefulWidget {
  const _WeightSheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(BuildContext context, UserSettings settings) =>
      AtemSheet.show<void>(
        context,
        title: AppL10n.of(context).weightTitle,
        closeLabel: AppL10n.of(context).commonClose,
        child: _WeightSheet(settings: settings),
      );

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  final _weight = TextEditingController();
  double? _candidateKg;
  var _seeded = false;

  UserSettings get settings => widget.settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Einmal füllen — und erst hier, weil die Zahlformatierung das
    // Gebietsschema braucht, das in initState noch nicht erreichbar ist.
    if (_seeded) return;
    _seeded = true;
    final kg = settings.bodyWeightKg;
    if (kg != null) {
      _weight.text =
          AtemNumberField.format(context, settings.unitSystem.fromKilograms(kg));
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  double? _parsedKg() {
    final raw = AtemNumberField.parse(_weight.text);
    if (raw == null) return null;
    final kg = settings.unitSystem.toKilograms(raw);
    return UserSettings.isPlausibleWeight(kg) ? kg : null;
  }

  Future<void> _save() async {
    final kg = _candidateKg;
    if (kg == null || kg == settings.bodyWeightKg) return;

    final l10n = AppL10n.of(context);

    ref
        .read(pendingWeightProvider.notifier)
        .begin(previousKg: settings.bodyWeightKg, newKg: kg);
    await ref
        .read(settingsControllerProvider.notifier)
        .update(settings.copyWith(bodyWeightKg: kg));
    if (!mounted) return;

    final message = l10n.weightSavedSnack(AtemNumberField.format(context, kg));
    ref.read(snackbarProvider.notifier).show(AtemSnack(
          message: message,
          semanticLabel: message,
          tone: AtemSnackTone.success,
          actionLabel: l10n.commonUndo,
          onAction: () => ref.read(pendingWeightProvider.notifier).undo(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(sessionsProvider);
    final current = settings.bodyWeightKg;
    final raw = AtemNumberField.parse(_weight.text);
    final typedKg = raw == null ? null : settings.unitSystem.toKilograms(raw);
    final fault = typedKg != null && !UserSettings.isPlausibleWeight(typedKg);
    final changed = _candidateKg != null && _candidateKg != current;
    final busy = ref.watch(settingsControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.weightBody, style: AtemType.labelSmall.of(context)),
        const SizedBox(height: 16),
        AtemNumberField.large(
          controller: _weight,
          semanticLabel: l10n.weightTitle,
          hasError: fault,
          locked: busy,
          suffix: settings.unitSystem == UnitSystem.metric
              ? l10n.unitSuffixKilograms
              : l10n.unitSuffixPounds,
          onChanged: (_) => setState(() => _candidateKg = _parsedKg()),
        ),
        const SizedBox(height: 6),
        Text(
          fault ? l10n.weightErrorRange : l10n.weightHint,
          style: AtemType.labelSmall.of(context).copyWith(
                color: fault ? AtemColors.magenta : AtemColors.textSecondary,
              ),
        ),
        if (current != null && changed) ...[
          const SizedBox(height: 6),
          Text(l10n.weightPrevious(AtemNumberField.format(context, current)),
              style: AtemType.meta.of(context)),
        ],
        // Die Vorschau erscheint erst bei Abweichung — der leere Platz
        // darunter ist Absicht, er füllt sich beim Tippen.
        if (changed && !fault) ...[
          const SizedBox(height: 18),
          if (async.isLoading)
            Text(l10n.weightSaveBusy, style: AtemType.labelSmall.of(context))
          else
            WeightPreview(
              sessions: async.value ?? const [],
              reference: ref.watch(historyReferenceProvider),
              currentKg: current ?? 0,
              candidateKg: _candidateKg!,
            ),
        ],
        const SizedBox(height: 18),
        AtemButton.gradient(
          label: changed
              ? (busy ? l10n.weightSaveBusy : l10n.weightSave)
              : l10n.weightSaveNone,
          semanticLabel: changed ? l10n.weightSave : l10n.weightSaveNone,
          busy: busy,
          onPressed: fault || !changed || busy ? null : _save,
        ),
      ],
    );
  }
}

/// Pausenzeit — fünf Werte im Segment, der fünfte ist eigen (Board 08, A3/1).
class _RestSheet extends ConsumerStatefulWidget {
  const _RestSheet({required this.settings});

  final UserSettings settings;

  /// Board 08, A3/1: fünf Stufen, dazu ein eigener Wert. 45 s fehlte —
  /// es ist die übliche Pause für Kraftausdauer.
  static const presets = [45, 60, 90, 120, 180];

  static Future<void> show(BuildContext context, UserSettings settings) =>
      AtemSheet.show<void>(
        context,
        title: AppL10n.of(context).restTitle,
        closeLabel: AppL10n.of(context).commonClose,
        child: _RestSheet(settings: settings),
      );

  @override
  ConsumerState<_RestSheet> createState() => _RestSheetState();
}

class _RestSheetState extends ConsumerState<_RestSheet> {
  late final TextEditingController _custom;
  late int _value;
  late bool _customMode;

  @override
  void initState() {
    super.initState();
    _value = widget.settings.restSeconds;
    _customMode = !_RestSheet.presets.contains(_value);
    _custom = TextEditingController(text: _customMode ? '$_value' : '');
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _apply(int seconds) async {
    final clamped = seconds.clamp(
        UserSettings.minRestSeconds, UserSettings.maxRestSeconds);
    setState(() => _value = clamped);
    await ref
        .read(settingsControllerProvider.notifier)
        .update(widget.settings.copyWith(restSeconds: clamped));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.restBody, style: AtemType.labelSmall.of(context)),
        const SizedBox(height: 16),
        AtemSegmented<int>(
          value: _customMode ? -1 : _value,
          groupSemanticLabel: l10n.restTitle,
          onChanged: (v) {
            if (v == -1) {
              setState(() => _customMode = true);
              return;
            }
            setState(() => _customMode = false);
            _apply(v);
          },
          segments: [
            for (final p in _RestSheet.presets)
              AtemSegment(
                value: p,
                label: l10n.restSeconds(p),
                semanticLabel: '${l10n.restTitle} ${l10n.restSeconds(p)}',
              ),
            AtemSegment(
              value: -1,
              label: l10n.restCustom,
              semanticLabel: l10n.restCustom,
            ),
          ],
        ),
        if (_customMode) ...[
          const SizedBox(height: 14),
          AtemNumberField(
            controller: _custom,
            semanticLabel: l10n.restCustom,
            width: null,
            suffix: l10n.unitSuffixSeconds,
            textInputAction: TextInputAction.done,
            onChanged: (t) {
              final v = int.tryParse(t.trim());
              if (v != null) _apply(v);
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${UserSettings.minRestSeconds}–${UserSettings.maxRestSeconds} ${l10n.unitSuffixSeconds}',
            style: AtemType.labelMicro.of(context),
          ),
        ],
        const SizedBox(height: 14),
        AtemNotice(
          title: l10n.restRunning,
          body: l10n.restSub,
          semanticLabel: '${l10n.restRunning} ${l10n.restSub}',
        ),
      ],
    );
  }
}

/// Einheitensystem — nur Anzeige, deshalb ein Beispiel statt einer
/// Vorschau (Board 08, A3/2).
class _UnitsSheet extends ConsumerWidget {
  const _UnitsSheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(BuildContext context, UserSettings settings) =>
      AtemSheet.show<void>(
        context,
        title: AppL10n.of(context).unitsTitle,
        closeLabel: AppL10n.of(context).commonClose,
        child: _UnitsSheet(settings: settings),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final live = ref.watch(settingsProvider).value ?? settings;
    final imperial = live.unitSystem == UnitSystem.imperial;

    String kg(double v) => l10n.unitKilograms(
        AtemNumberField.format(context, v).replaceAll('.0', ''));
    String lb(double v) =>
        '${AtemNumberField.format(context, (v * 2.20462 * 10).round() / 10)} ${l10n.unitSuffixPounds}';

    final rows = <(String, String)>[
      (l10n.workoutLoggingSets, imperial ? lb(82.5) : kg(82.5)),
      (l10n.detailLoad, imperial ? lb(4820) : kg(4820)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.unitsNote, style: AtemType.labelSmall.of(context)),
        const SizedBox(height: 16),
        AtemSegmented<UnitSystem>(
          value: live.unitSystem,
          groupSemanticLabel: l10n.unitsTitle,
          onChanged: (value) => ref
              .read(settingsControllerProvider.notifier)
              .update(live.copyWith(unitSystem: value)),
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
        const SizedBox(height: 18),
        Text(l10n.unitsExample.toUpperCase(),
            style: AtemType.labelMicro.of(context)),
        const SizedBox(height: 8),
        AtemStatBox(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              for (final (label, value) in rows)
                Semantics(
                  label: '$label: $value',
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(label,
                                style: AtemType.labelSmall.of(context)),
                          ),
                          Text(value,
                              style: AtemType.valueMedium
                                  .of(context)
                                  .copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Der Profilkopf — **eine Tatsache, kein Formular** (Board 08, A1/1).
///
/// Bild 52 dp mit Initialen auf dem Violet-Rose-Verlauf, Name, E-Mail in
/// Mono mit Ellipse, Schloss-Chip „Über Google · fest". Ein Knoten für
/// TalkBack: kein textField, kein disabled — ein deaktiviertes Feld liest
/// sich als Defekt.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final email = user?.email ?? l10n.commonNotAvailable;
    final name = user?.displayName ?? '';
    final initials = name.trim().isEmpty
        ? (email.isNotEmpty ? email[0].toUpperCase() : '?')
        : name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join()
            .toUpperCase();

    return Semantics(
      label: '$name $email. ${l10n.profileLocked}. ${l10n.profileLockedWhy}',
      child: ExcludeSemantics(
        child: AtemCard.list(
          padding: const EdgeInsets.all(AtemSpacing.cardPadding),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // Violet nur als Fläche — hier der Verlauf des Profilbilds.
                  gradient: LinearGradient(
                    colors: [AtemColors.violet, AtemColors.magentaDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  initials,
                  style: AtemType.valueMedium.of(context).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AtemColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (name.isNotEmpty)
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.titleSmallOrDefault(context)
                              .copyWith(fontWeight: FontWeight.w700)),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.meta.of(context)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AtemColors.surfaceSolid,
                        borderRadius: BorderRadius.circular(AtemRadii.pill),
                        border: Border.all(color: AtemColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 12, color: AtemColors.textSecondary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              l10n.profileLocked,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtemType.labelDeco.of(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der einzige Weg, der Jahre vernichtet — **für sich, ganz unten**.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onSignOut, required this.onDelete});

  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding:
          const EdgeInsets.symmetric(horizontal: AtemSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // „Daten bleiben", damit Abmelden und Löschen nie verwechselt
          // werden (Board 08, A1/2).
          SettingsRow(
            label: l10n.settingsSignOut,
            value: l10n.signoutKeep,
            quiet: true,
            onTap: onSignOut,
          ),
          const SettingsRule(),
          _DangerRow(onTap: onDelete),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemTappable(
      onTap: onTap,
      semanticLabel: '${l10n.accountDelete}. ${l10n.accountDeleteSub}',
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                      style: AtemType.labelSmall.of(context)),
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
