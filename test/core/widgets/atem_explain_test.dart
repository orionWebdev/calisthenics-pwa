import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {double width = 361, double scale = 1.0}) async {
  tester.view.physicalSize = Size(width, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: c!,
    ),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  const explanation = ['Wie viele Sätze du Woche für Woche machst.', 'Kein Sollwert.'];

  testWidgets('Erklärung ist zugeklappt und klappt per ⓘ auf und zu',
      (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(
        title: 'Sätze je Woche',
        trailing: '8 Wochen',
        explanation: explanation,
      ),
    );
    expect(find.text('Sätze je Woche'), findsOneWidget);
    expect(find.text('8 Wochen'), findsOneWidget);
    expect(find.text(explanation.first), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.text(explanation.first), findsOneWidget);
    expect(find.text(explanation.last), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text(explanation.first), findsNothing);
  });

  testWidgets('ⓘ trägt ein Vorlese-Label mit Titel und Zustand, 48 dp Ziel',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const AtemExplainHeader(title: 'Fokus', explanation: explanation),
    );
    final open = find.bySemanticsLabel('Erklärung zu Fokus, aufklappen');
    expect(open, findsOneWidget);
    final size = tester.getSize(open);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));

    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Erklärung zu Fokus, zuklappen'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ohne Erklärung gibt es kein ⓘ', (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(title: 'Fokus', explanation: []),
    );
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('200 % auf 320 dp aufgeklappt ohne Überlauf', (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(
        title: 'Geschätztes Maximum',
        trailing: '8 Wochen',
        explanation: explanation,
      ),
      width: 320,
      scale: 2.0,
    );
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // Seit Board 13 (20.09.2026) trägt der gesperrte Block **kein ⓘ**: Er
  // zeigt drei Dinge und keine vierte — Name, Umriss, Bedingung mit Nenner —
  // und hat keine Handlung, also auch kein Tap-Ziel. „Was er zeigen wird"
  // sagt seitdem die Form des Umrisses, nicht ein Satz hinter einem Knopf.
  testWidgets('Schwellenblock: Bedingung sichtbar, kein ⓘ, kein Tap-Ziel',
      (tester) async {
    await _pump(
      tester,
      const AtemThresholdBlock(
        title: 'Fortschritte',
        condition: 'Erscheint ab der zweiten Ausführung',
        current: 1,
        required: 2,
      ),
    );
    expect(find.text('Erscheint ab der zweiten Ausführung'), findsOneWidget);
    expect(find.text('Fortschritte'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(
      find.descendant(
          of: find.byType(AtemThresholdBlock),
          matching: find.byType(GestureDetector)),
      findsNothing,
      reason: 'gesperrt heisst: es gibt nichts zu tun',
    );
  });

  testWidgets('passt alles: Titel einzeilig, Zeitraum und ⓘ rechtsbündig',
      (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(
        // Kurz, weil die Testschrift jedes Zeichen quadratisch zeichnet.
        title: 'Tage',
        trailing: '12 W',
        explanation: explanation,
      ),
    );
    final title = tester.getRect(find.text('Tage'));
    final trailing = tester.getRect(find.text('12 W'));
    final info = tester.getRect(find.byIcon(Icons.info_outline));
    // eine Zeile
    expect((title.center.dy - trailing.center.dy).abs(), lessThan(4));
    // Titel nicht umbrochen: Höhe einer Zeile
    expect(title.height, lessThan(40));
    // Zeitraum steht direkt vor dem ⓘ, beide ganz rechts
    expect(info.right, greaterThan(361 - 16 - 32));
    expect(info.left - trailing.right, lessThan(24));
  });

  testWidgets('passt es nicht: Titel behält Vorrang, Zeitraum in Zeile 2',
      (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(
        title: 'Einheiten je Monat',
        trailing: 'KW 38 · 2 Einheiten',
        explanation: explanation,
      ),
      width: 320,
      scale: 1.6,
    );
    final title = tester.getRect(find.text('Einheiten je Monat'));
    final trailing = tester.getRect(find.text('KW 38 · 2 Einheiten'));
    expect(trailing.top, greaterThanOrEqualTo(title.bottom - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('langes Wort bei 200 % auf 320 dp bricht nicht im Wort',
      (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(
        title: 'Trainingszeit',
        trailing: 'KW 38',
        explanation: explanation,
      ),
      width: 320,
      scale: 2.0,
    );
    final title = tester.getRect(find.text('Trainingszeit'));
    final info = tester.getRect(find.byIcon(Icons.info_outline));
    // ⓘ steht unter dem Titel, nicht daneben — der Titel hat die volle Breite
    expect(info.top, greaterThanOrEqualTo(title.bottom - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ⓘ sitzt bündig am rechten Rand', (tester) async {
    await _pump(
      tester,
      const AtemExplainHeader(title: 'Tage', explanation: explanation),
    );
    final info = tester.getRect(find.byIcon(Icons.info_outline));
    // Gemessen wird das 14-dp-Symbol im 24-dp-Kreis im 32-dp-Kasten — der
    // Kreis selbst liegt am Rand, das Symbol sitzt darin rund 13 dp davor.
    expect(361 - 16 - info.right, lessThan(16));
  });
}
