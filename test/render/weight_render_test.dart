@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/presentation/screens/weight_history_screen.dart';
import 'package:atem/features/weight/presentation/widgets/weight_card.dart';
import 'package:atem/features/weight/presentation/widgets/weight_entry_sheet.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';
import '../support/render.dart';

/// Sichtprüfung des Gewichtsverlaufs (Board 14).
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/weight_render_test.dart
///
/// Vier Lagen: der Normalfall mit Kurve, die Lücke von sechs Wochen, der
/// einzelne Wert nach dem Neubeginn und die Verlaufsansicht. Dazu das
/// Eingabeblatt, weil es die einzige Stelle ist, an der ein fremder Baustein
/// (AtemStepPad) etwas Neues trägt.
final _today = DateTime(2026, 9, 20);

DateTime _ago(int days) =>
    DateTime(_today.year, _today.month, _today.day - days);

WeightEntry _e(int daysAgo, double kg,
        [WeightSource source = WeightSource.manual]) =>
    WeightEntry(date: _ago(daysAgo), kg: kg, source: source);

final _scenarios = <String, List<WeightEntry>>{
  'normal': [
    _e(89, 80.9, WeightSource.settings),
    _e(78, 80.6),
    _e(67, 80.4, WeightSource.healthConnect),
    _e(56, 80.1),
    _e(45, 79.8, WeightSource.healthConnect),
    _e(34, 79.6),
    _e(23, 79.3, WeightSource.healthConnect),
    _e(12, 79.1),
    _e(5, 78.9),
  ],
  'luecke': [
    _e(89, 80.4),
    _e(82, 80.2),
    // Sechs Wochen ohne Eintrag.
    _e(40, 79.4),
    _e(29, 79.2),
    _e(12, 79),
    _e(5, 78.9),
  ],
  'duenn': [
    _e(125, 81.5),
    _e(68, 80.4, WeightSource.healthConnect),
    _e(6, 79.6),
  ],
  'einzeln': [_e(201, 82.4, WeightSource.settings)],
};

Widget _app(Widget home, double scale) => MaterialApp(
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
      home: home,
    );

Future<void> _render(
  WidgetTester tester, {
  required String name,
  required List<WeightEntry> entries,
  required Widget home,
  required double width,
  required double scale,
}) async {
  await loadRealFonts();
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      weightRepositoryProvider
          .overrideWithValue(FakeWeightRepository(entries: entries)),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(
        settings: const UserSettings(bodyWeightKg: 78.9),
      )),
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      historyReferenceProvider.overrideWithValue(_today),
    ],
    child: RepaintBoundary(key: key, child: _app(home, scale)),
  ));
  await tester.pumpAndSettle();
  await writePng(tester, key, name);
}

void main() {
  for (final scenario in _scenarios.entries) {
    for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
      final name = 'weight_karte_${scenario.key}_${width.round()}_$scale';
      testWidgets('rendert $name', (tester) async {
        if (!renderEnabled) return;
        await _render(
          tester,
          name: name,
          entries: scenario.value,
          width: width,
          scale: scale,
          home: const Scaffold(
            backgroundColor: AtemColors.base,
            body: SingleChildScrollView(
              padding: EdgeInsets.all(AtemSpacing.screenPadding),
              child: WeightCard(),
            ),
          ),
        );
      });
    }
  }

  for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
    testWidgets('rendert weight_verlauf_${width.round()}_$scale',
        (tester) async {
      if (!renderEnabled) return;
      await _render(
        tester,
        name: 'weight_verlauf_${width.round()}_$scale',
        entries: _scenarios['normal']!,
        width: width,
        scale: scale,
        home: const WeightHistoryScreen(),
      );
    });

    testWidgets('rendert weight_blatt_${width.round()}_$scale',
        (tester) async {
      if (!renderEnabled) return;
      await _render(
        tester,
        name: 'weight_blatt_${width.round()}_$scale',
        entries: _scenarios['normal']!,
        width: width,
        scale: scale,
        home: const Scaffold(
          backgroundColor: AtemColors.base,
          body: WeightEntrySheet(),
        ),
      );
    });
  }
}
