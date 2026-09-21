@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/detail_fixtures.dart';
import '../support/render.dart';

/// Sichtprüfung des Einheitendetails (Board 16) — jede Art, jeder Zustand.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/detail_render_test.dart --tags render
class _Case {
  const _Case(this.session, this.settings, this.health, {this.scale = 1.15});

  final TrainingSession session;
  final UserSettings settings;
  final HealthSessionRepository health;
  final double scale;
}

void main() {
  final cases = <String, _Case>{
    'a1_kraft_zusammengefuehrt':
        _Case(detailMerged, detailSettings(), DetailHealth([detailRecord()])),
    'a2_laufen_aus_uhr':
        _Case(detailRun, detailSettings(), DetailHealth([detailRunRecord()])),
    'a3_regeneration':
        _Case(detailRecovery, detailSettings(), DetailHealth(const [])),
    'a4_kopf_ohne_zahl':
        _Case(detailBare, detailSettings(), DetailHealth(const [])),
    'c1_zu_wenig_daten': _Case(detailMerged, detailSettings(),
        DetailHealth([detailRecord(pulse: detailPulse(recordedMinutes: 21))])),
    'c2_zonen_fehlen': _Case(detailMerged, detailSettings(withZones: false),
        DetailHealth([detailRecord()])),
    'c4_laedt': _Case(
        detailMerged, detailSettings(), DetailHealth(const [], hangs: true)),
    'c5_fehler': _Case(
        detailMerged, detailSettings(), DetailHealth(const [], fails: true)),
    'gross_kraft_200': _Case(
        detailMerged, detailSettings(), DetailHealth([detailRecord()]),
        scale: 2.0),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      final gross = entry.key.startsWith('gross');
      tester.view.physicalSize = Size(gross ? 320 : 361, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final c = entry.value;
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: detailOverrides(
          session: c.session,
          settings: c.settings,
          health: c.health,
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
                textScaler: TextScaler.linear(c.scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: SessionDetailScreen(session: c.session),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, entry.key);
    });
  }
}
