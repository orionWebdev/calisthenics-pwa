@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/settings/presentation/screens/info_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung von Profilseite und Info-Seite mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/settings_render_test.dart
///
/// Je Bildschirm mehrere Aufnahmen einer Honor-Höhe (361 × 780 dp, Schrift
/// 1,15) und dieselbe Folge eng und gross (320 dp, Schrift 2,0) — dort
/// zeigt sich, ob ein Wort kürzt oder eine Zeile überläuft.
Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['ATEM_RENDER_DIR']!;
  for (var attempt = 0; attempt < 4; attempt++) {
    await tester.pump();
    final ok = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data.buffer.asUint8List());
      return true;
    });
    if (ok == true) return;
  }
}

void main() {
  final cases = <(String, Widget)>[
    ('settings', const SettingsScreen()),
    ('info', const InfoScreen()),
  ];

  for (final (name, screen) in cases) {
    for (final (suffix, width, scale) in [
      ('', 361.0, 1.15),
      ('_320_200', 320.0, 2.0),
    ]) {
      testWidgets('rendert $name$suffix', (tester) async {
        if (!renderEnabled) return;
        await loadRealFonts();
        tester.view.physicalSize = Size(width, 780);
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
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: screen,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final scrollables = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
        for (var shot = 0; shot < 8; shot++) {
          await _shot(tester, key, '$name$suffix' '_$shot');
          if (scrollables.evaluate().isEmpty) break;
          final state = tester.state<ScrollableState>(scrollables.first);
          final before = state.position.pixels;
          state.position.jumpTo((before + 640)
              .clamp(0, state.position.maxScrollExtent)
              .toDouble());
          await tester.pumpAndSettle();
          if (state.position.pixels == before) break;
        }
      });
    }
  }
}
