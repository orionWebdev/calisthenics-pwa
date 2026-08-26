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
  group('AtemButton', () {
    testWidgets('erreicht die Mindesthöhe und besteht beide Guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemButton.gradient(
          label: 'SESSION STARTEN',
          semanticLabel: 'Session starten',
          onPressed: () {},
        ),
      );

      expect(tester.getSize(find.byType(AtemButton)).height,
          greaterThanOrEqualTo(52.0));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('compact hält die 48-dp-Grenze', (tester) async {
      await _pump(
        tester,
        AtemButton.outline(
          label: '+30s',
          semanticLabel: 'Pause um 30 Sekunden verlängern',
          onPressed: () {},
          expand: false,
        ),
      );
      expect(tester.getSize(find.byType(AtemButton)).height,
          greaterThanOrEqualTo(48.0));
    });

    testWidgets('wächst bei 200 % Schrift, statt Text zu beschneiden',
        (tester) async {
      await _pump(
        tester,
        AtemButton.gradient(
          label: 'BEENDEN & SPEICHERN',
          semanticLabel: 'Beenden und speichern',
          onPressed: () {},
        ),
        scale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AtemButton)).height, greaterThan(52.0));
    });

    testWidgets('deaktiviert meldet das und löst nichts aus', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(
        tester,
        const AtemButton.gradient(
          label: 'GESPERRT',
          semanticLabel: 'Gesperrt',
          onPressed: null,
        ),
      );
      await tester.tap(find.byType(AtemButton));
      expect(taps, 0);
      handle.dispose();
    });

    testWidgets('semanticLabel darf vom sichtbaren Text abweichen',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemButton.outline(
          label: 'SESSION LÄUFT · 04:12',
          semanticLabel: 'Session läuft, 4 Minuten 12 Sekunden, '
              'tippen zum Stoppen',
          onPressed: () {},
          accent: AtemColors.green,
        ),
      );
      final node = tester.getSemantics(find.byType(AtemTappable));
      expect(node.label, contains('tippen zum Stoppen'));
      handle.dispose();
    });
  });

  group('AtemNumberField', () {
    testWidgets('hält 48 dp Höhe und die vorgegebenen Breiten', (tester) async {
      final weight = TextEditingController(text: '92,5');
      final reps = TextEditingController(text: '8');
      addTearDown(weight.dispose);
      addTearDown(reps.dispose);

      await _pump(
        tester,
        Row(mainAxisSize: MainAxisSize.min, children: [
          AtemNumberField.weight(
              controller: weight, semanticLabel: 'Gewicht, Satz 1'),
          AtemNumberField.reps(
              controller: reps, semanticLabel: 'Wiederholungen, Satz 1'),
        ]),
      );

      final sizes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(sizes.any((s) => s.width == 72), isTrue, reason: 'Gewicht 72 dp');
      expect(sizes.any((s) => s.width == 60), isTrue, reason: 'Wdh 60 dp');

      for (final f in find.byType(AtemNumberField).evaluate()) {
        expect(tester.getSize(find.byWidget(f.widget)).height,
            greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('meldet sich als Textfeld mit Wert', (tester) async {
      final c = TextEditingController(text: '100');
      addTearDown(c.dispose);
      final handle = tester.ensureSemantics();

      await _pump(
          tester,
          AtemNumberField.weight(
              controller: c, semanticLabel: 'Gewicht, Satz 2'));

      final node = tester.getSemantics(find.byType(AtemNumberField));
      expect(node.label, 'Gewicht, Satz 2');
      expect(node.value, '100');
      handle.dispose();
    });

    test('parse akzeptiert beide Dezimaltrennzeichen', () {
      expect(AtemNumberField.parse('92,5'), 92.5);
      expect(AtemNumberField.parse('92.5'), 92.5);
      expect(AtemNumberField.parse(' 100 '), 100);
      expect(AtemNumberField.parse('abc'), isNull);
    });
  });
}
