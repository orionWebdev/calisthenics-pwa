import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/domain/training_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/cardio_providers.dart';
import '../../data/cardio_live_store.dart';
import '../cardio_ui.dart';
import '../widgets/activity_sheet.dart';
import 'cardio_form_screen.dart';

/// Live mitlaufen lassen — **Laufband, Indoor-Rad** (Board 11, B2/3).
///
/// Die Uhr ist die einzige laufende Zahl. **Kein GPS, keine
/// Standortabfrage**: Die Distanz kommt vom Gerätedisplay und kann jederzeit
/// korrigiert werden — auch nach dem Beenden, im Formular.
///
/// Der Zeitgeber hier misst nichts. Er löst nur das Neuzeichnen aus; die Zeit
/// kommt aus zwei Zeitpunkten in einer Datei ([CardioLiveStore]). Ob die App
/// im Hintergrund liegt oder der Prozess stirbt, ändert am Ergebnis nichts.
class CardioLiveScreen extends ConsumerStatefulWidget {
  const CardioLiveScreen({super.key});

  /// Unter dieser Dauer lässt sich nichts beenden — eine Einheit unter einer
  /// Minute ist ein Fehltap, keine Einheit.
  static const minimum = Duration(seconds: 60);

  @override
  ConsumerState<CardioLiveScreen> createState() => _CardioLiveScreenState();
}

class _CardioLiveScreenState extends ConsumerState<CardioLiveScreen> {
  Timer? _ticker;
  late final TextEditingController _distance;
  var _asked = false;

