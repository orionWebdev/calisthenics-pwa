import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Regler aus dem Runner: ziehen statt tippen, mit Schrittweite und
/// Tastatur als zweitem Weg.
///
/// Die Zahlen in den Tests hängen an [AtemStepInput.pixelsPerStep] — 18 dp je
/// Rastpunkt. 90 dp Ziehen sind damit fünf Schritte, unabhängig davon, wie
/// gross ein Schritt gerade ist.
void main() {
  late TextEditingController controller;
  late List<String> changes;

  setUp(() {
    controller = TextEditingController();
    changes = [];
  });

  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    List<double> steps = const [1],
    String? unit,
    double min = 0,
    double? max,
    int decimals = 0,
    double width = 361,
    double scale = 1.0,
    bool enabled = true,
  }) async {
    tester.view.physicalSize = Size(width, 800);
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AtemStepInput(
            label: 'KG',
            controller: controller,
            onChanged: changes.add,
            steps: steps,
            semanticLabel: 'Gewicht, Satz 1',
            unit: unit,
            min: min,
            max: max,
            decimals: decimals,
            enabled: enabled,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Zieht das Band, ohne loszulassen — so mischt sich kein Nachlauf in die
  /// Messung. Nach links heisst mehr, wie bei einem echten Rad.
  Future<TestGesture> dragBy(WidgetTester tester, double dx) async {
    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(AtemStepInput.rulerKey)));
    await gesture.moveBy(Offset(dx, 0));
    await tester.pump();
    return gesture;
  }

  testWidgets('Ziehen rastet in Schritten und meldet den Text der App',
      (tester) async {
    controller.text = '60';
    await pump(tester);

    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(AtemStepInput.rulerKey)));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(-AtemStepInput.pixelsPerStep, 0));
      await tester.pump();
    }

    expect(controller.text, '65');
    // Jeder Rastpunkt meldet sich einzeln, nicht erst das Ende der Geste.
    expect(changes, ['61', '62', '63', '64', '65']);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.text, '65');
  });

  testWidgets('nach rechts zieht den Wert herunter', (tester) async {
    controller.text = '60';
    await pump(tester);

    final gesture = await dragBy(tester, 3 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '57');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('die Schrittweite ändert die Rastung', (tester) async {
    controller.text = '60';
    await pump(tester, steps: const [0.5, 1, 5], decimals: 1);

    // Standard ist die erste Schrittweite: halbe Kilogramm.
    var gesture = await dragBy(tester, -2 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '61');
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    // Fünfer rasten auf dem Fünfergitter: aus 61 werden 70, nicht 71.
    gesture = await dragBy(tester, -2 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '70');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('halbe Schritte schreiben ein Komma', (tester) async {
    controller.text = '60';
    await pump(tester, steps: const [0.5, 1, 5], decimals: 1);

    final gesture = await dragBy(tester, -AtemStepInput.pixelsPerStep);
    expect(controller.text, '60,5');
    expect(changes.single, '60,5');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('min und max halten den Wert im Rahmen', (tester) async {
    controller.text = '8';
    await pump(tester, min: 2, max: 10);

    var gesture = await dragBy(tester, -20 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '10');
    await gesture.up();
    await tester.pumpAndSettle();

    gesture = await dragBy(tester, 30 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '2');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('ohne Eingabe bleibt der Wert leer, bis jemand zieht',
      (tester) async {
    await pump(tester, min: 0);
    expect(controller.text, isEmpty);
    expect(changes, isEmpty);

    final gesture = await dragBy(tester, -3 * AtemStepInput.pixelsPerStep);
    expect(controller.text, '3');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('die Tastatur zeigt das bekannte Zahlenfeld', (tester) async {
    controller.text = '60';
    await pump(tester, steps: const [0.5, 1], decimals: 1, unit: 'kg');

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AtemNumberField), findsOneWidget);
    expect(find.byKey(AtemStepInput.rulerKey), findsNothing);

    await tester.enterText(find.byType(TextField), '82,5');
    expect(changes.last, '82,5');

    // Zurück zum Band — der getippte Wert steht dort weiter.
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.byKey(AtemStepInput.rulerKey), findsOneWidget);
    expect(find.text('82,5'), findsOneWidget);
  });

  testWidgets('die gewählte Schrittweite überlebt den Moduswechsel',
      (tester) async {
    controller.text = '60';
    await pump(tester, steps: const [0.5, 1, 5], decimals: 1);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final gesture = await dragBy(tester, -AtemStepInput.pixelsPerStep);
    expect(controller.text, '65');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('der Regler ist ein Slider für den Screenreader',
      (tester) async {
    final handle = tester.ensureSemantics();
    controller.text = '60';
    await pump(tester);

    final node = tester.getSemantics(find.byKey(AtemStepInput.rulerKey));
    expect(node.flagsCollection.isSlider, isTrue);
    expect(node.label, 'Gewicht, Satz 1');
    expect(node.value, '60');
    expect(node.increasedValue, '61');
    expect(node.decreasedValue, '59');

    final slider = find.semantics.byLabel('Gewicht, Satz 1');
    tester.semantics.increase(slider);
    await tester.pumpAndSettle();
    expect(controller.text, '61');

    tester.semantics.decrease(slider);
    await tester.pumpAndSettle();
    expect(controller.text, '60');
    handle.dispose();
  });

  testWidgets('mit Schwung läuft das Band nach und rastet dann ein',
      (tester) async {
    controller.text = '60';
    tester.view.physicalSize = const Size(361, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Ohne „disableAnimations": Hier läuft der Nachlauf wirklich.
    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AtemStepInput(
            label: 'KG',
            controller: controller,
            onChanged: changes.add,
            steps: const [1],
            semanticLabel: 'Gewicht, Satz 1',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.fling(
        find.byKey(AtemStepInput.rulerKey), const Offset(-120, 0), 600);
    await tester.pumpAndSettle();

    final settled = double.parse(controller.text);
    // Der Schwung trägt über die gezogene Strecke hinaus …
    expect(settled, greaterThan(66));
    // … und bleibt auf einem Rastpunkt stehen, nicht dazwischen.
    expect(settled, settled.roundToDouble());
    expect(tester.takeException(), isNull);
  });

  testWidgets('deaktiviert schreibt keine Geste einen Wert', (tester) async {
    controller.text = '60';
    await pump(tester, enabled: false);

    await tester.drag(
        find.byKey(AtemStepInput.rulerKey), const Offset(-90, 0));
    await tester.pumpAndSettle();
    expect(controller.text, '60');
    expect(changes, isEmpty);
  });

  testWidgets('200 % Schrift auf 320 dp läuft nicht über', (tester) async {
    controller.text = '60';
    await pump(tester,
        steps: const [0.5, 1, 5], decimals: 1, unit: 'kg', width: 320,
        scale: 2.0);

    expect(tester.takeException(), isNull);
    final gesture = await dragBy(tester, -AtemStepInput.pixelsPerStep);
    expect(controller.text, '60,5');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
