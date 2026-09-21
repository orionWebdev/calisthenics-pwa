import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/settings/presentation/screens/account_deletion_screen.dart';
import 'package:atem/features/settings/presentation/screens/effort_scale_screen.dart';
import 'package:atem/features/settings/presentation/screens/info_screen.dart';
import 'package:atem/features/settings/presentation/screens/settings_screen.dart';
import 'package:atem/features/weight/presentation/screens/weight_history_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

Future<AppL10n> _pump(WidgetTester tester, Widget home) async {
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
  return AppL10n.of(tester.element(find.byWidget(home)));
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
    final handle = tester.ensureSemantics();
    await _pump(tester, const SettingsScreen());

    // Board 14, E: Die Zeile zeigt den jüngsten Verlaufseintrag und nennt
    // damit ihre Grundlage — **vorgelesen**. Sichtbar steht seit dem
    // 21.09.2026 keine Unterzeile mehr da: „Zuletzt 21. Sept. · Eigene
    // Eingabe" unter jeder Einstellung machte die Seite unruhig.
    expect(find.textContaining('Zuletzt'), findsNothing);
    expect(find.textContaining('Eigene Eingabe'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^Körpergewicht, .*Zuletzt')),
        findsOneWidget);

    // Es gibt nur noch **einen** Weg zu schreiben: den Verlauf.
    //
    // `.first`: Seit Board 15 trägt auch die Health-Connect-Zeile das Wort
    // „Körpergewicht" — je Datentyp eine Zeile. Gemeint ist die Zeile im
    // Körper-Abschnitt, und die steht zuerst.
    await tester.tap(find.text('Körpergewicht').first);
    await tester.pumpAndSettle();

    expect(find.byType(WeightHistoryScreen), findsOneWidget);
    expect(find.text('Speichern und neu rechnen'), findsNothing);
    handle.dispose();
  });

  testWidgets('keine Unterzeilen unter den Einstellungen', (tester) async {
    final handle = tester.ensureSemantics();
    final l10n = await _pump(tester, const SettingsScreen());

    // Sichtbar steht nur die Zeile selbst. Die Erklärung bleibt dem, der sie
    // hört — Rückmeldung vom 21.09.2026: „zu viel Unruhe".
    for (final sub in [
      l10n.restSub,
      l10n.hapticsSub,
      l10n.exportSub,
      l10n.onboardingRepeatSub,
      l10n.infoSub,
    ]) {
      expect(find.text(sub), findsNothing, reason: sub);
    }
    // Vorgelesen wird sie trotzdem.
    expect(find.bySemanticsLabel(RegExp(l10n.restSub)), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Anstrengung je Satz führt auf eine Unterseite', (tester) async {
    final l10n = await _pump(tester, const SettingsScreen());

    // In der Liste steht nur die Zeile mit ihrem Wert — keine Segmente.
    expect(find.byType(AtemSegmented<EffortScale>), findsNothing);
    await tester.tap(find.text(l10n.settingsEffortScale));
    await tester.pumpAndSettle();

    expect(find.byType(EffortScaleScreen), findsOneWidget);
    expect(find.byType(AtemSegmented<EffortScale>), findsOneWidget);
    expect(find.text(l10n.settingsEffortScaleExplain), findsOneWidget);
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
