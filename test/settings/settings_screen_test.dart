import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: fixtureOverrides,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('zeigt die Abschnitte und das hinterlegte Gewicht',
      (tester) async {
    await _pump(tester, const SettingsScreen());

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Konto'), findsOneWidget);
    expect(find.text('Rechtliches'), findsOneWidget);
    expect(find.text('Über die App'), findsOneWidget);

    // Aus den Vorlagen: 78 kg, Pausenzeit 90.
    final weight = tester.widget<TextField>(find.byType(TextField).first);
    expect(weight.controller?.text, '78');
  });

  testWidgets('kein Themenschalter, aber die Tatsache dazu', (tester) async {
    await _pump(tester, const SettingsScreen());

    expect(find.textContaining('Nur dunkel'), findsOneWidget);
    // Es darf keine Zeile geben, die ein helles Thema anböte.
    expect(find.textContaining('Hell'), findsNothing);
  });

  testWidgets('die Vorschau erscheint erst bei einer Änderung',
      (tester) async {
    await _pump(tester, const SettingsScreen());
    expect(find.text('Was sich dadurch ändert'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '95');
    await tester.pumpAndSettle();

    // Der Bestand aus den Vorlagen trägt keine Körpergewichtsübungen —
    // dann sagt die Vorschau genau das, statt eine Zahl zu erfinden.
    final hasTable = find.text('Was sich dadurch ändert').evaluate().isNotEmpty;
    final saysNothing =
        find.textContaining('ändert das nichts').evaluate().isNotEmpty;
    expect(hasTable || saysNothing, isTrue,
        reason: 'entweder Zahlen oder die Auskunft, dass es keine gibt');
  });

  testWidgets('ein unsinniges Gewicht wird am Feld gemeldet', (tester) async {
    await _pump(tester, const SettingsScreen());

    await tester.enterText(find.byType(TextField).first, '780');
    await tester.pumpAndSettle();

    expect(
      find.text('Zwischen ${UserSettings.minBodyWeightKg.round()} und '
          '${UserSettings.maxBodyWeightKg.round()} kg.'),
      findsOneWidget,
    );
  });

  testWidgets('Löschen bleibt gesperrt, bis das Wort getippt ist',
      (tester) async {
    await _pump(tester, const AccountDeletionScreen());

    AtemButton button() => tester.widget<AtemButton>(
          find.widgetWithText(AtemButton, 'Konto löschen'),
        );

    expect(button().onPressed, isNull, reason: 'leeres Feld');

    // Kleinschreibung zählt nicht — sonst wäre es kein Innehalten.
    await tester.enterText(find.byType(TextField), 'löschen');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'LÖSCHEN');
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('der Abschlussbildschirm erklärt den bleibenden Zugang',
      (tester) async {
    await _pump(tester, const AccountDeletedScreen());

    expect(find.text('Konto gelöscht'), findsOneWidget);
    expect(find.text('Dein Zugang bleibt bestehen'), findsOneWidget);
    expect(find.textContaining('wieder dabei'), findsOneWidget);
  });
}
