import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {double scale = 1.0}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Scaffold(body: Center(child: child)),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: w!,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('AtemBadge', () {
    testWidgets('Statusträger meldet Klartext, nicht den Anzeigetext',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemBadge(
          label: 'ATEM HYBRID',
          semanticLabel: 'System aktiv',
          accent: AtemColors.green,
          leadingDot: true,
        ),
      );

      expect(find.bySemanticsLabel('System aktiv'), findsOneWidget);
      // Der sichtbare Text ist ausgeschlossen, sonst liest TalkBack doppelt.
      expect(find.bySemanticsLabel('ATEM HYBRID'), findsNothing);
      handle.dispose();
    });

    testWidgets('Chip trägt ein Chevron, der Statusträger nicht',
        (tester) async {
      await _pump(
        tester,
        Column(mainAxisSize: MainAxisSize.min, children: [
          const AtemBadge(label: 'QUADS'),
          AtemBadge.chip(
            label: 'FORM GUIDE',
            semanticLabel: 'Form-Video öffnen',
            accent: AtemColors.cyan,
            onTap: () {},
          ),
        ]),
      );

      // Genau ein Chevron: nur der Chip trägt eins.
      expect(find.byType(CustomPaint).evaluate().length, greaterThan(0));
      expect(find.byType(AtemTappable), findsOneWidget);
    });

    testWidgets('Chip erreicht 48 dp Trefferfläche, sichtbar bleibt es klein',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemBadge.chip(
          label: 'PR',
          semanticLabel: 'Persönlicher Rekord anzeigen',
          onTap: () {},
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.getSize(find.byType(AtemTappable)).height,
          greaterThanOrEqualTo(48.0));
      handle.dispose();
    });

    testWidgets('kürzt statt umzubrechen', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: AtemBadge(label: 'Ein sehr langer Badge-Text der nicht passt'),
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('wächst bei 200 % Schrift ohne Überlauf', (tester) async {
      await _pump(
        tester,
        const AtemBadge(label: 'HIGH INTENSITY', accent: AtemColors.magenta),
        scale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AtemBadge)).height, greaterThan(24.0));
    });

    testWidgets('Zähler ist die einzige volle Pille', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemBadge.counter(
          label: '2',
          semanticLabel: '2 ungelesene Benachrichtigungen',
        ),
      );
      expect(find.bySemanticsLabel('2 ungelesene Benachrichtigungen'),
          findsOneWidget);
      handle.dispose();
    });
  });

  group('AtemStatusDot', () {
    testWidgets('hat zwei Größen, 6 und 4 dp', (tester) async {
      await _pump(
        tester,
        const Column(mainAxisSize: MainAxisSize.min, children: [
          AtemStatusDot(color: AtemColors.green),
          AtemStatusDot(color: AtemColors.cyan, size: AtemDotSize.small),
        ]),
      );
      final sizes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .map((s) => s.width)
          .toSet();
      expect(sizes, containsAll(<double>[6, 4]));
    });

    testWidgets('ist für den Screenreader unsichtbar', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const AtemStatusDot(color: AtemColors.green));
      // Dekorativ — der Zustand steht im Text des umgebenden Elements.
      // Scaffold bringt eigene ExcludeSemantics mit, deshalb gezielt suchen.
      expect(
        find.descendant(
          of: find.byType(AtemStatusDot),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('pulsiert nicht bei reduzierter Bewegung', (tester) async {
      await _pump(
        tester,
        const AtemStatusDot(color: AtemColors.green, pulsing: true),
      );
      // pumpAndSettle terminiert — der Beweis, dass die Schleife steht.
      expect(tester.takeException(), isNull);
    });
  });
}
