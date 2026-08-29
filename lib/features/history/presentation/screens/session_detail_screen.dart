import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/history_providers.dart';
import '../../domain/readiness.dart';
import '../../domain/training_load.dart';
import '../../domain/training_session.dart';
import '../../domain/session_comparison.dart';
import '../../../plans/domain/plan.dart';
import '../../../plans/presentation/screens/plan_form_screen.dart';
import '../session_actions.dart';
import '../../../cardio/application/cardio_providers.dart';
import '../../../cardio/domain/cardio_intensity.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../../cardio/presentation/widgets/intensity_box.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../widgets/acwr_scale.dart';
import '../widgets/comparison_card.dart';
import '../widgets/percentile_card.dart';
import '../session_ui.dart';
import '../../../workout/domain/workout_start.dart';
import '../../../workout/presentation/screens/workout_runner_screen.dart';
import 'session_edit_screen.dart';

/// Detail einer Einheit — **vier Datenlagen, ein Layout**.
///
/// Der Bestand ist ungleich: 57 von 73 Krafteinheiten tragen Sätze, 16 nicht.
/// Cardio hat Strecke und Pace statt Volumen, Regeneration gar keine Kennzahl.
///
/// Wie im Übungsdetail gilt: **Ein Block rendert nur mit Daten.** Was fehlt,
/// existiert nicht — außer es gibt etwas zu erklären. Genau zwei Erklärungen
/// sind vorgesehen, und beide sagen dem Nutzer, dass seine Einheit trotzdem
/// zählt.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final weight = ref.watch(bodyWeightProvider).value ?? 0;
    final context_ = LoadContext(bodyWeightKg: weight);

    final load = TrainingLoad.of(session, context_);
    final sessions = ref.watch(sessionsProvider).value ?? const [];

    // Der ACWR **an diesem Tag**, nicht heute. Eine Einheit im April soll
    // zeigen, was sie damals bedeutet hat.
    final acwr = Readiness.compute(sessions, session.date, context: context_);

    final minutes = session.duration?.inMinutes;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        // Das Datum steht in der Leiste (Board 06, A3): „SA 05.07.2026".
        title: Text(
          DateFormat.yMEd(tag).format(session.date).toUpperCase(),
          style: AtemType.labelMicro.of(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            Semantics(
              header: true,
              label:
                  '${sessionName(l10n, session)}. ${DateFormat.yMMMMEEEEd(tag).format(session.date)}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionName(l10n, session),
                        style: AtemType.titleLarge.of(context)),
                    const SizedBox(height: 6),
                    Text(
                      (minutes == null
                              ? sessionKindLabel(l10n, session)
                              : l10n.detailSubtitle(
                                  sessionKindLabel(l10n, session), minutes))
                          .toUpperCase(),
                      style: AtemType.labelMicro.of(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _Stats(session: session, load: load),

            // **Der Vergleich steht direkt unter den Absolutwerten.** „412"
            // allein sagt niemandem etwas; „412, vorher 380" sagt alles —
            // und beides nebeneinander zu lesen ist der ganze Zweck.
            const SizedBox(height: 22),
            ComparisonCard(
              comparison: SessionComparison.forSession(
                session,
                sessions,
                context: context_,
              ),
              languageTag: tag,
            ),
            // „Belastung an diesem Tag" — die ACWR-Skala aus Board 06 mit
            // Zone als Wort, nicht nur als Segmentposition.
            if (acwr.acwr case final value?) ...[
              const SizedBox(height: 22),
              AtemCard.list(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.detailAcwrLabel.toUpperCase(),
                        style: AtemType.labelMicro.of(context)),
                    const SizedBox(height: 10),
                    AcwrScale(acwr: value),
                  ],
                ),
              ),
            ],
            // Für Cardio: wo diese Einheit im eigenen Bestand steht. Der
            // Vergleichsblock darüber misst Dauer und Last; hier geht es um
            // Strecke und Pace, die nur untereinander vergleichbar sind.
            if (session case final CardioSession cardio) ...[
              // Der Intensitätskasten steht an der Stelle der Übungsliste
              // (Board 11, Entscheidung „Cardio-Detail als eigener
              // Bildschirm-Typ": dasselbe Detail, andere Wertezeilen).
              if (CardioIntensity.of(cardio, sessions,
                      profileMaxHr: ref.watch(profileMaxHrProvider))
                  case final intensity?) ...[
                const SizedBox(height: 20),
                IntensityBox(
                  intensity: intensity,
                  isRun: cardio.activity == CardioActivity.run,
                ),
              ],
              const SizedBox(height: 20),
              PercentileCard(session: cardio, sessions: sessions),
            ],

            ..._exercises(context, l10n),
            ..._explanations(context, l10n, sessions),
            const SizedBox(height: 24),
            // **Der Weg zur Notiz steht auch dann da, wenn keine da ist.**
            // Vorher erschien der Text nur, wenn schon eine Notiz existierte
            // — es gab also keinen Weg, die erste zu schreiben.
            if (session.notes case final notes? when notes.trim().isNotEmpty)
              AtemCard.list(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.commonNotes.toUpperCase(),
                        style: AtemType.labelMicro.of(context)),
                    const SizedBox(height: 6),
                    Text(notes, style: AtemType.body.of(context)),
                  ],
                ),
              )
            else
              AtemButton.ghost(
                label: l10n.detailNoteAdd,
                semanticLabel: l10n.detailNoteAdd,
                leading: const Icon(Icons.edit_note,
                    size: 18, color: AtemColors.cyan),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SessionEditScreen(session: session),
                  ),
                ),
              ),

            // **Aus einer Einheit einen Plan machen.** Wer etwas
            // zusammengestellt hat, das gut war, will es wiederholen — und
            // hat die Zusammenstellung hier vor sich. Sie noch einmal von
            // Hand in den Planbuilder zu tippen wäre Abschreiben.
            //
            // Nur bei Einheiten mit Übungen: Aus einem Lauf lässt sich kein
            // Plan bauen, und aus einer Krafteinheit ohne Sätze auch nicht.
            if (session case StrengthSession(hasExerciseData: true)) ...[
              const SizedBox(height: 28),
              AtemButton.outline(
                label: l10n.detailSaveAsPlan,
                semanticLabel: l10n.detailSaveAsPlan,
                onPressed: () => _saveAsPlan(context, ref, l10n),
              ),
            ],

            // Die beiden Wege, die Einheit zu verändern — ganz unten, hinter
            // allem, was sie aussagt. Wer den Bildschirm öffnet, will in aller
            // Regel nachsehen, nicht ändern.
            const SizedBox(height: 32),
            AtemButton.outline(
              label: l10n.commonEdit,
              semanticLabel: '${l10n.commonEdit}: ${sessionName(l10n, session)}',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionEditScreen(session: session),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AtemButton.ghost(
              label: l10n.commonDelete,
              semanticLabel:
                  '${l10n.commonDelete}: ${sessionName(l10n, session)}',
              accent: AtemColors.magenta,
              onPressed: () async {
                final deleted =
                    await confirmDeleteSession(context, ref, session);
                // Zurück zur Liste: Ein Detail zu einer Einheit, die gerade
                // verschwunden ist, wäre ein Bildschirm über nichts.
                if (deleted && context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
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
  ) async {
    if (session is! StrengthSession) return;
    final strength = session as StrengthSession;

    final draft = Plan(
      id: '',
      name: strength.planName ?? '',
      items: [
        for (final exercise in strength.exercises)
          if (exercise.sets.any((s) => !s.isEmpty))
            PlanItem(
              exerciseId: exercise.exerciseId,
              sets: exercise.sets.where((s) => !s.isEmpty).length,
              reps: exercise.sets
                  .firstWhere((s) => !s.isEmpty)
                  .reps
                  ?.toString(),
            ),
      ],
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanFormScreen(original: draft, isCopy: true),
      ),
    );
  }

  List<Widget> _exercises(BuildContext context, AppL10n l10n) {
    if (session is! StrengthSession) return const [];
    final strength = session as StrengthSession;
    if (strength.exercises.isEmpty) return const [];

    final sets =
        strength.exercises.fold<int>(0, (total, e) => total + e.sets.length);

    return [
      const SizedBox(height: 22),
      Text(l10n.detailSetsCount(strength.exercises.length, sets).toUpperCase(),
          style: AtemType.labelMicro.of(context)),
      const SizedBox(height: 10),
      AtemCard.list(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < strength.exercises.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 1, thickness: 1, color: AtemColors.border),
              _ExerciseRow(exercise: strength.exercises[i]),
            ],
          ],
        ),
      ),
    ];
  }

  /// Die beiden Erklärungen — beide sagen: **deine Einheit zählt trotzdem.**
  List<Widget> _explanations(
    BuildContext context,
    AppL10n l10n,
    List<TrainingSession> sessions,
  ) {
    // 16 der 63 Krafteinheiten im Bestand tragen keine Übungen. Ohne diesen
    // Hinweis sähe das nach einem Fehler aus — und der Block „Beitrag zur
    // Form" sagt, was die Einheit trotzdem trägt (Board 06, A3/3).
    if (session case StrengthSession(exercises: final exercises)
        when exercises.isEmpty) {
      final load = TrainingLoad.of(session, const LoadContext());
      return [
        const SizedBox(height: 24),
        AtemNotice(
          title: l10n.detailSetsMissingTitle,
          body: l10n.detailSetsMissingBody,
          semanticLabel:
              '${l10n.detailSetsMissingTitle}. ${l10n.detailSetsMissingBody}',
        ),
        const SizedBox(height: 18),
        _Contribution(load: load),
        const SizedBox(height: 14),
        // Die Nachtrag-Aktion ist der einzige CTA dieser Datenlage.
        AtemButton.outline(
          label: l10n.setsAdd,
          semanticLabel: l10n.setsAdd,
          leading: const Icon(Icons.add, size: 18, color: AtemColors.cyan),
          onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(
            WorkoutRunnerScreen.routeName,
            arguments: WorkoutStart.session(session.id),
          ),
        ),
      ];
    }

    if (session is RecoverySession) {
      return [
        const SizedBox(height: 24),
        AtemNotice(
          title: l10n.detailRecoveryTitle,
          body: l10n.detailRecoveryBody,
          semanticLabel:
              '${l10n.detailRecoveryTitle}. ${l10n.detailRecoveryBody}',
        ),
        // Der Nachbarblock gibt dem dünnsten Detail Substanz, ohne Daten zu
        // erfinden (A3/4).
        const SizedBox(height: 18),
        _Neighbours(session: session, sessions: sessions),
      ];
    }

    return const [];
  }
}

