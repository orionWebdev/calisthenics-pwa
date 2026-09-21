import 'dart:async';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
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

/// Die Herzfrequenzzonen in den Einstellungen (Board 16, D).

class _Settings implements SettingsRepository {
  _Settings(this.current);

  UserSettings current;
  final saved = <UserSettings>[];
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
    saved.add(settings);
    _changes.add(settings);
  }
}

class _NoHealth implements HealthSessionRepository {
  @override
  Stream<List<HealthSession>> watch(String userId) => Stream.value(const []);
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

/// Die Fixture **mit ausgetauschter Einstellungsquelle** — ein Provider darf
/// nicht zweimal überschrieben werden.
List<Object> _base(_Settings repo) => [
      for (final o in fixtureOverrides)
        if (!identical(o, fixtureOverrides[_settingsIndex])) o,
      settingsRepositoryProvider.overrideWithValue(repo),
      healthSessionRepositoryProvider.overrideWithValue(_NoHealth()),
      currentUserIdProvider.overrideWithValue('u'),
    ];

/// Die Stelle von `settingsRepositoryProvider` in `fixtureOverrides`.
const _settingsIndex = 7;

final _zones = HeartRateZones.tryFrom(const [112, 131, 149, 168])!;

UserSettings _set() => UserSettings(
      heartRate: HeartRateSettings(
        hrMax: 186,
        hrMaxSetAt: DateTime(2026, 9, 2),
        zones: _zones,
        zonesSetAt: DateTime(2026, 9, 12),
      ),
    );

Future<AppL10n> _pump(WidgetTester tester, _Settings repo) async {
  tester.view.physicalSize = const Size(361, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: _base(repo).cast(),
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const HeartRateZonesScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(HeartRateZonesScreen)));
}

void main() {
  group('nicht festgelegt', () {
    testWidgets('zwei Wege, kein Vorbelegen', (tester) async {
      final l10n = await _pump(tester, _Settings(const UserSettings()));

      expect(find.text(l10n.settingsZonesUnsetNote), findsOneWidget);
      expect(find.text(l10n.settingsZonesSetBounds), findsOneWidget);
      expect(find.text(l10n.settingsZonesProposal), findsOneWidget);
      // Der Vorschlag nennt sich selbst einen Startpunkt.
      expect(find.text(l10n.settingsZonesProposalNote), findsOneWidget);
      // Keine Zone, keine Grenze: Nichts ist festgelegt.
      expect(find.text(l10n.detailZoneName(1)), findsNothing);
    });

    testWidgets('der Vorschlag ohne HFmax nennt beide Auswege', (tester) async {
      final repo = _Settings(const UserSettings());
      final l10n = await _pump(tester, repo);

      await tester.tap(find.text(l10n.settingsZonesProposal));
      await tester.pumpAndSettle();

      // D4: Der Fehler schliesst keinen Weg ab.
      expect(find.text(l10n.settingsZonesNoHrmax), findsOneWidget);
      expect(find.text(l10n.settingsZonesHrMaxEnter), findsOneWidget);
      expect(find.text(l10n.settingsZonesSetBounds), findsOneWidget);
      expect(find.text(l10n.settingsZonesKeepNote), findsOneWidget);
      expect(repo.saved, isEmpty, reason: 'nichts wird geraten');
    });

    testWidgets('der Vorschlag mit HFmax rechnet 60/70/80/90 aufgerundet',
        (tester) async {
      final repo = _Settings(UserSettings(
        heartRate:
            HeartRateSettings(hrMax: 186, hrMaxSetAt: DateTime(2026, 9, 2)),
      ));
      final l10n = await _pump(tester, repo);

      await tester.tap(find.text(l10n.settingsZonesProposal));
      await tester.pumpAndSettle();

      expect(repo.saved.single.heartRate.zones!.bounds, [112, 131, 149, 168]);
      // Und danach steht der festgelegte Zustand da.
      expect(find.text(l10n.detailZoneName(1)), findsOneWidget);
    });
  });

  group('festgelegt', () {
    testWidgets('Zonen im Wechsel mit Grenzen — nur die Grenze ist ein Ziel',
        (tester) async {
      final l10n = await _pump(tester, _Settings(_set()));

      for (var z = 1; z <= 5; z++) {
        expect(find.text(l10n.detailZoneName(z)), findsOneWidget);
      }
      // Vier Grenzen, jede mit ihrem Wert.
      for (final bpm in [112, 131, 149, 168]) {
        expect(find.text('$bpm BPM'), findsOneWidget);
      }
      // Bereiche der Zonen.
      expect(find.text(l10n.detailZoneRangeUpto(111)), findsOneWidget);
      expect(find.text(l10n.detailZoneRange(112, 130)), findsOneWidget);
      expect(find.text(l10n.detailZoneRangeFrom(168)), findsOneWidget);
      // Gilt auch für vergangene Einheiten — als Satz.
      expect(find.text(l10n.settingsZonesRetro), findsOneWidget);
    });

    testWidgets('eine Grenze verschieben und übernehmen', (tester) async {
      final repo = _Settings(_set());
      final l10n = await _pump(tester, repo);

      await tester.tap(find.text('131 BPM'));
      await tester.pumpAndSettle();

      // „Grenze 2" steht auch als Zeile dahinter — gezählt wird im Blatt.
      expect(
        find.descendant(
          of: find.byType(AtemSheet),
          matching: find.text(l10n.settingsZonesBoundaryTitle(2)),
        ),
        findsOneWidget,
      );
      // Der Grund für die obere Schranke steht da, bevor man ihn braucht.
      expect(find.text(l10n.settingsZonesBoundaryLimit(148)), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.settingsZonesPlusA11y));
      await tester.pumpAndSettle();
      expect(find.text('132'), findsOneWidget);

      await tester.tap(find.text(l10n.sheetPickerApply));
      await tester.pumpAndSettle();

      expect(repo.saved.single.heartRate.zones!.bounds, [112, 132, 149, 168]);
    });

    testWidgets('an der Schranke tut + nichts — und der Satz sagt warum',
        (tester) async {
      final repo = _Settings(_set());
      final l10n = await _pump(tester, repo);

      await tester.tap(find.text('131 BPM'));
      await tester.pumpAndSettle();

      // 131 → 148: siebzehn Schritte. Danach ist Schluss.
      for (var i = 0; i < 25; i++) {
        await tester.tap(find.bySemanticsLabel(l10n.settingsZonesPlusA11y));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('148'), findsOneWidget,
          reason: 'Grenze 3 liegt auf 149 — darüber wäre Zone 3 leer');
      expect(find.text(l10n.settingsZonesBoundaryLimit(148)), findsOneWidget);
    });

    testWidgets('Abbrechen schreibt nichts', (tester) async {
      final repo = _Settings(_set());
      final l10n = await _pump(tester, repo);

      await tester.tap(find.text('131 BPM'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.settingsZonesPlusA11y));
      await tester.pump();
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(repo.saved, isEmpty);
    });
  });

  group('Barrierefreiheit', () {
    testWidgets('festgelegt', (tester) async {
      await expectA11y(
        tester,
        const HeartRateZonesScreen(),
        baseOverrides: _base(_Settings(_set())),
      );
    });

    testWidgets('nicht festgelegt', (tester) async {
      await expectA11y(
        tester,
        const HeartRateZonesScreen(),
        baseOverrides: _base(_Settings(const UserSettings())),
      );
    });
  });
}
