import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/plans/domain/plan.dart';
import 'package:atem/features/plans/presentation/plan_bits.dart';
import 'package:atem/features/plans/presentation/widgets/plan_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Abstände und Umbrüche der Plan-Karten (17.09.2026).
void main() {
  Future<AppL10n> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(361, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late AppL10n l10n;
    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (context) {
          l10n = AppL10n.of(context);
          return child;
        }),
      ),
    ));
    await tester.pumpAndSettle();
    return l10n;
  }

  testWidgets('Metazeile ohne Typ hat keinen leeren Platz zwischen Trennern',
      (tester) async {
    final l10n = await pump(tester, const SizedBox());
    const plan = Plan(id: 'a', name: 'Push', items: [
      PlanItem(exerciseId: 'push_up'),
      PlanItem(exerciseId: 'dip'),
    ]);
    final line = planMetaLine(l10n, plan, withDuration: true);
    expect(line, isNot(contains('·  ·')));
    expect(line, isNot(contains('· ·')));
    expect(line.split(' · '), hasLength(2),
        reason: 'Übungen und Dauer — kein leerer Typ dazwischen');
    // Innerhalb einer Angabe nur geschützte Leerzeichen.
    for (final part in line.split(' · ')) {
      expect(part, isNot(contains(' ')));
    }
  });

  testWidgets('Karten einer Reihe sind gleich hoch, Knöpfe auf einer Linie',
      (tester) async {
    await pump(
      tester,
      SingleChildScrollView(
        child: PlanCardRow(
          plans: const [
            Plan(
              id: 'long',
              name: 'Oberkörper Push mit Zusatzgewicht und Handstand',
              items: [PlanItem(exerciseId: 'push_up')],
            ),
            Plan(id: 'short', name: 'Pull'),
          ],
          musclesOf: (_) => const [],
          onOpen: (_) {},
          onStart: (_) {},
        ),
      ),
    );
    final cards = find.byType(PlanCard);
    expect(cards, findsNWidgets(2));
    final a = tester.getRect(cards.at(0));
    final b = tester.getRect(cards.at(1));
    expect(a.height, closeTo(b.height, 0.5));

    final buttons = find.text('Starten');
    expect(
      tester.getRect(buttons.at(0)).bottom,
      closeTo(tester.getRect(buttons.at(1)).bottom, 0.5),
    );
    expect(tester.takeException(), isNull);
  });
}
