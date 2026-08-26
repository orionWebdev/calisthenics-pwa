import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/workout_providers.dart';
import '../../domain/workout_session.dart';
import '../set_type_ui.dart';

/// ATEM — Workout Runner.
///
/// Umsetzung von „TEM Workout Runner.dc.html". Minimiert kognitive Last im
/// Training: große Tap-Ziele (≥44 px) im unteren Bilddrittel, Haptik statt
/// Hinsehen, Auto-Pausen-Timer.
///
/// Die Trainingsdaten kommen aus [workoutSessionProvider]; hier leben nur die
/// Timer und die Text-Controller, die am Widget-Lebenszyklus hängen.
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

  int _elapsed = 0;
  bool _paused = false;
  bool _ended = false;
  int _exIndex = 0;

  bool _restOn = false;
  int _restLeft = 0;
  int _restTotal = 90;
  bool _restCompact = false;

  final _notesCtrl = TextEditingController();

  /// Ein Controller-Paar pro Satz, adressiert über die Satz-ID.
  final _weightCtrls = <String, TextEditingController>{};
  final _repsCtrls = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandTimer?.cancel();
    _notesCtrl.dispose();
    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    for (final c in _repsCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _tick() {
    if (_paused || _ended) return;
    setState(() {
      _elapsed++;
      if (_restOn) {
        _restLeft--;
        if (_restLeft <= 0) {
          _restOn = false;
          _restLeft = 0;
          _onRestDone();
        }
      }
    });
  }

  /// Timer-Ablauf: dreimal spürbar vibrieren, dann Systemton — der Blick
  /// bleibt beim Training.
  Future<void> _onRestDone() async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    await SystemSound.play(SystemSoundType.alert);
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}'
      ':${(s % 60).toString().padLeft(2, '0')}';

  TextEditingController _ctrl(
      Map<String, TextEditingController> pool, String id, String initial) {
    return pool.putIfAbsent(id, () => TextEditingController(text: initial));
  }

  void _onToggleSet(ActiveWorkout w, WorkoutSet s) {
    FocusScope.of(context).unfocus();
    final nowDone = ref
        .read(workoutSessionProvider(widget.sessionId).notifier)
        .toggleSet(_exIndex, s.id);
    if (!nowDone) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _restTotal = w.defaultRestSeconds;
      _restLeft = _restTotal;
      _restOn = true;
      _restCompact = false;
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
    final async = ref.watch(workoutSessionProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: AtemColors.base,
      resizeToAvoidBottomInset: false,
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => _ErrorState(
          message: '$e',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        data: (w) => _buildRunner(w),
      ),
    );
  }

  Widget _buildRunner(ActiveWorkout w) {
    final exercise = w.exercises[_exIndex.clamp(0, w.exercises.length - 1)];

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(w),
                  const SizedBox(height: 14),
                  _exerciseHeader(w, exercise),
                  const SizedBox(height: 6),
                  _tableHead(),
                  for (final s in exercise.sets) _setRow(w, s),
                  const SizedBox(height: 10),
                  _addSetButton(),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '${w.completedSets} VON ${w.totalSets} SÄTZEN ABGESCHLOSSEN',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 8.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_restOn && !_ended)
          Positioned(left: 14, right: 14, bottom: 16, child: _restBar()),
        if (_ended) _endedOverlay(w),
      ],
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _topBar(ActiveWorkout w) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SESSION', style: text.labelSmall?.copyWith(letterSpacing: 2)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _paused ? AtemColors.textSecondary : AtemColors.green,
                    boxShadow: _paused ? null : AtemGlow.dot(AtemColors.green),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _fmt(_elapsed),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AtemColors.textPrimary,
                    // Tabular: die Ziffern springen im Sekundentakt nicht.
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _iconButton(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: _paused ? AtemColors.green : AtemColors.textSecondary,
              onTap: () => setState(() => _paused = !_paused),
            ),
            const SizedBox(width: 8),
            _iconButton(
              icon: Icons.edit_note_rounded,
              color: AtemColors.textSecondary,
              onTap: () => _openNotes(w),
            ),
            const SizedBox(width: 8),
            _iconButton(
              icon: Icons.close_rounded,
              color: AtemColors.magenta,
              background: AtemColors.magenta.withValues(alpha: 0.10),
              border: AtemColors.magenta.withValues(alpha: 0.45),
              onTap: () => _confirmEnd(w),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color? background,
    Color? border,
  }) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background ?? AtemColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border ?? AtemColors.border),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  // ── Übungs-Header ─────────────────────────────────────────────────────────

  Widget _exerciseHeader(ActiveWorkout w, WorkoutExercise ex) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtemColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtemColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _arrowButton(Icons.chevron_left_rounded, _exIndex > 0,
                  () => setState(() => _exIndex--)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ÜBUNG ${_exIndex + 1} / ${w.exercises.length}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 8, color: AtemColors.cyan),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ex.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: AtemColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _arrowButton(
                Icons.chevron_right_rounded,
                _exIndex < w.exercises.length - 1,
                () => setState(() => _exIndex++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final m in ex.muscles) _chip(m, AtemColors.violet),
              _chip(ex.recordLabel, AtemColors.green),
              _chip('FORM GUIDE', AtemColors.cyan,
                  filled: true, icon: Icons.play_arrow_rounded, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrowButton(IconData icon, bool enabled, VoidCallback onTap) {
    return _Tappable(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AtemColors.surfaceSolid,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AtemColors.border),
          ),
          child: Icon(icon, size: 24, color: AtemColors.textPrimary),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color,
      {bool filled = false, IconData? icon, VoidCallback? onTap}) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.08) : null,
          borderRadius: AtemRadii.pillR,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon statt „▶": Android rendert U+25B6 als Emoji-Glyphe.
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Satz-Tabelle ──────────────────────────────────────────────────────────

  Widget _tableHead() {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(fontSize: 7.5, letterSpacing: 1.5);
    Widget h(String t, {TextAlign align = TextAlign.left}) =>
        Text(t, textAlign: align, style: style);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
      child: Row(
        children: [
          SizedBox(width: 34, child: h('SATZ')),
          const SizedBox(width: 8),
          Expanded(child: h('LETZTES MAL')),
          const SizedBox(width: 8),
          SizedBox(width: 66, child: h('KG', align: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 54, child: h('WDH', align: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 46, child: h('OK', align: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _setRow(ActiveWorkout w, WorkoutSet s) {
    final notifier =
        ref.read(workoutSessionProvider(widget.sessionId).notifier);
    final tc = s.type.color;
    final labelColor = s.type.labelColor;
    final isNeutral = s.type == SetType.normal;

    return AnimatedContainer(
      duration: AtemMotion.normal,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: s.done
            ? AtemColors.green.withValues(alpha: 0.07)
            : AtemColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.done
              ? AtemColors.green.withValues(alpha: 0.35)
              : AtemColors.border,
        ),
      ),
      child: Row(
        children: [
          // Satz-Typ — Tap zykliert W → N → D → F, gesperrt wenn abgehakt.
          _Tappable(
            onTap: s.done ? null : () => notifier.cycleType(_exIndex, s.id),
            child: Container(
              width: 34,
              height: 32,
              decoration: BoxDecoration(
                color: s.done
                    ? Colors.transparent
                    : (isNeutral
                        ? AtemColors.surfaceSolid
                        : tc.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.done || isNeutral
                      ? AtemColors.border
                      : tc.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                s.type.shortLabel(AppL10n.of(context)),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: s.done ? AtemColors.textSecondary : labelColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.previousLabel,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 8),
          _numField(
            controller: _ctrl(_weightCtrls, s.id, s.weight),
            locked: s.done,
            decimal: true,
            onChanged: (v) => notifier.updateWeight(_exIndex, s.id, v),
          ),
          const SizedBox(width: 8),
          _numField(
            controller: _ctrl(_repsCtrls, s.id, s.reps),
            locked: s.done,
            width: 54,
            onChanged: (v) => notifier.updateReps(_exIndex, s.id, v),
          ),
          const SizedBox(width: 8),
          // Häkchen — 44×44 Tap-Ziel, erneuter Tap entsperrt wieder.
          _Tappable(
            onTap: () => _onToggleSet(w, s),
            child: AnimatedContainer(
              duration: AtemMotion.fast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: s.done ? AtemColors.green : AtemColors.surfaceSolid,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: s.done ? AtemColors.green : const Color(0xFF3A3A52),
                ),
                boxShadow: s.done
                    ? [
                        BoxShadow(
                          color: AtemColors.green.withValues(alpha: 0.7),
                          blurRadius: 18,
                          spreadRadius: -2,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 22,
                color: s.done ? AtemColors.base : AtemColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required bool locked,
    required ValueChanged<String> onChanged,
    bool decimal = false,
    double width = 66,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );

    return SizedBox(
      width: width,
      height: 44,
      child: TextField(
        controller: controller,
        enabled: !locked,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: locked ? Colors.transparent : AtemColors.surfaceSolid,
          contentPadding: EdgeInsets.zero,
          enabledBorder: border(AtemColors.border),
          disabledBorder: border(AtemColors.border),
          focusedBorder: border(AtemColors.cyan.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _addSetButton() {
    return _Tappable(
      onTap: () => ref
          .read(workoutSessionProvider(widget.sessionId).notifier)
          .addSet(_exIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtemColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '+ SATZ HINZUFÜGEN',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11.5,
                letterSpacing: 1,
                color: AtemColors.textSecondary,
              ),
        ),
      ),
    );
  }

  // ── Pausen-Timer ──────────────────────────────────────────────────────────

  Widget _restBar() {
    return AnimatedContainer(
      duration: AtemMotion.normal,
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: _restCompact ? 8 : 14),
      decoration: BoxDecoration(
        color: AtemColors.surfaceSolid.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AtemColors.cyan.withValues(alpha: 0.4)),
        boxShadow: [
          const BoxShadow(
              color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
          BoxShadow(
            color: AtemColors.cyan.withValues(alpha: 0.5),
            blurRadius: 26,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAUSE',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontSize: 7.5, color: AtemColors.cyan),
                  ),
                  Text(
                    _fmt(_restLeft),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: AtemColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: _restTotal == 0 ? 0 : _restLeft / _restTotal,
                    minHeight: 5,
                    backgroundColor: AtemColors.track,
                    valueColor: const AlwaysStoppedAnimation(AtemColors.cyan),
                  ),
                ),
              ),
            ],
          ),
          if (!_restCompact) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: _restButton(
                    '−15s',
                    () => setState(
                        () => _restLeft = _restLeft > 15 ? _restLeft - 15 : 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _restButton('+30s', () {
                    setState(() {
                      _restLeft += 30;
                      _restTotal += 30;
                    });
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _Tappable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _restOn = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        borderRadius: AtemRadii.pillR,
                        gradient: LinearGradient(
                            colors: [AtemColors.cyan, AtemColors.violet]),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SKIP →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AtemColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _restButton(String label, VoidCallback onTap) {
    return _Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: AtemRadii.pillR,
          border: Border.all(color: AtemColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AtemColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Notizen ───────────────────────────────────────────────────────────────

  void _openNotes(ActiveWorkout w) {
    _notesCtrl.text = w.notes;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AtemColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: AtemRadii.sheetR),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 18, 16, 26 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SESSION-NOTIZEN',
              style: Theme.of(ctx)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 9, color: AtemColors.cyan),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              autofocus: true,
              style:
                  const TextStyle(fontSize: 13, color: AtemColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Wie fühlt sich die Session an?',
                filled: true,
                fillColor: AtemColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AtemColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Tappable(
              onTap: () {
                ref
                    .read(workoutSessionProvider(widget.sessionId).notifier)
                    .setNotes(_notesCtrl.text);
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  borderRadius: AtemRadii.pillR,
                  gradient: AtemGradients.neonWave,
                ),
                alignment: Alignment.center,
                child: Text('FERTIG',
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 11.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Beenden ───────────────────────────────────────────────────────────────

  void _confirmEnd(ActiveWorkout w) {
    showDialog<void>(
      context: context,
      barrierColor: AtemColors.base.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: AtemColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AtemColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Workout beenden?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AtemColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '${w.completedSets} von ${w.totalSets} Sätzen abgeschlossen · '
                '${_fmt(_elapsed)}\nDein Fortschritt wird gespeichert.',
                textAlign: TextAlign.center,
                style:
                    Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 16),
              _Tappable(
                onTap: () => _finish(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: AtemRadii.pillR,
                    gradient: AtemGradients.brandCta,
                    boxShadow: AtemGlow.soft(AtemColors.magenta, opacity: 0.7),
                  ),
                  alignment: Alignment.center,
                  child: Text('BEENDEN & SPEICHERN',
                      style: Theme.of(ctx)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontSize: 11.5)),
                ),
              ),
              const SizedBox(height: 9),
              _Tappable(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: AtemRadii.pillR,
                    border: Border.all(color: AtemColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Weiter trainieren',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AtemColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    HapticFeedback.mediumImpact();
    setState(() {
      _ended = true;
      _restOn = false;
    });
    try {
      await ref
          .read(workoutSessionProvider(widget.sessionId).notifier)
          .finish(Duration(seconds: _elapsed));
    } catch (e) {
      if (!mounted) return;
      setState(() => _ended = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  Widget _endedOverlay(ActiveWorkout w) {
    return Container(
      color: AtemColors.base.withValues(alpha: 0.85),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AtemColors.green.withValues(alpha: 0.35)),
          boxShadow: AtemGlow.soft(AtemColors.green, opacity: 0.45),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AtemColors.green.withValues(alpha: 0.12),
                border:
                    Border.all(color: AtemColors.green.withValues(alpha: 0.5)),
                boxShadow: AtemGlow.soft(AtemColors.green, opacity: 0.6),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 26, color: AtemColors.green),
            ),
            const SizedBox(height: 14),
            const Text(
              'Session gespeichert',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AtemColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '${w.completedSets} SÄTZE · ${_fmt(_elapsed)} · '
              '${w.totalVolume.round()} KG VOLUMEN',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 18),
            _Tappable(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  borderRadius: AtemRadii.pillR,
                  gradient: AtemGradients.neonWave,
                ),
                alignment: Alignment.center,
                child: Text('FERTIG',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 11.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kein Material-Ripple — Scale statt Welle, wie im Design festgelegt.
class _Tappable extends StatefulWidget {
  const _Tappable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: AtemMotion.fast,
        child: widget.child,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WORKOUT NICHT VERFÜGBAR',
                style: text.labelMedium?.copyWith(color: AtemColors.magenta)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: text.bodySmall),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onBack, child: const Text('ZURÜCK')),
          ],
        ),
      ),
    );
  }
}
