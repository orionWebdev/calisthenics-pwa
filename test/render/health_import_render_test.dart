@Tags(['render'])
library;

import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/domain/session_pairing.dart';
import 'package:atem/features/health_import/presentation/widgets/pair_sheet.dart';
import 'package:atem/features/health_import/presentation/widgets/review_sheet.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Eine Uhr-Quelle im Speicher, die schon etwas gelesen hat.
class _Repo implements HealthSessionRepository {
  _Repo(this.sessions);

  final List<HealthSession> sessions;

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(sessions);
  @override
  Future<List<HealthSession>> fetch(String userId) async => sessions;
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => DateTime(2026, 9, 20, 7, 12);
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

HealthSession _pending(String id, DateTime start, {String activity = 'RUNNING'}) =>
    HealthSession.pending(
      MeasuredSession(
        id: id,
        start: start,
        end: start.add(const Duration(minutes: 42)),
        sourceId: 'com.garmin.android.apps.connectmobile',
        activity: activity,
        deviceName: 'Garmin',
        averageHeartRate: 148,
        maxHeartRate: 171,
        calories: 412,
      ),
      DateTime(2026, 9, 20, 7, 12),
    );

void main() {
  final pending = [
    _pending('hc-1', DateTime(2026, 9, 20, 9, 14)),
    _pending('hc-2', DateTime(2026, 9, 18, 18), activity: 'BIKING'),
  ];

  final appSession = StrengthSession(
    id: 'a1',
    userId: 'u',
    date: DateTime(2026, 9, 18, 18, 2),
    createdAt: DateTime(2026, 9, 18, 18, 2),
    duration: const Duration(minutes: 52),
    rpe: 4,
    bodyweight: false,
    exercises: [
      LoggedExercise(
        exerciseId: 'e1',
        sets: [for (var i = 0; i < 24; i++) const LoggedSet(reps: 8)],
      ),
    ],
  );

  final watchForPair = HealthSession.pending(
    MeasuredSession(
      id: 'hc-pair',
      start: DateTime(2026, 9, 18, 18),
      end: DateTime(2026, 9, 18, 18, 58),
      sourceId: 'com.garmin.android.apps.connectmobile',
      deviceName: 'Garmin',
      averageHeartRate: 118,
      maxHeartRate: 164,
    ),
    DateTime(2026, 9, 20, 7, 12),
  );

  final cases = <String, Widget>{
    'hc_liste': const SessionListScreen(),
    'hc_paar': PairSheet(
      measured: watchForPair,
      verdict: PairSuggested(
        session: appSession,
        overlap: const Duration(minutes: 52),
      ),
    ),
    'hc_mehrdeutig': PairSheet(
      measured: watchForPair,
      verdict: PairAmbiguous([
        appSession,
        StrengthSession(
          id: 'a2',
          userId: 'u',
          date: DateTime(2026, 9, 18, 19),
          createdAt: DateTime(2026, 9, 18, 19),
          duration: const Duration(minutes: 20),
          bodyweight: false,
        ),
      ]),
    ),
    'hc_pruefblatt': HealthReviewSheet(pending: pending),
    'hc_pruefblatt_stapel': HealthReviewSheet(pending: pending),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...fixtureOverrides,
          healthSessionRepositoryProvider.overrideWithValue(_Repo(pending)),
          currentUserIdProvider.overrideWithValue('u'),
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
                textScaler: const TextScaler.linear(1.15),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: AtemColors.base,
              body: SafeArea(
                child: entry.key == 'hc_liste'
                    ? entry.value
                    : SizedBox(height: 960, child: entry.value),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      if (entry.key == 'hc_pruefblatt_stapel') {
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();
      }

      await writePng(tester, key, entry.key);
    });
  }
}
