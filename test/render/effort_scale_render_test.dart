@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/workout/presentation/widgets/set_effort.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung der beiden Skalen nebeneinander, mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/effort_scale_render_test.dart
///
/// Zu sehen ist der Unterschied, auf den es ankommt: In RPE steigt die Reihe
/// 6→10, in RIR fällt sie 4→0 — **die Richtung bleibt**, schwerer ist in beiden
/// Fassungen rechts.
void main() {
  Future<void> shot(
    WidgetTester tester,
    String name, {
    required EffortScale scale,
    double width = 361,
    double textScale = 1.15,
  }) async {
    if (!renderEnabled) return;
    await loadRealFonts();
    tester.view.physicalSize = Size(width, 700);
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
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: AtemColors.base,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RpeStrip(
                  setNumber: 1,
                  value: 8,
                  scale: scale,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                RpeBadge(
                  rpe: 8,
                  setNumber: 1,
                  scale: scale,
                  open: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await writePng(tester, key, name);
  }

  for (final (label, width, textScale) in [
    ('361', 361.0, 1.15),
    ('320_200', 320.0, 2.0),
  ]) {
    testWidgets('rendert RPE bei $label', (tester) async {
      await shot(tester, 'effort_rpe_$label',
          scale: EffortScale.rpe, width: width, textScale: textScale);
    });

    testWidgets('rendert RIR bei $label', (tester) async {
      await shot(tester, 'effort_rir_$label',
          scale: EffortScale.rir, width: width, textScale: textScale);
    });
  }
}