/// „Beitrag zur Form" — was eine Einheit ohne Sätze trotzdem trägt.
class _Contribution extends StatelessWidget {
  const _Contribution({required this.load});

  final double load;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final rows = <(String, String)>[
      (l10n.analysisCompConsistency, '+ ${l10n.detailContribCounts}'),
      (l10n.analysisCompLoad, l10n.detailContribLoad('${load.round()}')),
      (l10n.detailContribVolumeTrend, l10n.detailContribNa),
    ];
    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.detailContribTitle.toUpperCase(),
              style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Semantics(
              label: '$label: $value',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
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
        ],
      ),
    );
  }
}

/// „Eingebettet im Verlauf" — die Nachbarn der Regenerationseinheit.
///
/// Die nächstjüngere und die nächstältere Einheit mit ihrem Abstand in
/// Tagen; die Einheit selbst trägt „hier" (Badge + Dot aus Modul 3).
class _Neighbours extends StatelessWidget {
  const _Neighbours({required this.session, required this.sessions});

  final TrainingSession session;
  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));
    final index = sorted.indexWhere((s) => s.id == session.id);
    if (index < 0) return const SizedBox.shrink();
    final newer = index > 0 ? sorted[index - 1] : null;
    final older = index + 1 < sorted.length ? sorted[index + 1] : null;
    if (newer == null && older == null) return const SizedBox.shrink();

    int days(TrainingSession other) =>
        (DateTime(other.date.year, other.date.month, other.date.day)
                    .difference(DateTime(
                        session.date.year, session.date.month, session.date.day))
                    .inHours /
                24)
            .round();

    Widget row(TrainingSession s, {required bool here}) {
      final date = DateFormat.MMMEd(tag).format(s.date);
      final name = sessionName(l10n, s);
      final d = days(s);
      final tail = here
          ? l10n.detailNeighbourHere
          : l10n.detailNeighbourDays(d >= 0 ? '+' : '−', d.abs());
      return Semantics(
        label: '$date, $name, $tail',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text('$date · $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.labelSmall.of(context).copyWith(
                            color: here
                                ? AtemColors.textPrimary
                                : AtemColors.textTertiary,
                          )),
                ),
                const SizedBox(width: 10),
                here
                    ? AtemBadge(
                        label: tail.toUpperCase(),
                        accent: AtemColors.green,
                        leadingDot: true,
                      )
                    : Text(tail,
                        style: AtemType.labelMicro
                            .of(context)
                            .copyWith(letterSpacing: 0)),
              ],
            ),
          ),
        ),
      );
    }

    return AtemCard.list(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.detailNeighboursTitle.toUpperCase(),
              style: AtemType.labelMicro.of(context)),
          const SizedBox(height: 6),
          if (newer != null) row(newer, here: false),
          row(session, here: true),
          if (older != null) row(older, here: false),
        ],
      ),
    );
  }
}

