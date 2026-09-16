import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/domain/training_heatmap.dart';
import 'package:atem/features/hybrid/presentation/widgets/training_heatmap_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stichtag Mittwoch, 16.09.2026 (KW 38). Die Woche davor trägt drei Tage:
/// Montag Kraft, Mittwoch Cardio, Samstag Kraft **und** Regeneration.
final _today = DateTime(2026, 9, 16);

TrainingSession _at(DateTime date, SessionKind kind) => switch (kind) {
      SessionKind.cardio => CardioSession(
          id: 'c${date.day}',
          userId: 'u',
          date: date,
          createdAt: date,
          duration: const Duration(minutes: 40)),
      SessionKind.recovery => RecoverySession(
          id: 'r${date.day}',
          userId: 'u',
          date: date,
          createdAt: date,
          duration: const Duration(minutes: 20)),
      _ => StrengthSession(
          id: 's${date.day}',
          userId: 'u',
          date: date,
          createdAt: date,
          bodyweight: false,
          duration: const Duration(minutes: 50)),
    };

final _sessions = <TrainingSession>[
  _at(DateTime(2026, 9, 7), SessionKind.strength),
  _at(DateTime(2026, 9, 9), SessionKind.cardio),
  _at(DateTime(2026, 9, 12), SessionKind.strength),
  _at(DateTime(2026, 9, 12), SessionKind.recovery),
  _at(DateTime(2026, 9, 15), SessionKind.strength),
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

/// Die Kacheln, wie sie gezeichnet sind: Farbe oder Rand.
List<BoxDecoration> _cells(WidgetTester tester) => tester
    .widgetList<Container>(find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).borderRadius ==
            BorderRadius.circular(3)))
    .map((c) => c.decoration as BoxDecoration)
    .toList();

void main() {
  testWidgets('Farben je Spur, Hybrid-Ton bei mehreren, Rand für die Zukunft',
      (tester) async {
    final heatmap = TrainingHeatmap.compute(_sessions, _today);
    await _pump(tester, TrainingHeatmapCard(heatmap: heatmap));

    final cells = _cells(tester);
    expect(cells.length, 12 * 7);
    // Vorletzte Spalte (KW 37): Mo Cyan, Mi Violett, Sa Hybrid-Ton.
    final week37 = cells.sublist(10 * 7, 11 * 7);
    expect(week37[0].color, AtemColors.cyan);
    expect(week37[2].color, AtemColors.violet);
    expect(week37[5].color, AtemColors.tabHybrid);
    expect(week37[1].color, AtemColors.track);
    // Letzte Spalte: Di Kraft, ab Donnerstag Zukunft — kein Farbfeld, nur Rand.
    final week38 = cells.sublist(11 * 7);
    expect(week38[1].color, AtemColors.cyan);
    expect(week38[3].color, isNull);
    expect(week38[3].border, isNotNull);
    expect(week38[6].color, isNull);
  });

  testWidgets('Zählung mit Nenner und je Spur', (tester) async {
    final heatmap = TrainingHeatmap.compute(_sessions, _today);
    await _pump(tester, TrainingHeatmapCard(heatmap: heatmap));

    // 11 volle Wochen + Mo–Mi der Stichtagswoche = 80 Tage.
    expect(find.text('4 von 80 Tagen trainiert'), findsOneWidget);
    expect(find.text('3 Kraft · 1 Cardio · 1 Regeneration'), findsOneWidget);
    expect(find.text('12 Wochen'), findsOneWidget);
  });

  testWidgets('eine Woche ist ein Knoten und nennt die Tage mit Wort',
      (tester) async {
    final heatmap = TrainingHeatmap.compute(_sessions, _today);
    await _pump(tester, TrainingHeatmapCard(heatmap: heatmap));

    expect(
      find.bySemanticsLabel(
          'KW 37: 3 Trainingstage. Mo Kraft, Mi Cardio, Sa mehrere Arten'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('KW 30: kein Training'), findsOneWidget);
    // Die Legende trägt die Wörter, die Kacheln selbst sind stumm.
    expect(find.text('mehrere'), findsOneWidget);
    expect(find.text('kein Training'), findsOneWidget);
  });

  testWidgets('ohne Trainingstag rendert die Karte nicht', (tester) async {
    final heatmap = TrainingHeatmap.compute(const [], _today);
    await _pump(tester, TrainingHeatmapCard(heatmap: heatmap));
    expect(find.text('Trainingstage'), findsNothing);
  });

  testWidgets('200 % auf 320 dp läuft nicht über', (tester) async {
    final heatmap = TrainingHeatmap.compute(_sessions, _today);
    await _pump(tester, TrainingHeatmapCard(heatmap: heatmap),
        scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
    expect(find.text('Trainingstage'), findsOneWidget);
    // Kacheln bleiben mindestens 14 dp.
    final cell = tester.getSize(find
        .byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(3))
        .first);
    expect(cell.width, greaterThanOrEqualTo(14));
  });
}
