@Tags(['render'])
library;

import 'dart:async';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/presentation/screens/heart_rate_zones_screen.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/settings_repository.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung der Herzfrequenzzonen in den Einstellungen (Board 16, D).
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/pulse_render_test.dart --tags render
class _Settings implements SettingsRepository {
  _Settings(this.current);

  UserSettings current;
  final _changes = StreamController<UserSettings>.broadcast();

  @override
  Stream<UserSettings> watch(String userId) async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<UserSettings> fetch(String userId) async => current;

  @override
  Future<void> save(String userId, UserSettings settings) async {
    current = settings;
    _changes.add(settings);
  }
}

class _Health implements HealthSessionRepository {
  _Health(this.records);

  final List<HealthSession> records;

  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(records);
  @override
  Future<List<HealthSession>> fetch(String userId) async => records;
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

void main() {
  final zones = HeartRateZones.tryFrom(const [112, 131, 149, 168])!;
  final set = UserSettings(
    heartRate: HeartRateSettings(
      hrMax: 186,
      hrMaxSetAt: DateTime(2026, 9, 2),
      zones: zones,
      zonesSetAt: DateTime(2026, 9, 12),
    ),
  );

  final cases = <String, (UserSettings, double, bool)>{
    'zonen_d1_festgelegt': (set, 1.15, false),
    'zonen_d2_leer': (const UserSettings(), 1.15, false),
    'zonen_d4_hfmax_fehlt': (const UserSettings(), 1.15, true),
    'zonen_d1_gross': (set, 2.0, false),
    'zonen_d3_grenze': (set, 1.15, false),
  };

  for (final entry in cases.entries) {
    testWidgets('rendert ${entry.key}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final (settings, scale, proposal) = entry.value;
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          for (final o in fixtureOverrides)
            if (!identical(o, fixtureOverrides[7])) o as dynamic,
          settingsRepositoryProvider.overrideWithValue(_Settings(settings)),
          healthSessionRepositoryProvider.overrideWithValue(_Health(const [])),
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
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const HeartRateZonesScreen(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n =
          AppL10n.of(tester.element(find.byType(HeartRateZonesScreen)));
      if (proposal) {
        await tester.tap(find.text(l10n.settingsZonesProposal));
        await tester.pumpAndSettle();
      }
      if (entry.key == 'zonen_d3_grenze') {
        await tester.tap(find.text('131 BPM'));
        await tester.pumpAndSettle();
      }

      await writePng(tester, key, entry.key);
    });
  }
}
