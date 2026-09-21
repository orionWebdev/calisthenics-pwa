import 'dart:async';

import 'package:flutter/material.dart' show Icons, showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/heart_rate_zones.dart';
import 'zone_bars.dart';

/// Eine Grenze ändern — **ein Blatt, ein Stepper** (Board 16, D3).
///
/// Gibt die neuen Zonen zurück oder `null`, wenn abgebrochen wurde. Das Blatt
/// schreibt nichts: Wer es öffnet, entscheidet, ob gespeichert wird.
///
/// ## Was das Blatt zeigt
///
/// Die zwei Zonen, die an dieser Grenze liegen, und wie sich ihre Bereiche
/// verschieben — live, mit jedem Schritt. Man sieht, was man verschiebt,
/// bevor man es übernimmt.
///
/// ## Die Schranke steht als Satz, nicht als gesperrter Knopf
///
/// „Höchstens 148 bpm — Grenze 3 liegt auf 149." `+` tut bei 148 nichts mehr,
/// und der Grund stand vorher da. Ein ausgegrauter Knopf ohne Begründung wäre
/// die schlechtere Antwort: Man fragt sich, was man falsch macht.
Future<HeartRateZones?> showBoundarySheet(
  BuildContext context, {
  required HeartRateZones zones,
  required int index,
  int? hrMax,
}) {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<HeartRateZones>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: (_) => _BoundarySheet(zones: zones, index: index, hrMax: hrMax),
  );
}

class _BoundarySheet extends StatefulWidget {
  const _BoundarySheet({
    required this.zones,
    required this.index,
    required this.hrMax,
  });

  final HeartRateZones zones;
  final int index;
  final int? hrMax;

  @override
  State<_BoundarySheet> createState() => _BoundarySheetState();
}

class _BoundarySheetState extends State<_BoundarySheet> {
  late HeartRateZones _zones = widget.zones;

  int get _value => _zones.bounds[widget.index];

