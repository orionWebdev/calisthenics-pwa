@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/presentation/screens/hybrid_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung des Hybrid-Tabs mit realistischen Einheiten.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/hybrid_render_test.dart
///
/// Die allgemeinen Fixtures enden im Juni — am Stichtag hätte der Hybrid-Tab
/// weder Woche noch 28 Tage. Hier zwei Lagen: die des Nutzers nach dem
/// Neubeginn (zwei Krafteinheiten ohne Gewicht) und eine gemischte mit allen
/// drei Spuren über mehrere Wochen.
final _today = DateTime(2026, 9, 17);

DateTime _ago(int days) => DateTime(_today.year, _today.month, _today.day - days, 18);

StrengthSession _strength(String id, int daysAgo, int minutes, {double? kg}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      bodyweight: kg == null,
      duration: Duration(minutes: minutes),
      planName: 'Pull - Home',
      exercises: [
        LoggedExercise(
          exerciseId: 'pull_up',
          sets: [
            for (var i = 0; i < 4; i++) LoggedSet(reps: 8, weight: kg),
          ],
        ),
      ],
    );

CardioSession _cardio(String id, int daysAgo, int minutes, double km) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      activity: CardioActivity.run,
      duration: Duration(minutes: minutes),
      distanceKm: km,
    );

RecoverySession _recovery(String id, int daysAgo, int minutes) =>
    RecoverySession(
      id: id,
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      duration: Duration(minutes: minutes),
    );

final _scenarios = <String, List<TrainingSession>>{
  'neubeginn': [
    _strength('a', 1, 26),
    _strength('b', 2, 26),
    _recovery('r', 1, 15),
  ],
  'gemischt': [
    _strength('a', 0, 55, kg: 60),
    _strength('b', 2, 48, kg: 62.5),
    _cardio('c', 1, 34, 6.2),
    _recovery('r', 3, 20),
    for (var w = 1; w < 5; w++) ...[
      _strength('s$w', 7 * w + 1, 50, kg: 60),
      _cardio('k$w', 7 * w + 2, 40, 7),
    ],
    _cardio('x', 12, 60, 10.5),
    for (var i = 0; i < 6; i++) _strength('o$i', 40 + i * 3, 45, kg: 55),
  ],
};

void main() {
  for (final scenario in _scenarios.entries) {
    for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
      final name = 'hybrid_${scenario.key}_${width.round()}_$scale';
      testWidgets('rendert $name', (tester) async {
        if (!renderEnabled) return;
        await loadRealFonts();
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(ProviderScope(
          overrides: [
            // Der letzte Eintrag der Fixtures setzt den Stichtag auf den
            // 27.08.; hier gilt der 17.09. — zweimal überschreiben verbietet
            // Riverpod.
            ...fixtureOverrides.take(fixtureOverrides.length - 1),
            historyReferenceProvider.overrideWithValue(_today),
            sessionStreamProvider
                .overrideWith((ref) => Stream.value(scenario.value)),
          ],
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
              home: const HybridScreen(),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        await writePng(tester, key, name);
      });
    }
  }
}
