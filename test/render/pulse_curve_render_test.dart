@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/presentation/widgets/pulse_curve_chart.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung des Pulsverlaufs — Zonenfarben, Grenzlinien, Marken, Achse.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/pulse_curve_render_test.dart --tags render
void main() {
  final zones = HeartRateZones.tryFrom(const [111, 131, 149, 168])!;

  /// Ein Intervalltraining: einlaufen, vier harte Stücke, auslaufen — mit
  /// einer echten Lücke, in der die Uhr nichts gemessen hat.
  final intervals = <int, int>{
    for (var m = 0; m <= 8; m++) m: 95 + m * 4,
    for (var m = 9; m <= 12; m++) m: 172 - (m - 9) * 2,
    for (var m = 13; m <= 16; m++) m: 128 + (m - 13),
    for (var m = 17; m <= 20; m++) m: 176 - (m - 17) * 3,
    // 21–24 fehlen: Lücke.
    for (var m = 25; m <= 34; m++) m: 150 - (m - 25) * 4,
  };

  final cases = <String, (Map<int, int>, HeartRateZones?, double, double?)>{
    'kurve_zonen': (intervals, zones, 1.0, null),
    'kurve_ohne_zonen': (intervals, null, 1.0, null),
    'kurve_200': (intervals, zones, 2.0, null),
    // Mit gesetzter Marke: der Zustand, den ein Standbild sonst nie zeigt.
    'kurve_abgelesen': (intervals, zones, 1.0, 0.33),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();

      final (curve, z, scale, scrubAt) = entry.value;
      tester.view.physicalSize = const Size(361 * 2, 320 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
              key: key,
              child: Material(
                color: AtemColors.base,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PulseCurveChart(
                    bpmByMinute: curve,
                    totalMinutes: 36,
                    zones: z,
                    resolution: 'je Minute ein Wert',
                    height: 120,
                    semanticLabel: 'Pulsverlauf',
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      TestGesture? gesture;
      if (scrubAt != null) {
        final box = tester.getRect(find.byType(CustomPaint).last);
        gesture = await tester.startGesture(
            Offset(box.left + 2, box.center.dy));
        await gesture.moveTo(
            Offset(box.left + box.width * scrubAt, box.center.dy));
        await tester.pump();
      }

      await writePng(tester, key, entry.key);
      await gesture?.up();
    });
  }
}
