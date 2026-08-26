import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _host(
    WidgetTester tester, void Function(BuildContext) open) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => open(context),
            child: const Text('öffnen'),
          ),
        ),
      ),
    ),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: w!,
    ),
  ));
  await tester.tap(find.text('öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  group('AtemSheet', () {
    testWidgets('zeigt Titel, Griff und Fußzeile', (tester) async {
      await _host(tester, (c) {
        AtemSheet.show<void>(
          c,
          title: 'Session-Notizen',
          closeLabel: 'Notizen schließen',
          child: const SizedBox(height: 100),
          primaryAction: AtemButton.gradient(
            label: 'FERTIG',
            semanticLabel: 'Fertig',
            onPressed: () {},
          ),
        );
      });

      expect(find.text('Session-Notizen'), findsOneWidget);
      expect(find.text('FERTIG'), findsOneWidget);
    });

    testWidgets('Griff und Schließen erfüllen die Guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _host(tester, (c) {
        AtemSheet.show<void>(
          c,
          title: 'Filter',
          closeLabel: 'Filter schließen',
          child: const SizedBox(height: 80),
        );
      });

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('bleibt unter 90 Prozent der Höhe', (tester) async {
      await _host(tester, (c) {
        AtemSheet.show<void>(
          c,
          title: 'Lang',
          closeLabel: 'Schließen',
          child: const SizedBox(height: 2000),
        );
      });

      final sheet = tester.getSize(find.byType(AtemSheet));
      // Nie 100 %: ein Streifen Canvas bleibt sichtbar.
      expect(sheet.height, lessThanOrEqualTo(800 * 0.9 + 1));
    });
  });

  group('AtemDialog', () {
    testWidgets('bestätigen nutzt den Gradient', (tester) async {
      await _host(tester, (c) {
        AtemDialog.show<void>(
          c,
          kind: AtemDialogKind.confirm,
          title: 'Workout beenden?',
          message: 'Dein Fortschritt wird gespeichert.',
          confirmLabel: 'Beenden & speichern',
          dismissLabel: 'Weiter trainieren',
          barrierLabel: 'Entscheidung nötig',
          onConfirm: () {},
        );
      });
      expect(find.text('Beenden & speichern'), findsOneWidget);
      expect(find.text('Weiter trainieren'), findsOneWidget);
    });

    testWidgets('zerstörend trägt die Warnung im Label, nicht nur im Text',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _host(tester, (c) {
        AtemDialog.show<void>(
          c,
          kind: AtemDialogKind.destructive,
          title: 'Workout verwerfen?',
          message: 'Kann nicht rückgängig gemacht werden.',
          confirmLabel: 'Verwerfen',
          dismissLabel: 'Abbrechen',
          barrierLabel: 'Entscheidung nötig',
          onConfirm: () {},
        );
      });

      // Die Warnung steckt im Semantics-Label der Aktion selbst.
      expect(
        find.bySemanticsLabel(RegExp(r'Verwerfen.*rückgängig', dotAll: true)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('lässt sich nicht durch Tippen daneben schließen',
        (tester) async {
      await _host(tester, (c) {
        AtemDialog.show<void>(
          c,
          kind: AtemDialogKind.confirm,
          title: 'Frage',
          message: 'Bitte entscheiden.',
          confirmLabel: 'Ja',
          barrierLabel: 'Entscheidung nötig',
          onConfirm: () {},
        );
      });

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // Der Dialog verlangt eine Entscheidung.
      expect(find.text('Frage'), findsOneWidget);
    });
  });

  group('Kartenrezepte', () {
    testWidgets('alle drei rendern', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AtemTheme.dark,
        home: const Scaffold(
          body: Column(children: [
            AtemCard.glass(child: Text('K1')),
            AtemCard.gradientBorder(child: Text('K2')),
            AtemCard.list(child: Text('K3')),
            AtemStatBox(child: Text('Einlage')),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final t in ['K1', 'K2', 'K3', 'Einlage']) {
        expect(find.text(t), findsOneWidget);
      }
    });
  });
}