/// Der StatBox-Dreier — **feste Gruppe, fehlender Wert gestrichelt**.
///
/// Board 06, A3: Kraft zeigt Minuten, Last, Volumen; Cardio Kilometer, Last,
/// Pace; Regeneration nur zwei Boxen. Eine leere Box bleibt sichtbar
/// (gestrichelter Rand, „—"), damit die Dreiergruppe nicht springt — und
/// vorgelesen wird „nicht erfasst", nie „Strich".
class _Stats extends StatelessWidget {
  const _Stats({required this.session, required this.load});

  final TrainingSession session;
  final double load;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final minutes = session.duration?.inMinutes;
    final loadText = load > 0 ? load.round().toString() : null;

    final entries = switch (session) {
      StrengthSession s => <(String, String?)>[
          (l10n.detailStatMinutes, minutes?.toString()),
          (l10n.detailLoad, loadText),
          (
            l10n.detailVolume,
            s.hasExerciseData ? _volumeText(context, _volume(s)) : null
          ),
        ],
      CardioSession c => <(String, String?)>[
          (
            l10n.detailStatKilometers,
            c.distanceKm == null ? null : formatKm(context, c.distanceKm!)
          ),
          (l10n.detailLoad, loadText),
          (l10n.formPace, c.tempo == null ? null : formatTempo(context, c.tempo!)),
        ],
      _ => <(String, String?)>[
          (l10n.detailStatMinutes, minutes?.toString()),
          (l10n.detailLoad, loadText),
        ],
    };

