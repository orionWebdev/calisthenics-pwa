import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/workout/application/workout_providers.dart';
import 'package:atem/features/workout/data/preview_workout_repository.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth.dart';

/// Fixture-Datenquellen für alle Tests.
///
/// Ohne Typannotation: `Override` wird von flutter_riverpod nicht exportiert,
/// der Typ wird aus dem Literal abgeleitet. Die Preview-Repositories sind
/// zustandslos, geteilte Instanzen sind also unbedenklich.
final fixtureOverrides = [
  authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
  dashboardRepositoryProvider.overrideWithValue(PreviewDashboardRepository()),
  workoutRepositoryProvider.overrideWithValue(PreviewWorkoutRepository()),
];

/// Die Prüfmatrix aus `docs/contracts/01-accessibility.md`.
///
/// Drei Schriftskalierungen mal drei Breiten. Das ist die einzige Prüfung, die
/// Überlauf zuverlässig fängt — ein Layout, das bei 390 dp und Faktor 1.0
/// funktioniert, sagt nichts über 320 dp bei Faktor 2.0.
const a11yTextScales = <double>[1.0, 1.3, 2.0];
const a11ySizes = <Size>[
  Size(320, 640), // schmalstes verbreitetes Android-Gerät
  Size(360, 800), // Median
  Size(412, 915), // Pixel-Klasse
];

/// Ergebnis einer einzelnen Matrixzelle.
class A11yFinding {
  A11yFinding(this.width, this.scale, this.rule, this.detail);

  final double width;
  final double scale;
  final String rule;
  final String detail;

  @override
  String toString() =>
      '${width.toInt()}dp @${scale}x  $rule\n      ${detail.split('\n').first}';
}

/// Prüft ein Widget über die gesamte Matrix gegen den A11y-Vertrag.
///
/// Sammelt **alle** Befunde statt beim ersten abzubrechen — beim Aufräumen
/// technischer Schuld ist die vollständige Liste mehr wert als der erste Treffer.
///
/// Animationen sind abgeschaltet: Ohne das laufen die dekorativen Dauerschleifen
/// endlos und `pumpAndSettle()` läuft in den Timeout (Vertrag R8).
Future<List<A11yFinding>> collectA11yFindings(
  WidgetTester tester,
  Widget home, {
  List<double> textScales = a11yTextScales,
  List<Size> sizes = a11ySizes,
}) async {
  final findings = <A11yFinding>[];

  for (final size in sizes) {
    for (final scale in textScales) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixtureOverrides,
          child: MaterialApp(
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: home,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Überlauf und Layoutfehler schlagen als Exception auf.
      final rendered = tester.takeException();
      if (rendered != null) {
        findings
            .add(A11yFinding(size.width, scale, 'layout', rendered.toString()));
      }

      for (final entry in <String, AccessibilityGuideline>{
        'tap-target': androidTapTargetGuideline,
        'label': labeledTapTargetGuideline,
      }.entries) {
        final result = await entry.value.evaluate(tester);
        if (!result.passed) {
          findings.add(
              A11yFinding(size.width, scale, entry.key, result.reason ?? ''));
        }
      }

      handle.dispose();
    }
  }

  return findings;
}

/// Das eigentliche Tor. Schlägt fehl, sobald irgendeine Zelle einen Befund hat.
Future<void> expectA11y(
  WidgetTester tester,
  Widget home, {
  List<double> textScales = a11yTextScales,
  List<Size> sizes = a11ySizes,
}) async {
  final findings = await collectA11yFindings(
    tester,
    home,
    textScales: textScales,
    sizes: sizes,
  );
  expect(
    findings,
    isEmpty,
    reason: 'Verstöße gegen docs/contracts/01-accessibility.md:\n'
        '${findings.map((f) => '  $f').join('\n')}',
  );
}
