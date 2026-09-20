import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:atem/features/settings/presentation/screens/info_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/features/weight/presentation/screens/weight_history_screen.dart';
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

    // Abschnittsköpfe stehen in Mono-Versalien (Board 08, A1).
    expect(find.text('TRAINING'), findsOneWidget);
    expect(find.text('APP'), findsOneWidget);
    expect(find.text('DEINE DATEN'), findsOneWidget);

    // Rechtliches und „Über die App" liegen seit 17.09.2026 hinter „Info".
    expect(find.text('RECHTLICHES'), findsNothing);
    expect(find.text('ÜBER DIE APP'), findsNothing);
    expect(find.text('Info'), findsOneWidget);

    // Aus den Vorlagen: Pausenzeit 90 als Wert in der Zeile (Board 08).
    // Das Gewicht steht seit Board 14 nicht mehr aus dem Profil da (78), sondern
    // als jüngster Verlaufseintrag (78,5) — die Zeile ist eine Ableitung.
    expect(find.text('78,5 kg'), findsOneWidget);
    expect(find.text('90 s'), findsOneWidget);
  });


  testWidgets('die Version steht als Fussnote, nicht in einem Abschnitt',
      (tester) async {
    await _pump(tester, const SettingsScreen());

    // Ohne gelesenes Paket steht ein Strich — keine erfundene Nummer.
    expect(find.textContaining('Version'), findsOneWidget);
  });

  testWidgets('„Info" öffnet die Unterseite mit Rechtlichem und Auskünften',
      (tester) async {
    await _pump(tester, const SettingsScreen());

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    expect(find.byType(InfoScreen), findsOneWidget);
    expect(find.text('RECHTLICHES'), findsOneWidget);
    expect(find.text('ÜBER DIE APP'), findsOneWidget);
    expect(find.text('Datenschutz'), findsOneWidget);
    // Die Version bleibt draussen — sie steht auf der Profilseite.
    expect(find.text('VERSION'), findsNothing);
  });

  testWidgets('kein Themenschalter, aber die Tatsache dazu', (tester) async {
    await _pump(tester, const InfoScreen());

    expect(find.textContaining('keine helle Fassung'), findsOneWidget);
    // Es darf keine Zeile geben, die ein helles Thema anböte.
    expect(find.text('Hell'), findsNothing);
  });

  testWidgets('das Körpergewicht ist eine Ableitung, kein Eingabefeld',
      (tester) async {
    await _pump(tester, const SettingsScreen());

    // Board 14, E: Die Zeile zeigt den jüngsten Verlaufseintrag samt Datum
    // und Herkunft — und nennt damit ihre Grundlage.
    expect(find.textContaining('Zuletzt'), findsWidgets);
    expect(find.textContaining('Eigene Eingabe'), findsOneWidget);

    // Es gibt nur noch **einen** Weg zu schreiben: den Verlauf.
    await tester.tap(find.text('Körpergewicht'));
    await tester.pumpAndSettle();

    expect(find.byType(WeightHistoryScreen), findsOneWidget);
    expect(find.text('Speichern und neu rechnen'), findsNothing);
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
    expect(find.text('Eine Sache bleibt'), findsOneWidget);
    expect(find.textContaining('wieder drin'), findsOneWidget);
  });
}
