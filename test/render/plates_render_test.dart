@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung des Scheibenrechners im Eingabeblatt, mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/plates_render_test.dart
///
/// Vier Gewichte — glatt (60, 100), viele Scheiben mit 1,25 (142,5), ein
/// Rest (101) — je bei 361 dp/1,15 und 320 dp/2,0.
void main() {
  Future<void> shot(
    WidgetTester tester,
    String name, {
    required double value,
    double width = 361,
    double scale = 1.15,
    double? bar,
  }) async {
    if (!renderEnabled) return;
    await loadRealFonts();
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final key = GlobalKey();

    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: AtemColors.base,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AtemStepPad(
              key: ValueKey(name),
              field: AtemStepField.weight,
              setNumber: 2,
              value: value,
              previousValue: 95,
              previousLabel: '95 kg × 8',
              showPlates: true,
              onApply: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheiben'));
    await tester.pumpAndSettle();
    if (bar != null) {
      await tester.tap(find.bySemanticsLabel(
          'Stange ${AtemPlateStack.formatKg(tester.element(find.byType(AtemStepPad)), bar)} Kilogramm'));
      await tester.pumpAndSettle();
    }
    await writePng(tester, key, name);
  }

  for (final (value, label) in [
    (60.0, '60'),
    (100.0, '100'),
    (142.5, '142_5'),
    (101.0, '101'),
  ]) {
    testWidgets('$label kg, 361 dp bei 1,15', (tester) async {
      await shot(tester, 'plates_${label}_361', value: value);
    });
    testWidgets('$label kg, 320 dp bei 2,0', (tester) async {
      await shot(tester, 'plates_${label}_320_200',
          value: value, width: 320, scale: 2.0);
    });
  }

  testWidgets('15 kg an der 20-kg-Stange', (tester) async {
    await shot(tester, 'plates_15_below_361', value: 15);
  });

  testWidgets('400 kg an der 10-kg-Stange, 320 dp bei 2,0', (tester) async {
    await shot(tester, 'plates_400_bar10_320_200',
        value: 400, bar: 10, width: 320, scale: 2.0);
  });
}
