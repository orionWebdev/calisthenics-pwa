import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/pulse/presentation/widgets/pulse_curve_chart.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Pulsverlauf als Baustein — Zeile darüber, Achse darunter, Schieber.
///
/// Geprüft wird, was man lesen kann. Die Farbgebung der Linie steckt im
/// Painter und ist ein Fall für die Sichtprüfung
/// (`test/render/pulse_render_test.dart`), nicht für eine Zusicherung über
/// Pixel.
void main() {
  final zones = HeartRateZones.tryFrom(const [120, 140, 160, 175])!;

  // 0..9 min, ansteigend von Zone 1 bis Zone 5 — mit einer echten Lücke bei
  // Minute 4, damit der Schieber sie überspringen muss.
  final curve = <int, int>{
    0: 100,
    1: 110,
    2: 130,
    3: 135,
    5: 152,
    6: 158,
    7: 168,
    8: 178,
    9: 180,
  };

  Future<AppL10n> pump(
    WidgetTester tester, {
    HeartRateZones? withZones,
    double textScale = 1.0,
    double width = 340,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: PulseCurveChart(
                  bpmByMinute: curve,
                  totalMinutes: 10,
                  zones: withZones,
                  semanticLabel: 'Pulsverlauf',
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppL10n.of(tester.element(find.byType(PulseCurveChart)));
  }

  /// Zieht auf [fraction] der Kurvenbreite und lässt den Finger dort liegen.
  Future<TestGesture> dragTo(WidgetTester tester, double fraction) async {
    final box = tester.getRect(find.byType(CustomPaint).last);
    final start = Offset(box.left + 2, box.center.dy);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(Offset(box.left + box.width * fraction, box.center.dy));
    await tester.pump();
    return gesture;
  }

  group('die Zeile über der Kurve', () {
    testWidgets('zeigt in Ruhe die Spanne', (tester) async {
      final l10n = await pump(tester, withZones: zones);
      expect(find.text(l10n.pulseCurveRange(100, 180)), findsOneWidget);
    });

    testWidgets('zeigt beim Ziehen Zeit, Wert und Zone', (tester) async {
      final l10n = await pump(tester, withZones: zones);
      final gesture = await dragTo(tester, 0.98);

      // Am rechten Rand: Minute 9, 180 bpm, Zone 5 (ab 175).
      expect(
        find.text(l10n.pulseCurveReadout(
            l10n.durationMinutes(9), '180 ${l10n.detailUnitBpm}',
            l10n.detailZoneName(5))),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      // Losgelassen steht wieder die Spanne da.
      expect(find.text(l10n.pulseCurveRange(100, 180)), findsOneWidget);
    });

    testWidgets('ohne festgelegte Zonen nennt sie keine Zone', (tester) async {
      final l10n = await pump(tester);
      final gesture = await dragTo(tester, 0.98);
      expect(
        find.text(l10n.pulseCurveReadoutPlain(
            l10n.durationMinutes(9), '180 ${l10n.detailUnitBpm}')),
        findsOneWidget,
      );
      await gesture.up();
    });

    testWidgets('springt über eine Lücke auf eine gemessene Minute',
        (tester) async {
      final l10n = await pump(tester, withZones: zones);
      // 0,44 der Breite ist Minute 4 — dort wurde nichts gemessen.
      final gesture = await dragTo(tester, 4 / 9);

      // Kein Wert für Minute 4; die Marke sitzt auf 3 oder 5, nie dazwischen.
      expect(find.textContaining(l10n.durationMinutes(4)), findsNothing);
      final onThree = find.textContaining(l10n.durationMinutes(3));
      final onFive = find.textContaining(l10n.durationMinutes(5));
      expect(
        tester.widgetList(onThree).isNotEmpty ||
            tester.widgetList(onFive).isNotEmpty,
        isTrue,
      );
      await gesture.up();
    });

    testWidgets('die Höhe springt beim Ziehen nicht', (tester) async {
      // Bei 200 % auf schmaler Breite bricht die abgelesene Zeile um. Beide
      // Zustände liegen im selben Stack, deshalb steht die Höhe vorher fest.
      await pump(tester, withZones: zones, textScale: 2.0, width: 300);
      final before = tester.getSize(find.byType(PulseCurveChart)).height;

      final gesture = await dragTo(tester, 0.98);
      expect(tester.getSize(find.byType(PulseCurveChart)).height, before);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PulseCurveChart)).height, before);
    });
  });

  group('die Zeitachse', () {
    testWidgets('nennt Anfang und Ende', (tester) async {
      final l10n = await pump(tester, withZones: zones);
      expect(find.text(l10n.pulseCurveStart), findsOneWidget);
      expect(find.text(l10n.durationMinutes(10)), findsOneWidget);
    });

    testWidgets('bei 200 % auf 320 dp bleibt das Ende', (tester) async {
      final l10n = await pump(tester, withZones: zones, textScale: 2.0, width: 150);
      expect(find.text(l10n.durationMinutes(10)), findsOneWidget);
      expect(find.text(l10n.pulseCurveStart), findsNothing);
    });
  });

  testWidgets('unter zwei Messpunkten zeichnet der Baustein nichts',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const Scaffold(
        body: PulseCurveChart(
          bpmByMinute: {0: 120},
          totalMinutes: 10,
          semanticLabel: 'Pulsverlauf',
        ),
      ),
    ));
    expect(find.byType(CustomPaint).evaluate().isEmpty, isFalse); // Scaffold
    expect(find.byType(GestureDetector), findsNothing);
  });
}
