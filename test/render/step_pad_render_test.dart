@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung des Eingabeblattes mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/step_pad_render_test.dart
///
/// Drei Felder, beide Modi, dazu der Extremfall 320 dp bei Schrift 2,0.
void main() {
  Future<void> shot(
    WidgetTester tester,
    String name, {
    required AtemStepField field,
    double? value,
    double? previousValue,
    String? previousLabel,
    bool keyboard = false,
    double width = 361,
    double scale = 1.15,
  }) async {
    if (!renderEnabled) return;
    await loadRealFonts();
    tester.view.physicalSize = Size(width, 620);
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
              field: field,
              setNumber: 2,
              value: value,
              previousValue: previousValue,
              previousLabel: previousLabel,
              onApply: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    if (keyboard) {
      await tester.tap(find.text('TASTATUR'));
      await tester.pumpAndSettle();
    }
    await writePng(tester, key, name);
  }

  testWidgets('Gewicht, Regler', (tester) async {
    await shot(tester, 'pad_gewicht_regler',
        field: AtemStepField.weight,
        value: 60,
        previousValue: 55,
        previousLabel: '55 kg × 8');
  });

  testWidgets('Gewicht, Tastatur', (tester) async {
    await shot(tester, 'pad_gewicht_tastatur',
        field: AtemStepField.weight,
        value: 60,
        previousValue: 55,
        previousLabel: '55 kg × 8',
        keyboard: true);
  });

  testWidgets('Wiederholungen, Regler', (tester) async {
    await shot(tester, 'pad_wdh_regler',
        field: AtemStepField.reps,
        value: 8,
        previousValue: 10,
        previousLabel: '100 kg × 10');
  });

  testWidgets('Halten, Regler', (tester) async {
    await shot(tester, 'pad_halten_regler',
        field: AtemStepField.hold,
        value: 45,
        previousValue: 40,
        previousLabel: '40 s');
  });

  testWidgets('Gewicht, Regler, 320 dp bei Schrift 2,0', (tester) async {
    await shot(tester, 'pad_gewicht_regler_320_200',
        field: AtemStepField.weight,
        value: 107.5,
        previousValue: 100,
        previousLabel: '100 kg × 8',
        width: 320,
        scale: 2.0);
  });

  testWidgets('Gewicht, Tastatur, 320 dp bei Schrift 2,0', (tester) async {
    await shot(tester, 'pad_gewicht_tastatur_320_200',
        field: AtemStepField.weight,
        value: 107.5,
        previousValue: 100,
        previousLabel: '100 kg × 8',
        keyboard: true,
        width: 320,
        scale: 2.0);
  });
}
