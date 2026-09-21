import 'package:flutter/material.dart' show AppBar, Icons, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/application/snackbar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../health_import/application/health_import_providers.dart';
import '../../../health_import/domain/health_session.dart';
import '../../../history/presentation/session_ui.dart';
import '../../application/pulse_providers.dart';
import '../../domain/heart_rate_zones.dart';
import '../widgets/boundary_sheet.dart';
import '../widgets/hr_input_sheets.dart';

/// Die Herzfrequenzzonen in den Einstellungen (Board 16, D).
///
/// ## Vier Zustände, kein fünfter
///
/// - **Festgelegt** (D1): Zonen und Grenzen im Wechsel — die Zone nennt ihren
///   Bereich und ist nicht tippbar, die Grenze ist das Ziel.
/// - **Nicht festgelegt** (D2): zwei Wege, **kein Vorbelegen**.
/// - **Grenze ändern** (D3): ein Blatt, ein Stepper.
/// - **HFmax fehlt** (D4): ein Vorschlag braucht ihn; der Fehler nennt beide
///   Auswege und schliesst keinen ab.
///
/// ## Ohne Fehlerzustand für die Grenzen
///
/// Bearbeitet werden vier Grenzen, keine fünf Bereiche — Lücken und
/// Überlappungen sind durch die Konstruktion unmöglich.
class HeartRateZonesScreen extends ConsumerStatefulWidget {
  const HeartRateZonesScreen({super.key});

  @override
  ConsumerState<HeartRateZonesScreen> createState() =>
      _HeartRateZonesScreenState();
}

class _HeartRateZonesScreenState extends ConsumerState<HeartRateZonesScreen> {
  /// D4: Der Vorschlag wurde gewählt, aber HFmax fehlt.
  bool _needsHrMax = false;

  Future<void> _save(HeartRateZones zones, {String? message}) async {
    final l10n = AppL10n.of(context);
    final snack = ref.read(snackbarProvider.notifier);
    await ref.read(heartRateControllerProvider).setZones(zones);
    if (!mounted) return;
    setState(() => _needsHrMax = false);
    snack.show(AtemSnack(
      message: message ?? l10n.settingsZonesSaved,
      semanticLabel: l10n.settingsZonesSaved,
      tone: AtemSnackTone.success,
    ));
  }

  Future<void> _propose() async {
    final settings = ref.read(heartRateSettingsProvider);
    final l10n = AppL10n.of(context);
    final hrMax = settings.hrMax;
    if (hrMax == null) {
      setState(() => _needsHrMax = true);
      return;
    }
    final proposal = HeartRateZones.proposalFor(hrMax);
    if (proposal == null) {
      setState(() => _needsHrMax = true);
      return;
    }
    await _save(proposal, message: l10n.settingsZonesProposalDone);
  }

  Future<void> _enterHrMax() async {
    final current = ref.read(heartRateSettingsProvider).hrMax;
    final value = await showHrMaxSheet(context, current: current);
    if (value == null || !mounted) return;
    await ref.read(heartRateControllerProvider).setHrMax(value);
    if (!mounted) return;
    setState(() => _needsHrMax = false);
  }

  Future<void> _setBounds() async {
    final zones = await showBoundsSheet(context,
        current: ref.read(heartRateZonesProvider));
    if (zones == null || !mounted) return;
    await _save(zones);
  }

  Future<void> _editBoundary(HeartRateZones zones, int index) async {
    final next = await showBoundarySheet(
      context,
      zones: zones,
      index: index,
      hrMax: ref.read(heartRateSettingsProvider).hrMax,
    );
    if (next == null || next == zones || !mounted) return;
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(heartRateSettingsProvider);
    final zones = settings.zones;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.settingsZonesTitle,
            style: AtemType.titleLarge.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 4, AtemSpacing.screenPadding, 40),
          children: [
            if (zones != null)
              _Set(
                zones: zones,
                onBoundary: (i) => _editBoundary(zones, i),
                onHrMax: _enterHrMax,
              )
            else
              _Unset(
                needsHrMax: _needsHrMax,
                onBounds: _setBounds,
                onPropose: _propose,
                onHrMax: _enterHrMax,
              ),
          ],
        ),
      ),
    );
  }
}

