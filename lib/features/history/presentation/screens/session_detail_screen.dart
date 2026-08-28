import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../dashboard/presentation/readiness_zone_ui.dart';
import '../../application/history_providers.dart';
import '../../domain/readiness.dart';
import '../../domain/training_load.dart';
import '../../domain/training_session.dart';
import '../../domain/session_comparison.dart';
import '../session_actions.dart';
import '../widgets/comparison_card.dart';
import '../session_ui.dart';
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

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(backgroundColor: AtemColors.base),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            Text(sessionName(l10n, session),
                style: AtemType.titleLarge.of(context)),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMMEEEEd(tag).format(session.date),
              style: AtemType.labelSmall.of(context),
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
            if (acwr.acwr case final value?) ...[
              const SizedBox(height: 24),
              Text(l10n.detailAcwrLabel,
                  style: AtemType.labelMedium.of(context)),
              const SizedBox(height: 8),
              AtemStatBox(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  l10n.detailAcwrZone(
                    value.toStringAsFixed(2),
                    acwr.zone?.label(l10n) ?? '',
                  ),
                  style: AtemType.labelSmall.of(context),
                ),
              ),
            ],
            ..._exercises(context, l10n),
            ..._explanations(context, l10n),
            if (session.notes case final notes?) ...[
              const SizedBox(height: 24),
              Text(notes, style: AtemType.body.of(context)),
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

  List<Widget> _exercises(BuildContext context, AppL10n l10n) {
    if (session is! StrengthSession) return const [];
    final strength = session as StrengthSession;
    if (strength.exercises.isEmpty) return const [];

    final sets =
        strength.exercises.fold<int>(0, (total, e) => total + e.sets.length);

    return [
      const SizedBox(height: 24),
      Text(l10n.detailSetsCount(strength.exercises.length, sets),
          style: AtemType.labelMedium.of(context)),
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
  List<Widget> _explanations(BuildContext context, AppL10n l10n) {
    // 16 der 63 Krafteinheiten im Bestand tragen keine Übungen. Ohne diesen
    // Hinweis sähe das nach einem Fehler aus.
    if (session is StrengthSession &&
        (session as StrengthSession).exercises.isEmpty) {
      return [
        const SizedBox(height: 24),
        AtemNotice(
          title: l10n.detailSetsMissingTitle,
          body: l10n.detailSetsMissingBody,
          semanticLabel:
              '${l10n.detailSetsMissingTitle}. ${l10n.detailSetsMissingBody}',
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
      ];
    }

    return const [];
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.session, required this.load});

  final TrainingSession session;
  final double load;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final entries = <(String, String)>[
      if (session.duration case final d?)
        (l10n.detailDuration, l10n.durationMinutes(d.inMinutes)),
      if (load > 0) (l10n.detailLoad, load.round().toString()),
      if (session case CardioSession(distanceKm: final km?))
        (l10n.detailDistance, l10n.unitKilometers(km.toStringAsFixed(1))),
      if (session case CardioSession(pace: final pace?))
        (l10n.detailPace, pace.toStringAsFixed(2)),
      if (session case StrengthSession s when s.hasExerciseData)
        (l10n.detailVolume, _volume(s).round().toString()),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AtemSpacing.gridGap,
      runSpacing: AtemSpacing.gridGap,
      children: [
        for (final (label, value) in entries)
          Semantics(
            label: '$label: $value',
            child: ExcludeSemantics(
              child: AtemStatBox(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: AtemType.valueMedium.of(context)),
                    const SizedBox(height: 2),
                    Text(label, style: AtemType.labelMicro.of(context)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

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

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final LoggedExercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    final sets = exercise.sets
        .where((s) => !s.isEmpty)
        .map((s) => [
              if (s.reps != null) '${s.reps}',
              if (s.weight != null) l10n.unitKilograms(_trim(s.weight!)),
              if (s.holdSeconds != null) l10n.restSeconds(s.holdSeconds!),
            ].join(' × '))
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.exerciseId,
              style: AtemType.titleSmallOrDefault(context)),
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sets,
                style:
                    AtemType.labelMicro.of(context).copyWith(letterSpacing: 0)),
          ],
        ],
      ),
    );
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';
}
