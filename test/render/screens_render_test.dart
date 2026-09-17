@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/presentation/screens/analysis_screen.dart';
import 'package:atem/features/history/presentation/screens/history_screen.dart';
import 'package:atem/features/hybrid/presentation/screens/hybrid_screen.dart';
import 'package:atem/features/workout/presentation/screens/workouts_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung der Hauptbildschirme mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render
///
/// Schreibt je Bildschirm ein langes PNG (361 dp breit, Schrift 1,15 — wie
/// das Honor). Ohne `ATEM_RENDER_DIR` wird nichts geschrieben und der Test
/// ist sofort grün.
void main() {
  final screens = <String, Widget>{
    'hybrid': const HybridScreen(),
    'kraft_trainieren': WorkoutsScreen(onStart: (_) {}, embedded: true),
    'kraft_verlauf': HistoryScreen(embedded: true, onStart: () {}),
    'kraft_auswertung': const AnalysisScreen(embedded: true),
  };

  for (final entry in screens.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 2600);
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
            home: Scaffold(body: SafeArea(child: entry.value)),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, entry.key);
    });
  }
}