/// Die HFmax-Zeile — Auskunft und Weg zugleich.
class _HrMaxLine extends ConsumerWidget {
  const _HrMaxLine({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(heartRateSettingsProvider);
    final hrMax = settings.hrMax;
    if (hrMax == null) return const SizedBox.shrink();
    final at = settings.hrMaxSetAt;
    final date =
        at == null ? '' : DateFormat.MMMd(languageTag(context)).format(at);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AtemTappable(
        onTap: onTap,
        semanticLabel: l10n.settingsZonesHrMaxA11y(hrMax, date),
        minTapSize: const Size(0, 48),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.settingsZonesHrMaxLine(hrMax, date),
                style: AtemType.meta.of(context),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AtemColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// D2 und D4 — nichts festgelegt.
class _Unset extends StatelessWidget {
  const _Unset({
    required this.needsHrMax,
    required this.onBounds,
    required this.onPropose,
    required this.onHrMax,
  });

  final bool needsHrMax;
  final VoidCallback onBounds;
  final VoidCallback onPropose;
  final VoidCallback onHrMax;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needsHrMax)
          // D4: Der Fehler nennt beide Auswege und schliesst keinen ab.
          // Der Satz trägt die ganze Aussage: Ein Titel „Herzfrequenzzonen"
          // darüber wiederholte die Überschrift des Bildschirms.
          AtemNotice(
            title: l10n.settingsZonesNoHrmax,
            body: '',
            tone: AtemNoticeTone.error,
            semanticLabel: l10n.settingsZonesNoHrmax,
          )
        else
          Text(l10n.settingsZonesUnsetNote, style: AtemType.body.of(context)),
        const SizedBox(height: 16),
        if (needsHrMax) ...[
          _PathRow(
            label: l10n.settingsZonesHrMaxEnter,
            onTap: onHrMax,
          ),
          const SizedBox(height: 10),
          _PathRow(label: l10n.settingsZonesSetBounds, onTap: onBounds),
          const SizedBox(height: 12),
          Text(l10n.settingsZonesKeepNote, style: AtemType.meta.of(context)),
        ] else ...[
          _PathRow(label: l10n.settingsZonesSetBounds, onTap: onBounds),
          const SizedBox(height: 10),
          _PathRow(label: l10n.settingsZonesProposal, onTap: onPropose),
          const SizedBox(height: 10),
          // **Startpunkt, keine Empfehlung** — im Fusstext selbst gesagt.
          // Ohne Angebot legt niemand vier Grenzen von Hand fest; mit Angebot
          // ohne dieses Wort wäre es eine Empfehlung, die die App nicht
          // geben darf.
          Text(l10n.settingsZonesProposalNote,
              style: AtemType.meta.of(context)),
          _HrMaxLine(onTap: onHrMax),
        ],
      ],
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: label,
        minTapSize: const Size(0, 56),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AtemColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  // Cyan trägt Handlung: Diese Zeile ist ein Weg.
                  style: AtemType.body
                      .of(context)
                      .copyWith(color: AtemColors.cyan),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AtemColors.textSecondary),
            ],
          ),
        ),
      );
}

/// D1 — festgelegt.
class _Set extends ConsumerWidget {
  const _Set({
    required this.zones,
    required this.onBoundary,
    required this.onHrMax,
  });

  final HeartRateZones zones;
  final ValueChanged<int> onBoundary;
  final VoidCallback onHrMax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(heartRateSettingsProvider);
    final hrMax = settings.hrMax;
    final tag = languageTag(context);

    // Die Minuten rechts zeigen, was die Grenzen an **einer echten Einheit**
    // bewirken — die jüngste mit Puls. Ohne sie stehen die Zonen ohne Zahlen
    // da, was keine Lücke ist.
    HealthSession? latest;
    for (final s in ref.watch(healthSessionsProvider).value ?? const []) {
      if (s.pulse == null) continue;
      if (latest == null || s.start.isAfter(latest.start)) latest = s;
    }
    final distribution = latest == null
        ? null
        : ZoneDistribution.of(
            secondsByBpm: latest.pulse!.secondsByBpm,
            windowSeconds: latest.pulse!.windowSeconds,
            zones: zones,
          );

