import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/workout_providers.dart';
import '../../../history/presentation/widgets/wellness_fields.dart';
import '../../domain/workout_session.dart';
import '../../data/workout_draft_store.dart';
import '../../domain/workout_clock.dart';
import '../../domain/workout_start.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/exercise_picker.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../widgets/exercise_header.dart';
import '../widgets/rest_bar.dart';
import '../set_type_ui.dart';
import '../widgets/session_top_bar.dart';
import '../widgets/set_row.dart';
import '../../../../app/application/snackbar_providers.dart';

/// ATEM — Workout Runner.
///
/// Der Screen orchestriert nur: Timer, Navigation, Bausteine. Alles Sichtbare
/// liegt in `presentation/widgets/`.
class WorkoutRunnerScreen extends ConsumerStatefulWidget {
  const WorkoutRunnerScreen({
    super.key,
    required this.start,
    this.readiness,
  });

  static const routeName = '/runner';

  /// Plan und Pausenzeit. Freies Training trägt keinen Plan.
  final WorkoutStart start;

  /// Die Antwort aus dem Startblatt, 1 bis 5. `null`, wenn übersprungen.
  /// Sie wandert einmal in den Zustand und wird beim Beenden mitgeschrieben.
  final int? readiness;

  @override
  ConsumerState<WorkoutRunnerScreen> createState() =>
      _WorkoutRunnerScreenState();
}

