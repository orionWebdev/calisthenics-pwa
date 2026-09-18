@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/dashboard/application/dashboard_providers.dart';
import 'package:atem/features/dashboard/data/preview_dashboard_repository.dart';
import 'package:atem/features/dashboard/domain/dashboard_data.dart';
import 'package:atem/features/dashboard/domain/dashboard_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/hybrid/presentation/screens/hybrid_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung der verschmolzenen Karte „Heute und diese Woche".
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/hybrid_today_render_test.dart
///
/// Zwei Lagen: mit Termin für heute (Tagesteil plus Wochenteil) und ohne
/// (nur Woche). Je 361 dp bei 1,15 wie das Honor und 320 dp bei 2,0.
final _today = DateTime(2026, 9, 17);

DateTime _ago(int days) =>
    DateTime(_today.year, _today.month, _today.day - days, 18);

StrengthSession _strength(String id, int daysAgo, int minutes) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      bodyweight: true,
      duration: Duration(minutes: minutes),
      planName: 'Pull - Home',
      exercises: [
        LoggedExercise(
          exerciseId: 'pull_up',
          sets: [for (var i = 0; i < 4; i++) const LoggedSet(reps: 8)],
        ),
      ],
    );

// Ausdrücklich als `List<TrainingSession>`: Eine Liste, die nur
// `StrengthSession` trägt, lässt `LastActivity.of` beim `reduce` auflaufen —
// die App reicht immer den Obertyp durch.
final List<TrainingSession> _sessions = [
  _strength('a', 1, 26),
  _strength('b', 2, 26),
];

/// Dashboard ohne Termin für heute.
class _NoSessionDashboard implements DashboardRepository {
  @override
  Stream<DashboardData> watchDashboard() =>
      PreviewDashboardRepository().watchDashboard().map((d) => DashboardData(
            user: d.user,
            readiness: d.readiness,
            performance: d.performance,
            session: null,
            workoutLog: d.workoutLog,
            lastSession: d.lastSession,
            nextSession: d.nextSession,
          ));
}

void main() {
  // Ohne Termin wird das Dashboard ersetzt; mit Termin bleibt die Attrappe
  // aus den Fixtures. Der Typ der Überschreibungen ist in Riverpod nicht
  // öffentlich, deshalb steht hier ein Schalter statt einer Liste.
  const scenarios = {'today_mit_termin': false, 'today_ohne_termin': true};

  for (final scenario in scenarios.entries) {
    final withoutSession = scenario.value;
    for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
      final name = '${scenario.key}_${width.round()}_$scale';
      testWidgets('rendert $name', (tester) async {
        if (!renderEnabled) return;
        await loadRealFonts();
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(ProviderScope(
          overrides: [
            // Der letzte Eintrag der Fixtures setzt den Stichtag; hier gilt
            // der 17.09. — zweimal überschreiben verbietet Riverpod.
            ...fixtureOverrides.take(fixtureOverrides.length - 1).where((o) =>
                !withoutSession ||
                !o.toString().contains('DashboardRepository')),
            historyReferenceProvider.overrideWithValue(_today),
            sessionStreamProvider
                .overrideWith((ref) => Stream.value(_sessions)),
            if (withoutSession)
              dashboardRepositoryProvider
                  .overrideWithValue(_NoSessionDashboard()),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
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
              home: HybridScreen(onStart: (_) {}),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        await writePng(tester, key, name);
      });
    }
  }
}
