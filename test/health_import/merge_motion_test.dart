import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/health_inbox.dart';
import 'package:atem/features/health_import/presentation/widgets/merge_motion.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Die Verschmelzung als Bewegung (Board 15, B6).
///
/// Geprüft wird, was die drei Phasen versprechen — nicht, wie es aussieht:
/// dass die Uhr-Zeile für die Dauer der Bewegung noch einmal da ist, dass in
/// Phase 1 nichts darunter weicht, dass die Liste danach zur Ruhe kommt, und
/// dass bei reduzierter Bewegung nichts davon läuft.

/// Die Uhr-Einheit **nach** der Entscheidung: übernommen, also nicht mehr im
/// Eingang. Genau der Zustand, in dem die Liste steht, wenn das Blatt sich
/// schliesst.
final _measured = HealthSession.pending(
  MeasuredSession(
    id: 'hc-pull',
    start: DateTime(2026, 9, 18, 18, 4),
    end: DateTime(2026, 9, 18, 18, 56),
    sourceId: 'com.garmin.android.apps.connectmobile',
    deviceName: 'Garmin',
    averageHeartRate: 118,
  ),
  DateTime(2026, 9, 20, 7, 12),
);

class _Accepted implements HealthSessionRepository {
  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value([
        _measured.copyWith(
          state: HealthSessionState.accepted,
          sessionId: 'pull',
        ),
      ]);
  @override
  Future<List<HealthSession>> fetch(String userId) async => const [];
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

/// Zwei Einheiten: die zusammengeführte und eine ältere darunter, an der sich
/// ablesen lässt, ob die Liste weicht.
final _sessions = <TrainingSession>[
  StrengthSession(
    id: 'pull',
    userId: 'u',
    date: DateTime(2026, 9, 18, 18),
    createdAt: DateTime(2026, 9, 18, 18),
    duration: const Duration(minutes: 52),
    rpe: 4,
    bodyweight: false,
    planName: 'Pull B',
    healthSessionId: 'hc-pull',
  ),
  StrengthSession(
    id: 'push',
    userId: 'u',
    date: DateTime(2026, 9, 16, 18),
    createdAt: DateTime(2026, 9, 16, 18),
    duration: const Duration(minutes: 44),
    rpe: 3,
    bodyweight: false,
    planName: 'Push A',
  ),
];

class _Sessions extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(_sessions);
  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => _sessions;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool reduced = false,
}) async {
  tester.view.physicalSize = const Size(361, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    for (var i = 0; i < fixtureOverrides.length; i++)
      // fixtureOverrides[6] ist die Sitzungsquelle — ersetzen, nicht doppeln.
      if (i == 6)
        sessionRepositoryProvider.overrideWithValue(_Sessions())
      else
        fixtureOverrides[i],
    healthSessionRepositoryProvider.overrideWithValue(_Accepted()),
    currentUserIdProvider.overrideWithValue('u'),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const SessionListScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

Finder get _watchRow => find.byType(HealthPendingRow);
Finder get _below => find.text('Push A');

void main() {
  testWidgets('die Uhr-Zeile ist noch einmal da und läuft dann hinein',
      (tester) async {
    final container = await _pump(tester);

    // Vorher: übernommen heisst, sie steht nicht mehr in der Liste.
    expect(_watchRow, findsNothing);

    container.read(mergeAnimationProvider.notifier).arm('pull', _measured);
    await tester.pump();
    // Der Auftrag fährt erst im Folgeframe los.
    await tester.pump();

    expect(_watchRow, findsOneWidget,
        reason: 'ohne zweite Zeile liefe nichts in etwas hinein');
    expect(find.byType(AtemMergingWatchRow), findsOneWidget);

    // Phase 1 endet bei 140 ms; danach beginnt sie zu fallen.
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(_watchRow, findsNothing);
    expect(container.read(mergeAnimationProvider), isNull,
        reason: 'sonst liefe die Bewegung beim nächsten Bau erneut');
  });

  testWidgets('in Phase 1 weicht nichts darunter', (tester) async {
    final container = await _pump(tester);
    container.read(mergeAnimationProvider.notifier).arm('pull', _measured);
    await tester.pump();
    await tester.pump();

    final start = tester.getTopLeft(_below).dy;
    // Mitten in Phase 1: Die beiden Zeilen rücken aufeinander zu, aber die
    // Höhen stehen — die Zeile darunter darf sich keinen Pixel bewegen.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(_below).dy, start);

    // Erst in Phase 2 fällt die Uhr-Zeile, und die Liste rückt nach.
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getTopLeft(_below).dy, lessThan(start));

    await tester.pumpAndSettle();
  });

  testWidgets('der Herkunftspunkt stellt sich erst in Phase 3 um',
      (tester) async {
    final container = await _pump(tester);
    container.read(mergeAnimationProvider.notifier).arm('pull', _measured);
    await tester.pump();
    await tester.pump();

    double? progressOf(WidgetTester t) => t
        .widgetList<AtemOriginDot>(find.byType(AtemOriginDot))
        .map((d) => d.mergeProgress)
        .firstWhere((p) => p != null, orElse: () => null);

    expect(progressOf(tester), 0, reason: 'Phase 1 rührt den Punkt nicht an');
    await tester.pump(const Duration(milliseconds: 300));
    expect(progressOf(tester), 0, reason: 'Phase 2 auch nicht');
    await tester.pump(const Duration(milliseconds: 60));
    expect(progressOf(tester), greaterThan(0));

    await tester.pumpAndSettle();
    // Danach Ruhelage: kein Nachpulsen, der Punkt steht auf Ring mit Kern.
    expect(
      tester
          .widgetList<AtemOriginDot>(find.byType(AtemOriginDot))
          .map((d) => d.shape),
      contains(AtemOriginShape.ringWithCore),
    );
  });

  testWidgets('bei reduzierter Bewegung läuft die Choreografie gar nicht',
      (tester) async {
    final container = await _pump(tester, reduced: true);
    container.read(mergeAnimationProvider.notifier).arm('pull', _measured);
    await tester.pump();
    await tester.pump();

    // Die Uhr-Zeile kommt nicht zurück — es gibt nichts zu sehen, nur den
    // Endzustand und die Meldung in Worten.
    expect(_watchRow, findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    expect(container.read(mergeAnimationProvider), isNull);
  });
}
