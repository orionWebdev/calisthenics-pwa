import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/presentation/widgets/training_time_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der zusammengeführte Block „Trainingszeit": zwei Fenster, drei Spuren,
/// Metazeilen ohne Nullgrössen, Verschiebung nur in der Woche.
final _today = DateTime(2026, 9, 17);

StrengthSession _lift(String id, DateTime date, int minutes,
        {double? kg}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: kg == null,
      duration: Duration(minutes: minutes),
      exercises: [
        LoggedExercise(
          exerciseId: 'pull_up',
          sets: [for (var i = 0; i < 4; i++) LoggedSet(reps: 8, weight: kg)],
        ),
      ],
    );

CardioSession _run(String id, DateTime date, int minutes, double km) =>
    CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: Duration(minutes: minutes),
      distanceKm: km,
    );

final _thisWeek = [
  _lift('a', DateTime(2026, 9, 15, 18), 26),
  _lift('b', DateTime(2026, 9, 16, 18), 26),
];

final _withHistory = [
  for (var w = 1; w <= 4; w++) ...[
    _lift('l$w', DateTime(2026, 9, 15 - 7 * w, 18), 30, kg: 50),
    _run('r$w', DateTime(2026, 9, 16 - 7 * w, 18), 30, 5),
  ],
  _lift('now', DateTime(2026, 9, 15, 18), 90, kg: 60),
  _run('nowr', DateTime(2026, 9, 16, 18), 30, 6.2),
];

Future<void> _pump(WidgetTester tester, List<TrainingSession> sessions,
    {double scale = 1.0, double width = 361}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TrainingTimeCard(sessions: sessions, reference: _today),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Standard „Diese Woche": KW im Kopf, drei Zeilen, Grundlage',
      (tester) async {
    await _pump(tester, _thisWeek);
    expect(find.text('Trainingszeit'), findsOneWidget);
    expect(find.text('KW 38'), findsOneWidget);
    expect(find.text('Diese Woche'), findsOneWidget);
    expect(find.text('28 Tage'), findsOneWidget);
    expect(find.text('100 %'), findsOneWidget);
    expect(find.text('0 %'), findsNWidgets(2));
    expect(find.text('52 min · 2 Einheiten'), findsOneWidget);
  });

  testWidgets('Metazeile: nie „0 t Volumen", Sätze bei Körpergewicht',
      (tester) async {
    await _pump(tester, _thisWeek);
    final meta = find.textContaining('8 Sätze');
    expect(meta, findsOneWidget);
    expect(find.textContaining('Volumen'), findsNothing);
    expect(find.textContaining('km'), findsNothing);
  });

  testWidgets('Verschiebung nur in der Woche, als Wort vorgelesen',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _withHistory);
    expect(find.textContaining('pp'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'^Kraft: 90 Minuten.*Prozentpunkte mehr')),
      findsOneWidget,
    );
    // Glyphen werden nie vorgelesen.
    expect(find.bySemanticsLabel(RegExp('▲|▼')), findsNothing);

    await tester.tap(find.text('28 Tage'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pp'), findsNothing);
    expect(find.text('KW 38'), findsNothing);
    handle.dispose();
  });

  testWidgets('ohne Minuten in beiden Fenstern rendert nichts', (tester) async {
    await _pump(tester, [
      _lift('alt', DateTime(2026, 6, 1, 18), 40),
    ]);
    expect(find.text('Trainingszeit'), findsNothing);
    expect(TrainingTimeCard.hasData([], _today), isFalse);
  });

  testWidgets('Woche leer, 28 Tage nicht: Zeile statt Balken, Umschalter bleibt',
      (tester) async {
    await _pump(tester, [_lift('vorige', DateTime(2026, 9, 10, 18), 40)]);
    expect(find.text('Diese Woche noch keine Einheit mit Dauer.'),
        findsOneWidget);
    await tester.tap(find.text('28 Tage'));
    await tester.pumpAndSettle();
    expect(find.text('100 %'), findsOneWidget);
  });

  testWidgets('Erklärung hinter dem ⓘ', (tester) async {
    await _pump(tester, _withHistory);
    expect(find.textContaining('Kein Sollverhältnis'), findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kein Sollverhältnis'), findsOneWidget);
  });

  for (final (width, scale) in [(320.0, 2.0), (361.0, 1.15)]) {
    testWidgets('ohne Überlauf bei ${(scale * 100).round()} % auf $width dp',
        (tester) async {
      await _pump(tester, _withHistory, width: width, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
