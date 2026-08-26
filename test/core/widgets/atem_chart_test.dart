import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _series = [
  const AtemChartSeries(
    label: 'LOAD',
    values: [46, 63, 33, 76, 92, 57, 69],
    color: AtemColors.cyan,
    style: AtemSeriesStyle.primary,
  ),
  const AtemChartSeries(
    label: 'STRAIN',
    values: [26, 33, 51, 39, 61, 29, 37],
    color: AtemColors.magenta,
    style: AtemSeriesStyle.dashed,
  ),
  const AtemChartSeries(
    label: 'RECOVERY',
    values: [66, 55, 71, 61, 80, 73, 63],
    color: AtemColors.green,
    style: AtemSeriesStyle.angled,
  ),
];

Future<void> _pump(WidgetTester tester,
    {double width = 390, double scale = 1.0, int? highlight = 4}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AtemChartCard(
          title: 'PERFORMANCE · 7 TAGE',
          series: _series,
          axisLabels: const ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'],
          semanticSummary: 'Wochenverlauf: Load, Strain, Recovery, '
              'Montag bis Sonntag',
          highlightIndex: highlight,
          tooltip: 'FR · LOAD 92',
        ),
      ),
    ),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: w!,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('AtemChartCard', () {
    testWidgets('rendert auf 320 dp ohne Überlauf', (tester) async {
      // Der Vorgänger malte hier die Achsenbeschriftung außerhalb der Canvas.
      await _pump(tester, width: 320);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert über die gesamte Matrix', (tester) async {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          await _pump(tester, width: width, scale: scale);
          expect(tester.takeException(), isNull,
              reason: 'w=$width scale=$scale');
        }
      }
    });

    testWidgets('meldet eine Zusammenfassung statt der Einzelteile',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      final node = tester.getSemantics(find.byType(AtemChartCard));
      expect(node.label, contains('Wochenverlauf'));
      // Die Legende ist dekorativ und darf nicht einzeln angesagt werden.
      expect(find.bySemanticsLabel('LOAD'), findsNothing);
      handle.dispose();
    });

    testWidgets('ohne Hervorhebung rendert es trotzdem', (tester) async {
      await _pump(tester, highlight: null);
      expect(tester.takeException(), isNull);
    });

    testWidgets('verkraftet eine einzelne Datenreihe mit einem Punkt',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: AtemTheme.dark,
        home: const Scaffold(
          body: AtemChartCard(
            title: 'LEER',
            series: [
              AtemChartSeries(
                label: 'X',
                values: [50],
                color: AtemColors.cyan,
                style: AtemSeriesStyle.primary,
              ),
            ],
            axisLabels: ['MO'],
            semanticSummary: 'Ein Punkt',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Reihen ohne Farbe unterscheidbar', () {
    test('jede Reihe hat ein eigenes Formmerkmal', () {
      final markers = AtemSeriesStyle.values.map((s) => s.marker).toSet();
      final widths = AtemSeriesStyle.values.map((s) => s.strokeWidth).toSet();

      // Drei verschiedene Marker und drei verschiedene Strichstärken —
      // ohne Farbe bleiben die Reihen auseinanderhaltbar.
      expect(markers.length, 3);
      expect(widths.length, 3);
      expect(AtemSeriesStyle.dashed.isDashed, isTrue);
      expect(AtemSeriesStyle.primary.isDashed, isFalse);
    });

    test('nur die Primärreihe ist die dickste', () {
      expect(AtemSeriesStyle.primary.strokeWidth,
          greaterThan(AtemSeriesStyle.dashed.strokeWidth));
      expect(AtemSeriesStyle.primary.strokeWidth,
          greaterThan(AtemSeriesStyle.angled.strokeWidth));
    });
  });
}
