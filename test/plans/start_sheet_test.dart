import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/plans/presentation/start_sheet.dart';
import 'package:atem/features/strength/presentation/screens/strength_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Das Start-Blatt **aus einem Tab heraus**.
///
/// Der verschachtelte Navigator ist der Punkt dieses Tests. Ohne ihn ist alles
/// derselbe Navigator und der Fehler unsichtbar: Das Blatt liegt auf dem
/// Wurzel-Navigator, `Navigator.of(context)` löst aber gegen den Tab auf. Der
/// Startknopf schloss deshalb nicht das Blatt, sondern versuchte den
/// Tab-Stapel zu leeren — und kein Training startete.
void main() {
  Future<StartRequest?> tapThrough(WidgetTester tester) async {
    StartRequest? got;

    await tester.pumpWidget(ProviderScope(
      overrides: fixtureOverrides,
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        // Wie in der Hülle: je Tab ein eigener Navigator unter dem Wurzel-.
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => StrengthScreen(onStart: (r) => got = r),
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Freies Training').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Starten').first);
    await tester.pumpAndSettle();
    return got;
  }

  testWidgets('freies Training startet aus dem Tab heraus', (tester) async {
    final request = await tapThrough(tester);

    expect(request, isNotNull,
        reason: 'Der Startknopf muss auf dem Wurzel-Navigator schliessen');
    expect(request!.isFree, isTrue);
    // Vorgabe aus den Einstellungen, nicht die Konstante des Blattes.
    expect(request.restSeconds, greaterThan(0));
    // Und das Blatt ist weg.
    expect(find.text('Starten'), findsNothing);
  });
}