class _WorkoutRunnerScreenState extends ConsumerState<WorkoutRunnerScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _expandTimer;
  Timer? _flashTimer;

  /// **Die Uhr, nicht ein Zähler.** Der Zeitgeber unten löst nur noch das
  /// Neuzeichnen aus; gemessen wird an zwei Zeitpunkten. Warum, steht am
  /// [WorkoutClock].
  late WorkoutClock _clockState;

  bool _ended = false;

  /// Die Antwort aus dem Beenden-Dialog, 1 bis 5.
  ///
  /// Sie wird **vor** dem Schreiben eingesammelt, nicht danach: Ein
  /// nachgereichtes `SessionPatch` trägt laut seinem eigenen Vertrag
  /// „`null` löscht das Feld" — ein Teilpatch nur für das Gefühl nähme der
  /// Einheit Dauer und Notiz.
  int? _feeling;
  int _exIndex = 0;

  bool _restCompact = false;
  bool _restFinishing = false;

  /// Ob die Pause schon als beendet gemeldet wurde — sonst löste jeder Tick
  /// nach Ablauf erneut Vibration und Ton aus.
  bool _restAnnounced = false;

  /// Welcher Wert gerade am Regler hängt — Satz-Kennung und Feld.
  ///
  /// Höchstens einer zur Zeit: Zwei offene Regler übereinander machen aus der
  /// Satzliste ein Formular.
  ({String setId, SetField field})? _editing;

  final _weightControllers = <String, TextEditingController>{};
  final _repsControllers = <String, TextEditingController>{};
  final _holdControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _clockState = WorkoutClock.startingAt(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Nach dem ersten Aufbau fragen — vorher gibt es keinen Kontext für
    // einen Dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyReadiness();
      _offerDraft();
    });
  }

  /// Trägt die Antwort aus dem Startblatt in den Zustand.
  ///
  /// **Idempotent, und das ist keine Kür.** Beim ersten Frame ist die Einheit
  /// noch nicht geladen — der `AsyncNotifier` holt sie aus dem Repository —,
  /// also läuft der erste Versuch ins Leere. Ein zweiter kommt, sobald Daten
  /// da sind, und ein dritter nach dem Übernehmen eines Zwischenstands, der
  /// den Zustand ersetzt.
  ///
  /// Der Vergleich vor dem Schreiben ist der Schutz gegen die Schleife: Ohne
  /// ihn erzeugte jedes Setzen einen neuen Zustand, der den Zuhörer weckt,
  /// der wieder setzt.
  void _applyReadiness() {
    final value = widget.readiness;
    if (value == null) return;
    final workout = ref.read(workoutSessionProvider(widget.start)).value;
    if (workout == null || workout.preWorkoutReadiness == value) return;
    ref
        .read(workoutSessionProvider(widget.start).notifier)
        .setReadiness(value);
  }

  /// Bietet einen gefundenen Zwischenstand an.
  ///
  /// **Er stellt sich nicht von allein wieder her.** Ein Training, das beim
  /// Öffnen einfach weiterläuft, überrascht — und eines von heute früh wäre
  /// eine falsche Auskunft. Also gefragt, mit den Zahlen dazu.
  Future<void> _offerDraft() async {
    if (!mounted || _amends) return;

    final draft = await const WorkoutDraftStore().read(DateTime.now());
    if (draft == null || !mounted) return;

    final done = draft.workout.completedSets;
    if (done == 0) {
      // Ein Zwischenstand ohne abgehakten Satz ist nichts wert.
      await const WorkoutDraftStore().clear();
      return;
    }

    final l10n = AppL10n.of(context);
    final ago = _elapsedLabel(
      DateTime.now().difference(draft.clock.startedAt),
    );

    final resume = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.confirm,
      title: l10n.workoutResumeTitle,
      message: l10n.workoutResumeBody(ago, done, draft.workout.totalSets),
      confirmLabel: l10n.workoutResumeContinue,
      dismissLabel: l10n.workoutResumeDiscard,
      barrierLabel: l10n.workoutResumeTitle,
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
    );

    if (resume != true) {
      await const WorkoutDraftStore().clear();
      return;
    }
    if (!mounted) return;

    setState(() {
      _clockState = draft.clock;
      _exIndex = draft.exerciseIndex;
      _restAnnounced = !draft.clock.isResting;
    });
    _notifier.restore(draft.workout);
  }

  static String _elapsedLabel(Duration since) {
    final minutes = since.inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${since.inHours} h ${minutes % 60} min';
  }

  /// Beim Zurückkommen aus dem Hintergrund sofort neu zeichnen.
  ///
  /// Die Zahlen stimmen ohnehin — sie kommen aus der Uhr. Ohne diesen Anstoß
  /// stünde aber bis zum nächsten Tick der alte Stand da, und eine abgelaufene
  /// Pause bliebe eine Sekunde lang scheinbar offen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _expandTimer?.cancel();
    _flashTimer?.cancel();
    for (final c in [
      ..._weightControllers.values,
      ..._repsControllers.values,
      ..._holdControllers.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Zeichnet neu und meldet eine abgelaufene Pause. **Misst nichts.**
  void _tick() {
    if (_ended) return;
    final now = DateTime.now();
    final restOver = _clockState.restElapsed(now);

    setState(() {});

    if (restOver && !_restAnnounced) {
      _restAnnounced = true;
      _clockState = _clockState.stopRest();
      _onRestDone();
    }
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

  Duration get _elapsed => _clockState.elapsed(DateTime.now());

  bool get _paused => _clockState.isPaused;
  bool get _restOn => _clockState.isResting;
  Duration get _restRemaining => _clockState.restRemaining(DateTime.now());
  Duration get _restTotal => _clockState.restTotal;

  String get _clock {
    final seconds = _elapsed.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}'
        ':${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// Das Feld zu einem Satz — und der Abgleich mit dem Zustand.
  ///
  /// Der Zustand kann den Wert **selbst** setzen: Beim Abhaken wandern Gewicht
  /// und Wiederholungen in den nächsten Satz. Ein Feld, das nur bei seiner
  /// Erzeugung liest, zeigte davon nichts.
  ///
  /// Übernommen wird nur in ein **leeres** Feld. Alles andere hat jemand
  /// getippt, und getippt schlägt gerechnet.
  TextEditingController _controller(
    Map<String, TextEditingController> pool,
    String id,
    String value,
  ) {
    final controller =
        pool.putIfAbsent(id, () => TextEditingController(text: value));
    if (controller.text.trim().isEmpty && value.trim().isNotEmpty) {
      controller.text = value;
    }
    return controller;
  }

  bool get _amends => widget.start.amends;

  /// Die Zielvorgabe aus dem Plan, als Satz. `null`, wenn keine hinterlegt
  /// ist — dann steht dort nichts statt „Ziel —".
  static String? _target(AppL10n l10n, WorkoutExercise exercise) {
    if (exercise.targetHoldSeconds case final hold?) {
      return l10n.workoutTargetHold(hold);
    }
    if (exercise.targetReps case final reps? when reps.trim().isNotEmpty) {
      return l10n.workoutTargetReps(reps);
    }
    return null;
  }

  /// Entfernt eine Übung — **mit Rückfrage**.
  ///
  /// Der Knopf sitzt unter „Satz hinzufügen" und „Übung hinzufügen", also
  /// dort, wo man während des Trainings ohnehin tippt. Ohne Rückfrage war er
  /// mehrfach aus Versehen getroffen worden, und mit ihm gingen die
  /// abgehakten Sätze der Übung verloren.
  ///
  /// Kein Widerruf danach: Ein Widerrufsfenster mitten im Training wäre eine
  /// Meldung über der Satzliste, die dort niemand haben will. Die Rückfrage
  /// kostet einen Tap und verhindert genau den Fehler.
  Future<void> _confirmRemove(int index, WorkoutExercise exercise) async {
    final l10n = AppL10n.of(context);

    final confirmed = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.workoutRemoveExerciseConfirm(_displayName(exercise)),
      message: l10n.workoutRemoveExerciseBody,
      confirmLabel: l10n.workoutRunnerRemoveExercise,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.workoutRunnerRemoveExerciseA11y(_displayName(exercise)),
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
    );
    if (confirmed != true || !mounted) return;

    _notifier.removeExercise(index);
    setState(() => _exIndex = 0);
    final workout = ref.read(workoutSessionProvider(widget.start)).value;
    if (workout != null) _persist(workout);
  }

  /// Pausiert oder setzt fort — beides über die Uhr, nicht über ein Flag.
  void _togglePause(ActiveWorkout workout) {
    final now = DateTime.now();
    setState(() {
      _clockState =
          _clockState.isPaused ? _clockState.resume(now) : _clockState.pause(now);
    });
    _persist(workout);
  }

  WorkoutSessionController get _notifier =>
      ref.read(workoutSessionProvider(widget.start).notifier);

  /// Öffnet den Regler unter einer Satzzeile — oder schliesst ihn.
  ///
  /// Höchstens einer ist offen: Ein zweiter Regler daneben wäre eine zweite
  /// Stelle, an der dieselbe Geste etwas anderes tut.
  void _openStepper(WorkoutSet set, SetField? field) {
    FocusScope.of(context).unfocus();
    setState(() {
      _editing =
          field == null ? null : (setId: set.id, field: field);
    });
  }

  /// Die Übung aus dem Bestand, **wenn sie etwas zu erklären hat**.
  ///
  /// Eigene Übungen tragen meist nur einen Namen; für sie erscheint kein
  /// Chip, statt ein leeres Blatt zu öffnen.
  Exercise? _formGuide(WorkoutExercise exercise) {
    for (final entry
        in ref.read(exercisesProvider).value ?? const <Exercise>[]) {
      if (entry.id != exercise.id) continue;
      final hasGuide = entry.instructions.isNotEmpty ||
          entry.cues.isNotEmpty ||
          entry.commonMistakes.isNotEmpty ||
          (entry.description?.trim().isNotEmpty ?? false);
      return hasGuide ? entry : null;
    }
    return null;
  }

  /// Anleitung, Cues und typische Fehler — im Blatt, ohne den Runner zu
  /// verlassen.
  ///
  /// Der Chip lag bis zum 18.09.2026 auf einem leeren Rückruf: Er sah aus wie
  /// ein Weg und war keiner.
  void _openFormGuide(WorkoutExercise exercise) {
    final guide = _formGuide(exercise);
    if (guide == null) return;
    final l10n = AppL10n.of(context);

    AtemSheet.show<void>(
      context,
      title: _displayName(exercise),
      closeLabel: l10n.commonClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (guide.description?.trim().isNotEmpty ?? false)
            _GuideSection(
              title: l10n.workoutFormGuideDescription,
              lines: [guide.description!.trim()],
              numbered: false,
            ),
          if (guide.instructions.isNotEmpty)
            _GuideSection(
              title: l10n.exerciseInstructions,
              lines: guide.instructions,
              numbered: true,
            ),
          if (guide.cues.isNotEmpty)
            _GuideSection(
              title: l10n.exerciseCues,
              lines: guide.cues,
              numbered: false,
            ),
          if (guide.commonMistakes.isNotEmpty)
            _GuideSection(
              title: l10n.exerciseMistakes,
              lines: guide.commonMistakes,
              numbered: false,
              accent: AtemColors.magenta,
            ),
        ],
      ),
    );
  }

  void _toggleSet(ActiveWorkout w, WorkoutSet set) {
    FocusScope.of(context).unfocus();
    // Ein offener Regler gehört zum Eintragen, nicht zum Abhaken.
    if (_editing?.setId == set.id) setState(() => _editing = null);
    final nowDone = _notifier.toggleSet(_exIndex, set.id);
    if (!nowDone) return;

    setState(() {
      _clockState = _clockState.startRest(
        DateTime.now(),
        Duration(seconds: w.defaultRestSeconds),
      );
      _restAnnounced = false;
      _restCompact = false;
      _restFinishing = false;
    });
    _persist(w);

    // **War das der letzte offene Satz dieser Übung, weiter zur nächsten.**
    //
    // Vorher blieb der Bildschirm stehen, und man tippte sich durch den
    // Pfeil oben — mitten in der Pause, in der man ohnehin nichts anderes
    // tut. Die Pause läuft dabei weiter: Sie gehört zum Satz, nicht zur
    // Übung, und sie neu zu starten verschenkte die Hälfte.
    final exercise = w.exercises[_exIndex];
    final open = exercise.sets.where((s) => !s.done && s.id != set.id).length;
    if (open == 0 && _exIndex < w.exercises.length - 1) {
      setState(() => _exIndex++);
    }
  }

  /// Sichert den Zwischenstand.
  ///
  /// Nach jeder Änderung, die etwas wert ist — abgehakte Sätze, gewechselte
  /// Übung, geänderte Notiz. Nicht bei jedem Tastendruck in einem Feld: Das
  /// wären Dutzende Schreibvorgänge je Satz, und der Wert eines halb
  /// getippten Gewichts ist gering.
  void _persist(ActiveWorkout workout) {
    unawaited(const WorkoutDraftStore().save(WorkoutDraft(
      start: widget.start,
      clock: _clockState,
      workout: workout,
      exerciseIndex: _exIndex,
    )));
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
    final async = ref.watch(workoutSessionProvider(widget.start));
    // **Beobachtet, nicht nur gelesen.** Der Übungsbestand kommt aus einem
    // Strom und ist beim ersten Frame leer. Wer ihn nur liest, zeigt für
    // immer den englischen Grundnamen und keinen Form-Guide-Chip — beides
    // hing bis zum 18.09.2026 daran.
    ref.watch(exercisesProvider);

    // Sobald die Einheit da ist — und wieder, wenn ein Zwischenstand den
    // Zustand ersetzt hat. Siehe [_applyReadiness].
    ref.listen(workoutSessionProvider(widget.start), (_, __) {
      _applyReadiness();
    });

    return PopScope(
      // **Die Zurück-Geste beendete das Training vollständig.** Kein
      // Zwischenstand, keine Rückfrage, die abgehakten Sätze weg. Sie fragt
      // jetzt — und der Stand liegt ohnehin schon auf der Platte.
      canPop: _ended,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
              ref.invalidate(workoutSessionProvider(widget.start)),
        ),
          data: _buildRunner,
        ),
      ),
    );
  }

  /// Beim Verlassen fragen — **und den Stand behalten**.
  ///
  /// Kein „verwerfen" an dieser Stelle: Wer aus Versehen wischt, will nichts
  /// wegwerfen. Wer wirklich verwerfen will, findet den Weg im Beenden-Dialog,
  /// wo er zweimal bestätigt wird.
  Future<bool> _confirmLeave() async {
    if (_ended) return true;
    final l10n = AppL10n.of(context);

    final leave = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.confirm,
      title: l10n.workoutLeaveTitle,
      message: l10n.workoutLeaveBody,
      confirmLabel: l10n.workoutLeaveKeep,
      dismissLabel: l10n.workoutLeaveStay,
      barrierLabel: l10n.workoutLeaveTitle,
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
    );
    if (leave != true) return false;

    // Ein letztes Mal sichern, damit auch die zuletzt getippten Werte
    // drinstehen — die schreibt `_persist` sonst erst beim nächsten Abhaken.
    final workout = ref.read(workoutSessionProvider(widget.start)).value;
    if (workout != null) _persist(workout);
    return true;
  }

  /// Nimmt eine Übung in die laufende Einheit auf.
  ///
  /// Der einzige Weg, ein freies Training zu füllen — und zugleich der Weg,
  /// einen Plan zu ergänzen, wenn unterwegs etwas dazukommt.
  Future<void> _addExercise() async {
    final chosen = await ExercisePicker.show(context);
    if (chosen == null || chosen.isEmpty) return;
    for (final exercise in chosen) {
      _notifier.addExercise(exercise);
    }
    // Direkt zur neuen Übung springen: Wer sie hinzufügt, will sie eintragen.
    final count = ref.read(workoutSessionProvider(widget.start)).value
            ?.exercises.length ??
        1;
    setState(() => _exIndex = count - 1);
  }

  /// Der anzuzeigende Übungsname.
  ///
  /// Die laufende Einheit trägt den englischen Grundnamen — sie entsteht in
  /// der Datenschicht, die kein Gebietsschema kennt. Hier ist der Bestand
  /// da, und damit die deutsche Fassung.
  String _displayName(WorkoutExercise exercise) {
    for (final entry in ref.read(exercisesProvider).value ?? const <Exercise>[]) {
      if (entry.id == exercise.id) return exerciseName(context, entry);
    }
    return exercise.name;
  }

  Widget _buildRunner(ActiveWorkout w) {
    final l10n = AppL10n.of(context);
    if (w.exercises.isEmpty) {
      // **Kein Fehlerbild.** Ein leerer Runner ist beim freien Training der
      // normale Anfang, nicht ein Plan, der nicht geladen hat.
      return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 6, AtemSpacing.screenPadding, 0),
              child: SessionTopBar(
                amending: w.amendsSessionId != null,
                elapsed: _clock,
                paused: _paused,
                onTogglePause: () => _togglePause(w),
                onEnd: () => _confirmEnd(w),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AtemEmptyState(
                  title: l10n.workoutRunnerEmptyTitle,
                  body: l10n.workoutRunnerEmptyBody,
                  action: AtemButton.gradient(
                    label: l10n.workoutLoggingAddExercise,
                    semanticLabel: l10n.workoutLoggingAddExercise,
                    expand: false,
                    size: AtemButtonSize.compact,
                    onPressed: _addExercise,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              // Unten Platz für die schwebende Pausenleiste, sonst deckt sie
              // die letzten Sätze zu.
              padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding, 6,
                  AtemSpacing.screenPadding, 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SessionTopBar(
                    amending: w.amendsSessionId != null,
                    elapsed: _clock,
                    paused: _paused,
                    onTogglePause: () => _togglePause(w),
                    onEnd: () => _confirmEnd(w),
                  ),
                  const SizedBox(height: AtemSpacing.cardGap),
                  ExerciseHeader(
                    exercise: exercise,
                    title: _displayName(exercise),
                    index: index,
                    total: w.exercises.length,
                    onPrevious:
                        index > 0 ? () => setState(() => _exIndex--) : null,
                    onNext: index < w.exercises.length - 1
                        ? () => setState(() => _exIndex++)
                        : null,
                    onFormGuide: _formGuide(exercise) == null
                        ? null
                        : () => _openFormGuide(exercise),
                  ),
                  // Die Vorgabe aus dem Plan — **neben** den Feldern, nicht
                  // darin. Sie sagt, was gedacht war; was war, tippt man ein.
                  if (_target(l10n, exercise) case final target?) ...[
                    const SizedBox(height: AtemSpacing.sm),
                    Text(target,
                        textAlign: TextAlign.center,
                        style: AtemType.meta
                            .of(context)
                            .copyWith(color: AtemColors.cyan)),
                  ],
                  const SizedBox(height: AtemSpacing.md),
                  if (!SetRow.isCompact(context))
                    _TableHead(isHold: exercise.isHold),
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
                      editing: _editing?.setId == exercise.sets[i].id
                          ? _editing!.field
                          : null,
                      onEdit: (field) => _openStepper(exercise.sets[i], field),
                      holdController: exercise.isHold
                          ? _controller(_holdControllers,
                              exercise.sets[i].id, exercise.sets[i].hold)
                          : null,
                      onHoldChanged: exercise.isHold
                          ? (v) => _notifier.updateHold(
                              index, exercise.sets[i].id, v)
                          : null,
                    ),
                  const SizedBox(height: AtemSpacing.sm),
                  // **Die Kürzel erklären sich nicht von selbst.** „D" und
                  // „N" standen unkommentiert in jeder Zeile; die Frage
                  // „was bedeutet das?" ist beim Training die falsche.
                  const _SetTypeLegend(),
                  const SizedBox(height: AtemSpacing.md),
                  AtemButton.outline(
                    label: l10n.workoutRunnerAddSet,
                    semanticLabel: l10n.workoutScreenAddSet,
                    accent: AtemColors.textSecondary,
                    onPressed: () => _notifier.addSet(index),
                  ),
                  const SizedBox(height: AtemSpacing.sm),
                  AtemButton.outline(
                    label: l10n.workoutLoggingAddExercise,
                    semanticLabel: l10n.workoutLoggingAddExercise,
                    onPressed: _addExercise,
                  ),
                  const SizedBox(height: AtemSpacing.sm),
                  AtemButton.ghost(
                    label: l10n.workoutRunnerRemoveExercise,
                    semanticLabel:
                        l10n.workoutRunnerRemoveExerciseA11y(_displayName(exercise)),
                    accent: AtemColors.magenta,
                    onPressed: () => _confirmRemove(index, exercise),
                  ),
                  const SizedBox(height: AtemSpacing.lg),
                  Center(
                    child: Text(
                      l10n.workoutRunnerSetsCompleted(
                          w.completedSets, w.totalSets),
                      textAlign: TextAlign.center,
                      style: AtemType.meta.of(context),
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
                _clockState =
                    _clockState.shiftRest(const Duration(seconds: 30));
              }),
              onShorten: () => setState(() {
                // Nie unter eine Sekunde: Eine Pause, die im Moment des
                // Verkürzens endet, löste Vibration und Ton aus.
                final left = _restRemaining;
                final by = left > const Duration(seconds: 16)
                    ? const Duration(seconds: -15)
                    : -(left - const Duration(seconds: 1));
                _clockState = _clockState.shiftRest(by);
              }),
              onSkip: () => setState(() {
                _clockState = _clockState.stopRest();
                _restAnnounced = true;
              }),
            ),
          ),
        // Die Zusammenfassung gehört zu einem beendeten Training, nicht zu
        // nachgetragenen Sätzen.
        if (_ended && w.amendsSessionId == null)
          _SummaryOverlay(workout: w, elapsed: _clock),
      ],
    );
  }

  /// Beenden — **eine Frage, drei mögliche Antworten**.
  ///
  /// ## Warum die Dialoge jetzt Werte zurückgeben
  ///
  /// Vorher schloss jeder Dialog sich selbst über `maybePop()` und öffnete
  /// den nächsten gleich danach. `maybePop` ist asynchron — es fragt erst,
  /// ob geschlossen werden darf. Der zweite Dialog wurde also aufgebaut,
  /// während der erste noch am Schliessen war, und das Schliessen traf dann
  /// den falschen.
  ///
  /// Sichtbar wurde es beim Verwerfen: Der Runner blieb stehen. Der Weg
  /// zurück hatte einen Dialog geschlossen, der schon weg war, und der
  /// Bildschirm überlebte.
  ///
  /// Jetzt gibt jeder Dialog sein Ergebnis zurück und der Ablauf steht an
  /// einer Stelle. Kein Dialog kennt mehr den nächsten.
  Future<void> _confirmEnd(ActiveWorkout w) async {
    final l10n = AppL10n.of(context);

    // Beim Nachtragen gibt es nichts zu beenden: Die Einheit existiert, es
    // kommen nur Sätze dazu. Also sichern oder zurück, ohne Zwischenfrage.
    if (w.amendsSessionId != null) {
      await _finish();
      return;
    }

    final choice = await AtemDialog.show<_EndChoice>(
      context,
      // Beenden speichert — der Gradient ist berechtigt.
      kind: AtemDialogKind.confirm,
      title: l10n.workoutScreenEndWorkoutConfirm,
      message: l10n.workoutScreenEndWorkoutConfirmText,
      confirmLabel: l10n.workoutScreenEndWorkoutAction,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.workoutScreenEndWorkout,
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(_EndChoice.save),
      // Der zweite Ausgang. Ohne ihn gäbe es nur „speichern" oder „weiter
      // trainieren" — wer sich vertan hat oder nur ausprobiert, säße fest und
      // müsste eine falsche Einheit in seinen Verlauf schreiben.
      alternativeLabel: l10n.workoutScreenDiscardWorkout,
      onAlternative: () => Navigator.of(context).pop(_EndChoice.discard),
      detail: _EndDetail(
        workout: w,
        elapsed: _clock,
        feeling: _feeling,
        onFeeling: (v) => _feeling = v,
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case _EndChoice.save:
        await _finish();
      case _EndChoice.discard:
        await _confirmDiscard();
      case null:
        break;
    }
  }

  /// Verwerfen wird **ein zweites Mal** bestätigt.
  ///
  /// Es ist die einzige Handlung im Runner, die Arbeit vernichtet, und sie ist
  /// nicht rückgängig zu machen.
  Future<void> _confirmDiscard() async {
    final l10n = AppL10n.of(context);

    final confirmed = await AtemDialog.show<bool>(
      context,
      kind: AtemDialogKind.destructive,
      title: l10n.workoutScreenDiscardConfirmTitle,
      message: l10n.workoutScreenDiscardConfirm,
      confirmLabel: l10n.workoutScreenDiscardWorkout,
      dismissLabel: l10n.commonCancel,
      barrierLabel: l10n.workoutScreenDiscardWorkout,
      onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
    );
    if (confirmed != true || !mounted) return;

    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Nichts wird geschrieben, der Timer stirbt mit dem Notifier.
    Navigator.of(context).pop();
  }

  Future<void> _finish() async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    final duration = _elapsed;
    setState(() {
      _ended = true;
      _clockState = _clockState.stopRest();
    });
    // Vor dem Schreiben, damit `toDraft` sie mitnimmt.
    _notifier.setFeeling(_feeling);
    // Der Zwischenstand hat seinen Zweck erfüllt.
    await const WorkoutDraftStore().clear();
    try {
      await _notifier.finish(duration);
      // Beim Nachtragen führt der Weg direkt zurück — es gibt keine
      // Zusammenfassung, auf die man noch schauen würde.
      if (mounted && _amends) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ended = false);
      // Über den gemeinsamen Kanal, nicht über Material: Nur so gilt dieselbe
      // Dauer und dieselbe Gestalt wie für jede andere Meldung.
      final message = AppL10n.of(context).workoutRunnerSavedFailed;
      ref.read(snackbarProvider.notifier).show(AtemSnack(
            message: message,
            semanticLabel: message,
          ));
    }
  }
}

