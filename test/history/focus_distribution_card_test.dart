import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/focus_distribution_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 9, 16);

StrengthSession _strength(int daysAgo, WorkoutFocus? focus) => StrengthSession(
      id: 's$daysAgo',
      userId: 'u',
      date: DateTime(_today.year, _today.month, _today.day - daysAgo),
      createdAt: _today,
      bodyweight: true,
      workoutFocus: focus,
    );

Future<void> _pump(WidgetTester tester, List<TrainingSession> sessions,
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
        child: SingleChildScrollView(
          child: FocusDistributionCard(sessions: sessions, reference: _today),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

final _filled = [
  _strength(1, WorkoutFocus.pull),
  _strength(3, WorkoutFocus.pull),
  _strength(5, WorkoutFocus.pull),
  _strength(8, WorkoutFocus.push),
  _strength(10, WorkoutFocus.legs),
  _strength(12, null),
  _strength(14, null),
];

void main() {
  testWidgets('unter der Schwelle: Titel, Bedingung, Fortschritt — kein Anteil',
      (tester) async {
    await _pump(tester, [
      _strength(1, WorkoutFocus.pull),
      _strength(2, WorkoutFocus.push),
      _strength(3, null),
    ]);
    expect(find.text('Fokus'), findsOneWidget);
    expect(find.text('2 von 3'), findsOneWidget);
    expect(find.textContaining('Ab 3 Einheiten mit Fokus'),
        findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Ziehen'), findsNothing);
  });

  testWidgets('ohne jede Einheit rendert der Block trotzdem', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Fokus'), findsOneWidget);
    expect(find.text('0 von 3'), findsOneWidget);
  });

  testWidgets('gefüllt: Zeilen je Fokus mit Anzahl und Anteil, Nenner darunter',
      (tester) async {
    await _pump(tester, _filled);
    expect(find.text('Ziehen'), findsOneWidget);
    expect(find.text('Drücken'), findsOneWidget);
    expect(find.text('Beine'), findsOneWidget);
    expect(find.text('Rumpf'), findsNothing);
    expect(find.text('3 Einheiten'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    // Seit 17.09.2026: Der Nenner bleibt sichtbar, der Hinweis auf Einheiten
    // ohne Fokus steht hinter dem ⓘ.
    expect(find.text('5 von 7 Einheiten mit Fokus'), findsOneWidget);
    expect(find.textContaining('ohne Fokus'), findsNothing);
  });

  testWidgets('ohne Einheiten ohne Fokus fehlt der Hinweis', (tester) async {
    await _pump(tester, _filled.where((s) => s.workoutFocus != null).toList());
    expect(find.textContaining('ohne Fokus'), findsNothing);
    expect(find.text('5 von 5 Einheiten mit Fokus'), findsOneWidget);
  });

  testWidgets('eine Zeile ist ein Semantics-Knoten', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _filled);
    expect(find.bySemanticsLabel('Ziehen, 3 Einheiten, 60 Prozent'),
        findsOneWidget);
    expect(find.bySemanticsLabel('Drücken, 1 Einheit, 20 Prozent'),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('200 % auf 320 dp ohne Überlauf — gefüllt und unter der Schwelle',
      (tester) async {
    await _pump(tester, _filled, scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
    await _pump(tester, [_strength(1, WorkoutFocus.pull)],
        scale: 2.0, width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Erklärung ist hinter dem ⓘ', (tester) async {
    await _pump(tester, _filled);
    expect(find.textContaining('Wogegen deine Krafteinheiten gingen'),
        findsNothing);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.textContaining('Wogegen deine Krafteinheiten gingen'),
        findsOneWidget);
    expect(find.textContaining('Einheiten ohne Fokus zählen nicht mit'),
        findsOneWidget);
  });
}
