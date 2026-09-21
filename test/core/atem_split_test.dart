import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Das Split-Card-Modul (21.09.2026).
Future<void> _pump(
  WidgetTester tester, {
  Widget? left,
  Widget? right,
  double scale = 1.0,
  double width = 361,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AtemSpacing.screenPadding),
        child: AtemSplit(left: left, right: right),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Widget _box(String label) => SizedBox(
      height: 80,
      child: ColoredBox(
        color: AtemColors.card,
        child: Center(child: Text(label)),
      ),
    );

void main() {
  testWidgets('zwei Karten teilen sich die Zeile, gleich breit',
      (tester) async {
    await _pump(tester, left: _box('A'), right: _box('B'));

    final a = tester.getRect(find.text('A'));
    final b = tester.getRect(find.text('B'));
    expect(a.center.dy, b.center.dy, reason: 'nebeneinander, oben bündig');
    expect(a.center.dx, lessThan(b.center.dx));

    final aBox = tester.getSize(find.ancestor(
        of: find.text('A'), matching: find.byType(SizedBox).first));
    expect(aBox.width, greaterThan(0));
  });

  testWidgets('fehlt eine Hälfte, nimmt die andere die volle Breite',
      (tester) async {
    await _pump(tester, left: _box('A'));

    final a = tester.getRect(find.byType(ColoredBox));
    // Volle Breite abzüglich der Bildschirmränder.
    expect(a.width, 361 - 2 * AtemSpacing.screenPadding);
  });

  testWidgets('ohne beide rendert nichts', (tester) async {
    await _pump(tester);
    expect(find.byType(ColoredBox), findsNothing);
  });

  testWidgets('ab 130 Prozent stehen sie untereinander', (tester) async {
    await _pump(tester, left: _box('A'), right: _box('B'), scale: 1.3);

    final a = tester.getRect(find.text('A'));
    final b = tester.getRect(find.text('B'));
    expect(a.center.dy, lessThan(b.center.dy), reason: 'untereinander');
    expect(a.center.dx, b.center.dx, reason: 'in derselben Spalte');
  });

  testWidgets('auf 320 dp bei 200 Prozent läuft nichts über', (tester) async {
    await _pump(
      tester,
      left: _box('Erfasste Einheiten'),
      right: _box('Muskelbalance'),
      scale: 2.0,
      width: 320,
    );
    expect(tester.takeException(), isNull);
  });
}
