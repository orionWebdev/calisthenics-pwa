import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/merge_motion.dart';
import 'package:atem/features/health_import/presentation/widgets/pair_sheet.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Der **ganze** Weg: aus der Liste ins Paar-Blatt, zusammenführen, zurück —
/// und dort muss die Bewegung laufen.
///
/// Die Einzelteile waren geprüft und grün, der Weg als Ganzes nicht. Auf dem
/// Gerät lief die Bewegung deshalb dreimal nicht, ohne dass ein Test etwas
/// davon merkte.

final _watch = HealthSession.pending(
  MeasuredSession(
    id: 'hc-1',
    start: DateTime(2026, 9, 18, 18),
    end: DateTime(2026, 9, 18, 18, 58),
    sourceId: 'com.garmin.android.apps.connectmobile',
    averageHeartRate: 118,
    maxHeartRate: 164,
  ),
  DateTime(2026, 9, 20, 7),
);

final _app = StrengthSession(
  id: 'a1',
  userId: 'u',
  date: DateTime(2026, 9, 18),
  createdAt: DateTime(2026, 9, 18),
  startedAt: DateTime(2026, 9, 18, 18, 2),
  duration: const Duration(minutes: 52),
  bodyweight: false,
  planName: 'Pull B',
);

class _Repo implements HealthSessionRepository {
  final records = <HealthSession>[_watch];

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(records);
  @override
  Future<List<HealthSession>> fetch(String userId) async => records;
  @override
  Future<void> save(String userId, HealthSession session) async {
    records
      ..removeWhere((r) => r.externalId == session.externalId)
      ..add(session);
  }

  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

class _Sessions extends FakeSessionRepository {
  final sessions = <TrainingSession>[_app];

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(sessions);
  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => sessions;
  @override
  Future<void> linkHealthSession(String id, String? healthSessionId) async {}
}

void main() {
  testWidgets('aus der Liste zusammengeführt — und die Bewegung läuft',
      (tester) async {
    tester.view.physicalSize = const Size(361, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      for (var i = 0; i < fixtureOverrides.length; i++)
        // fixtureOverrides[6] ist die Sitzungsquelle — ersetzen, nicht doppeln.
        if (i == 6)
          sessionRepositoryProvider.overrideWithValue(_Sessions())
        else
          fixtureOverrides[i],
      healthSessionRepositoryProvider.overrideWithValue(_Repo()),
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
      ),
    ));
    await tester.pumpAndSettle();

    final l10n = AppL10n.of(tester.element(find.byType(SessionListScreen)));

    // Die wartende Zeile steht da, mit ihrer Aufforderung.
    expect(find.text(l10n.hcInboxAction), findsWidgets);
    await tester.tap(find.text(l10n.hcInboxAction).first);
    await tester.pumpAndSettle();

    // Paar-Blatt: die Vermutung mit ihrer Begründung.
    expect(find.text(l10n.hcPairQuestion), findsOneWidget);
    await tester.tap(find.text(l10n.hcPairMerge));
    await tester.pumpAndSettle();

    // Stufe 2 der Folgen.
    await tester.tap(find.text(l10n.hcPairMerge).last);

    // **Kein `pumpAndSettle` hier.** Es spult jede laufende Animation bis
    // zum Ende — auch die, um die es geht. Der Test sähe dann immer einen
    // fertigen Bildschirm und wäre grün, gleich ob sich etwas bewegt hat.
    // Gezählt wird nur, was **ohne Blatt darüber** zu sehen war. Eine
    // Bewegung, die abläuft, während das Prüfblatt noch herunterfährt,
    // findet zwar statt — gesehen hat sie niemand.
    var sichtbar = 0;
    var verdeckt = 0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final laeuft = find.byType(AtemMergingWatchRow).evaluate().isNotEmpty;
      final blattWeg = find.byType(PairSheet).evaluate().isEmpty &&
          find.byType(BottomSheet).evaluate().isEmpty;
      if (laeuft && blattWeg) sichtbar++;
      if (laeuft && !blattWeg) verdeckt++;
    }

    // **Fast alles muss sichtbar sein.** Bis zum 21.09.2026 lief die
    // Bewegung ab dem Moment, in dem das Blatt zu fallen begann: Von 420 ms
    // lagen 300 hinter dem Blatt, übrig blieb der Punkt. Der Nutzer sah
    // dreimal nichts und fragte, wo die Animation bleibe.
    expect(verdeckt, 0, reason: 'keine Phase darf hinter dem Blatt ablaufen');
    expect(sichtbar, greaterThanOrEqualTo(6),
        reason: 'die Bewegung dauert 420 ms — das sind mindestens sechs '
            'Bilder im Abstand von 50 ms');

    await tester.pumpAndSettle();
    expect(container.read(mergeAnimationProvider), isNull,
        reason: 'danach Ruhelage');

    // Die Meldung steht sechs Sekunden. Ohne sie abzuwarten bliebe ihr
    // Zeitgeber offen, und das Testgerüst meldet das als Fehler.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });
}
