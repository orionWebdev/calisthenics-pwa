import 'package:atem/app/application/snackbar_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/planning/application/training_goal_providers.dart';
import 'package:atem/features/planning/domain/training_goal.dart';
import 'package:atem/features/planning/presentation/screens/training_goal_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';
import '../support/fake_training_goal.dart';

/// Das Zielbriefing — Board 18, A1–A7.
///
/// Geprüft wird die Haltung, nicht die Pixel: nichts vorbelegt, Folgefragen
/// erst mit ihrer Antwort, Abhängiges geht mit und kommt mit Rückgängig
/// zurück, eine Ablehnung steht im Block, ein Ladefehler zeigt keine Fragen.

late FakeTrainingGoalRepository repo;
late ProviderContainer container;

final _today = DateTime(2026, 9, 23);

Future<void> _pump(
  WidgetTester tester, {
  TrainingGoal initial = TrainingGoal.empty,
  bool denied = false,
  bool hang = false,
}) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  repo = FakeTrainingGoalRepository(
      initial: initial, denied: denied, hang: hang);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      trainingGoalRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: TrainingGoalScreen(today: _today),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  container = ProviderScope.containerOf(
      tester.element(find.byType(TrainingGoalScreen)));
}

/// Die Snackbar steht 6 s; ohne Abwarten bliebe ihr Timer hängen.
Future<void> _drainSnack(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 7));

Finder _option(String label) => find.bySemanticsLabel(label);

bool _checked(WidgetTester tester, String label) =>
    // ignore: deprecated_member_use
    tester.getSemantics(_option(label)).hasFlag(SemanticsFlag.isChecked);

