import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/workout_providers.dart';
import '../../domain/workout_session.dart';
import '../widgets/exercise_header.dart';
import '../widgets/rest_bar.dart';
import '../widgets/session_top_bar.dart';
import '../widgets/set_row.dart';

/// ATEM — Workout Runner.
///
/// Der Screen orchestriert nur: Timer, Navigation, Bausteine. Alles Sichtbare
/// liegt in `presentation/widgets/`.
class WorkoutRunnerScreen extends ConsumerStatefulWidget {
  const WorkoutRunnerScreen({super.key, required this.sessionId});

  static const routeName = '/runner';

  final String sessionId;

  @override
  ConsumerState<WorkoutRunnerScreen> createState() =>
      _WorkoutRunnerScreenState();
}

class _WorkoutRunnerScreenState extends ConsumerState<WorkoutRunnerScreen> {
  Timer? _ticker;
  Timer? _expandTimer;
  Timer? _flashTimer;

  int _elapsed = 0;
  bool _paused = false;
  bool _ended = false;
  int _exIndex = 0;

  Duration _restRemaining = Duration.zero;
  Duration _restTotal = Duration.zero;
  bool _restOn = false;
  bool _restCompact = false;
  bool _restFinishing = false;

  final _notesController = TextEditingController();
  final _weightControllers = <String, TextEditingController>{};
  final _repsControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandTimer?.cancel();
    _flashTimer?.cancel();
    _notesController.dispose();
    for (final c in [
      ..._weightControllers.values,
      ..._repsControllers.values
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _tick() {
    if (_paused || _ended) return;
    setState(() {
      _elapsed++;
      if (!_restOn) return;
      _restRemaining -= const Duration(seconds: 1);
      if (_restRemaining > Duration.zero) return;
      _restRemaining = Duration.zero;
      _restOn = false;
      _onRestDone();
    });
  }

  /// Dreifache Vibration, Systemton — **und ein sichtbarer Blitz.**
  ///
  /// Ohne den letzten Teil existiert das Ende auf einem stummgeschalteten
  /// Gerät nicht.
  Future<void> _onRestDone() async {
    setState(() => _restFinishing = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _restFinishing = false);
    });

    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    await SystemSound.play(SystemSoundType.alert);
  }

  String get _clock => '${(_elapsed ~/ 60).toString().padLeft(2, '0')}'
      ':${(_elapsed % 60).toString().padLeft(2, '0')}';

  TextEditingController _controller(
    Map<String, TextEditingController> pool,
    String id,
    String initial,
  ) =>
      pool.putIfAbsent(id, () => TextEditingController(text: initial));

  WorkoutSessionController get _notifier =>
      ref.read(workoutSessionProvider(widget.sessionId).notifier);

  void _toggleSet(ActiveWorkout w, WorkoutSet set) {
    FocusScope.of(context).unfocus();
    final nowDone = _notifier.toggleSet(_exIndex, set.id);
    if (!nowDone) return;
    setState(() {
      _restTotal = Duration(seconds: w.defaultRestSeconds);
      _restRemaining = _restTotal;
      _restOn = true;
      _restCompact = false;
      _restFinishing = false;
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    if (_restOn && !_restCompact) setState(() => _restCompact = true);
    _expandTimer?.cancel();
    _expandTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _restCompact = false);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(workoutSessionProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AtemColors.base,
      resizeToAvoidBottomInset: false,
      body: async.when(
        loading: () => Padding(
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.paddingOf(context).top + 16, 16, 16),
          child: AtemSkeleton(
            semanticLabel: l10n.workoutA11yLoading,
            blocks: const [
              AtemSkeletonBlock(height: 56, radius: 14),
              AtemSkeletonBlock(height: 150),
              AtemSkeletonBlock(height: 64, radius: 14),
              AtemSkeletonBlock(height: 64, radius: 14),
              AtemSkeletonBlock(height: 64, radius: 14),
            ],
          ),
        ),
        error: (e, _) => AtemErrorState(
          title: l10n.workoutRunnerNotAvailable,
          body: l10n.errorsLoadFailed,
          retryLabel: l10n.commonRetry,
          onRetry: () =>
              ref.invalidate(workoutSessionProvider(widget.sessionId)),
        ),
        data: _buildRunner,
      ),
    );
  }

