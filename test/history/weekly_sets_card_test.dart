import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/weekly_sets_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sätze je Woche in der Kraft-Auswertung (16.09.2026): Schwelle, Zahl mit
/// und ohne Vergleich, leere Woche als Strich, ein Knoten je Teil, 200 %.
final _ref = DateTime(2026, 9, 16, 15);

StrengthSession _s(String id, DateTime date,
        {int sets = 3, bool noSets = false}) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      exercises: noSets
          ? const []
          : [
              LoggedExercise(exerciseId: 'pull_up', sets: [
                for (var i = 0; i < sets; i++) const LoggedSet(reps: 8),
              ]),
            ],
    );

Future<void> _pump(
  WidgetTester tester,
  List<TrainingSession> sessions, {
  double scale = 1.0,
  double width = 361,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
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
          child: WeeklySetsCard(sessions: sessions, reference: _ref),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ohne Einheit mit Sätzen steht der Schwellen-Block', (t) async {
    await _pump(t, [_s('a', DateTime(2026, 9, 15), noSets: true)]);
    expect(find.byType(AtemThresholdBlock), findsOneWidget);
    expect(find.text('Sätze je Woche'), findsOneWidget);
    expect(find.text('0 von 1'), findsOneWidget);
    expect(find.text('Erscheint mit deiner ersten Einheit mit Sätzen'),
        findsOneWidget);
    // Kein Wert, kein Streifen.
    expect(find.byKey(const ValueKey('empty')), findsNothing);
    expect(find.byKey(const ValueKey('filled')), findsNothing);
  });

  testWidgets('ohne Vergleich: Zahl, keine Pille, „noch 2"', (t) async {
    await _pump(t, [_s('a', DateTime(2026, 9, 15), sets: 4)]);
    expect(find.byType(AtemThresholdBlock), findsNothing);
    expect(find.text('Diese Woche · KW 38 · 1 Einheit'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Sätze'), findsOneWidget);
    expect(find.byType(AtemBadge), findsNothing);
    expect(find.text('Vergleich ab 2 vollen Wochen · noch 2'), findsOneWidget);
  });

  testWidgets('mit Vergleich: Pille und Grundlage', (t) async {
    await _pump(t, [
      _s('a', DateTime(2026, 9, 2), sets: 10),
      _s('b', DateTime(2026, 9, 9), sets: 6),
      _s('c', DateTime(2026, 9, 15), sets: 12),
    ]);
    expect(find.text('▲ +4'), findsOneWidget);
    expect(find.text('gegen 4-Wochen-Schnitt 8 Sätze'), findsOneWidget);
  });

  testWidgets('weniger als der Schnitt: Pille nach unten', (t) async {
    await _pump(t, [
      _s('a', DateTime(2026, 9, 2), sets: 10),
      _s('b', DateTime(2026, 9, 9), sets: 10),
      _s('c', DateTime(2026, 9, 15), sets: 7),
    ]);
    expect(find.text('▼ −3'), findsOneWidget);
  });

  testWidgets('gemessene Woche ohne Satz ist ein Strich, davor nichts',
      (t) async {
    await _pump(t, [
      _s('a', DateTime(2026, 9, 1)),
      _s('b', DateTime(2026, 9, 16)),
    ]);
    // KW 36 und 38 gefüllt, KW 37 leer, fünf Wochen vor Beginn.
    expect(find.byKey(const ValueKey('filled')), findsNWidgets(2));
    expect(find.byKey(const ValueKey('empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('before')), findsNWidgets(5));
    final strich = t.getSize(find.byKey(const ValueKey('empty')));
    expect(strich.height, 2);
  });

  testWidgets('Einheiten ohne Sätze werden genannt', (t) async {
    await _pump(t, [
      _s('a', DateTime(2026, 9, 15), sets: 4),
      _s('b', DateTime(2026, 9, 16), noSets: true),
    ]);
    expect(find.text('1 Einheit ohne Sätze nicht gezählt'), findsOneWidget);
  });

  testWidgets('Kopf und Streifen sind je ein Knoten, Glyphen stumm', (t) async {
    final handle = t.ensureSemantics();
    await _pump(t, [
      _s('a', DateTime(2026, 9, 2), sets: 10),
      _s('b', DateTime(2026, 9, 9), sets: 6),
      _s('c', DateTime(2026, 9, 15), sets: 12),
    ]);
    expect(
      find.bySemanticsLabel(
          'Diese Woche, 12 Sätze in 1 Einheit, 4 mehr als der 4-Wochen-Schnitt von 8'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(
          r'^Sätze je Woche: KW 31: vor deiner ersten Einheit, .*KW 36: 10, KW 37: 6, KW 38: 12$')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('[▲▼]')), findsNothing);
    handle.dispose();
  });

  testWidgets('200 % auf 320 dp ohne Überlauf', (t) async {
    await _pump(
      t,
      [
        _s('a', DateTime(2026, 9, 2), sets: 10),
        _s('b', DateTime(2026, 9, 9), sets: 6),
        _s('c', DateTime(2026, 9, 15), sets: 120),
        _s('d', DateTime(2026, 9, 16), noSets: true),
      ],
      scale: 2.0,
      width: 320,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('Schwellen-Block bei 200 % auf 320 dp ohne Überlauf', (t) async {
    await _pump(t, const [], scale: 2.0, width: 320);
    expect(t.takeException(), isNull);
  });

  testWidgets('Erklärung ist hinter dem ⓘ', (t) async {
    await _pump(t, [_s('a', DateTime(2026, 9, 15), sets: 4)]);
    expect(find.textContaining('Woche für Woche'), findsNothing);
    await t.tap(find.byIcon(Icons.info_outline));
    await t.pumpAndSettle();
    expect(find.textContaining('Woche für Woche'), findsOneWidget);
    expect(find.textContaining('4 vollen Wochen davor'), findsOneWidget);
  });
}
