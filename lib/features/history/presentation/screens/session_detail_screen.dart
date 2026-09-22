import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../pulse/application/pulse_providers.dart';
import '../../../cardio/domain/cardio_intensity.dart';
import '../../../cardio/presentation/widgets/intensity_box.dart';
import '../../../health_import/application/health_import_providers.dart';
import '../../../health_import/domain/health_session.dart';
import '../../../health_import/presentation/widgets/source_capsule.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/screens/plan_form_screen.dart';
import '../../../workout/domain/workout_start.dart';
import '../../../workout/presentation/screens/workout_runner_screen.dart';
import '../../application/history_providers.dart';
import '../../domain/readiness.dart';
import '../../domain/session_detail.dart';
import '../../domain/training_load.dart';
import '../../domain/training_session.dart';
import '../detail/detail_blocks.dart';
import '../detail/detail_header.dart';
import '../detail/detail_providers.dart';
import '../detail/detail_text.dart';
import '../detail/pulse_block.dart';
import '../session_actions.dart';
import '../widgets/acwr_scale.dart';
import '../widgets/percentile_card.dart';
import 'session_edit_screen.dart';

/// Detail einer Einheit — **ein Kopf, ein Rückgrat, so viele Blöcke wie Daten**
/// (Board 16).
///
/// ## Der Satz, an dem alles gemessen wird
///
/// Die Art einer Einheit wählt nie das Layout — sie füllt nur einen Katalog von
/// Grössen und eine feste Reihe von Blockplätzen. Oben steht genau eine Zahl,
/// die sagt, was das war; jede weitere Zahl nennt ihre Grundlage; und was
/// keine Daten hat, ist nicht leer, sondern nicht da.
///
/// ## Sechs Plätze, immer in dieser Reihenfolge
///
/// Kopf · Kennzahlen · Arbeit · Puls & Zonen · Notiz · Herkunft und Eingriffe.
/// Sortiert nach Blickrichtung: was war · wie viel · was genau · wie hat der
/// Körper reagiert · wie hat es sich angefühlt · woher weiss die App das. Eine
/// Art füllt Plätze, sie sortiert nicht um und fügt keinen siebten hinzu.
/// Laufen, Radfahren und Schwimmen sind keine neuen Bildschirme, sondern neue
/// Einträge im Grössenkatalog und andere Zeilen in derselben Listenanatomie.
///
/// ## Was hier nicht mehr steht
///
/// Der Vergleichsblock mit Dauer, Last, Volumen und Sätzen im Kopf ist weg:
/// Ein Delta neben der Leitzahl wäre ein zweiter Blickfang und stellte eine
/// Einheit gegen eine willkürliche Vorgängerin (Entscheidung 19). Vergleichen
/// tut jetzt die Übungszeile — gegen dieselbe Übung, mit genanntem Datum.
///
/// ## Was **hinter** den sechs Plätzen bleibt
///
/// Die Einordnungen aus den Boards 06, 09 und 11 — Belastung an diesem Tag,
/// Perzentil, Beitrag zur Form — hat Board 16 nicht neu gefasst. Sie stehen
/// unverändert zwischen Notiz und Herkunft und sind **eine offene
/// Entscheidung**, kein Bestandteil des Rückgrats.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(sessionsProvider).value ?? const [];

    // **Die lebende Einheit, nicht die übergebene.** Nach „Verbindung lösen"
    // oder einer Zusammenführung ändert sich die Einheit im Bestand; die, die
    // beim Öffnen übergeben wurde, bliebe auf dem alten Stand stehen.
    final live =
        sessions.where((s) => s.id == session.id).firstOrNull ?? session;

    final loadContext = ref.watch(loadContextProvider);
    final load = TrainingLoad.of(live, loadContext);
    final watch = ref.watch(watchFiguresProvider(live));

    final lead = SessionDetail.leadOf(live);
    final tiles = SessionDetail.tilesOf(live, watch: watch.value, load: load);
    final text = DetailHeaderText.of(context, live, lead: lead);
    final rows = SessionDetail.exercisesOf(live, sessions);

    // Ein Block ohne Daten rendert nicht: Was nicht da ist, fehlt.
    final hasPulseBlock = watch.isLoading ||
        watch.hasError ||
        (watch.value?.pulse != null && !watch.value!.pulse!.isEmpty);

    // **Eine Einordnung braucht etwas, das einzuordnen ist.** Ohne Last —
    // Regeneration, eine Krafteinheit ohne Angaben — gibt es nichts, was die
    // Belastung dieses Tages einordnen könnte, und der Bildschirm hört
    // dort auf, wo seine Daten aufhören (Board 16, A3 und A4).
    final acwr = load > 0
        ? Readiness.compute(sessions, live.date, context: loadContext)
        : null;

    var index = 0;
    Widget block(Widget child) => AtemEntrance(index: index++, child: child);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            const _BackRow(),
            block(DetailHeader(session: live, text: text)),

            // ---- 2 · Kennzahlen -----------------------------------------
            // Solange die Uhr antwortet, stehen die Kacheln im Skelett: vier,
            // auch wenn am Ende zwei kommen — die Höhe ist reserviert, damit
            // nichts springt.
            if (tiles.isNotEmpty || watch.isLoading) ...[
              const SizedBox(height: 16),
              block(Semantics(
                liveRegion: watch.isLoading,
                label: watch.isLoading ? l10n.detailLoadingA11y : null,
                child: MetricTiles(tiles: tiles, loading: watch.isLoading),
              )),
            ],

            // ---- 3 · Arbeit ---------------------------------------------
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              block(WorkBlock(
                rows: rows,
                setCount: SessionDetail.setCount(live),
              )),
            ],

            // ---- 4 · Puls & Zonen ---------------------------------------
            if (hasPulseBlock) ...[
              const SizedBox(height: 12),
              block(PulseZonesBlock(watch: watch)),
            ],

            // ---- 5 · Notiz ----------------------------------------------
            if (live.notes case final notes? when notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              block(NoteBlock(text: notes)),
            ],

            // ---- Einordnungen aus den Boards 06, 09 und 11 ---------------
            ..._placements(context, ref, l10n, live, sessions, acwr?.acwr,
                load: load, hasWatchPulse: hasPulseBlock),

            // ---- 6 · Herkunft und Eingriffe -----------------------------
            const SizedBox(height: 24),
            block(SourceCapsule(
              session: live,
              onlyKindAndDay: lead == null && rows.isEmpty,
            )),
            const SizedBox(height: 10),
            ..._interventions(context, ref, l10n, live),
          ],
        ),
      ),
    );
  }

  /// Die Einordnungen, die Board 16 nicht neu gefasst hat.
  List<Widget> _placements(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    TrainingSession live,
    List<TrainingSession> sessions,
    double? acwr, {
    required double load,
    required bool hasWatchPulse,
  }) {
    final intensity = live is CardioSession && !hasWatchPulse && load > 0
        ? CardioIntensity.of(live, sessions,
            zones: ref.watch(heartRateZonesProvider))
        : null;

    return [
      // „Belastung an diesem Tag" — die ACWR-Skala aus Board 06 mit Zone als
      // Wort, nicht nur als Segmentposition.
      if (acwr != null) ...[
        const SizedBox(height: 12),
        AtemCard.list(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.detailAcwrLabel.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 10),
              AcwrScale(acwr: acwr),
            ],
          ),
        ),
      ],
      if (live case final CardioSession cardio) ...[
        // **Der Intensitätskasten weicht dem Pulsblock.** Er teilt den Puls in
        // Zonen nach festen Prozenten von HFmax und nennt sie „schwellig" —
        // ein Urteil und ein zweites Zonensystem neben den eigenen fünf. Wo
        // eine Uhr den Verlauf liefert, gilt dieser; der Kasten bleibt für
        // Einheiten, deren Puls von Hand eingetragen wurde.
        if (intensity != null) ...[
          const SizedBox(height: 12),
          IntensityBox(
            intensity: intensity,
            isRun: cardio.activity == CardioActivity.run,
          ),
        ],
        if (load > 0 && cardio.distanceKm != null) ...[
          const SizedBox(height: 12),
          PercentileCard(session: cardio, sessions: sessions),
        ],
      ],
    ];
  }

  /// Die Eingriffe — **ganz unten**, hinter allem, was die Einheit aussagt.
  /// Wer den Bildschirm öffnet, will in aller Regel nachsehen, nicht ändern.
  List<Widget> _interventions(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    TrainingSession live,
  ) {
    HealthSession? measured;
    final linked = live.healthSessionId;
    if (linked != null) {
      for (final s in ref.watch(healthSessionsProvider).value ?? const []) {
        if (s.externalId == linked) measured = s;
      }
    }

    Future<void> edit() => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionEditScreen(session: live),
          ),
        );

    return [
      // **Die Anstrengung kann eine Uhr nicht messen.** An einer Einheit aus
      // der Uhr steht der Weg, sie nachzutragen — als Weg, nicht als Mahnung.
      if (live.origin == SessionOrigin.watch && live.rpe == null) ...[
        _ActionRow(label: l10n.detailAddEffort, onTap: edit),
        const SizedBox(height: 8),
      ],
      _ActionRow(label: l10n.detailEdit, onTap: edit),
      // Der Weg, Sätze an eine bestehende Einheit zu hängen, bleibt — als
      // Zeile unter den Eingriffen, **nicht als Aufruf**. Board 16 (A4) zeigt
      // hier nur Bearbeiten und Löschen; ohne diese Zeile gäbe es aber keinen
      // Weg mehr, eine Einheit ohne Sätze zu ergänzen. Offen für dich.
      if (live case StrengthSession(hasExerciseData: false)) ...[
        const SizedBox(height: 8),
        _ActionRow(
          label: l10n.setsAdd,
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(
            WorkoutRunnerScreen.routeName,
            arguments: WorkoutLaunch(WorkoutStart.session(live.id)),
          ),
        ),
      ],
      if (live case StrengthSession(hasExerciseData: true)) ...[
        const SizedBox(height: 8),
        // **Aus einer Einheit einen Plan machen.** Wer etwas zusammengestellt
        // hat, das gut war, will es wiederholen — und hat die Zusammenstellung
        // hier vor sich.
        _ActionRow(
          label: l10n.detailSaveAsPlan,
          onTap: () => _saveAsPlan(context, ref, l10n, live),
        ),
      ],
      if (live.origin == SessionOrigin.merged && measured != null) ...[
        const SizedBox(height: 8),
        UnlinkRow(session: live, measured: measured),
      ],
      const SizedBox(height: 8),
      _ActionRow(
        label: l10n.detailDelete,
        danger: true,
        onTap: () async {
          final deleted = await confirmDeleteSession(context, ref, live);
          // Zurück zur Liste: Ein Detail zu einer Einheit, die gerade
          // verschwunden ist, wäre ein Bildschirm über nichts.
          if (deleted && context.mounted) Navigator.of(context).pop();
        },
      ),
    ];
  }

  /// Legt aus dieser Einheit einen Plan an.
  ///
  /// Die Zielwerte kommen aus dem, was tatsächlich gemacht wurde: Anzahl der
  /// Sätze je Übung, und die Wiederholungen des ersten Satzes als Vorgabe.
  /// **Kein Mittelwert über die Sätze** — ein Plan sagt, was man vorhat, und
  /// die erste Zahl ist die, die man sich vorgenommen hatte.
  ///
  /// Der Plan wird nicht sofort geschrieben, sondern im Planbuilder geöffnet:
  /// Ein Name fehlt noch, und die Reihenfolge will vielleicht angepasst
  /// werden. Ein still angelegter Plan namens „Krafttraining" wäre ein
  /// Eintrag, den niemand bestellt hat.
  Future<void> _saveAsPlan(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
    TrainingSession session,
  ) async {
    if (session is! StrengthSession) return;
    final strength = session;

    final draft = Plan(
      id: '',
      name: strength.planName ?? '',
      items: [
        for (final exercise in strength.exercises)
          if (exercise.sets.any((s) => !s.isEmpty))
            PlanItem(
              exerciseId: exercise.exerciseId,
              sets: exercise.sets.where((s) => !s.isEmpty).length,
              reps:
                  exercise.sets.firstWhere((s) => !s.isEmpty).reps?.toString(),
            ),
      ],
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanFormScreen(original: draft, isCopy: true),
      ),
    );
  }
}

/// „‹ VERLAUF" — die Rückweg-Zeile, 48 × 96 dp.
class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: AtemTappable(
        onTap: () => Navigator.of(context).maybePop(),
        semanticLabel: l10n.detailBackA11y,
        minTapSize: const Size(96, 48),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left, size: 20, color: AtemColors.cyan),
            const SizedBox(width: 2),
            Text(
              l10n.detailBack.toUpperCase(),
              style: AtemType.labelMicro
                  .of(context)
                  .copyWith(color: AtemColors.cyan),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Eingriffszeile: 48 dp, Rand, Chevron. „Löschen" in Magenta — Magenta
/// ist Eingriff und Störung, nie ein Wert.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AtemColors.magenta : AtemColors.textTertiary;
    return AtemTappable(
      onTap: onTap,
      semanticLabel: label,
      minTapSize: const Size(0, 48),
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: danger
                ? AtemColors.magenta.withValues(alpha: 0.4)
                : AtemColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style:
                      AtemType.labelSmall.of(context).copyWith(color: color)),
            ),
            Icon(Icons.chevron_right,
                size: 20,
                color: danger ? AtemColors.magenta : AtemColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
