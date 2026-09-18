import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Das Eingabeblatt des Runners — Gestalt und Verhalten aus der
/// Claude-Design-Vorlage `TEM Workout Runner.dc.html`.
Future<double?> _applied(WidgetTester tester) async => _lastApplied;
double? _lastApplied;

Future<void> _pumpPad(
  WidgetTester tester, {
  AtemStepField field = AtemStepField.weight,
  int setNumber = 2,
  double? value,
  double? previousValue,
  String? previousLabel,
  double width = 361,
  double scale = 1.0,
}) async {
  _lastApplied = null;
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
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
    home: Scaffold(
      backgroundColor: AtemColors.base,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: AtemStepPad(
          // Eigener Key je Pump: Ohne ihn hält Flutter den State des vorigen
          // Blattes fest, und ein zweiter Pump im selben Test behielte die
          // Konfiguration des ersten Feldes.
          key: ValueKey('$field-$value-$setNumber'),
          field: field,
          setNumber: setNumber,
          value: value,
          previousValue: previousValue,
          previousLabel: previousLabel,
          onApply: (v) => _lastApplied = v,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Die grosse Zahl steht als einziger Mono-Text über dem Band.
String _bigValue(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => (t.style?.fontSize ?? 0) >= 28)
      .toList();
  expect(texts, isNotEmpty, reason: 'Die grosse Zahl fehlt');
  return texts.first.data!;
}

void main() {
  group('Aufbau', () {
    testWidgets('Titel, Vorwert, Wert und Einheit stehen', (tester) async {
      await _pumpPad(tester,
          value: 60, previousValue: 55, previousLabel: '55 kg × 8');

      expect(find.text('GEWICHT · SATZ 2'), findsOneWidget);
      expect(find.text('Letztes Mal: 55 kg × 8'), findsOneWidget);
      expect(_bigValue(tester), '60');
      expect(find.text('KG'), findsOneWidget);
      expect(find.text('ÜBERNEHMEN'), findsOneWidget);
    });

    testWidgets('ohne Wert und Vorwert öffnet der Rückfallwert der Vorlage',
        (tester) async {
      await _pumpPad(tester);
      expect(_bigValue(tester), '20');
      // Ohne Vorwert steht keine Vorwertzeile und keine Delta-Zeile.
      expect(find.textContaining('Letztes Mal'), findsNothing);
      expect(find.textContaining('ZU LETZTEM MAL'), findsNothing);
    });

    testWidgets('Schrittkapseln je Feld wie in der Vorlage', (tester) async {
      await _pumpPad(tester, value: 60);
      expect(find.text('0,5 kg'), findsOneWidget);
      expect(find.text('1 kg'), findsOneWidget);
      expect(find.text('5 kg'), findsOneWidget);

      await _pumpPad(tester, field: AtemStepField.reps, value: 8);
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);

      await _pumpPad(tester, field: AtemStepField.hold, value: 45);
      expect(find.text('1 s'), findsOneWidget);
      expect(find.text('5 s'), findsOneWidget);
      expect(find.text('SEK'), findsOneWidget);
      // Halten startet auf Schritt 5 — so steht es in der Vorlage.
      expect(find.text('ZIEHEN ZUM EINSTELLEN · SCHRITT 5 s'), findsOneWidget);
    });
  });

  group('Band', () {
    testWidgets('Ziehen nach links erhöht in Schrittweiten', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(-60, 0));
      await tester.pumpAndSettle();
      // 30 dp je Schritt, Schritt 1 → zwei Schritte.
      expect(_bigValue(tester), '62');
    });

    testWidgets('Ziehen nach rechts verringert', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(90, 0));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '57');
    });

    testWidgets('die Schrittkapsel ändert die Rastung', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.tap(find.text('5 kg'));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(-30, 0));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '65');

      await tester.tap(find.text('0,5 kg'));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(-30, 0));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '65,5');
    });

    testWidgets('− und + gehen einen Schritt', (tester) async {
      await _pumpPad(tester, field: AtemStepField.reps, value: 8);
      final handle = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('Wert erhöhen'));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '9');

      await tester.tap(find.bySemanticsLabel('Wert verringern'));
      await tester.tap(find.bySemanticsLabel('Wert verringern'));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '7');
      handle.dispose();
    });

    testWidgets('die Grenzen der Vorlage halten', (tester) async {
      await _pumpPad(tester, field: AtemStepField.reps, value: 2);
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '1', reason: 'Wiederholungen beginnen bei 1');

      await _pumpPad(tester, field: AtemStepField.weight, value: 399);
      await tester.tap(find.text('5 kg'));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '400', reason: 'Gewicht endet bei 400');
    });

    testWidgets('das Band meldet sich als Regler mit Zu- und Abnahme',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPad(tester, value: 60);

      final node = tester.getSemantics(
          find.bySemanticsLabel('Gewicht in Kilogramm, ziehen zum Einstellen'));
      expect(node.value, '60 KG');
      expect(node.increasedValue, '61 KG');
      expect(node.decreasedValue, '59 KG');

      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      handle.dispose();
    });
  });

  group('Delta', () {
    testWidgets('nennt den Unterschied ohne Ampelfarbe', (tester) async {
      await _pumpPad(tester,
          value: 60, previousValue: 55, previousLabel: '55 kg × 8');

      final delta = find.text('+5 KG ZU LETZTEM MAL');
      expect(delta, findsOneWidget);
      expect(
        tester.widget<Text>(delta).style?.color,
        AtemColors.textTertiary,
        reason: 'CLAUDE.md: Deltas tragen keine Ampelfarbe',
      );
    });

    testWidgets('verschwindet, sobald der Wert den Vorwert trifft',
        (tester) async {
      await _pumpPad(tester, value: 55, previousValue: 55);
      expect(find.textContaining('ZU LETZTEM MAL'), findsNothing);
    });
  });

  group('Tastatur', () {
    testWidgets('Umschalter zeigt Feld und Schnellknöpfe', (tester) async {
      await _pumpPad(tester, value: 60);
      expect(find.byKey(AtemStepPad.rulerKey), findsOneWidget);

      await tester.tap(find.text('TASTATUR'));
      await tester.pumpAndSettle();

      expect(find.byKey(AtemStepPad.rulerKey), findsNothing);
      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('−5'), findsOneWidget);
      expect(find.text('REGLER'), findsOneWidget);
    });

    testWidgets('Tippen und Schnellknopf ändern den Wert', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.tap(find.text('TASTATUR'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), '72,5');
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '72,5');

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '77,5');
    });

    testWidgets('zurück zum Regler behält den Wert', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.tap(find.text('TASTATUR'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '80');
      await tester.pumpAndSettle();
      await tester.tap(find.text('REGLER'));
      await tester.pumpAndSettle();
      expect(_bigValue(tester), '80');
      expect(find.byKey(AtemStepPad.rulerKey), findsOneWidget);
    });
  });

  group('Übernehmen', () {
    testWidgets('gibt den eingestellten Wert zurück', (tester) async {
      await _pumpPad(tester, value: 60);
      await tester.drag(find.byKey(AtemStepPad.rulerKey), const Offset(-30, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ÜBERNEHMEN'));
      await tester.pumpAndSettle();
      expect(await _applied(tester), 61);
    });

    testWidgets('das Blatt schliesst und liefert den Wert; Abbruch gibt null',
        (tester) async {
      double? result;
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  opened++;
                  result = await showAtemStepPad(
                    context,
                    field: AtemStepField.weight,
                    setNumber: 1,
                    value: 60,
                  );
                },
                child: const Text('öffnen'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
      expect(find.text('GEWICHT · SATZ 1'), findsOneWidget);
      await tester.tap(find.text('ÜBERNEHMEN'));
      await tester.pumpAndSettle();
      expect(result, 60);
      expect(find.text('GEWICHT · SATZ 1'), findsNothing);

      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
      // Zurück-Geste statt Übernehmen: kein Wert.
      Navigator.of(tester.element(find.text('GEWICHT · SATZ 1'))).pop();
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(opened, 2);
    });
  });

  testWidgets('200 % Schrift auf 320 dp läuft nicht über', (tester) async {
    await _pumpPad(tester,
        value: 107.5,
        previousValue: 100,
        previousLabel: '100 kg × 8',
        width: 320,
        scale: 2.0);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('TASTATUR'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
