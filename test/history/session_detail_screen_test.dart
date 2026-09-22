import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/detail/detail_blocks.dart';
import 'package:atem/features/history/presentation/screens/session_detail_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/detail_fixtures.dart';

/// Das Einheitendetail (Board 16) — was jede Aussage des Boards im Bildschirm
/// bedeutet.
Future<AppL10n> _pump(
  WidgetTester tester,
  TrainingSession session, {
  bool zones = true,
  DetailHealth? health,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = const Size(361, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: detailOverrides(
      session: session,
      settings: detailSettings(withZones: zones),
      health: health ??
          DetailHealth(
              session.healthSessionId == null ? const [] : [detailRecord()]),
    ).cast(),
    child: MaterialApp(
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
      home: SessionDetailScreen(session: session),
    ),
  ));
  await tester.pumpAndSettle();
  return AppL10n.of(tester.element(find.byType(SessionDetailScreen)));
}

void main() {
  group('der Kopf', () {
    testWidgets('eine grosse Zahl, und die ist die Leitzahl', (tester) async {
      final l10n = await _pump(tester, detailMerged);

      expect(find.text('Kraft · Push A'), findsOneWidget);
      // Die Leitzahl: zehn Sätze, nicht die Dauer und nicht das Volumen.
      expect(find.text('10'), findsWidgets);
      expect(find.text(l10n.detailLeadSets.toUpperCase()), findsWidgets);
      // Die Grundlage nennt, woraus sie besteht.
      expect(
        find.text(l10n.detailBasisStrength(3, 52, 4)),
        findsOneWidget,
      );
    });

    testWidgets('der Kopf wird als ein Knoten vorgelesen', (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _pump(tester, detailMerged);

      final header = find.bySemanticsLabel(RegExp(r'^Kraft · Push A\. '));
      expect(header, findsOneWidget);
      final label = tester.getSemantics(header).label;
      expect(label, contains('10 ${l10n.detailLeadSets}'));
      expect(label, contains(l10n.detailBasisStrength(3, 52, 4)));
      handle.dispose();
    });

    testWidgets('ohne alles: keine Zahl, kein Strich, kein Aufruf',
        (tester) async {
      final l10n = await _pump(tester, detailBare);

      expect(find.text('Kraft'), findsOneWidget);
      expect(find.text(l10n.detailBasisEmpty), findsOneWidget);
      // Kein „0", kein „—" als Wert.
      expect(find.text('0'), findsNothing);
      expect(find.text('—'), findsNothing);
      // Das Board verwirft die Platzhalterkarte ausdrücklich (Entscheidung
      // 20): Bestand ist kein Mangel. Seit dem Umbau auf Board 16 gibt es
      // weder „Sätze fehlen" noch „Beitrag zur Form" überhaupt noch als
      // Baustein — die Abwesenheit steht nicht mehr hier, sondern darin,
      // dass der Bildschirm nach dem Kopf aufhört.
      expect(find.byType(DetailBlock), findsNothing);
      // Es gibt keine Tageszeit, also steht keine erfunden da.
      expect(find.textContaining('00:00'), findsNothing);
    });

    testWidgets('Regeneration hört nach dem Kopf auf', (tester) async {
      final l10n = await _pump(tester, detailRecovery);

      expect(find.text('30'), findsWidgets,
          reason: 'die Dauer ist die Leitzahl');
      // Keine Kennzahlkachel — die Dauer wäre dieselbe Zahl zweimal.
      expect(find.text(l10n.detailMetricDuration.toUpperCase()), findsNothing);
      // Keine Arbeit, kein Puls, keine Notiz.
      expect(find.text(l10n.detailBlockHrZones.toUpperCase()), findsNothing);
      expect(find.text(l10n.detailBlockNote.toUpperCase()), findsNothing);
      // Herkunft und Eingriffe stehen immer da.
      expect(find.text(l10n.detailOriginApp), findsOneWidget);
      expect(find.text(l10n.detailEdit), findsOneWidget);
      expect(find.text(l10n.detailDelete), findsOneWidget);
    });
  });

  group('Kacheln', () {
    testWidgets('Puls und Kalorien tragen die Uhr, Dauer und Volumen die App',
        (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _pump(tester, detailMerged);

      // Die Herkunft im Label, nicht als eigener Knoten.
      expect(
        find.bySemanticsLabel(
            RegExp('^${l10n.detailSpokenHrAvg} .*${l10n.hcOriginWatch}\$')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp(
            '^${l10n.detailMetricDuration} 52 min, ${l10n.detailSourceApp}')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('Arbeit', () {
    testWidgets('Übungen mit Vergleich gegen dieselbe Übung', (tester) async {
      final l10n = await _pump(tester, detailMerged);

      expect(find.text('Bankdrücken'), findsOneWidget);
      // ▲ 2,5 kg gegen 11. Sept. — eine Tatsache mit Datum.
      expect(find.textContaining('2,5 KG GEGEN 11. SEPT'), findsOneWidget);
      // Schulterdrücken: gleiches Gewicht, zwei Wiederholungen weniger.
      expect(find.textContaining('2 WDH GEGEN 11. SEPT'), findsOneWidget);
      // Dips: keine frühere Ausführung — kein erfundener Bezug.
      expect(
          find.text(l10n.detailWorkNoComparison.toUpperCase()), findsOneWidget);
    });

    testWidgets('eine Zeile öffnet ihre Sätze — eine zugleich', (tester) async {
      final l10n = await _pump(tester, detailMerged);

      expect(find.text(l10n.detailSetRow(1, '8 × 80 kg')), findsNothing);
      await tester.tap(find.text('Bankdrücken'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailSetRow(1, '8 × 80 kg')), findsOneWidget);

      await tester.tap(find.text('Schulterdrücken'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailSetRow(1, '8 × 80 kg')), findsNothing,
          reason: 'es steht nur eine Zeile offen');
    });

    testWidgets('das Delta wird nie als Glyph vorgelesen', (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _pump(tester, detailMerged);

      final label = tester
          .getSemantics(find.bySemanticsLabel(RegExp(r'^Bankdrücken, ')))
          .label;
      // Das Wort steht im Label, nie ▲.
      expect(
          label,
          contains(l10n.detailDeltaSpokenMore(
              l10n.detailSpokenKg('2,5'), '11. Sept.')));
      expect(label, isNot(contains('▲')));
      expect(label, isNot(contains('▼')));
      handle.dispose();
    });
  });

  group('Puls & Zonen', () {
    testWidgets('Default: Werte, Grundlage vor den Balken, fünf Zonen',
        (tester) async {
      final l10n = await _pump(tester, detailMerged);

      expect(find.text(l10n.detailBlockHrZones.toUpperCase()), findsOneWidget);
      for (var z = 1; z <= 5; z++) {
        expect(find.textContaining(l10n.detailZoneShort(z)), findsWidgets);
      }
      expect(find.textContaining('deine Zonen vom 12. Sept.'), findsOneWidget);
      // Ohne Zeitachse (Einheiten vor dem 22.09.2026) bleibt der
      // Pulsverlauf weg — kein leerer Titel ohne Kurve.
      expect(find.text(l10n.detailPulseCurveTitle.toUpperCase()), findsNothing);
    });

    testWidgets('Pulsverlauf: eigene Zeile, ein Semantics-Knoten mit Lücke',
        (tester) async {
      final handle = tester.ensureSemantics();
      final l10n = await _pump(
        tester,
        detailMerged,
        health: DetailHealth([detailRecord(pulse: detailPulseWithCurve())]),
      );

      expect(
          find.text(l10n.detailPulseCurveTitle.toUpperCase()), findsOneWidget);
      // 52 Minuten, 100 bis 175 bpm, minutengenau. Seit dem Nachtrag zu
      // Board 16 ist die Kurve ein **Slider**: Das Label nennt Dauer, Spanne
      // und Auflösung, den einzelnen Wert trägt `value`.
      expect(
        find.bySemanticsLabel(l10n.pulseCurveA11ySlider(
            52, 100, 175, l10n.pulseCurveResolutionMinute)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('zu wenig Daten: der Satz steht vor den Balken',
        (tester) async {
      final l10n = await _pump(
        tester,
        detailMerged,
        health: DetailHealth(
            [detailRecord(pulse: detailPulse(recordedMinutes: 21))]),
      );

      final thin = find.text(l10n.detailZonesThin(21, 52));
      expect(thin, findsOneWidget);
      // Vor dem ersten Balken, nicht dahinter.
      final firstZone = find.textContaining('${l10n.detailZoneShort(1)} ·');
      expect(tester.getTopLeft(thin).dy,
          lessThan(tester.getTopLeft(firstZone.first).dy));
      // Zone 1 und Zone 5 bleiben leer, sind aber nicht benachbart — sie
      // fassen sich nicht zusammen. Zone 5 bekommt immer ihre eigene Zeile.
      expect(find.text('0:00'), findsNWidgets(2),
          reason: 'nicht benachbarte leere Zonen bleiben getrennt, '
              'Zone 5 fasst nie zusammen');
    });

    testWidgets('Zonen fehlen: nur „Puls", ein Weg — kein Aufruf',
        (tester) async {
      final l10n = await _pump(tester, detailMerged, zones: false);

      expect(find.text(l10n.detailBlockHr.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.detailBlockHrZones.toUpperCase()), findsNothing,
          reason: 'kein Titel verspricht etwas, das nicht kommt');
      expect(find.text(l10n.detailZonesUnset), findsOneWidget);
      expect(find.text(l10n.detailZonesSetAction), findsOneWidget);
      // Ohne Grenzen keine Verteilung.
      expect(find.textContaining('${l10n.detailZoneShort(1)} ·'), findsNothing);
    });

    testWidgets('lädt: Skelett ohne Zahlen', (tester) async {
      final l10n = await _pump(tester, detailMerged,
          health: DetailHealth(const [], hangs: true));

      expect(find.text(l10n.detailBlockHrZones.toUpperCase()), findsOneWidget);
      // Keine Werte — ein Skelett behauptet keine.
      expect(find.text('136'), findsNothing);
      expect(find.text('175'), findsNothing);
    });

    testWidgets('nicht lesbar: ein Fehler, der bleibt', (tester) async {
      final l10n = await _pump(tester, detailMerged,
          health: DetailHealth(const [], fails: true));

      expect(find.textContaining(l10n.detailErrorHr), findsOneWidget);
      expect(find.text(l10n.detailRetry.toUpperCase()), findsOneWidget);
      // Der Rest des Bildschirms bleibt bedienbar.
      expect(find.text('Bankdrücken'), findsOneWidget);
    });

    testWidgets('kein Puls vorhanden: der Block rendert nicht', (tester) async {
      // Der Datensatz existiert, trägt aber keinen Verlauf. Das ist kein
      // Fehler — kein Titel, keine leere Karte, kein „—".
      final l10n = await _pump(
        tester,
        detailMerged,
        health: DetailHealth([detailRecord().copyWith()]).withoutPulse(),
      );

      expect(find.text(l10n.detailBlockHrZones.toUpperCase()), findsNothing);
      expect(find.text(l10n.detailBlockHr.toUpperCase()), findsNothing);
      expect(find.textContaining(l10n.detailErrorHr), findsNothing);
    });
  });

  group('Herkunft', () {
    testWidgets('zusammengeführt: beide Quellen, und der Weg zurück',
        (tester) async {
      final l10n = await _pump(tester, detailMerged);

      expect(find.text(l10n.detailOriginBoth), findsOneWidget);
      await tester.tap(find.text(l10n.detailOriginBoth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.hcSourceApp), findsOneWidget);
      expect(find.text(l10n.hcUnlink), findsOneWidget);
    });

    testWidgets('selbst geführt: die Herkunft steht trotzdem da',
        (tester) async {
      final l10n = await _pump(tester, detailBare);

      expect(find.text(l10n.detailOriginApp), findsOneWidget);
      expect(
          find.text(l10n.detailOriginMetaEmpty.toUpperCase()), findsOneWidget);
    });

    testWidgets('die Kapsel erklärt, wie die Last gerechnet wird',
        (tester) async {
      // Board 16, Nachtrag, M: Die Erklärung klappt **in** der Kapsel auf,
      // sie öffnet kein Blatt.
      final l10n = await _pump(tester, detailMerged);
      expect(find.text(l10n.detailLoadExplainTitle), findsNothing);

      await tester.tap(find.text(l10n.detailOriginBoth));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailLoadExplainTitle), findsOneWidget);

      // Die Formel steht erst hinter dem ⓘ, nicht schon daneben.
      expect(find.text(l10n.detailLoadExplainFormulaStrength), findsNothing);
      await tester.tap(find.bySemanticsLabel(
          l10n.explainOpenA11y(l10n.detailLoadExplainTitle)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailLoadExplainFormulaStrength), findsOneWidget);
    });

    testWidgets('Regeneration trägt keine Last und deshalb keine Erklärung',
        (tester) async {
      final l10n = await _pump(tester, detailRecovery);
      await tester.tap(find.text(l10n.detailOriginApp));
      await tester.pumpAndSettle();
      expect(find.text(l10n.detailLoadExplainTitle), findsNothing);
    });
  });

  group('Barrierefreiheit', () {
    for (final entry in {
      'Kraft zusammengeführt': (detailMerged, true),
      'Kraft ohne Zonen': (detailMerged, false),
      'Laufen aus der Uhr': (detailRun, true),
      'Regeneration': (detailRecovery, true),
      'Kopf ohne Zahl': (detailBare, true),
    }.entries) {
      testWidgets(entry.key, (tester) async {
        final (session, zones) = entry.value;
        await expectA11y(
          tester,
          SessionDetailScreen(session: session),
          baseOverrides: detailOverrides(
            session: session,
            settings: detailSettings(withZones: zones),
            health: DetailHealth(session.id == 'run'
                ? [detailRunRecord()]
                : session.healthSessionId == null
                    ? const []
                    : [detailRecord()]),
          ),
        );
      });
    }
  });
}
