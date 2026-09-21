import 'package:flutter/material.dart'
    show TextInputAction, showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/heart_rate_zones.dart';

Future<T?> _show<T>(BuildContext context, WidgetBuilder builder) {
  final l10n = AppL10n.of(context);
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: AtemOverlays.barrier(AtemOverlays.sheetBarrierOpacity),
    barrierLabel: l10n.stepPadClose,
    showDragHandle: false,
    builder: builder,
  );
}

/// HFmax eintragen — **nur, was jemand selbst weiss.**
///
/// ATEM schätzt ihn nicht: „220 minus Alter" wäre eine erfundene Angabe mit
/// ±20 bpm Streuung, und auf ihr stünden fünf Zonen und jede Verteilung
/// (Board 16, Entscheidung 13). Der Satz unter dem Feld sagt das, damit
/// niemand nach einer Schätzung sucht.
Future<int?> showHrMaxSheet(BuildContext context, {int? current}) =>
    _show<int>(context, (_) => _HrMaxSheet(current: current));

class _HrMaxSheet extends StatefulWidget {
  const _HrMaxSheet({this.current});

  final int? current;

  @override
  State<_HrMaxSheet> createState() => _HrMaxSheetState();
}

class _HrMaxSheetState extends State<_HrMaxSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null) return null;
    final v = parsed.round();
    return v >= HeartRateZones.minHrMax && v <= HeartRateZones.maxHrMax
        ? v
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final value = _value;
    const min = HeartRateZones.minHrMax;
    const max = HeartRateZones.maxHrMax;

    return AtemSheet.content(
      title: l10n.settingsZonesHrMaxTitle,
      closeLabel: l10n.stepPadClose,
      primaryAction: AtemButton.gradient(
        label: l10n.settingsZonesHrMaxSave,
        // **Der Grund steht im Label.** Ein deaktivierter Knopf ohne ihn wäre
        // für einen Screenreader nur „nicht verfügbar".
        semanticLabel: value == null
            ? l10n.settingsZonesHrMaxInvalid(min, max)
            : l10n.settingsZonesHrMaxSave,
        onPressed:
            value == null ? null : () => Navigator.of(context).pop(value),
      ),
      secondaryAction: AtemButton.ghost(
        label: l10n.commonCancel,
        semanticLabel: l10n.commonCancel,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtemFieldLabel(label: l10n.settingsZonesHrMaxField),
          const SizedBox(height: 8),
          AtemNumberField.large(
            controller: _controller,
            semanticLabel: l10n.settingsZonesHrMaxField,
            suffix: 'bpm',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(l10n.settingsZonesHrMaxRange(min, max),
              style: AtemType.meta.of(context)),
        ],
      ),
    );
  }
}

/// Vier Grenzen von Hand — der Weg **ohne** Vorschlag.
///
/// Kein Vorbelegen: Was hier steht, hat jemand hingeschrieben. Der Knopf
/// bleibt aus, bis die vier Werte eine gültige Folge sind, und sein Label
/// nennt, welche Grenze fehlt. Damit gibt es auch hier keinen ungültigen
/// Zustand, der gespeichert werden könnte.
Future<HeartRateZones?> showBoundsSheet(BuildContext context,
        {HeartRateZones? current}) =>
    _show<HeartRateZones>(context, (_) => _BoundsSheet(current: current));

class _BoundsSheet extends StatefulWidget {
  const _BoundsSheet({this.current});

  final HeartRateZones? current;

  @override
  State<_BoundsSheet> createState() => _BoundsSheetState();
}

class _BoundsSheetState extends State<_BoundsSheet> {
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < HeartRateZones.boundaryCount; i++)
      TextEditingController(text: widget.current?.bounds[i].toString() ?? ''),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<int?> get _values => [
        for (final c in _controllers) int.tryParse(c.text.trim()),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final values = _values;

    final missing = values.where((v) => v == null).length;
    HeartRateZones? zones;
    // Die erste Grenze, die nicht über der vorigen liegt — sie wird genannt.
    int? offender;
    if (missing == 0) {
      final ints = [for (final v in values) v!];
      zones = HeartRateZones.tryFrom(ints);
      if (zones == null) {
        for (var i = 1; i < ints.length; i++) {
          if (ints[i] <= ints[i - 1]) {
            offender = i;
            break;
          }
        }
        // Sonst liegt es an den äusseren Schranken.
        offender ??= ints.first < HeartRateZones.minBoundary ? 0 : 3;
      }
    }

    final reason = missing > 0
        ? l10n.settingsZonesBoundsMissing(missing)
        : offender != null && offender > 0
            ? l10n.settingsZonesBoundsInvalid(offender + 1, offender)
            : null;

    return AtemSheet.content(
      title: l10n.settingsZonesBoundsTitle,
      closeLabel: l10n.stepPadClose,
      primaryAction: AtemButton.gradient(
        label: l10n.commonSave,
        semanticLabel: zones == null
            ? (reason ?? l10n.settingsZonesBoundsMissing(0))
            : l10n.commonSave,
        onPressed:
            zones == null ? null : () => Navigator.of(context).pop(zones),
      ),
      secondaryAction: AtemButton.ghost(
        label: l10n.commonCancel,
        semanticLabel: l10n.commonCancel,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.settingsZonesBoundsRule, style: AtemType.meta.of(context)),
          const SizedBox(height: 16),
          for (var i = 0; i < HeartRateZones.boundaryCount; i++) ...[
            AtemFieldLabel(label: l10n.settingsZonesBoundsField(i + 1)),
            const SizedBox(height: 6),
            AtemNumberField.large(
              controller: _controllers[i],
              semanticLabel: l10n.settingsZonesBoundsField(i + 1),
              suffix: 'bpm',
              hasError: offender == i && i > 0,
              textInputAction: i == HeartRateZones.boundaryCount - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],
          if (offender != null && offender > 0)
            Text(reason!, style: AtemType.meta.of(context)),
        ],
      ),
    );
  }
}