  /// Die Distanz wird **einmal** aus der Datei übernommen. Danach ist das
  /// Feld die Quelle und die Datei folgt ihm — sonst überschriebe jeder
  /// Zeitgeber-Tick ein halb getipptes „6,".
  var _distanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _distance = TextEditingController();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _distance.dispose();
    super.dispose();
  }

  /// Ohne laufende Uhr: zuerst die Aktivität, dann geht es los. Wer das
  /// Blatt schliesst, hat es sich anders überlegt — dann zurück.
  Future<void> _askActivity() async {
    if (_asked) return;
    _asked = true;
    final activity = await ActivitySheet.show(context);
    if (!mounted) return;
    if (activity == null) {
      Navigator.of(context).pop();
      return;
    }
    await ref.read(cardioLiveProvider.notifier).start(activity);
  }

  Future<void> _finish(CardioLiveDraft draft) async {
    final stopped = await ref.read(cardioLiveProvider.notifier).stop();
    if (!mounted || stopped == null) return;
    // Nach „Beenden" öffnet dasselbe Formular wie beim Nacherfassen,
    // vorbefüllt — es gibt nur ein Formular.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CardioFormScreen(
          prefill: CardioPrefill(
            activity: stopped.activity,
            duration: stopped.clock.elapsed(DateTime.now()),
            distanceText: stopped.distanceText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final live = ref.watch(cardioLiveProvider);

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.cardioLiveStart,
            style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: live.when(
          // Wiederaufnahme: Die Datei wird gelesen. Kurz, aber nicht null.
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AtemSpacing.screenPadding),
            child: AtemSkeleton(
              semanticLabel: l10n.commonLoading,
              blocks: const [AtemSkeletonBlock(height: 220)],
            ),
          ),
          // Die Uhr aus der Persistenz liess sich nicht lesen — neu beginnen.
          error: (_, __) => _Empty(onStart: _askActivity),
          data: (draft) {
            if (draft == null) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _askActivity());
              return _Empty(onStart: _askActivity);
            }
            if (!_distanceLoaded) {
              _distanceLoaded = true;
              _distance.text = draft.distanceText;
            }
            return _Running(
              draft: draft,
              distance: _distance,
              onDistanceChanged: (t) =>
                  ref.read(cardioLiveProvider.notifier).setDistance(t),
              onToggle: () =>
                  ref.read(cardioLiveProvider.notifier).togglePause(),
              onFinish: () => _finish(draft),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
      child: AtemEmptyState(
        title: l10n.cardioLiveStart,
        body: l10n.liveNogps,
        action: AtemButton.gradient(
          label: l10n.formActivity,
          semanticLabel: l10n.formActivity,
          expand: false,
          size: AtemButtonSize.compact,
          onPressed: onStart,
        ),
      ),
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({
    required this.draft,
    required this.distance,
    required this.onDistanceChanged,
    required this.onToggle,
    required this.onFinish,
  });

  final CardioLiveDraft draft;
  final TextEditingController distance;
  final ValueChanged<String> onDistanceChanged;
  final VoidCallback onToggle;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final now = DateTime.now();
    final elapsed = draft.clock.elapsed(now);
    final paused = draft.clock.isPaused;
    final state = paused ? l10n.liveStatePaused : l10n.liveStateRunning;
    final clock = formatClock(elapsed);
    final canFinish = elapsed >= CardioLiveScreen.minimum;
    final km = AtemNumberField.parse(distance.text);
    final tempo = CardioTempo.of(
      distanceKm: km,
      duration: elapsed,
      activity: draft.activity,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 32),
      children: [
        AtemCard.list(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(activityLabel(l10n, draft.activity),
                        style: AtemType.titleMedium.of(context)),
                  ),
                  const SizedBox(width: 10),
                  // Der Zustand als Wort neben dem Lime-Punkt — nie Farbe
                  // allein. Als Live-Region, höflich: angesagt wird nur ein
                  // Wechsel, nicht jede Sekunde.
                  Semantics(
                    liveRegion: true,
                    label: state,
                    child: AtemBadge(
                      label: state.toUpperCase(),
                      accent: paused ? AtemColors.textSecondary : AtemColors.green,
                      fill: AtemBadgeFill.tinted,
                      leadingDot: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Die Uhr mittig in ihrer eigenen Fläche (B2/3).
              AtemStatBox(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Text(l10n.commonDuration.toUpperCase(),
                        style: AtemType.labelMicro.of(context)),
                    const SizedBox(height: 6),
                    Semantics(
                      label: l10n.liveDurationA11y(clock, state),
                      child: ExcludeSemantics(
                        child: Text(
                          clock,
                          textAlign: TextAlign.center,
                          style: AtemType.valueLarge.of(context).copyWith(
                                fontSize: 40,
                                shadows: AtemGlow.text(AtemColors.cyan),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.liveStarted(DateFormat.Hm(languageTag(context))
                          .format(draft.clock.startedAt)),
                      style: AtemType.meta.of(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AtemButton.outline(
                      label: paused ? l10n.liveResume : l10n.livePause,
                      semanticLabel: paused ? l10n.liveResume : l10n.livePause,
                      onPressed: onToggle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AtemButton.gradient(
                      label: l10n.liveStop,
                      // Gesperrt mit Grund: „Beenden, nicht möglich —
                      // Einheit unter einer Minute."
                      semanticLabel:
                          canFinish ? l10n.liveStop : l10n.liveStopTooShort,
                      size: AtemButtonSize.compact,
                      onPressed: canFinish ? onFinish : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AtemFieldLabel(label: l10n.liveDistanceManual),
        AtemNumberField(
          controller: distance,
          semanticLabel: l10n.liveDistanceManual,
          width: null,
          decimal: true,
          suffix: l10n.liveDistanceSource,
          textInputAction: TextInputAction.done,
          onChanged: onDistanceChanged,
        ),
        const SizedBox(height: 14),
        TempoOutput(
          tempo: tempo,
          label: l10n.formPace,
          note: l10n.livePaceRunning,
        ),
        const SizedBox(height: 18),
        _InfoLine(text: l10n.liveNogps),
      ],
    );
  }
}

/// Die Hinweiszeile — der Notice-Slot aus Modul 2 in Grau.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        label: text,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AtemColors.border),
                ),
                child: Text('i',
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0, height: 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: AtemType.labelSmall.of(context)),
              ),
            ],
          ),
        ),
      );
}
