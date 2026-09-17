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

  testWidgets('Schwellenblock: „was" steht hinter ⓘ, Bedingung bleibt sichtbar',
      (tester) async {
    await _pump(
      tester,
      const AtemThresholdBlock(
        title: 'Fortschritte',
        what: 'Neue Bestwerte der letzten 4 Wochen.',
        condition: 'Erscheint ab der zweiten Ausführung',
        current: 1,
        required: 2,
      ),
    );
    expect(find.text('Erscheint ab der zweiten Ausführung'), findsOneWidget);
    expect(find.text('Neue Bestwerte der letzten 4 Wochen.'), findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.text('Neue Bestwerte der letzten 4 Wochen.'), findsOneWidget);
  });

  test('Metazeilen und Mono-Köpfe stehen in der dritten Textstufe', () {
    expect(AtemType.meta.base.color, AtemColors.textSecondary);
    expect(AtemType.labelMicro.base.color, AtemColors.textSecondary);
    expect(AtemType.labelSmall.base.color, AtemColors.textTertiary);
  });
}
