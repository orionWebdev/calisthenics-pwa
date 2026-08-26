import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ));
}

void main() {
  group('AtemTappable', () {
    testWidgets('vergrößert die Fläche auf 48 dp, das Kind bleibt klein',
        (tester) async {
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Pause',
          onTap: () {},
          child: const SizedBox(width: 24, height: 24),
        ),
      );

      // Die Layoutfläche — und damit die Semantics-Größe — ist 48x48.
      expect(tester.getSize(find.byType(AtemTappable)), const Size(48, 48));
      // Das sichtbare Kind bleibt bei 24.
      expect(tester.getSize(find.byType(SizedBox).first), const Size(24, 24));
    });

    testWidgets('größere Kinder werden nicht beschnitten', (tester) async {
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Breit',
          onTap: () {},
          child: const SizedBox(width: 200, height: 60),
        ),
      );
      expect(tester.getSize(find.byType(AtemTappable)), const Size(200, 60));
    });

    testWidgets('besteht die Android-Tap-Ziel-Prüfung', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Workout beenden',
          onTap: () {},
          child: const SizedBox(width: 20, height: 20),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('meldet Rolle, Label und Zustand', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Analytics',
          semanticHint: 'Tab 3 von 5',
          selected: true,
          onTap: () {},
          child: const SizedBox.square(dimension: 20),
        ),
      );

      final node = tester.getSemantics(find.byType(AtemTappable));
      expect(node.label, 'Analytics');
      expect(node.hint, 'Tab 3 von 5');
      // isButton liefert bool, isSelected/isEnabled liefern Tristate.
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('onTap null meldet deaktiviert und löst nichts aus',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemTappable(
          semanticLabel: 'Gesperrt',
          onTap: null,
          child: SizedBox.square(dimension: 20),
        ),
      );

      final node = tester.getSemantics(find.byType(AtemTappable));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);

      await tester.tap(find.byType(AtemTappable));
      await tester.pump();
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('schließt die Semantics des Kindes aus', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Session starten',
          onTap: () {},
          // Ohne ExcludeSemantics läse ein Screenreader beides vor.
          child: const Text('SESSION STARTEN'),
        ),
      );

      final node = tester.getSemantics(find.byType(AtemTappable));
      expect(node.label, 'Session starten');
      expect(find.bySemanticsLabel('SESSION STARTEN'), findsNothing);
      handle.dispose();
    });

    testWidgets('löst onTap aus', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AtemTappable(
          semanticLabel: 'Zähler',
          onTap: () => taps++,
          child: const SizedBox.square(dimension: 20),
        ),
      );
      await tester.tap(find.byType(AtemTappable));
      expect(taps, 1);
    });
  });
}
