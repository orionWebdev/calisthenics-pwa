import 'package:flutter/material.dart' show Icons, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/pulse_profile.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../health_import/application/health_import_providers.dart';
import '../../../pulse/application/pulse_providers.dart';
import '../../../pulse/domain/heart_rate_zones.dart';
import '../../../pulse/presentation/screens/heart_rate_zones_screen.dart';
import '../../../pulse/presentation/widgets/pulse_curve_chart.dart';
import '../../../pulse/presentation/widgets/zone_bars.dart';
import '../../domain/session_detail.dart';
import '../session_ui.dart';
import 'detail_blocks.dart';

/// „Puls & Zonen" — wie hat der Körper reagiert (Board 16, Platz 4).
///
/// ## Fünf Zustände
///
/// - **Default**: Ø, Max, Min und fünf Balken, die Grundlage als Satz davor.
/// - **Zu wenig Daten** (C1): Die Balken werden gezeichnet, aber der Satz
///   steht **vor** ihnen — die Verteilung beschreibt den aufgezeichneten
///   Teil, nicht die Einheit.
/// - **Zonen nicht festgelegt** (C2): Der Titel heisst nur „Puls" — kein Titel
///   verspricht etwas, das nicht kommt. Die Werte bleiben, der Zonenteil
///   entfällt. Die **einzige** Stelle des Bildschirms, die etwas anbietet.
/// - **Lädt** (C4): Fünf Spuren in voller Länge ohne Füllung; die Höhe steht
///   fest, bevor die Zahlen kommen.
/// - **Nicht lesbar** (C5): Ein Fehler, der sichtbar bleibt.
///
/// ## Kein Puls vorhanden (C6)
///
/// Der Block **rendert nicht**. Kein Titel, keine leere Karte, kein „—".
/// *Nicht lesbar* ist ein Fehler, weil es Daten gibt, die man erwarten darf;
/// *nicht vorhanden* ist keiner und verschwindet vollständig.
class PulseZonesBlock extends ConsumerWidget {
  const PulseZonesBlock({super.key, required this.watch});

  final AsyncValue<WatchFigures?> watch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return watch.when(
      loading: () => const _Loading(),
      error: (_, __) => const _Error(),
      data: (figures) {
        final pulse = figures?.pulse;
        if (pulse == null || pulse.isEmpty) return const SizedBox.shrink();
        return _Data(pulse: pulse);
      },
    );
  }
}

class _Data extends ConsumerWidget {
  const _Data({required this.pulse});

  final PulseProfile pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final settings = ref.watch(heartRateSettingsProvider);
    final zones = settings.zones;

    final recorded = pulse.recordedSeconds;
    final minutes = (recorded / 60).round();
    final total = (pulse.windowSeconds / 60).round();

    final distribution = zones == null
        ? null
        : ZoneDistribution.of(
            secondsByBpm: pulse.secondsByBpm,
            windowSeconds: pulse.windowSeconds,
            zones: zones,
          );

    final setAt = settings.zonesSetAt;

    // **Die Grundlage trägt drei Glieder** (Board 16, Nachtrag): aufgezeichnet
    // von der Gesamtdauer · Zahl der Abschnitte · Auflösung. Das
    // Abschnittsglied nur, wenn es mehr als einen gibt — „in 1 Abschnitt" ist
    // keine Auskunft.
    //
    // Der Stichtag der Zonen stand bis zum 22.09.2026 abends hier und zog
    // ins ⓘ: Die Zeile hat drei Plätze, und die Auflösung ist der Grund,
    // warum die Kurve aussieht, wie sie aussieht. Verschwunden ist er nicht.
    final sections = pulse.curveSections.length;
    final interval = pulse.slotSeconds >= 60
        ? l10n.pulseCurveIntervalMinute
        : l10n.pulseCurveIntervalTen;
    // **Die Auflösung als Wort** — und bei einem Wechsel beide, mit der
    // Stelle dazwischen. Die gestrichelte Marke im Plot allein trüge die
    // Auskunft nicht; Farbe und Strich sind nie alleinige Statusträger.
    final change = pulse.resolutionChangeSlot;
    String shortWord(int seconds) => seconds >= 60
        ? l10n.pulseCurveResolutionShortMinute
        : l10n.pulseCurveResolutionShortTen;

