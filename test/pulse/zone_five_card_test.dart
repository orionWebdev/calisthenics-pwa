import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/pulse/presentation/widgets/zone_five_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/detail_fixtures.dart';

/// Zone 5 je Woche in der Auswertung — jeder Zustand.
Future<AppL10n> _pump(
  WidgetTester tester, {
  required DetailHealth health,
  bool zones = true,
}) async {
  tester.view.physicalSize = const Size(361, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: detailOverrides(
      session: detailMerged,
      settings: detailSettings(withZones: zones),
      health: health,
    ).cast(),
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ZoneFiveCard(
            sessions: [detailBefore, detailMerged],
            reference: DateTime(2026, 9, 20),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(ZoneFiveCard)));
}

void main() {
  testWidgets('mit Puls und Zonen: die Zahl der Woche und ihre Grundlage',
      (tester) async {
    final l10n = await _pump(tester, health: DetailHealth([detailRecord()]));

    expect(find.text(l10n.zoneFiveTitle), findsOneWidget);
    // Die Fixture legt 3:20 in Zone 5 — drei Minuten, gerundet.
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l10n.zoneFiveHead(38, 1)), findsOneWidget);
    // Jede Zahl nennt ihre Grundlage: 1 Einheit mit Puls von 2 im Streifen.
    expect(find.text(l10n.zoneFiveBasis(1, 2)), findsOneWidget);
    // Kein Vergleich, kein Pfeil, kein Sollwert.
    expect(find.textContaining('▲'), findsNothing);
    expect(find.textContaining('▼'), findsNothing);
  });

  testWidgets('die Zahl trägt die Farbe von Zone 5', (tester) async {
    await _pump(tester, health: DetailHealth([detailRecord()]));

    final number = tester.widget<Text>(find.text('3'));
    expect(number.style?.color, AtemColors.zone5);
  });

  testWidgets('ohne Zonen: die Schwelle nennt beide Bedingungen',
      (tester) async {
    final l10n = await _pump(
      tester,
      health: DetailHealth([detailRecord()]),
      zones: false,
    );

    expect(find.byType(AtemThresholdBlock), findsOneWidget);
    expect(find.text(l10n.zoneFiveConditionZones), findsOneWidget);
    // Kein Wert und kein Null-Chart unter der Schwelle.
    expect(find.text('3'), findsNothing);
  });

  testWidgets('mit Zonen, aber ohne Puls: die Schwelle wartet auf die Uhr',
      (tester) async {
    final l10n = await _pump(tester, health: DetailHealth(const []));

    expect(find.byType(AtemThresholdBlock), findsOneWidget);
    expect(find.text(l10n.zoneFiveConditionPulse), findsOneWidget);
  });

  testWidgets('eine wartende Einheit zählt nicht', (tester) async {
    // „Sichtbar, aber ohne Wirkung auf eine einzige Zahl": Was im Eingang
    // wartet, ist nicht geprüft und darf keine Auswertung färben.
    final l10n = await _pump(
      tester,
      health: DetailHealth([
        detailRecord().copyWith(state: HealthSessionState.pending),
      ]),
    );

    expect(find.byType(AtemThresholdBlock), findsOneWidget);
    expect(find.text(l10n.zoneFiveConditionPulse), findsOneWidget);
  });

  group('Barrierefreiheit', () {
    testWidgets('mit Daten', (tester) async {
      await expectA11y(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ZoneFiveCard(
              sessions: [detailBefore, detailMerged],
              reference: DateTime(2026, 9, 20),
            ),
          ),
        ),
        baseOverrides: detailOverrides(
          session: detailMerged,
          settings: detailSettings(),
          health: DetailHealth([detailRecord()]),
        ),
      );
    });

    testWidgets('unter der Schwelle', (tester) async {
      await expectA11y(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ZoneFiveCard(
              sessions: [detailBefore, detailMerged],
              reference: DateTime(2026, 9, 20),
            ),
          ),
        ),
        baseOverrides: detailOverrides(
          session: detailMerged,
          settings: detailSettings(withZones: false),
          health: DetailHealth(const []),
        ),
      );
    });
  });
}
