@Tags(['render'])
library;

import 'package:atem/app/application/tab_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_screen.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung der Cardio-Auswertung — vor allem der Lage von „Zone 5 je
/// Woche" unter den Wochenkilometern.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/cardio_analysis_render_test.dart --tags render
class _MixedSessions extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(_sessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => _sessions;
}

final _sessions = <TrainingSession>[
  ...fixtureSessions,
  for (var i = 0; i < 6; i++)
    CardioSession(
      id: 'c$i',
      userId: 'u',
      date: DateTime(2026, 8, 10 + i * 2),
      createdAt: DateTime(2026, 8, 10 + i * 2),
      activity: CardioActivity.run,
      duration: const Duration(minutes: 40),
      distanceKm: 7.5 + i,
      rpe: 3,
    ),
];

void main() {
  testWidgets('Cardio › Auswertung', (tester) async {
    if (!renderEnabled) return;
    await loadRealFonts();

    tester.view.physicalSize = const Size(361 * 2, 1100 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      // Stelle 6 ist der Einheiten-Speicher; ersetzen statt ergänzen.
      overrides: [
        for (var i = 0; i < fixtureOverrides.length; i++)
          if (i != 6) fixtureOverrides[i],
        sessionRepositoryProvider.overrideWithValue(_MixedSessions()),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: AtemTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.15)),
            child: child!,
          ),
          home: const CardioScreen(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    ProviderScope.containerOf(tester.element(find.byType(CardioScreen)))
        .read(appTabsProvider.notifier)
        .setCardioSegment(CardioSegment.analysis);
    await tester.pumpAndSettle();

    await writePng(tester, key, 'cardio_auswertung');
  });
}
