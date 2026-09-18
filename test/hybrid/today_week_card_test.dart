import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/cardio/domain/week_ratio.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/presentation/widgets/today_week_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Heute und diese Woche in einer Karte (18.09.2026).
///
/// Geprüft wird, was der Nutzer verlangt hat: beide Aussagen in **einer**
/// Karte, sichtbar voneinander getrennt, und kein „nichts geplant", wenn
/// nichts ansteht.
final _today = DateTime(2026, 9, 17);

const _session = TodaySession(
  id: 's1',
  title: 'Oberkörper Push',
  duration: Duration(minutes: 45),
  intensityLabel: 'strength',
  blockCount: 4,
  planId: 'p1',
);

WeekRatio _ratio({int strength = 2, int cardio = 0}) => WeekRatio.compute(
      [
        for (var i = 0; i < strength; i++)
          StrengthSession(
            id: 's$i',
            userId: 'u',
            date: DateTime(2026, 9, 16, 18),
            createdAt: DateTime(2026, 9, 16, 18),
            bodyweight: true,
            duration: const Duration(minutes: 26),
          ),
        for (var i = 0; i < cardio; i++)
          CardioSession(
            id: 'c$i',
            userId: 'u',
            date: DateTime(2026, 9, 15, 18),
            createdAt: DateTime(2026, 9, 15, 18),
            activity: CardioActivity.run,
            duration: const Duration(minutes: 30),
            distanceKm: 5,
          ),
      ],
      _today,
    );

Future<AppL10n> _pump(
  WidgetTester tester,
  Widget card, {
  double width = 361,
  double scale = 1.15,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: AtemColors.base,
      body: Padding(padding: const EdgeInsets.all(16), child: card),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(TodayWeekCard)));
}

void main() {
  testWidgets('trägt Tag und Woche in einer Karte, durch eine Linie getrennt',
      (tester) async {
    final l10n = await _pump(
      tester,
      TodayWeekCard(
        ratio: _ratio(),
        session: _session,
        onStart: () {},
      ),
    );

    // Tagesteil oben …
    expect(find.text(l10n.workoutsTodayLabel.toUpperCase()), findsOneWidget);
    expect(find.text(_session.title), findsOneWidget);
    expect(find.text(l10n.workoutsStart), findsOneWidget);
    // … Wochenteil unten, beide in derselben Karte.
    expect(find.text(l10n.hybridWeekTitle.toUpperCase()), findsOneWidget);
    expect(find.byType(AtemCard), findsOneWidget);

    final day = tester.getRect(find.text(_session.title));
    final week = tester.getRect(find.text(l10n.hybridWeekTitle.toUpperCase()));
    expect(week.top, greaterThan(day.bottom));

    // Die Trennlinie liegt zwischen beiden Teilen.
    final rule = find.byType(ColoredBox);
    expect(rule, findsOneWidget);
    final ruleRect = tester.getRect(rule);
    expect(ruleRect.top, greaterThan(day.bottom));
    expect(ruleRect.bottom, lessThan(week.top));
  });

  testWidgets('ohne Termin steht nur die Woche — kein „nichts geplant"',
      (tester) async {
    final l10n = await _pump(tester, TodayWeekCard(ratio: _ratio()));

    expect(find.text(l10n.hybridWeekTitle.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.workoutsTodayLabel.toUpperCase()), findsNothing);
    expect(find.text(l10n.emptyTodayTitle), findsNothing);
    expect(find.text(l10n.workoutsStart), findsNothing);
    // Ohne zweiten Teil auch keine Trennlinie.
    expect(find.byType(ColoredBox), findsNothing);
  });

  testWidgets('ohne Woche steht nur der Tag', (tester) async {
    final l10n = await _pump(
      tester,
      TodayWeekCard(
        ratio: _ratio(strength: 0),
        session: _session,
        onStart: () {},
      ),
    );

    expect(find.text(_session.title), findsOneWidget);
    expect(find.text(l10n.hybridWeekTitle.toUpperCase()), findsNothing);
    expect(find.byType(ColoredBox), findsNothing);
  });

  testWidgets('ohne beides rendert sie nicht', (tester) async {
    await _pump(tester, TodayWeekCard(ratio: _ratio(strength: 0)));
    expect(find.byType(AtemCard), findsNothing);
    expect(
      TodayWeekCard.hasData(ratio: _ratio(strength: 0)),
      isFalse,
    );
  });

  testWidgets('ohne Rückruf bleibt der Tagesteil verborgen', (tester) async {
    final l10n =
        await _pump(tester, TodayWeekCard(ratio: _ratio(), session: _session));

    expect(find.text(_session.title), findsNothing);
    expect(find.text(l10n.hybridWeekTitle.toUpperCase()), findsOneWidget);
  });

  testWidgets('der Startknopf nennt den Plan im Vorlese-Label', (tester) async {
    final handle = tester.ensureSemantics();
    var started = 0;
    final l10n = await _pump(
      tester,
      TodayWeekCard(
        ratio: _ratio(),
        session: _session,
        onStart: () => started++,
      ),
    );

    final button =
        find.bySemanticsLabel('${l10n.workoutsStart}: ${_session.title}');
    expect(button, findsOneWidget);
    final size = tester.getSize(button);
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    expect(started, 1);
    handle.dispose();
  });

  testWidgets('der Hinweis zur Bereitschaft steht im Wochenteil',
      (tester) async {
    final l10n = await _pump(
      tester,
      TodayWeekCard(ratio: _ratio(), thinHint: 'Bereitschaft ab 8 Einheiten.'),
    );

    final hint = find.text('Bereitschaft ab 8 Einheiten.');
    expect(hint, findsOneWidget);
    expect(
      tester.getRect(hint).top,
      greaterThan(
          tester.getRect(find.text(l10n.hybridWeekTitle.toUpperCase())).bottom),
    );
  });

  testWidgets('200 % Schrift auf 320 dp ohne Überlauf', (tester) async {
    await _pump(
      tester,
      TodayWeekCard(
        ratio: _ratio(cardio: 1),
        session: _session,
        onStart: () {},
        thinHint: 'Bereitschaft ab 8 Einheiten.',
      ),
      width: 320,
      scale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });
}