    final step = pulse.curveStepSeconds ?? pulse.slotSeconds;
    final resolution = change == null
        ? (step >= 60
            ? l10n.pulseCurveResolutionMinute
            : l10n.pulseCurveResolutionTen)
        : l10n.pulseCurveResolutionMixed(
            shortWord(_stepBefore(pulse, change)),
            _clock(change * pulse.slotSeconds),
            shortWord(_stepAfter(pulse, change)),
          );

    final basis = pulse.curve.length < 2
        ? l10n.detailHrBasisNoZones(minutes, total)
        : sections > 1
            ? l10n.pulseCurveBlockBasis(minutes, total,
                l10n.pulseCurveSections(sections), resolution)
            : l10n.pulseCurveBlockBasisWhole(minutes, total, resolution);

    return DetailBlock(
      // Ohne Zonen heisst er nur „Puls" — kein Titel verspricht etwas, das
      // nicht kommt (C2).
      title: zones == null ? l10n.detailBlockHr : l10n.detailBlockHrZones,
      // Erklärt wird nur, was gerechnet wurde: ohne Zonen kein ⓘ.
      explanation: [
        if (zones != null) l10n.detailExplainZones,
        if (zones != null && setAt != null)
          l10n.detailZonesSetOn(DateFormat.MMMd(tag).format(setAt)),
        // **Warum die Kurve flacher aussieht als die Kacheln.** Sie zeichnet
        // Mittel, die Kacheln nennen Rohwerte — ohne diesen Satz liest man
        // „Max 120" über einer Kurve, die nie über 115 kommt, und sucht den
        // Fehler bei sich.
        if (pulse.curve.length >= 2)
          l10n.pulseCurveExplainRawVsCurve(interval),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Values(pulse: pulse),
          const SizedBox(height: 10),
          if (zones == null) ...[
            Text(basis, style: AtemType.meta.of(context)),
            const SizedBox(height: 12),
            // Ohne Grenzen keine Verteilung — und kein Alarmton: Der Zustand
            // ist keine Meldung. Er zeigt den kürzesten Weg zur fehlenden
            // Angabe, keinen Aufruf.
            Text(l10n.detailZonesUnset,
                style: AtemType.body
                    .of(context)
                    .copyWith(color: AtemColors.textTertiary)),
            const SizedBox(height: 4),
            AtemTappable(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const HeartRateZonesScreen()),
              ),
              semanticLabel: l10n.detailZonesSetAction,
              minTapSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AtemColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(l10n.detailZonesSetAction,
                          style: AtemType.labelSmall.of(context).copyWith(
                              color: AtemColors.cyan,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AtemColors.cyan),
                  ],
                ),
              ),
            ),
          ] else ...[
            // **Der Nenner steht über den Balken, nie als Fussnote** — bei
            // unvollständiger Aufzeichnung als Satz, der die Verteilung
            // einordnet, bevor man sie sieht.
            if (distribution!.isPartial) ...[
              Text(l10n.detailZonesThin(minutes, total),
                  style: AtemType.body
                      .of(context)
                      .copyWith(color: AtemColors.textTertiary)),
              const SizedBox(height: 12),
            ] else ...[
              Text(basis, style: AtemType.meta.of(context)),
              const SizedBox(height: 12),
            ],
            _Zones(
              zones: zones,
              distribution: distribution,
              groupLabel: l10n.detailZonesGroupA11y(minutes, total,
                  setAt == null ? '' : DateFormat.yMMMMd(tag).format(setAt)),
              totalMinutes: total,
            ),
            if (distribution.isPartial) ...[
              const SizedBox(height: 10),
              Text(basis, style: AtemType.meta.of(context)),
            ],
          ],
          // Unter zwei Werten zeichnet der Baustein nichts — dann bleibt
          // dieser Teil einfach weg, kein leerer Titel davor.
          if (pulse.curve.length >= 2) ...[
            const SizedBox(height: 14),
            Text(l10n.detailPulseCurveTitle.toUpperCase(),
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(color: AtemColors.textTertiary)),
            const SizedBox(height: 8),
            PulseCurveChart(
              bpmBySlot: pulse.curve,
              slotSeconds: pulse.slotSeconds,
              totalSeconds: pulse.windowSeconds,
              // Wie lange ein Wert gilt — dieselbe Grenze, an der auch die
              // Abschnitte hängen. Über ihr eine Lücke, darunter läuft die
              // Linie durch.
              gapSeconds: PulseProfile.maxGapSeconds,
              // Dieselben Grenzen, die auch die Verteilung darüber rechnet.
              // Fehlen sie, bleibt die Linie einfarbig — geraten wird nicht.
              zones: zones,
              // **Die Auflösung sagt, was dasteht** — nicht, wie fein das
              // Raster ist. Eine Uhr, die nur jede Minute misst, füllt auch
              // im Zehn-Sekunden-Raster nur jeden sechsten Schlitz.
              resolution: resolution,
              changeSlot: change,
              semanticLabel: l10n.pulseCurveA11yCurve(
                total,
                minutes,
                l10n.pulseCurveSections(sections),
                resolution,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ø, Max, Min — drei Kacheln in der Uhr-Fläche.
class _Values extends StatelessWidget {
  const _Values({required this.pulse});

  final PulseProfile pulse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final entries = <(String, String, int?)>[
      (l10n.detailHrAvgShort, l10n.detailSpokenHrAvg, pulse.average),
      (l10n.detailHrMaxShort, l10n.detailSpokenHrMax, pulse.max),
      (l10n.detailHrMinShort, l10n.detailSpokenHrMin, pulse.min),
    ];

    // Ab 200 % Schrift untereinander statt nebeneinander: Drei Kacheln in
    // 288 dp verlören sonst ihre Zahl.
    final stacked = MediaQuery.textScalerOf(context).scale(10) / 10 >= 2.0;
    final tiles = [
      for (final (short, spoken, value) in entries)
        if (value != null)
          Semantics(
            container: true,
            label: l10n.detailSpokenTile(
                spoken, '$value', l10n.detailUnitBpm, l10n.hcOriginWatch),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                decoration: BoxDecoration(
                  // Fläche ist die Quelle, dazu der Ring-Glyph.
                  color: AtemColors.violet.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AtemColors.violet.withValues(alpha: 0.55)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(short.toUpperCase(),
                              style: AtemType.labelMicro
                                  .of(context)
                                  .copyWith(color: AtemColors.textTertiary)),
                        ),
                        const AtemOriginDot(
                          shape: AtemOriginShape.hollow,
                          color: AtemColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$value',
                        style: AtemType.valueMedium.of(context).copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AtemColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
    ];

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            tiles[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

/// Fünf Balken in den Farben ihrer Zonen — oder **weniger Zeilen**, wenn
/// Zonen leer blieben.
///
/// Eine Zone mit 0:00 verschwindet nicht: Eine leere Spur zeigt, dass sie
/// gemessen und nicht erreicht wurde. **Zwei** leere Zonen unter Zone 4
/// fasst eine einzige Zeile zusammen — die einzige Ausnahme, weil 0:00 keine
/// Länge hat.
///
/// Zone 5 nimmt daran nie teil: Sie bekommt immer eine eigene Zeile unterhalb
/// von Zone 4, auch bei 0:00 — sonst verschwindet ihre eigene Farbe in der
/// einer anderen Zone, wenn beide leer sind. „Zone 5 bekommt ihre eigene
/// Auswertung" (`AtemColors`, Board 16, auf Wunsch vom 21.09.2026).
class _Zones extends StatelessWidget {
  const _Zones({
    required this.zones,
    required this.distribution,
    required this.groupLabel,
    required this.totalMinutes,
  });

  final HeartRateZones zones;
  final ZoneDistribution distribution;
  final String groupLabel;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    const lastMergeable = HeartRateZones.zoneCount - 1;
    final empty = [
      for (var z = 1; z <= lastMergeable; z++)
        if (distribution.secondsPerZone[z - 1] == 0) z,
    ];
    final merge = empty.length >= 2;

    final rows = <Widget>[
      for (var z = 1; z <= lastMergeable; z++)
        if (!(merge && empty.contains(z)))
          _ZoneRow(
            zones: zones,
            zoneNumbers: [z],
            seconds: distribution.secondsPerZone[z - 1],
            fraction: distribution.shareOfRecorded(z),
            totalMinutes: totalMinutes,
          ),
      if (merge)
        _ZoneRow(
          zones: zones,
          zoneNumbers: empty,
          seconds: 0,
          fraction: 0,
          totalMinutes: totalMinutes,
        ),
      _ZoneRow(
        zones: zones,
        zoneNumbers: const [HeartRateZones.zoneCount],
        seconds: distribution.secondsPerZone[HeartRateZones.zoneCount - 1],
        fraction: distribution.shareOfRecorded(HeartRateZones.zoneCount),
        totalMinutes: totalMinutes,
      ),
    ];

    return Semantics(
      // Die Grundlage ist Teil des Gruppenlabels — nie nur Fussnote.
      container: true,
      label: groupLabel,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Eine Zone: **zweizeilig**, damit Name, bpm-Bereich und Minuten nie in
/// einer Zeile konkurrieren (200 % auf 320 dp).
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zones,
    required this.zoneNumbers,
    required this.seconds,
    required this.fraction,
    required this.totalMinutes,
  });

  final HeartRateZones zones;
  final List<int> zoneNumbers;
  final int seconds;
  final double fraction;
  final int totalMinutes;

  String _range(AppL10n l10n, int zone) {
    final lower = zones.lowerOf(zone);
    final upper = zones.upperOf(zone);
    return switch ((lower, upper)) {
      (null, _) => l10n.detailZoneRangeUpto(zones.bounds.first - 1),
      (final low?, null) => l10n.detailZoneRangeFrom(low),
      (final low?, final u?) => l10n.detailZoneRange(low, u),
    };
  }

  String _spokenRange(AppL10n l10n, int zone) {
    final lower = zones.lowerOf(zone);
    final upper = zones.upperOf(zone);
    return switch ((lower, upper)) {
      (null, _) => l10n.detailZoneRangeUpto(zones.bounds.first - 1),
      (final low?, null) => l10n.detailZoneRangeFrom(low),
      (final low?, final u?) => l10n.detailZoneSpokenRange(low, u),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final name = [
      for (final z in zoneNumbers)
        '${l10n.detailZoneShort(z)} · ${_range(l10n, z)}',
    ].join(' · ');
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

    // „Zone 3, 131 bis 148 bpm, 21 Minuten 30 von 52 Minuten" — kein „hoch"
    // oder „niedrig", kein Urteil im Label.
    final spoken = [
      for (final z in zoneNumbers)
        l10n.detailZoneA11y(
          z,
          _spokenRange(l10n, z),
          l10n.detailZoneTimeSpoken(seconds ~/ 60, seconds % 60),
          totalMinutes,
        ),
    ].join('. ');

    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // **Der Schlüssel zwischen Kurve und Zonennamen** (Board 16,
                // Nachtrag, Q): Die Kurve trägt die Zonenfarben, hier steht
                // dieselbe Farbe neben dem Namen. Ohne ihn wüsste niemand,
                // welches Rot welche Zone ist.
                //
                // Er trägt nichts allein — Nummer, Bereich und Minuten stehen
                // daneben —, und er wird nie vorgelesen. Bei gestapelten
                // Zonen („Z3 · Z4") gilt die erste: Zwei Punkte vor einer
                // Zeile behaupteten zwei Zeilen.
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 7),
                  child: SizedBox.square(
                    dimension: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AtemColors.zone(zoneNumbers.first),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(name, style: AtemType.meta.of(context)),
                ),
                const SizedBox(width: 10),
                Text(time,
                    style: AtemType.valueMedium.of(context).copyWith(
                        fontSize: 12, color: AtemColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 4),
            ZoneTrack(zone: zoneNumbers.first, fraction: fraction),
          ],
        ),
      ),
    );
  }
}

/// C4 — lädt: fünf Spuren in voller Länge, ohne Füllung.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Semantics(
      // Höflich, nie dringlich (Vertrag): Ein Ladezustand unterbricht nicht.
      liveRegion: true,
      label: l10n.detailHrLoading,
      child: ExcludeSemantics(
        // Kein ⓘ im Ladezustand — es gibt noch nichts zu erklären.
        child: DetailBlock(
          title: l10n.detailBlockHrZones,
          explanation: const [],
          child: Column(
            children: [
              for (var i = 0; i < HeartRateZones.zoneCount; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                ZoneTrack(zone: i + 1, fraction: 0, height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// C5 — nicht lesbar: **ein Fehler, der sichtbar bleibt**, weil es Daten gibt,
/// die man erwarten darf.
class _Error extends ConsumerWidget {
  const _Error();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);
    final lastRead = ref.watch(healthLastReadProvider).value;
    final message = '${l10n.detailErrorHr}. ${l10n.detailErrorHrBody}';

    return DetailBlock(
      title: l10n.detailBlockHr,
      // Erklärt wird nur, was gerechnet wurde.
      explanation: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label: message,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AtemColors.magenta.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AtemColors.magenta.withValues(alpha: 0.4)),
                ),
                child: Text(message,
                    style: AtemType.body
                        .of(context)
                        .copyWith(color: AtemColors.textTertiary)),
              ),
            ),
          ),
          AtemTappable(
            onTap: () => ref.invalidate(healthSessionsProvider),
            semanticLabel: l10n.detailRetry,
            minTapSize: const Size(0, 48),
            alignment: Alignment.centerLeft,
            child: Text(l10n.detailRetry.toUpperCase(),
                style: AtemType.labelSmall.of(context).copyWith(
                    color: AtemColors.cyan, fontWeight: FontWeight.w700)),
          ),
          if (lastRead != null)
            Text(
              l10n
                  .detailHrLastRead(
                      DateFormat.MMMd(tag).add_Hm().format(lastRead))
                  .toUpperCase(),
              style: AtemType.meta.of(context),
            ),
        ],
      ),
    );
  }
}

/// „12:00" — eine Stelle in der Einheit, als Uhrzeit seit dem Beginn.
String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Der Abstand zweier gespeicherter Werte **vor** dem Wechsel, in Sekunden.
int _stepBefore(PulseProfile pulse, int changeSlot) {
  final before = pulse.curve.keys.where((s) => s < changeSlot).toList()..sort();
  if (before.length < 2) return pulse.slotSeconds;
  return (before.last - before[before.length - 2]) * pulse.slotSeconds;
}

/// Derselbe Abstand **nach** dem Wechsel.
int _stepAfter(PulseProfile pulse, int changeSlot) {
  final after = pulse.curve.keys.where((s) => s >= changeSlot).toList()..sort();
  if (after.length < 2) return pulse.slotSeconds;
  return (after[1] - after.first) * pulse.slotSeconds;
}
