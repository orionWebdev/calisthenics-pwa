import 'dart:ui' show Tristate;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Ortszeile des One-Pagers (Board 13, seit 20.09.2026).
void main() {
  const labels = ['Trainieren', 'Verlauf', 'Auswertung', 'Pläne'];

  /// Vier Themen, das letzte bewusst kurz — es kann nie bis unter die Zeile
  /// steigen und muss trotzdem erreichbar sein.
  const heights = [900.0, 900.0, 900.0, 120.0];

  late List<int> reported;

  Future<void> pump(
    WidgetTester tester, {
    bool reduced = true,
    double width = 361,
    double scale = 1.0,
    int selected = 0,
  }) async {
    tester.view.physicalSize = Size(width, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    reported = [];

    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: AtemColors.base,
        body: AtemSectionPage(
          selected: selected,
          onSelected: reported.add,
          barSemanticLabel: (name, n, total) =>
              'Thema $name, $n von $total. Öffnet die Themenliste.',
          jumpListLabel: 'Springen zu',
          jumpSemanticLabel: (name, n, total) =>
              'Zu $name springen, $n von $total',
          arrivedSemanticLabel: (name, n, total) => '$name, $n von $total',
          hereLabel: 'HIER',
          sections: [
            for (var i = 0; i < labels.length; i++)
              AtemSection(
                label: labels[i],
                child: SizedBox(
                  height: heights[i],
                  child: Text('Inhalt ${labels[i]}'),
                ),
              ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  double barBottom(WidgetTester tester) =>
      tester.getRect(find.byType(AtemSectionBar)).bottom;

  /// Das Wort, das die Zeile gerade zeigt — das einzige sichtbare.
  String word(WidgetTester tester) {
    for (final l in labels) {
      final finder = find.descendant(
          of: find.byType(AtemSectionBar), matching: find.text(l));
      if (finder.evaluate().isNotEmpty) return l;
    }
    return '';
  }

  Future<void> openList(WidgetTester tester) async {
    await tester.tap(find.byType(AtemSectionBar));
    await tester.pumpAndSettle();
  }

  Future<void> scrollBy(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(CustomScrollView), Offset(0, dy),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('die Zeile zeigt genau ein Wort und den Zähler',
      (tester) async {
    await pump(tester);

    expect(word(tester), 'Trainieren');
    expect(find.text('1 / 4'), findsOneWidget);
    // Die anderen drei stehen nicht in der Zeile — genau das ist der Punkt.
    for (final l in ['Verlauf', 'Auswertung', 'Pläne']) {
      expect(
        find.descendant(
            of: find.byType(AtemSectionBar), matching: find.text(l)),
        findsNothing,
      );
    }
  });

  testWidgets('ein Tipp zeigt alle vier Wörter, ein zweiter schliesst wieder',
      (tester) async {
    await pump(tester);
    expect(find.byType(AtemSectionJumpList), findsNothing);

    await openList(tester);
    expect(find.byType(AtemSectionJumpList), findsOneWidget);
    for (final l in labels) {
      expect(
        find.descendant(
            of: find.byType(AtemSectionJumpList), matching: find.text(l)),
        findsOneWidget,
        reason: '$l muss vollständig dastehen',
      );
    }
    expect(find.text('HIER'), findsOneWidget);

    await openList(tester);
    expect(find.byType(AtemSectionJumpList), findsNothing);
  });

  testWidgets('eine Auswahl springt an den Anfang des Themas',
      (tester) async {
    await pump(tester);
    await openList(tester);
    await tester.tap(find.descendant(
        of: find.byType(AtemSectionJumpList), matching: find.text('Auswertung')));
    await tester.pumpAndSettle();

    expect(reported.last, 2);
    expect(word(tester), 'Auswertung');
    expect(find.byType(AtemSectionJumpList), findsNothing,
        reason: 'die Liste schliesst sich mit der Auswahl');
    expect(tester.getTopLeft(find.text('Inhalt Auswertung')).dy,
        closeTo(barBottom(tester), 0.5));
  });

  testWidgets('Scrollen schliesst die Liste', (tester) async {
    await pump(tester);
    await openList(tester);
    await scrollBy(tester, -120);
    expect(find.byType(AtemSectionJumpList), findsNothing);
  });

  testWidgets('die Zeile klebt oben, der Inhalt läuft darunter durch',
      (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byType(AtemSectionBar));
    await scrollBy(tester, -400);
    expect(tester.getRect(find.byType(AtemSectionBar)), before,
        reason: 'sie blendet nie aus — sie ist die einzige Ortsangabe');
  });

  testWidgets('Scrollen wechselt Wort und Zähler', (tester) async {
    await pump(tester);
    expect(word(tester), 'Trainieren');

    await scrollBy(tester, -1000);
    expect(reported.last, 1);
    expect(word(tester), 'Verlauf');
    expect(find.text('2 / 4'), findsOneWidget);

    await scrollBy(tester, 1000);
    expect(reported.last, 0);
    expect(word(tester), 'Trainieren');
  });

  testWidgets('am unteren Anschlag gewinnt das letzte Thema', (tester) async {
    await pump(tester);
    await scrollBy(tester, -4000);
    expect(reported.last, 3);
    expect(word(tester), 'Pläne');
  });

  testWidgets('ein von aussen gesetztes Thema wirft die Seite an',
      (tester) async {
    await pump(tester, selected: 2);
    expect(word(tester), 'Auswertung');
    expect(tester.getTopLeft(find.text('Inhalt Auswertung')).dy,
        closeTo(barBottom(tester), 0.5));
  });

  testWidgets('Semantics: Knopf mit Zustand, Liste als Auswahl',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    const barLabel = 'Thema Trainieren, 1 von 4. Öffnet die Themenliste.';
    expect(find.bySemanticsLabel(barLabel), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(barLabel)).flagsCollection
          .isButton,
      isTrue,
    );

    await openList(tester);
    final row = tester.getSemantics(find.descendant(
        of: find.byType(AtemSectionJumpList), matching: find.text('Verlauf')));
    expect(row.label, 'Zu Verlauf springen, 2 von 4');
    expect(row.flagsCollection.isSelected, Tristate.isFalse);
    expect(row.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(
      tester
          .getSemantics(find.descendant(
              of: find.byType(AtemSectionJumpList),
              matching: find.text('Trainieren')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
  });

  testWidgets(
      'bei 200 % auf 320 dp steht das Wort vollständig und nichts läuft über',
      (tester) async {
    await pump(tester, width: 320, scale: 2.0);
    expect(tester.takeException(), isNull);

    // Der kritische Fall der alten Reiterleiste — hier unkritisch, weil nur
    // ein Wort im Rennen ist.
    await scrollBy(tester, -2000);
    expect(word(tester), 'Auswertung');
    final rect = tester.getRect(find.descendant(
        of: find.byType(AtemSectionBar), matching: find.text('Auswertung')));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);

    // Und auch die Liste bleibt lesbar.
    await openList(tester);
    expect(tester.takeException(), isNull);
    for (final l in labels) {
      expect(
        find.descendant(
            of: find.byType(AtemSectionJumpList), matching: find.text(l)),
        findsOneWidget,
      );
    }
  });
}