/// Die vier Satztypen als farbige Pillen.
///
/// Vorher stand hier ein Satz — „W Aufwärmen · N Normal · D Dropsatz · F
/// Failure" —, der auf dem Gerät mitten in einem Begriff umbrach („F /
/// Failure"). Jede Pille trägt jetzt ihr Kürzel im Ton des Typs und das Wort
/// daneben; der `Wrap` bricht **zwischen** Pillen, nie in einer.
///
/// Ein Semantics-Knoten für alle vier: Vier einzelne Knoten wären beim
/// Durchwischen vier Stationen für eine Legende.
class _SetTypeLegend extends StatelessWidget {
  const _SetTypeLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      label: '${l10n.workoutSetTypeLegendTitle}: '
          '${l10n.workoutSetTypeLegend(
        SetType.warmup.longLabel(l10n),
        SetType.normal.longLabel(l10n),
        SetType.dropset.longLabel(l10n),
        SetType.failure.longLabel(l10n),
      )}',
      excludeSemantics: true,
      child: Wrap(
        spacing: AtemSpacing.sm,
        runSpacing: AtemSpacing.sm,
        children: [
          for (final type in SetType.values)
            Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AtemRadii.pill),
                border: Border.all(color: type.color.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AtemColors.surfaceSolid,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.shortLabel(l10n),
                      style: AtemType.labelUi.of(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: type.labelColor,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Flexibel, nicht starr: Bei 200 % Schrift ist „Aufwärmen"
                  // breiter als die Zeile, und eine Pille darf umbrechen —
                  // aber sie darf nicht über den Rand laufen.
                  Flexible(
                    child: Text(type.longLabel(l10n),
                        style: AtemType.meta.of(context)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Ein Abschnitt im Anleitungs-Blatt.
class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.lines,
    required this.numbered,
    this.accent = AtemColors.cyan,
  });

  final String title;
  final List<String> lines;

  /// Anleitungsschritte sind nummeriert, Cues und Fehler nicht — die
  /// Reihenfolge trägt dort keine Bedeutung.
  final bool numbered;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AtemSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(),
                style: AtemType.labelMicro.of(context)),
            const SizedBox(height: AtemSpacing.sm),
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: AtemSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      numbered ? '${i + 1}.' : '·',
                      style: AtemType.meta.of(context).copyWith(color: accent),
                    ),
                  ),
                  Expanded(
                    child: Text(lines[i],
                        style: AtemType.labelSmall.of(context)),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _TableHead extends StatelessWidget {
  const _TableHead({required this.isHold});

  /// Bei Halteübungen heißt die vierte Spalte „Halten" statt „Wdh".
  final bool isHold;

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

    // Dieselben Masse wie die Zeile darunter (SetRow) — vorher rechnete der
    // Kopf mit eigenen Zahlen, und die Beschriftungen standen neben ihren
    // Spalten.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SetRow.rowPadding, AtemSpacing.sm, SetRow.rowPadding, 6),
        child: Row(
          children: [
            cell(l10n.workoutRunnerTableSet, w: SetRow.typeWidth),
            const SizedBox(width: SetRow.columnGap),
            cell(l10n.workoutRunnerTableLast),
            const SizedBox(width: SetRow.columnGap),
            cell(l10n.workoutRunnerTableWeight,
                align: TextAlign.center, w: SetRow.weightWidth),
            const SizedBox(width: SetRow.columnGap),
            cell(
              isHold
                  ? l10n.workoutRunnerTableHold
                  : l10n.workoutRunnerTableReps,
              align: TextAlign.center,
              w: SetRow.repsWidth,
            ),
            const SizedBox(width: SetRow.columnGap),
            cell(l10n.workoutRunnerTableDone,
                align: TextAlign.center, w: SetRow.doneWidth),
          ],
        ),
      ),
    );
  }
}

