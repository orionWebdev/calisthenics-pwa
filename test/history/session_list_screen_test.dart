import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/history_screen.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/features/plans/application/plan_providers.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';

/// Der Bestand, wie er wirklich aussieht — nicht die glatte Fixture.
///
/// Der Hänger vom 16.09.2026 trat nur mit echten Daten auf: Die Fixture der
/// Prüfmatrix hat alle drei Tage eine Einheit und damit **keine einzige
/// Lücke**. Der Lückenstreifen wurde in keinem Test je gebaut.
final realisticSessions = <TrainingSession>[
  // Mehrfachtag: zwei Einheiten am 20.08.
  StrengthSession(
    id: 'a',
    userId: 'u',
    date: DateTime(2026, 8, 20, 18),
    createdAt: DateTime(2026, 8, 20, 18),
    bodyweight: false,
    duration: const Duration(minutes: 50),
    planName: 'Push Day A',
    exercises: const [
      LoggedExercise(
        exerciseId: 'archer_push_up',
        sets: [LoggedSet(reps: 8, weight: 60)],
      ),
    ],
  ),
  CardioSession(
    id: 'b',
    userId: 'u',
    date: DateTime(2026, 8, 20, 7),
    createdAt: DateTime(2026, 8, 20, 7),
    activity: CardioActivity.run,
    duration: const Duration(minutes: 30),
    distanceKm: 5.2,
  ),
  // Einheit ohne Dauer.
  StrengthSession(
    id: 'c',
    userId: 'u',
    date: DateTime(2026, 8, 15),
    createdAt: DateTime(2026, 8, 15),
    bodyweight: true,
  ),
  // Regeneration ohne Art.
  RecoverySession(
    id: 'd',
    userId: 'u',
    date: DateTime(2026, 8, 12),
    createdAt: DateTime(2026, 8, 12),
    duration: const Duration(minutes: 25),
  ),
  // Cardio ohne Distanz.
  CardioSession(
    id: 'e',
    userId: 'u',
    date: DateTime(2026, 8, 10),
    createdAt: DateTime(2026, 8, 10),
    activity: CardioActivity.other,
    duration: const Duration(minutes: 40),
  ),
  // Lücke von mehr als 30 Tagen davor — die längste im Verlauf.
  for (var i = 0; i < 40; i++)
    StrengthSession(
      id: 'f$i',
      userId: 'u',
      date: DateTime(2026, 7, 1 - i * 3),
      createdAt: DateTime(2026, 7, 1 - i * 3),
      bodyweight: false,
      duration: const Duration(minutes: 45),
      planName: 'Leg Day',
      exercises: [
        LoggedExercise(
          exerciseId: 'pistol_squat',
          sets: [LoggedSet(reps: 6, weight: 20 + i.toDouble())],
        ),
      ],
    ),
];

class _RealisticSessions extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(realisticSessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async =>
      realisticSessions;
}

final _overrides = [
  authRepositoryProvider.overrideWithValue(
    FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
  ),
  allowlistRepositoryProvider.overrideWithValue(FakeAllowlistRepository()),
  profileRepositoryProvider
      .overrideWithValue(FakeProfileRepository(weightKg: 78)),
  dashboardRepositoryProvider.overrideWithValue(PreviewDashboardRepository()),
  exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository()),
  planRepositoryProvider.overrideWithValue(FakePlanRepository()),
  sessionRepositoryProvider.overrideWithValue(_RealisticSessions()),
  settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
  accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
  historyReferenceProvider.overrideWithValue(DateTime(2026, 9, 16)),
];

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(361, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.15),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Einheitenliste mit echtem Bestand', () {
    testWidgets('baut Lücken, Mehrfachtage und das Ende ohne Layoutfehler',
        (tester) async {
      await _pump(tester, const SessionListScreen());
      expect(tester.takeException(), isNull);

      // Der Lückenstreifen ist da — und die Zeile mit der längsten Pause.
      expect(find.textContaining('Tage'), findsWidgets);
      // Mehrfachtag: die zweite Einheit des Tages ist gekennzeichnet.
      expect(find.textContaining('2.'), findsWidgets);
      // Scrollen darf keinen Layoutfehler nachziehen.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ganz nach unten scrollen erreicht das Listenende',
        (tester) async {
      await _pump(tester, const SessionListScreen());
      final l10n = AppL10n.of(tester.element(find.byType(SessionListScreen)));
      // Der Kopf der Endkarte steht in Versalien (Mono-Sektionskopf).
      final end = find.text(l10n.listEndTitle.toUpperCase());
      await tester.scrollUntilVisible(
        end,
        600,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first,
      );
      expect(tester.takeException(), isNull);
      expect(end, findsOneWidget);
    });

    testWidgets('gefiltert leer nennt die Gesamtzahl und hebt den Zeitraum auf',
        (tester) async {
      await _pump(tester, const SessionListScreen());
      final element = tester.element(find.byType(SessionListScreen));
      final container = ProviderScope.containerOf(element);
      // Dezember 2025 hat keine Einheit.
      container.read(sessionFilterProvider.notifier).setPeriod(2025, 12);
      await tester.pumpAndSettle();

      final l10n = AppL10n.of(element);
      expect(find.text(l10n.listFilterEmptyTitle), findsOneWidget);
      expect(find.text(l10n.listFilterClear), findsOneWidget);

      await tester.tap(find.text(l10n.listFilterClear));
      await tester.pumpAndSettle();
      expect(find.text(l10n.listFilterEmptyTitle), findsNothing);
    });

    testWidgets('eine Zeile öffnet das Detail', (tester) async {
      await _pump(tester, const SessionListScreen());
      await tester.tap(find.text('Push Day A').first);
      await tester.pumpAndSettle();
      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Letzte Einheiten im Verlaufs-Tab', () {
    testWidgets('eine Zeile öffnet das Detail, „Alle" die Liste',
        (tester) async {
      await _pump(tester, HistoryScreen(onStart: () {}));
      final element = tester.element(find.byType(HistoryScreen));
      final l10n = AppL10n.of(element);

      // Die Auswertung steht seit 16.09.2026 oben im Verlauf; die Zeile liegt
      // dadurch tiefer und muss erst in den sichtbaren Bereich.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push Day A').last);
      await tester.pumpAndSettle();
      expect(find.byType(SessionDetailScreen), findsOneWidget);

      // Der Zurück-Weg ist der eigene Baustein, kein Material-Pfeil.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      final all = find.textContaining(l10n.historyAll(0).split(' ').first).last;
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.byType(SessionListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