  void _step(int delta) {
    final next = _zones.withBoundary(widget.index, _value + delta);
    if (next == _zones) return;
    setState(() => _zones = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final index = widget.index;
    final lowerZone = index + 1;
    final upperZone = index + 2;
    final hrMax = widget.hrMax;

    final atMin = _value <= _zones.minFor(index);

    // **Nur der Grund, der gerade gilt.** Steht die Grenze an einer
    // Schranke, sagt der Satz welche; sonst der obere, weil man in aller
    // Regel nach oben schiebt.
    final limit = atMin
        ? l10n.settingsZonesLowerLimit(_zones.minFor(index))
        : l10n.settingsZonesBoundaryLimit(_zones.maxFor(index));

    return AtemSheet.content(
      title: l10n.settingsZonesBoundaryTitle(index + 1),
      closeLabel: l10n.stepPadClose,
      primaryAction: AtemButton.gradient(
        label: l10n.sheetPickerApply,
        semanticLabel: l10n.sheetPickerApply,
        onPressed: () => Navigator.of(context).pop(_zones),
      ),
      secondaryAction: AtemButton.ghost(
        label: l10n.commonCancel,
        semanticLabel: l10n.commonCancel,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsZonesBetween(lowerZone, upperZone),
            style: AtemType.labelMicro.of(context),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                semanticLabel: l10n.settingsZonesMinusA11y,
                onStep: () => _step(-1),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: '$_value bpm',
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text('$_value',
                            textAlign: TextAlign.center,
                            style: AtemType.valueLarge
                                .of(context)
                                .copyWith(fontSize: 24)),
                        const SizedBox(height: 2),
                        Text(
                          hrMax == null
                              ? l10n.settingsZonesStepperCaptionBpm
                              : l10n.settingsZonesStepperCaption(
                                  (_value * 100 / hrMax).round(), hrMax),
                          textAlign: TextAlign.center,
                          style: AtemType.meta.of(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                semanticLabel: l10n.settingsZonesPlusA11y,
                onStep: () => _step(1),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Die zwei betroffenen Zonen — sie wachsen und schrumpfen mit.
          _AffectedZone(zones: _zones, zone: lowerZone, of: index),
          const SizedBox(height: 10),
          _AffectedZone(zones: _zones, zone: upperZone, of: index),
          const SizedBox(height: 16),
          Text(limit,
              style: AtemType.meta.of(context),
              // Der Grund ist Teil der Bedienung, nicht Fussnote.
              semanticsLabel: limit),
        ],
      ),
    );
  }
}

/// Eine der beiden Zonen an der Grenze: Name, Bereich und eine Spur, deren
/// Länge die Breite des Bereichs ist.
class _AffectedZone extends StatelessWidget {
  const _AffectedZone({
    required this.zones,
    required this.zone,
    required this.of,
  });

  final HeartRateZones zones;
  final int zone;

  /// Die Grenze, an der beide Zonen liegen.
  final int of;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final lower = zones.lowerOf(zone);
    final upper = zones.upperOf(zone);
    final range = switch ((lower, upper)) {
      (null, final u?) => l10n.detailZoneRangeUpto(u + 1),
      (final low?, null) => l10n.detailZoneRangeFrom(low),
      (final low?, final u?) => l10n.detailZoneRange(low, u),
      _ => '',
    };
    // **Beide Spuren teilen sich dieselbe Spanne**: die vom Anfang der einen
    // bis zum Ende der anderen. Sie bleibt beim Schieben gleich lang, also
    // wächst die eine genau um das, was die andere verliert — man sieht,
    // was man verschiebt. Ohne Zahl, die behauptet, wie breit „richtig" wäre.
    final low = zones.bounds[of];
    final start = of == 0 ? HeartRateZones.minBoundary : zones.bounds[of - 1];
    final end = of == HeartRateZones.boundaryCount - 1
        ? HeartRateZones.maxBoundary
        : zones.bounds[of + 1];
    final total = (end - start).clamp(1, 1000);
    final width = (zone == of + 1 ? low - start : end - low) / total;

    return Semantics(
      label: '${l10n.detailZoneName(zone)}, $range',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.detailZoneName(zone),
                    style: AtemType.titleSmallOrDefault(context)),
                const Spacer(),
                Text(range, style: AtemType.meta.of(context)),
              ],
            ),
            const SizedBox(height: 6),
            ZoneTrack(
              fraction: width,
              height: 10,
              // Rückmeldung auf einen Tipp: 120 ms, kein Nachfedern.
              duration: const Duration(milliseconds: 120),
            ),
          ],
        ),
      ),
    );
  }
}

/// − oder +: ein Tipp ein Schritt, **Halten wiederholt**.
///
/// 48 × 48 dp, wie jedes Ziel. Das Wiederholen ist kein zweiter Weg zur
/// selben Aktion, sondern die einzige Möglichkeit, von 131 nach 148 zu
/// kommen, ohne siebzehnmal zu tippen — und für Menschen, die nicht tippen,
/// bleibt die Semantik-Aktion „tippen" ein einzelner Schritt.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onStep,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _delay;
  Timer? _repeat;

  /// Ob dieses Halten schon wiederholt hat. Dann ist das Loslassen kein
  /// weiterer Tipp — sonst käme zu jedem Halten ein Schritt dazu.
  bool _repeated = false;

  static const _holdDelay = Duration(milliseconds: 400);
  static const _interval = Duration(milliseconds: 70);

  void _start() {
    _repeated = false;
    _delay?.cancel();
    _delay = Timer(_holdDelay, () {
      _repeated = true;
      widget.onStep();
      _repeat = Timer.periodic(_interval, (_) => widget.onStep());
    });
  }

  void _stop() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: AtemTappable(
          onTap: () {
            if (_repeated) {
              _repeated = false;
              return;
            }
            widget.onStep();
          },
          semanticLabel: widget.semanticLabel,
          minTapSize: const Size(48, 48),
          alignment: Alignment.center,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AtemColors.surfaceSolid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AtemColors.border),
            ),
            child: Icon(widget.icon, size: 22, color: AtemColors.cyan),
          ),
        ),
      );
}