/// Statistik im Beenden-Dialog — StatBox als Einlage, nie als eigene Karte.
/// Der Detailteil des Beenden-Dialogs: die Zahlen und **eine** Frage.
///
/// ## Warum die Frage hier steht und nicht in der Zusammenfassung
///
/// Die Zusammenfassung erscheint erst, wenn die Einheit schon geschrieben
/// ist. Eine Antwort von dort müsste nachgereicht werden — und ein
/// `SessionPatch` nur für das Gefühl löschte laut seinem eigenen Vertrag
/// Dauer und Notiz mit. Vor dem Schreiben gefragt, reist sie im Entwurf mit.
///
/// Der Dialog behält seine drei Wege (speichern, verwerfen, abbrechen). Die
/// Frage ist keiner davon: Sie ist überspringbar, und wer sie übergeht,
/// speichert genauso.
class _EndDetail extends StatefulWidget {
  const _EndDetail({
    required this.workout,
    required this.elapsed,
    required this.feeling,
    required this.onFeeling,
  });

  final ActiveWorkout workout;
  final String elapsed;
  final int? feeling;
  final ValueChanged<int?> onFeeling;

  @override
  State<_EndDetail> createState() => _EndDetailState();
}

class _EndDetailState extends State<_EndDetail> {
  late int? _value = widget.feeling;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _EndStats(workout: widget.workout, elapsed: widget.elapsed),
        const SizedBox(height: 16),
        AtemFieldLabel(label: l10n.formFeeling),
        FeelingChoice(
          value: _value,
          surface: AtemColors.surfaceSolid,
          onChanged: (v) {
            setState(() => _value = v);
            widget.onFeeling(v);
          },
        ),
      ],
    );
  }
}

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

/// Wie ein Workout endet.
enum _EndChoice { save, discard }
