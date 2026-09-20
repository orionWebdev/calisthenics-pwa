@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung des Kraft-One-Pagers in seinen Zuständen — oben, in den
/// Verlauf gescrollt, und auf jedem Reiter.
void main() {
  const states = {
    'trainieren': 0,
    'liste': 0,
    'verlauf': 1,
    'auswertung': 2,
    'plaene': 3,
  };

  for (final entry in states.entries) {
    testWidgets('rendert kraft_onepager_${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: fixtureOverrides,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.15),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: StrengthScreen(onStart: (_) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = AppL10n.of(tester.element(find.byType(StrengthScreen)));
      final labels = [
        l10n.segTrain,
        l10n.segHistory,
        l10n.segAnalysis,
        l10n.segPlans,
      ];

      if (entry.key == 'liste') {
        // Die Sprungliste offen — alle vier Wörter vollständig.
        await tester.tap(find.byType(AtemSectionBar));
        await tester.pumpAndSettle();
      } else if (entry.value > 0) {
        await tester.tap(find.byType(AtemSectionBar));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(
            of: find.byType(AtemSectionJumpList),
            matching: find.text(labels[entry.value])));
        await tester.pumpAndSettle();
      }

      await writePng(tester, key, 'kraft_onepager_${entry.key}');
    });
  }
}
