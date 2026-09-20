import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/screens/session_list_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// Die Herkunft im Bestand (Board 15, Abschnitt C).
///
/// Geprüft wird die Regel, an der das Idiom hängt: Punkt **oder** Wort, nie
/// beides — und die Herkunft gehört ins Zeilenlabel, nicht in einen eigenen
/// Knoten daneben.

/// Eine Uhr-Quelle, die nichts im Eingang hat: Der Eingangskopf soll die
/// Prüfung nicht mit seinen eigenen gestrichelten Punkten stören.
class _EmptyInbox implements HealthSessionRepository {
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

final _sessions = <TrainingSession>[
  // In der App geführt, mit Anstrengung.
  StrengthSession(
    id: 'app',
    userId: 'u',
    date: DateTime(2026, 9, 19, 18),
    createdAt: DateTime(2026, 9, 19, 18),
    duration: const Duration(minutes: 52),
    rpe: 4,
    bodyweight: false,
    planName: 'Push A',
  ),
  // In der App geführt, **ohne** Anstrengung: Hier ist die Angabe schlicht
  // nicht gemacht worden. Das ist keine Fehlstelle der Uhr und gehört nicht
  // in die Zeile.
  StrengthSession(
    id: 'app-ohne-rpe',
    userId: 'u',
    date: DateTime(2026, 9, 18, 18),
    createdAt: DateTime(2026, 9, 18, 18),
    duration: const Duration(minutes: 40),
    bodyweight: false,
    planName: 'Pull A',
  ),
  // Aus der Uhr übernommen — eine Uhr misst keine Anstrengung.
  CardioSession(
    id: 'uhr',
    userId: 'u',
    date: DateTime(2026, 9, 17, 7, 30),
    createdAt: DateTime(2026, 9, 20, 7, 12),
    duration: const Duration(minutes: 42),
    name: 'Laufen',
    fromHealth: true,
    healthSessionId: 'hc-run',
  ),
  // Beides, zusammengeführt.
  StrengthSession(
    id: 'beides',
    userId: 'u',
    date: DateTime(2026, 9, 16, 18),
    createdAt: DateTime(2026, 9, 16, 18),
    duration: const Duration(minutes: 48),
    rpe: 3,
    bodyweight: false,
    planName: 'Pull B',
    healthSessionId: 'hc-pull',
  ),
];

class _Sessions extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(_sessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => _sessions;
}

Future<AppL10n> _pump(WidgetTester tester, {required double scale}) async {
  tester.view.physicalSize = const Size(361, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      for (var i = 0; i < fixtureOverrides.length; i++)
        // fixtureOverrides[6] ist die Sitzungsquelle — ersetzen, nicht doppeln.
        if (i == 6)
          sessionRepositoryProvider.overrideWithValue(_Sessions())
        else
          fixtureOverrides[i],
      healthSessionRepositoryProvider.overrideWithValue(_EmptyInbox()),
      currentUserIdProvider.overrideWithValue('u'),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const SessionListScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(SessionListScreen)));
}

Iterable<AtemOriginShape> _shapes(WidgetTester tester) => tester
    .widgetList<AtemOriginDot>(find.byType(AtemOriginDot))
    .map((d) => d.shape);

String _labelOf(WidgetTester tester, String name) => tester
    .widgetList<AtemTappable>(find.byType(AtemTappable))
    .firstWhere((t) => t.semanticLabel.contains(name))
    .semanticLabel;

void main() {
  testWidgets('jede Zeile trägt ihre Punktform — und kein Wort daneben',
      (tester) async {
    final l10n = await _pump(tester, scale: 1.0);

    expect(
      _shapes(tester),
      containsAll([
        AtemOriginShape.filled,
        AtemOriginShape.hollow,
        AtemOriginShape.ringWithCore,
      ]),
    );
    // Punkt **oder** Wort. Solange der Punkt trägt, steht kein Wort da.
    expect(find.textContaining(l10n.hcOriginWatch), findsNothing);
    expect(find.textContaining(l10n.hcOriginBoth), findsNothing);
  });

  testWidgets('ab 130 % tritt das Wort an die Stelle des Punktes',
      (tester) async {
    final l10n = await _pump(tester, scale: 1.3);

    expect(find.byType(AtemOriginDot), findsNothing,
        reason: 'ein 10-dp-Punkt wird neben dieser Schrift zum Staubkorn');
    expect(find.textContaining(l10n.hcOriginWatch), findsOneWidget);
    expect(find.textContaining(l10n.hcOriginBoth), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'die Herkunft steht im Zeilenlabel, nicht in einem eigenen Knoten',
      (tester) async {
    final l10n = await _pump(tester, scale: 1.0);

    expect(_labelOf(tester, 'Laufen'), contains(l10n.hcOriginWatch));
    // Gesprochen „App und Uhr": Das Pluszeichen aus der sichtbaren Fassung
    // liest nicht jede Stimme, und die Reihenfolge App zuerst ist fest.
    expect(_labelOf(tester, 'Pull B'), contains(l10n.hcOriginBothSpoken));
    expect(_labelOf(tester, 'Pull B'), isNot(contains(l10n.hcOriginBoth)));
  });

  testWidgets('„ohne Anstrengung" steht nur an Einheiten aus der Uhr',
      (tester) async {
    final l10n = await _pump(tester, scale: 1.0);

    // Die Uhr kann Anstrengung nicht messen — eine Tatsache.
    expect(_labelOf(tester, 'Laufen'), contains(l10n.hcOriginMissingEffort));
    // Bei „Pull A" hat man sie nur nicht eingetippt. Das in jeder Zeile zu
    // vermerken wäre eine Mahnung.
    expect(_labelOf(tester, 'Pull A'),
        isNot(contains(l10n.hcOriginMissingEffort)));
  });
}