  Widget _buildRunner(ActiveWorkout w) {
    final l10n = AppL10n.of(context);
    if (w.exercises.isEmpty) {
      return AtemEmptyState(
        title: l10n.workoutScreenNoExercisesFound,
        body: l10n.workoutScreenEmptyHint,
      );
    }

    final index = _exIndex.clamp(0, w.exercises.length - 1);
    final exercise = w.exercises[index];

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SessionTopBar(
                    elapsed: _clock,
                    paused: _paused,
                    onTogglePause: () => setState(() => _paused = !_paused),
                    onOpenNotes: () => _openNotes(w),
                    onEnd: () => _confirmEnd(w),
                  ),
                  const SizedBox(height: 14),
                  ExerciseHeader(
                    exercise: exercise,
                    index: index,
                    total: w.exercises.length,
                    onPrevious:
                        index > 0 ? () => setState(() => _exIndex--) : null,
                    onNext: index < w.exercises.length - 1
                        ? () => setState(() => _exIndex++)
                        : null,
                    onFormGuide: () {},
                  ),
                  const SizedBox(height: 10),
                  if (!SetRow.isCompact(context)) _TableHead(),
                  for (var i = 0; i < exercise.sets.length; i++)
                    SetRow(
                      set: exercise.sets[i],
                      index: i + 1,
                      weightController: _controller(_weightControllers,
                          exercise.sets[i].id, exercise.sets[i].weight),
                      repsController: _controller(_repsControllers,
                          exercise.sets[i].id, exercise.sets[i].reps),
                      onToggle: () => _toggleSet(w, exercise.sets[i]),
                      onCycleType: () =>
                          _notifier.cycleType(index, exercise.sets[i].id),
                      onWeightChanged: (v) =>
                          _notifier.updateWeight(index, exercise.sets[i].id, v),
                      onRepsChanged: (v) =>
                          _notifier.updateReps(index, exercise.sets[i].id, v),
                    ),
                  const SizedBox(height: 10),
                  AtemButton.outline(
                    label: l10n.workoutRunnerAddSet,
                    semanticLabel: l10n.workoutScreenAddSet,
                    accent: AtemColors.textSecondary,
                    onPressed: () => _notifier.addSet(index),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      l10n.workoutRunnerSetsCompleted(
                          w.completedSets, w.totalSets),
                      textAlign: TextAlign.center,
                      style: AtemType.labelMicro.of(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_restOn && !_ended)
          Positioned(
            left: 14,
            right: 14,
            // Safe-Area beachten: sonst liegt die Leiste auf Geräten mit
            // Drei-Tasten-Navigation unter der Systemleiste.
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: RestBar(
              remaining: _restRemaining,
              total: _restTotal,
              compact: _restCompact,
              finishing: _restFinishing,
              onExtend: () => setState(() {
                _restRemaining += const Duration(seconds: 30);
                _restTotal += const Duration(seconds: 30);
              }),
              onShorten: () => setState(() {
                _restRemaining = _restRemaining > const Duration(seconds: 15)
                    ? _restRemaining - const Duration(seconds: 15)
                    : const Duration(seconds: 1);
              }),
              onSkip: () => setState(() => _restOn = false),
            ),
          ),
        if (_ended) _SummaryOverlay(workout: w, elapsed: _clock),
      ],
    );
  }

  void _openNotes(ActiveWorkout w) {
    final l10n = AppL10n.of(context);
    _notesController.text = w.notes;
    AtemSheet.show<void>(
      context,
      title: l10n.workoutRunnerNotesTitle,
      closeLabel: l10n.commonClose,
      primaryAction: AtemButton.gradient(
        label: l10n.workoutRunnerNotesDone,
        semanticLabel: l10n.workoutRunnerNotesDone,
        onPressed: () {
          _notifier.setNotes(_notesController.text);
          Navigator.of(context).maybePop();
        },
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        autofocus: true,
        style: AtemType.body.base,
        decoration: InputDecoration(hintText: l10n.workoutRunnerNotesHint),
      ),
    );
  }

  void _confirmEnd(ActiveWorkout w) {
    final l10n = AppL10n.of(context);
    AtemDialog.show<void>(
      context,
      // Beenden speichert — der Gradient ist berechtigt.
      kind: AtemDialogKind.confirm,
      title: l10n.workoutScreenEndWorkoutConfirm,
      message: l10n.workoutScreenEndWorkoutConfirmText,
      confirmLabel: l10n.workoutScreenEndWorkoutAction,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.workoutScreenEndWorkout,
      onConfirm: _finish,
      // Der zweite Ausgang. Ohne ihn gäbe es nur „speichern" oder „weiter
      // trainieren" — wer sich vertan hat oder nur ausprobiert, säße fest und
      // müsste eine falsche Einheit in seinen Verlauf schreiben.
      alternativeLabel: l10n.workoutScreenDiscardWorkout,
      onAlternative: _confirmDiscard,
      detail: _EndStats(workout: w, elapsed: _clock),
    );
  }

  /// Verwerfen wird **ein zweites Mal** bestätigt.
  ///
  /// Es ist die einzige Handlung im Runner, die Arbeit vernichtet, und sie ist
  /// nicht rückgängig zu machen. Ein Dialog, der direkt aus einem anderen
  /// Dialog verwirft, wäre zu leicht auszulösen.
  void _confirmDiscard() {
    final l10n = AppL10n.of(context);
    Navigator.of(context).maybePop();

    AtemDialog.show<void>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.workoutScreenDiscardConfirmTitle,
      message: l10n.workoutScreenDiscardConfirm,
      confirmLabel: l10n.workoutScreenDiscardWorkout,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.workoutScreenDiscardWorkout,
      onConfirm: _discard,
    );
  }

  /// Beendet ohne zu speichern.
  Future<void> _discard() async {
    Navigator.of(context).maybePop();
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Der Bildschirm verschwindet; nichts wird geschrieben. Der Timer stirbt
    // mit dem Notifier.
    Navigator.of(context).maybePop();
  }

  Future<void> _finish() async {
    Navigator.of(context).maybePop();
    await HapticFeedback.mediumImpact();
    setState(() {
      _ended = true;
      _restOn = false;
    });
    try {
      await _notifier.finish(Duration(seconds: _elapsed));
    } catch (_) {
      if (!mounted) return;
      setState(() => _ended = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).workoutRunnerSavedFailed)),
      );
    }
  }
}

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final style = AtemType.labelMicro.of(context);
    Widget cell(String t, {TextAlign align = TextAlign.left, double? w}) {
      final text = Text(t, textAlign: align, style: style, maxLines: 1);
      return w == null
          ? Expanded(child: text)
          : SizedBox(width: w, child: text);
    }

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Row(
          children: [
            cell(l10n.workoutRunnerTableSet, w: 48),
            const SizedBox(width: 8),
            cell(l10n.workoutRunnerTableLast),
            const SizedBox(width: 8),
            cell(l10n.workoutRunnerTableWeight, align: TextAlign.center, w: 72),
            const SizedBox(width: 8),
            cell(l10n.workoutRunnerTableReps, align: TextAlign.center, w: 60),
            const SizedBox(width: 8),
            cell(l10n.workoutRunnerTableDone, align: TextAlign.center, w: 48),
          ],
        ),
      ),
    );
  }
}