void main() {
  testWidgets('erster Aufruf: sechs Fragen offen, keine Antwort vorgewählt',
      (tester) async {
    await _pump(tester);

    expect(find.text('Was trainierst du?'), findsOneWidget);
    expect(find.text('Sieht jede Woche ähnlich aus?'), findsOneWidget);
    expect(find.text('Trainierst du manchmal mehrmals am Tag?'), findsOneWidget);
    expect(find.text('Wo trainierst du?'), findsOneWidget);
    expect(find.text('Worauf trainierst du hin?'), findsOneWidget);
    expect(find.text('Beschreibt das dein Training gerade?'), findsOneWidget);
    // Anzahl und Tage fragen je Art — ohne Art gibt es nichts zu fragen.
    expect(find.text('Wie viele Einheiten in einer üblichen Woche?'),
        findsNothing);
    expect(find.text('Trainierst du an festen Tagen?'), findsNothing);

    for (final label in ['Kraft', 'Cardio', 'Kraft und Cardio']) {
      expect(_checked(tester, label), isFalse, reason: label);
    }
    // Ohne Antwort nichts zu entfernen, und kein „Zuletzt geändert".
    expect(find.text('Alle Angaben entfernen'), findsNothing);
    expect(find.textContaining('Zuletzt geändert'), findsNothing);
    // Kein Speichern-Knopf, kein Fortschritt.
    expect(find.textContaining('Speichern'), findsNothing);
  });

  testWidgets('„Kraft und Cardio" öffnet Anzahl und Tage darunter',
      (tester) async {
    await _pump(tester);
    await tester.tap(_option('Kraft und Cardio'));
    await tester.pumpAndSettle();

    expect(repo.writes.single, {
      'modalities': ['strength', 'cardio'],
    });
    expect(_checked(tester, 'Kraft und Cardio'), isTrue);
    expect(find.text('Wie viele Einheiten in einer üblichen Woche?'),
        findsOneWidget);
    expect(find.text('Trainierst du an festen Tagen?'), findsOneWidget);
    expect(find.bySemanticsLabel('Kraft, 3 Einheiten je Woche'),
        findsOneWidget);
    expect(find.bySemanticsLabel('Cardio, 1 Einheit je Woche'), findsOneWidget);
    expect(find.bySemanticsLabel('Cardio, 8 oder mehr Einheiten je Woche'),
        findsOneWidget);
  });

  testWidgets('die gewählte Antwort nochmals tippen tut nichts',
      (tester) async {
    await _pump(tester);
    await tester.tap(_option('Kraft'));
    await tester.pumpAndSettle();
    await tester.tap(_option('Kraft'));
    await tester.pumpAndSettle();
    expect(repo.writes, hasLength(1));
    expect(_checked(tester, 'Kraft'), isTrue);
  });

  testWidgets('„nur Kraft" nimmt Cardio mit — und Rückgängig holt es zurück',
      (tester) async {
    await _pump(
      tester,
      initial: TrainingGoal.empty
          .withLanes({Lane.strength, Lane.cardio})
          .withPerWeek(Lane.strength, 3)
          .withPerWeek(Lane.cardio, 3),
    );
    // Wiederansehen: erst die Zeile aufklappen.
    await tester.tap(find.bySemanticsLabel(
        RegExp(r'^Was du trainierst, Kraft und Cardio\. Ändern$')));
    await tester.pumpAndSettle();
    await tester.tap(_option('Kraft'));
    await tester.pumpAndSettle();

    expect(repo.writes.last, {
      'modalities': ['strength'],
      'perWeek.cardio': null,
    });
    expect(repo.goal.perWeek.cardio, isNull);

    final snack = container.read(snackbarProvider);
    expect(snack?.message, 'Cardio-Angaben entfernt');
    snack!.onAction!();
    await tester.pumpAndSettle();
    expect(repo.goal.perWeek.cardio, 3);
    expect(repo.goal.hasCardio, isTrue);
    await _drainSnack(tester);
  });

  testWidgets('Wiederansehen: Zeilen, offene Fragen heissen „Offen"',
      (tester) async {
    await _pump(
      tester,
      initial: TrainingGoal.empty
          .withLanes({Lane.strength})
          .withPerWeek(Lane.strength, 3)
          .withPlaces({Place.gym}),
    );

    // Keine Blöcke, nur Zeilen.
    expect(find.text('Was trainierst du?'), findsNothing);
    expect(find.text('Einheiten je Woche'), findsOneWidget);
    expect(find.text('Kraft 3×'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Offen'), findsWidgets);
    expect(
        find.bySemanticsLabel('Wochenmuster, offen. Beantworten'), findsOne);
    // Bei „nur Kraft" taucht Cardio nirgends auf.
    expect(find.textContaining('Cardio'), findsNothing);
    expect(find.text('Alle Angaben entfernen'), findsOneWidget);
  });

  testWidgets('eine Zeile klappt auf, die vorher offene schliesst',
      (tester) async {
    await _pump(
      tester,
      initial: TrainingGoal.empty.withLanes({Lane.strength}),
    );
    await tester.tap(find.bySemanticsLabel('Wochenmuster, offen. Beantworten'));
    await tester.pumpAndSettle();
    expect(find.text('Sieht jede Woche ähnlich aus?'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Wo du trainierst, offen. Beantworten'));
    await tester.pumpAndSettle();
    expect(find.text('Sieht jede Woche ähnlich aus?'), findsNothing);
    expect(find.text('Wo trainierst du?'), findsOneWidget);
  });

  testWidgets('Ablehnung: Fehler im Block, beide Werte genannt, nichts gespeichert',
      (tester) async {
    await _pump(
      tester,
      initial: TrainingGoal.empty
          .withLanes({Lane.strength})
          .withPerWeek(Lane.strength, 3),
    );
    await tester.tap(
        find.bySemanticsLabel('Einheiten je Woche, Kraft 3×. Ändern'));
    await tester.pumpAndSettle();
    repo.reject = true;
    await tester.tap(find.bySemanticsLabel('Kraft, 4 Einheiten je Woche'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('„Kraft 4×“ nicht gespeichert'),
      findsOneWidget,
    );
    expect(find.textContaining('Gilt weiter: Kraft 3×.'), findsOneWidget);
    expect(repo.goal.perWeek.strength, 3);
    expect(_checked(tester, 'Kraft, 3 Einheiten je Woche'), isTrue);

    // Erneut versuchen schreibt dieselbe Antwort noch einmal.
    repo.reject = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(repo.goal.perWeek.strength, 4);
    expect(find.textContaining('nicht gespeichert'), findsNothing);
  });

  testWidgets('Antwort zurücknehmen macht sie wieder offen, nicht zur Null',
      (tester) async {
    await _pump(tester);
    await tester.ensureVisible(_option('Nein, so will ich wieder trainieren'));
    await tester.tap(_option('Nein, so will ich wieder trainieren'));
    await tester.pumpAndSettle();
    expect(repo.goal.describes, Describes.intended);

    await tester.ensureVisible(find.text('Antwort zurücknehmen'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(
        'Antwort zurücknehmen: Beschreibt das dein Training gerade?'));
    await tester.pumpAndSettle();
    expect(repo.writes.last, {'describes': null});
    expect(repo.goal.fields, isEmpty);
    expect(container.read(snackbarProvider)?.message, 'Antwort zurückgenommen');
    await _drainSnack(tester);
  });

  testWidgets('Alle Angaben entfernen — mit Rückgängig', (tester) async {
    final initial = TrainingGoal.empty
        .withLanes({Lane.cardio})
        .withGoals({TrainingAim.health});
    await _pump(tester, initial: initial);
    await tester.tap(find.text('Alle Angaben entfernen'));
    await tester.pumpAndSettle();
    expect(repo.goal.hasAny, isFalse);

    container.read(snackbarProvider)!.onAction!();
    await tester.pumpAndSettle();
    expect(repo.goal.lanes, {Lane.cardio});
    expect(repo.goal.goals, {TrainingAim.health});
    await _drainSnack(tester);
  });

  testWidgets('Ladefehler: keine Fragen, nur der Grund und „Erneut versuchen"',
      (tester) async {
    await _pump(tester, denied: true);
    expect(find.text('Angaben konnten nicht geladen werden.'), findsOneWidget);
    expect(find.text('Was trainierst du?'), findsNothing);
    expect(find.textContaining('Offen'), findsNothing);
  });

  testWidgets('Laden: Titel steht sofort, Fragen noch nicht', (tester) async {
    await _pump(tester, hang: true);
    expect(find.text('Trainings\u00ADangaben'), findsOneWidget);
    expect(find.text('Was trainierst du?'), findsNothing);
  });

  testWidgets('Wechselwochen: Anker und Woche B erscheinen darunter',
      (tester) async {
    await _pump(tester,
        initial: TrainingGoal.empty.withLanes({Lane.strength}));
    await tester.tap(find.bySemanticsLabel('Wochenmuster, offen. Beantworten'));
    await tester.pumpAndSettle();
    await tester.tap(_option('Zwei Wochen wechseln sich ab'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Diese Woche ist Woche A'));
    await tester.pumpAndSettle();
    expect(repo.goal.anchorWeekStart, DateTime(2026, 9, 21));
    expect(repo.goal.isWeekA(_today), isTrue);
  });
}
