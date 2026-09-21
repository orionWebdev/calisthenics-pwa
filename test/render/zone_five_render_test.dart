@Tags(['render'])
library;

import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/pulse/presentation/widgets/zone_five_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/detail_fixtures.dart';
import '../support/render.dart';

/// Sichtprüfung von „Zone 5 je Woche" (Auswertung).
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/zone_five_render_test.dart --tags render
HealthSession _week(int daysAgo, int zone5Minutes, String id) =>
    HealthSession.pending(
      MeasuredSession(
        id: id,
        start: DateTime(2026, 9, 20).subtract(Duration(days: daysAgo)),
        end: DateTime(2026, 9, 20)
            .subtract(Duration(days: daysAgo))
            .add(const Duration(minutes: 45)),
        sourceId: 'garmin',
        pulse: PulseProfile(
          secondsByBpm: {
            130: 25 * 60,
            if (zone5Minutes > 0) 175: zone5Minutes * 60,
          },
          windowSeconds: 45 * 60,
        ),
      ),
      DateTime(2026, 9, 20),
    ).copyWith(state: HealthSessionState.accepted);

void main() {
  final cases = <String, (List<HealthSession>, double)>{
    'z5_daten': (
      [
        _week(2, 11, 'a'),
        _week(4, 6, 'b'),
        _week(10, 3, 'c'),
        _week(17, 0, 'd'),
        _week(31, 14, 'e'),
        _week(45, 8, 'f'),
      ],
      1.15,
    ),
    'z5_gross': ([_week(2, 11, 'a'), _week(10, 3, 'c')], 2.0),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize =
          Size(entry.key.contains('gross') ? 320 : 361, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: detailOverrides(
          session: detailMerged,
          settings: detailSettings(),
          health: DetailHealth(entry.value.$1),
        ).cast(),
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
                textScaler: TextScaler.linear(entry.value.$2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: AtemColors.base,
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ZoneFiveCard(
                  sessions: [detailBefore, detailMerged],
                  reference: DateTime(2026, 9, 20),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, entry.key);
    });
  }
}
