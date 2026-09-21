import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/health_permissions.dart';
import 'package:atem/features/settings/presentation/widgets/settings_bits.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/application/weight_sync_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/domain/weight_series.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_health.dart';

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
  Future<DateTime?> lastRead(String userId) async => null;
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

HealthSession _accepted(String id) => HealthSession.pending(
      MeasuredSession(
        id: id,
        start: DateTime(2026, 9, 20, 9),
        end: DateTime(2026, 9, 20, 9, 42),
        sourceId: 'garmin',
      ),
      DateTime(2026, 9, 20, 10),
    ).copyWith(state: HealthSessionState.accepted, sessionId: 's$id');

/// Die zwei Schalter aus Board 15, Abschnitt D.
///
/// Sie waren bis zum 21.09.2026 Zeilen mit „Freigeben"; Health Connect kennt
/// für eine App aber nur „alles entziehen". Ein Schalter, der wirklich
/// schaltet, sitzt deshalb in ATEM — die Tests prüfen, dass er es tut.
void main() {
  late FakeHealthGateway gateway;
  late FakeSettingsRepository settingsRepo;

  Future<AppL10n> pump(
    WidgetTester tester, {
    HealthAvailability availability = HealthAvailability.available,
    bool weight = false,
    bool sessions = false,
    List<HealthSession> known = const [],
    WeightSeries series = WeightSeries.empty,
    UserSettings? settings,
  }) async {
    settingsRepo = FakeSettingsRepository(
      settings: settings ?? const UserSettings(),
    );
    gateway = FakeHealthGateway(
      availabilityValue: availability,
      granted: weight,
      sessionsGranted: sessions,
    );
    tester.view.physicalSize = const Size(361, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Die Einstellungsquelle der Fixture wird ersetzt, nicht ergänzt:
        // Ein Provider darf nicht zweimal überschrieben werden.
        for (final o in fixtureOverrides)
          if (!identical(o, fixtureOverrides[7])) o as dynamic,
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        healthGatewayProvider.overrideWithValue(gateway),
        healthSessionRepositoryProvider.overrideWithValue(_Repo(known)),
        currentUserIdProvider.overrideWithValue('u'),
        // Die Fixtures tragen gemessene Gewichtswerte; die machten aus
        // „nie freigegeben" ein „entzogen". Jeder Fall stellt seine eigene
        // Reihe.
        weightSeriesProvider.overrideWith((ref) => Stream.value(series)),
      ],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          backgroundColor: AtemColors.base,
          body: SingleChildScrollView(
            child: HealthPermissionsSection(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppL10n.of(tester.element(find.byType(HealthPermissionsSection)));
  }

  /// Der Wert des Schalters mit dieser Beschriftung.
  bool isOn(WidgetTester tester, String label) => tester
      .widgetList<SettingsSwitch>(find.byType(SettingsSwitch))
      .firstWhere((s) => s.label == label)
      .value;

  testWidgets('D1 — ohne Health Connect gibt es keinen Schalter',
      (tester) async {
    final l10n =
        await pump(tester, availability: HealthAvailability.notInstalled);

    // Kein Schalter, der nichts tun könnte — der Satz erklärt, warum.
    expect(find.byType(SettingsSwitch), findsNothing);
    expect(find.text(l10n.hcPermMissingNote), findsOneWidget);
    expect(find.text(l10n.hcPermInstall), findsOneWidget);
  });

  testWidgets('D2 — zwei Schalter, weil Google zwei Fragen stellt',
      (tester) async {
    final l10n = await pump(tester);

    expect(find.byType(SettingsSwitch), findsNWidgets(2));
    expect(isOn(tester, l10n.hcPermWeight), isFalse);
    expect(isOn(tester, l10n.hcPermSessions), isFalse);
    // Kein Sammelknopf „Alles erlauben".
    expect(find.text(l10n.hcPermGrant), findsNothing);
    // Und keine Unterzeilen: Der Zustand steht im Schalter.
    expect(find.text(l10n.hcStateDenied.toUpperCase()), findsNothing);
    expect(find.text(l10n.hcPermNoneNote), findsNothing);
  });

  testWidgets('D3 — Gewicht an, Einheiten aus', (tester) async {
    final l10n = await pump(tester, weight: true);

    expect(isOn(tester, l10n.hcPermWeight), isTrue);
    expect(isOn(tester, l10n.hcPermSessions), isFalse);
    expect(find.text(l10n.hcPermPartialNote), findsNothing);
  });

  testWidgets('entzogen: aus, und keine Drohung darunter', (tester) async {
    // Entzogen heisst: Es liegt schon etwas aus der Quelle da. Die Zeile
    // sagt dazu nichts mehr — der Schalter steht aus, mehr gibt es nicht zu
    // sagen.
    final l10n = await pump(
      tester,
      known: [_accepted('a'), _accepted('b')],
      series: WeightSeries.of([
        WeightEntry(
          date: DateTime(2026, 9, 19),
          kg: 78,
          source: WeightSource.healthConnect,
          externalId: 'hc-w',
        ),
      ]),
    );

    expect(isOn(tester, l10n.hcPermWeight), isFalse);
    expect(isOn(tester, l10n.hcPermSessions), isFalse);
    expect(find.text(l10n.hcPermRevokedNote(2)), findsNothing);
  });

  group('schalten', () {
    testWidgets('anschalten ohne Freigabe fragt genau einmal, je Datentyp',
        (tester) async {
      final l10n = await pump(tester);

      await tester.tap(find.text(l10n.hcPermWeight));
      await tester.pumpAndSettle();

      expect(gateway.requests, 1);
      expect(gateway.sessionRequests, 0);
      expect(settingsRepo.saved.last.healthWeightEnabled, isTrue);
    });

    testWidgets('lehnt jemand den Dialog ab, bleibt der Schalter aus',
        (tester) async {
      final l10n = await pump(tester);
      gateway.grantOnRequest = false;

      await tester.tap(find.text(l10n.hcPermWeight));
      await tester.pumpAndSettle();

      expect(gateway.requests, 1);
      expect(settingsRepo.saved, isEmpty,
          reason: 'ein Schalter auf „an", der nichts tut, wäre gelogen');
      expect(isOn(tester, l10n.hcPermWeight), isFalse);
    });

    testWidgets('ausschalten schaltet in ATEM — ohne Dialog', (tester) async {
      // Health Connect kennt nur „alles entziehen". Aus heisst deshalb: ATEM
      // liest und schreibt nicht mehr; die Freigabe des Systems bleibt.
      final l10n = await pump(tester, weight: true);
      expect(isOn(tester, l10n.hcPermWeight), isTrue);

      await tester.tap(find.text(l10n.hcPermWeight));
      await tester.pumpAndSettle();

      expect(settingsRepo.saved.last.healthWeightEnabled, isFalse);
      expect(settingsRepo.saved.last.healthSessionsEnabled, isTrue,
          reason: 'der andere Datentyp bleibt, wie er ist');
      expect(gateway.requests, 0);
    });

    testWidgets('freigegeben, aber ausgeschaltet: anschalten fragt nicht',
        (tester) async {
      final l10n = await pump(
        tester,
        weight: true,
        settings: const UserSettings(healthWeightEnabled: false),
      );
      expect(isOn(tester, l10n.hcPermWeight), isFalse,
          reason: 'an ist nur, wenn beides stimmt');

      await tester.tap(find.text(l10n.hcPermWeight));
      await tester.pumpAndSettle();

      expect(gateway.requests, 0, reason: 'die Freigabe steht ja noch');
      expect(settingsRepo.saved.last.healthWeightEnabled, isTrue);
    });

    testWidgets('Einheiten anschalten fragt für Einheiten, nicht für Gewicht',
        (tester) async {
      final l10n = await pump(tester);

      await tester.tap(find.text(l10n.hcPermSessions));
      await tester.pumpAndSettle();

      expect(gateway.sessionRequests, 1);
      expect(gateway.requests, 0);
      expect(settingsRepo.saved.last.healthSessionsEnabled, isTrue);
    });
  });
}
