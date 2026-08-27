import 'package:atem/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:atem/features/workout/domain/workout_start.dart';
import 'package:atem/features/workout/presentation/screens/workout_runner_screen.dart';
import 'package:atem/main.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/a11y.dart';

/// Dieselben Attrappen wie in der Prüfmatrix.
///
/// Vorher stand hier eine eigene, kürzere Liste — sie reichte, solange der
/// Runner seine Übungen aus einer Attrappe bezog. Jetzt setzt er sie aus Plan,
/// Übungsbestand und Historie zusammen und braucht alle drei.
final _overrides = fixtureOverrides;

/// Hohe Testfläche: die ListView baut lazy, sonst liegt die Session-Card
/// unterhalb der Kante und existiert nicht im Baum.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumpt ein Widget mit abgeschalteten Animationen.
///
/// Das ist der Regelfall für Tests: Ohne `disableAnimations` laufen die
/// dekorativen Dauerschleifen endlos und `pumpAndSettle()` läuft in den Timeout.
Future<void> _pumpStill(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        // Sprache festnageln: Die Testumgebung meldet en_US, und ohne diese
        // Zeile prüfen deutsche Erwartungen gegen englische Texte.
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Dashboard rendert Readiness-Score und Session', (tester) async {
    _useTallSurface(tester);
    await _pumpStill(tester, DashboardScreen(onSelectTab: (_) {}));

    // Der eigentliche Beweis: mit abgeschalteten Animationen kommt der Baum
    // zur Ruhe. Vor der Einführung von AtemMotion.syncLoop hing das hier.
    await tester.pumpAndSettle();

    expect(find.text('ATEM READINESS'), findsOneWidget);
    expect(find.text('HEUTIGE SESSION'), findsOneWidget);
    expect(find.textContaining('SESSION STARTEN'), findsOneWidget);
    // Count-up ist ohne Animation sofort am Ziel.
    expect(find.text('89'), findsOneWidget);
  });

  testWidgets('Workout Runner baut die Einheit aus dem Plan', (tester) async {
    _useTallSurface(tester);
    await _pumpStill(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')),
    );
    // Drei Abfragen nacheinander — Plan, Übungen, Historie. Ein einzelnes
    // `pump` löst nur die erste auf.
    await tester.pumpAndSettle();

    // Der Plan aus den Vorlagen: zwei Einträge, vier plus drei Sätze.
    expect(find.text('Archer Push-up mit sehr langem Namen'), findsOneWidget);
    expect(find.text('0 VON 7 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);

    // Der erste Satz ist offen — über sein Semantics-Label finden, nicht über
    // ein Icon: das Häkchen erscheint erst im abgehakten Zustand.
    final handle = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Satz 1 abschließen'));
    await tester.pump();

    expect(find.text('1 VON 7 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Der Runner belegt keine Felder vor', (tester) async {
    // Ein Feld, in dem schon „8" steht, ist nach dem Abhaken eine
    // Leistungsangabe — und zwar eine, die niemand gemacht hat.
    _useTallSurface(tester);
    await _pumpStill(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')),
    );
    await tester.pump();

    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller?.text, isEmpty);
    }
  });

  testWidgets('Freies Training beginnt leer, nicht erfunden', (tester) async {
    _useTallSurface(tester);
    await _pumpStill(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart.free()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Übung'), findsOneWidget);
    expect(find.text('Übung hinzufügen'), findsOneWidget);
    // Der entscheidende Punkt: keine Übung aus einer Attrappe.
    expect(find.text('Back Squat'), findsNothing);
  });

  testWidgets('Eine gelöschte Übung im Plan blockiert nicht', (tester) async {
    _useTallSurface(tester);
    await _pumpStill(
      tester,
      const WorkoutRunnerScreen(start: WorkoutStart(planId: 'p1')),
    );
    await tester.pumpAndSettle();

    // Der zweite Eintrag zeigt auf eine Übung, die es nicht gibt. Die Einheit
    // ist trotzdem startbar; die Kennung tritt an die Stelle des Namens.
    expect(tester.takeException(), isNull);
    expect(find.text('0 VON 7 SÄTZEN ABGESCHLOSSEN'), findsOneWidget);
  });

  testWidgets('AtemApp startet ohne Fehler', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides, child: const AtemApp()),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