    final setAt = settings.zonesSetAt;
    final setDate = setAt == null ? null : DateFormat.MMMd(tag).format(setAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          (hrMax == null
                  ? l10n.settingsZonesBasisBpm
                  : l10n.settingsZonesBasisPct(hrMax))
              .toUpperCase(),
          style: AtemType.labelMicro.of(context),
        ),
        const SizedBox(height: 4),
        Text(
          hrMax == null
              ? l10n.settingsZonesBasisNoteBpm
              : l10n.settingsZonesBasisNotePct(hrMax),
          style: AtemType.meta.of(context),
        ),
        const SizedBox(height: 14),
        for (var zone = 1; zone <= HeartRateZones.zoneCount; zone++) ...[
          _ZoneRow(
            zones: zones,
            zone: zone,
            seconds: distribution?.secondsPerZone[zone - 1],
          ),
          if (zone < HeartRateZones.zoneCount) ...[
            const SizedBox(height: 8),
            _BoundaryRow(
              zones: zones,
              index: zone - 1,
              hrMax: hrMax,
              onTap: () => onBoundary(zone - 1),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 16),
        // Gilt auch für vergangene Einheiten — als Satz, weil es sonst eine
        // Überraschung wäre (Entscheidung 15).
        Text(l10n.settingsZonesRetro, style: AtemType.meta.of(context)),
        const SizedBox(height: 6),
        if (setDate != null)
          Text(l10n.settingsZonesStateSet(setDate),
              style: AtemType.meta.of(context)),
        if (latest != null)
          Text(
            l10n.settingsZonesLastSession(
                DateFormat.MMMd(tag).format(latest.start)),
            style: AtemType.meta.of(context),
          ),
        _HrMaxLine(onTap: onHrMax),
      ],
    );
  }
}

/// Eine Zone: Name und Bereich links, Minuten rechts. **Nicht tippbar und
/// kein Cyan** — sie trägt Auskunft, keine Handlung.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zones, required this.zone, this.seconds});

  final HeartRateZones zones;
  final int zone;
  final int? seconds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final lower = zones.lowerOf(zone);
    final upper = zones.upperOf(zone);
    final range = switch ((lower, upper)) {
      (null, _) => l10n.detailZoneRangeUpto(zones.bounds.first - 1),
      (final low?, null) => l10n.detailZoneRangeFrom(low),
      (final low?, final u?) => l10n.detailZoneRange(low, u),
    };
    final time = seconds == null ? null : clock(seconds!);

    return Semantics(
      label: [
        l10n.detailZoneName(zone),
        range,
        if (time != null) time,
      ].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              // Der Farbpunkt der Zone — dieselbe Farbe wie im Einheitendetail.
              // Dekorativ: Name, Bereich und Minuten tragen die Auskunft.
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AtemColors.zone(zone),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.detailZoneName(zone),
                        style: AtemType.titleSmallOrDefault(context)),
                    Text(range,
                        style: AtemType.meta
                            .of(context)
                            .copyWith(color: AtemColors.textSecondary)),
                  ],
                ),
              ),
              if (time != null)
                Text(time, style: AtemType.valueMedium.of(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// Sekunden als „6:10".
  static String clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Eine Grenze — **das Ziel**: 56 dp hoch, der Wert in Cyan.
class _BoundaryRow extends StatelessWidget {
  const _BoundaryRow({
    required this.zones,
    required this.index,
    required this.hrMax,
    required this.onTap,
  });

  final HeartRateZones zones;
  final int index;
  final int? hrMax;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final value = zones.bounds[index];
    final title = l10n.settingsZonesBoundaryTitle(index + 1);
    final between =
        '${l10n.detailZoneName(index + 1)} / ${l10n.detailZoneName(index + 2)}';

    return AtemTappable(
      onTap: onTap,
      semanticLabel:
          '${l10n.settingsZonesBoundary(index + 1, index + 1, index + 2)}, $value bpm.',
      minTapSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtemColors.border),
        ),
        // **Ab 130 % Schrift zweizeilig**: Name und Wert nebeneinander
        // bräuchten mehr Breite, als 320 dp hergeben, und Ellipsis oder
        // Verkleinern kommen nicht in Frage (Board 16, 200 % auf 320 dp).
        child: MediaQuery.textScalerOf(context).scale(10) / 10 >= 1.3
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AtemType.titleSmallOrDefault(context)),
                  Text(between, style: AtemType.meta.of(context)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _value(context, value)),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AtemColors.textSecondary),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AtemType.titleSmallOrDefault(context)),
                        Text(between, style: AtemType.meta.of(context)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _value(context, value),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AtemColors.textSecondary),
                ],
              ),
      ),
    );
  }

  static Widget _value(BuildContext context, int value) => Text(
        '$value BPM',
        style:
            AtemType.valueMedium.of(context).copyWith(color: AtemColors.cyan),
      );
}