/// Statistik im Beenden-Dialog — StatBox als Einlage, nie als eigene Karte.
class _EndStats extends StatelessWidget {
  const _EndStats({required this.workout, required this.elapsed});
  final ActiveWorkout workout;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    Widget box(String value, String label) => Expanded(
          child: AtemStatBox(
            child: Column(
              children: [
                Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  // Kein FittedBox: der machte die Schriftskalierung des
                  // Nutzers stillschweigend rückgängig.
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.valueMedium.of(context),
                ),
                const SizedBox(height: 3),
                Text(label,
                    textAlign: TextAlign.center,
                    style: AtemType.labelMicro.of(context)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        box(elapsed, l10n.commonDuration),
        const SizedBox(width: 8),
        box('${workout.completedSets}', l10n.workoutPostWorkoutSets),
        const SizedBox(width: 8),
        box('${workout.totalVolume.round()}', l10n.workoutSetLoggerWeightUnit),
      ],
    );
  }
}

class _SummaryOverlay extends StatelessWidget {
  const _SummaryOverlay({required this.workout, required this.elapsed});
  final ActiveWorkout workout;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return ColoredBox(
      color: AtemColors.base.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AtemCard.list(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AtemProgressRing(
                  value: 1.0,
                  diameter: 54,
                  semanticLabel: l10n.workoutRunnerSaved,
                ),
                const SizedBox(height: 14),
                Text(l10n.workoutRunnerSaved,
                    style: AtemType.titleMedium.of(context)),
                const SizedBox(height: 6),
                Text(
                  l10n.workoutRunnerSummary(
                    workout.completedSets,
                    elapsed,
                    '${workout.totalVolume.round()}',
                  ),
                  textAlign: TextAlign.center,
                  style: AtemType.labelSmall.of(context),
                ),
                const SizedBox(height: 18),
                AtemButton.gradient(
                  label: l10n.workoutRunnerSavedDone,
                  semanticLabel: l10n.workoutRunnerSavedDone,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
