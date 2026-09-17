import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/presentation/widgets/time_split_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Trainingszeit-Karte: Balkenanteile, leere Spur, Vorlesen, Fenster.
///
/// Stichtag ist ein Mittwoch; die Einheiten liegen so, dass das 14-Tage-
/// Fenster nur Kraft trägt und das 28-Tage-Fenster dazu Ausdauer und eine
/// Einheit ohne Dauer.
final _today = DateTime(2026, 9, 16);

StrengthSession _strength(int daysAgo, int minutes) => StrengthSession(
      id: 's$daysAgo',
      userId: 'u',
      date: DateTime(_today.year, _today.month, _today.day - daysAgo),
      createdAt: _today,
      bodyweight: false,
      duration: Duration(minutes: minutes),
    );

CardioSession _cardio(int daysAgo, int? minutes) => CardioSession(
      id: 'c$daysAgo',
      userId: 'u',
      date: DateTime(_today.year, _today.month, _today.day - daysAgo),
      createdAt: _today,
      duration: minutes == null ? null : Duration(minutes: minutes),
    );

final _sessions = <TrainingSession>[
  _strength(1, 60),
  _strength(5, 30),
  _cardio(20, 90),
  _cardio(22, null),
];

Future<void> _pump(WidgetTester tester, Widget child,
    {double scale = 1.0, double width = 390}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: SingleChildScrollView(child: child),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Die farbigen Segmente des Balkens, in Reihenfolge.
Iterable<Color?> _segments(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.descendant(
      of: find.byType(TweenAnimationBuilder<double>),
      matching: find.byType(DecoratedBox),
    ))
    .map((b) => (b.decoration as BoxDecoration).color);

void main() {
  testWidgets('14 Tage: nur Kraft im Balken, alle drei Zeilen mit Nenner',
      (tester) async {
    await _pump(
        tester, TimeSplitCard(sessions: _sessions, reference: _today));

    expect(_segments(tester).toList(), [AtemColors.cyan]);
    expect(find.text('100 %'), findsOneWidget);
    expect(find.text('0 %'), findsNWidgets(2));
    expect(find.text('90 min in 14 Tagen · 2 Einheiten'),
        findsOneWidget);
    // Eine Zeile, ein Knoten — mit dem Wort, nicht nur der Farbe.
    expect(find.bySemanticsLabel('Kraft: 90 Minuten, 2 Einheiten, 100 Prozent'),
        findsWidgets);
    expect(find.bySemanticsLabel('Cardio: 0 Minuten, 0 Einheiten, 0 Prozent'),
        findsWidgets);
    expect(find.textContaining('ohne Dauer'), findsNothing);
  });

  testWidgets('28 Tage: zwei Spuren, Einheit ohne Dauer wird genannt',
      (tester) async {
    await _pump(
        tester, TimeSplitCard(sessions: _sessions, reference: _today));
    await tester.tap(find.text('28 Tage'));
    await tester.pumpAndSettle();

    expect(_segments(tester).toList(), [AtemColors.cyan, AtemColors.violet]);
    expect(find.text('50 %'), findsNWidgets(2));
    expect(find.text('180 min in 28 Tagen · 4 Einheiten'),
        findsOneWidget);
    expect(find.text('1 Einheit ohne Dauer nicht enthalten'), findsOneWidget);
  });

  testWidgets('leeres Fenster: Zeile statt Balken, Umschalter bleibt',
      (tester) async {
    await _pump(
      tester,
      TimeSplitCard(sessions: [_cardio(20, 90)], reference: _today),
    );
    expect(find.text('Keine Einheit mit Dauer in den letzten 14 Tagen.'),
        findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.text('28 Tage'), findsOneWidget);
  });

  testWidgets('ohne Minuten in 28 Tagen rendert die Karte nicht',
      (tester) async {
    await _pump(
      tester,
      TimeSplitCard(sessions: [_strength(40, 60)], reference: _today),
    );
    expect(find.text('Trainingszeit'), findsNothing);
    expect(TimeSplitCard.hasData([_strength(40, 60)], _today), isFalse);
    expect(TimeSplitCard.hasData(_sessions, _today), isTrue);
  });

  testWidgets('200 % auf 320 dp läuft nicht über', (tester) async {
    await _pump(tester, TimeSplitCard(sessions: _sessions, reference: _today),
        scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
    expect(find.text('Trainingszeit'), findsOneWidget);
  });
}
