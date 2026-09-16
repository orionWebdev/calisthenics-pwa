import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Reiterleiste über wischbaren Seiten.
void main() {
  const labels = ['Trainieren', 'Verlauf', 'Auswertung', 'Pläne'];

  Future<PageController> pump(
    WidgetTester tester, {
    bool reduced = false,
    double width = 361,
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            AtemPageTabs(
              controller: controller,
              labels: labels,
              groupSemanticLabel: 'Kraft-Seiten',
            ),
            Expanded(
              child: PageView(
                controller: controller,
                children: [
                  for (final l in labels) Center(child: Text('Seite $l'))
                ],
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  /// Der Indikator ist das einzige [Positioned] in der Leiste.
  Rect indicator(WidgetTester tester) => tester.getRect(find.descendant(
        of: find.byType(AtemPageTabs),
        matching: find.byType(Positioned),
      ));

  Rect pill(WidgetTester tester, String label) => tester.getRect(find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first);

  testWidgets('Tippen auf einen Reiter wechselt die Seite', (tester) async {
    final controller = await pump(tester);
    // Vier Reiter sind breiter als 361 dp — die Leiste scrollt.
    await tester.ensureVisible(find.text('Auswertung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auswertung'));
    await tester.pumpAndSettle();
    expect(controller.page, 2);
    expect(find.text('Seite Auswertung'), findsOneWidget);
  });

  testWidgets('der Indikator folgt der Seite zwischen zwei Reitern',
      (tester) async {
    final controller = await pump(tester);
    final first = pill(tester, 'Trainieren');
    final second = pill(tester, 'Verlauf');
    expect(indicator(tester).left, closeTo(first.left, 0.5));

    // Halb gewischt: Die Pille steht auf halbem Weg und hat eine
    // Zwischenbreite — nicht erst nach dem Loslassen.
    final width = tester.getSize(find.byType(PageView)).width;
    controller.jumpTo(width * 0.5);
    await tester.pump();
    final mid = indicator(tester);
    expect(mid.left, closeTo((first.left + second.left) / 2, 1));
    expect(mid.width, closeTo((first.width + second.width) / 2, 1));

    controller.jumpTo(width);
    await tester.pump();
    expect(indicator(tester).left, closeTo(second.left, 0.5));
  });

  testWidgets('Wischen wechselt die Seite, der Indikator zieht mit',
      (tester) async {
    final controller = await pump(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(controller.page, 1);
    expect(indicator(tester).left, closeTo(pill(tester, 'Verlauf').left, 0.5));
  });

  testWidgets('Semantics: Rolle, Position, ausgewählt', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    final node = tester.getSemantics(find.text('Verlauf'));
    expect(node.label, 'Verlauf, Seite 2 von 4');
    expect(node.flagsCollection.isSelected, Tristate.isFalse);
    expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(
        tester
            .getSemantics(find.text('Trainieren'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('bei reduzierter Bewegung springt die Seite', (tester) async {
    final controller = await pump(tester, reduced: true);
    await tester.ensureVisible(find.text('Pläne'));
    await tester.pump();
    await tester.tap(find.text('Pläne'));
    // Ein einziger Frame genügt: kein Animationsverlauf.
    await tester.pump();
    expect(controller.page, 3);
  });

  testWidgets(
      'bei 200 % auf 320 dp kein Überlauf, und der Reiter der Zielseite '
      'scrollt von selbst in Sicht', (tester) async {
    final controller = await pump(tester, width: 320, scale: 2.0);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('Pläne')).left, greaterThan(320),
        reason: 'Ausgangslage: der letzte Reiter liegt ausserhalb');

    // Nur gewischt, die Leiste nicht angefasst.
    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(PageView), const Offset(-250, 0), 1500);
      await tester.pumpAndSettle();
    }
    expect(controller.page, 3);
    final tab = tester.getRect(find.text('Pläne'));
    expect(tab.left, greaterThanOrEqualTo(0));
    expect(tab.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  // Der Vertrag, auf den die Seite „Trainieren" baut: Ihre Plan-Karten
  // stehen in einer horizontalen Liste innerhalb des PageView. Eine Geste auf
  // der Liste scrollt die Liste, nicht die Seite.
  testWidgets(
      'eine innere horizontale Liste scrollt, ohne die Seite zu wechseln',
      (tester) async {
    tester.view.physicalSize = const Size(361, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final pages = PageController();
    final inner = ScrollController();
    addTearDown(pages.dispose);
    addTearDown(inner.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: pages,
          children: [
            Column(children: [
              SizedBox(
                height: 160,
                child: ListView(
                  key: const Key('karten'),
                  controller: inner,
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 6; i++)
                      SizedBox(width: 240, child: Text('Karte $i')),
                  ],
                ),
              ),
            ]),
            const Text('Seite 2'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.fling(
        find.byKey(const Key('karten')), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(inner.offset, greaterThan(0));
    expect(pages.page, 0);

    // Ausserhalb der Liste gewischt, wechselt die Seite.
    await tester.flingFrom(const Offset(180, 500), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(pages.page, 1);
  });
}
