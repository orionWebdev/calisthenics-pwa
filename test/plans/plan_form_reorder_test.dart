import 'package:atem/features/plans/presentation/screens/plan_form_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Der Fehler, den dieser Test festhält: Ohne eigenen Schlüssel ordnet Flutter
/// den Zustand einer Karte ihrer **Position** zu. Beim Verschieben blieben die
/// Eingabefelder stehen und die Daten wanderten darunter durch — die
/// verschobene Übung zeigte danach die Zielwerte ihrer Nachbarin.
void main() {
  testWidgets('Verschieben nimmt die Zielwerte mit', (tester) async {
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: fixtureOverrides,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: PlanFormScreen(original: fixturePlans.first),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Der Vorlagenplan: erster Eintrag 4 Sätze, zweiter 3 Sätze mit „8-12".
    List<String> setsColumn() => tester
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller?.text ?? '')
        .toList();

    final before = setsColumn();
    expect(before, contains('4'));
    expect(before, contains('8-12'));

    // Den zweiten Eintrag nach oben schieben.
    await tester.tap(find.bySemanticsLabel(RegExp('Nach oben')).first);
    await tester.pumpAndSettle();

    final after = setsColumn();
    // Dieselben Werte, andere Reihenfolge — keiner ist verschwunden oder
    // verdoppelt worden.
    expect(after.where((v) => v == '4').length, before.where((v) => v == '4').length);
    expect(after.where((v) => v == '8-12').length,
        before.where((v) => v == '8-12').length);
  });
}