    // IntrinsicHeight statt stretch allein: Eine Row mit stretch verlangt
    // eine begrenzte Höhe, in einer Liste gibt es die nicht. So bekommen die
    // Boxen trotzdem dieselbe Höhe.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: AtemSpacing.gridGap),
            Expanded(
                child: _StatTile(label: entries[i].$1, value: entries[i].$2)),
          ],
        ],
      ),
    );
  }

  /// „7,2 t" ab einer Tonne, sonst Kilogramm.
  static String _volumeText(BuildContext context, double kg) => kg >= 1000
      ? '${AtemNumberField.format(context, kg / 1000)} t'
      : AppL10n.of(context).unitKilograms(kg.round().toString());

  static double _volume(StrengthSession s) {
    var total = 0.0;
    for (final e in s.exercises) {
      for (final set in e.sets) {
        final reps = set.reps ?? 0;
        final weight = set.weight ?? 0;
        total += reps * weight;
      }
    }
    return total;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;

  /// `null` heisst: nicht erfasst — gestrichelt, „—".
  final String? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final missing = value == null;

    return Semantics(
      label: missing
          ? '$label, ${l10n.intensityNoneA11y}'
          : '$label: $value',
      child: ExcludeSemantics(
        child: CustomPaint(
          foregroundPainter: missing ? _DashedFrame() : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: missing ? AtemColors.surfaceSolid : AtemColors.surfaceRaised,
              borderRadius: AtemRadii.statBoxR,
              border: missing ? null : Border.all(color: AtemColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value ?? l10n.intensityNoneValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.valueMedium.of(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: missing
                            ? AtemColors.textSecondary
                            : (label == l10n.detailLoad
                                ? AtemColors.cyan
                                : AtemColors.textPrimary),
                      ),
                ),
                const SizedBox(height: 2),
                Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.labelMicro.of(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gestrichelter Rand = „hier fehlt etwas" (Formmerkmal, Board 02).
class _DashedFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AtemColors.border;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(AtemRadii.statBox)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFrame old) => false;
}

/// Eine Übung der Einheit — **Punkt im Muskelton, Name, Schema rechts**
/// (Board 09, Spezifikation „Übungszeile im Einheitendetail": min-H 48 dp,
/// Punkt 8 dp, Text weiss; das Schema in Cyan-Mono ist ein Messwert).
///
/// Der Name kommt aus dem Übungsbestand — die Einheit selbst kennt nur die
/// Kennung, und `archer_push_up` ist kein Name.
class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({required this.exercise});

  final LoggedExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final catalog = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    final entry =
        catalog.where((e) => e.id == exercise.exerciseId).firstOrNull;
    final name = entry == null ? exercise.exerciseId : exerciseName(context, entry);
    final color = entry?.displayMuscles.firstOrNull?.color ?? AtemCategories.grey;

    final done = exercise.sets.where((s) => !s.isEmpty).toList();
    final reps = done.map((s) => s.reps).whereType<int>().toList();
    final weights = done.map((s) => s.weight).whereType<double>().toList();
    final holds = done.map((s) => s.holdSeconds).whereType<int>().toList();
    // „4 × 8 · 60 kg": Satzzahl, Wiederholungen des ersten Satzes, das
    // schwerste Gewicht — die drei Zahlen, die eine Zeile tragen kann.
    final scheme = <String>[
      if (done.isNotEmpty)
        reps.isNotEmpty ? '${done.length} × ${reps.first}' : '${done.length}',
      if (weights.isNotEmpty)
        l10n.unitKilograms(_trim(weights.reduce((a, b) => a > b ? a : b))),
      if (holds.isNotEmpty && reps.isEmpty)
        l10n.restSeconds(holds.reduce((a, b) => a > b ? a : b)),
    ].join(' · ');

    return Semantics(
      label: [name, if (scheme.isNotEmpty) scheme].join(', '),
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtemType.titleSmallOrDefault(context)),
              ),
              if (scheme.isNotEmpty) ...[
                const SizedBox(width: 10),
                // Bei 200 % darf das Schema umbrechen — der Name geht vor.
                Flexible(
                  child: Text(
                    scheme,
                    textAlign: TextAlign.end,
                    style: AtemType.valueMedium.of(context).copyWith(
                          fontSize: 13,
                          color: AtemColors.cyan,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
