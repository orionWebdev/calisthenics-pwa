import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/health_import/presentation/widgets/health_inbox.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Der Hinweis auf dem Hybrid-Tab: **nur, solange etwas wartet.**
///
/// Ein „Lese…", das bei jedem Start erscheint und wieder geht, wäre ein
/// Flackern über der Startseite; ein Lesefehler gehört dorthin, wo man ihn
/// beheben kann. Beides bleibt am eigenen Ort des Eingangs.

class _Repo implements HealthSessionRepository {
  _Repo(this.records);

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
  Future<DateTime?> lastRead(String userId) async => DateTime(2026, 9, 21, 7);
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

HealthSession _pending(String id) => HealthSession.pending(
      MeasuredSession(
        id: id,
        start: DateTime(2026, 9, 20, 18),
        end: DateTime(2026, 9, 20, 18, 42),
        sourceId: 'com.garmin.android.apps.connectmobile',
      ),
      DateTime(2026, 9, 21, 7),
    );

Future<AppL10n> _pump(
  WidgetTester tester, {
  required List<HealthSession> records,
}) async {
  tester.view.physicalSize = const Size(361, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...fixtureOverrides,
      healthSessionRepositoryProvider.overrideWithValue(_Repo(records)),
      currentUserIdProvider.overrideWithValue('u'),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const Scaffold(
        body: HealthInboxHeader(onlyWhenPending: true),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(HealthInboxHeader)));
}

void main() {
  testWidgets('wartet nichts, steht dort nichts', (tester) async {
    await _pump(tester, records: const []);

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.textContaining('Health'), findsNothing);
    expect(tester.getSize(find.byType(HealthInboxHeader)).height, 0,
        reason: 'ein Block ohne Daten rendert nicht');
  });

  testWidgets('wartet etwas, steht die Zahl da und ein Weg hinein',
      (tester) async {
    final l10n = await _pump(tester, records: [_pending('hc-1')]);

    expect(find.text(l10n.hcInboxTitle(1)), findsOneWidget);
    expect(find.text(l10n.hcInboxAction), findsOneWidget);
  });
}
