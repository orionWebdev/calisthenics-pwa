import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/history/domain/strength_progress.dart';
import 'package:atem/features/history/presentation/widgets/estimated_max_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Das geschätzte Maximum in der Kraft-Auswertung (seit 16.09.2026):
/// Übungskapseln, ein Semantics-Knoten je Kurve, Richtung im Wort statt im
/// Glyph, der dünne Zustand mit Kandidaten — und nichts ohne Kandidaten.
ExerciseStrengthSeries _series(String id, List<double> maxes,
    {DateTime? start}) {
  final first = start ?? DateTime(2026, 6, 1);
  return ExerciseStrengthSeries(
    exerciseId: id,
    points: [
      for (final (i, m) in maxes.indexed)
        StrengthPoint(
          date: first.add(Duration(days: 4 * i)),
          estimatedMax: m,
          weight: m / 1.2,
          reps: 6,
        ),
    ],
  );
}

String _name(String id) => switch (id) {
      'bench' => 'Bankdrücken',
      'squat' => 'Kniebeuge',
      'row' => 'Rudern',
      _ => id,
    };

Future<void> _pump(
  WidgetTester tester, {
  required List<ExerciseStrengthSeries> series,
  required List<ExerciseStrengthSeries> candidates,
  double scale = 1.0,
  double width = 361,
  bool alwaysShow = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
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
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EstimatedMaxCard(
            series: series,
            candidates: candidates,
            nameOf: _name,
            alwaysShow: alwaysShow,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final bench = _series('bench', [80, 82.5, 84, 84, 86]);
  final squat = _series('squat', [100, 102, 104, 106, 108, 110, 112]);
  final row = _series('row', [60, 58, 57, 56, 55]);

  group('mit genug Einheiten', () {
    testWidgets('eine Kapsel je Übung, die mit den meisten Einheiten zuerst',
        (tester) async {
      await _pump(tester, series: [squat, bench], candidates: [squat, bench]);
      expect(find.text('Kniebeuge'), findsOneWidget);
      expect(find.text('Bankdrücken'), findsOneWidget);
      // Standard ist die erste Reihe: die Kurve nennt die Kniebeuge.
      expect(
        find.bySemanticsLabel(RegExp(r'^Kniebeuge: geschätztes Maximum')),
        findsOneWidget,
      );
      expect(find.text('7 Einheiten · zuletzt 112 kg · Bestwert 112 kg'),
          findsOneWidget);
    });

    testWidgets('eine Kapsel antippen wechselt die Kurve', (tester) async {
      await _pump(tester, series: [squat, bench], candidates: [squat, bench]);
      await tester.tap(find.text('Bankdrücken'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
            RegExp(r'^Bankdrücken: geschätztes Maximum von 80 auf 86')),
        findsOneWidget,
      );
      expect(find.text('5 Einheiten · zuletzt 86 kg · Bestwert 86 kg'),
          findsOneWidget);
    });

    testWidgets('die Kurve ist ein Knoten mit Anfang, Ende und Anzahl',
        (tester) async {
      await _pump(tester, series: [bench], candidates: [bench]);
      expect(
        find.bySemanticsLabel(
            'Bankdrücken: geschätztes Maximum von 80 auf 86 Kilogramm über 5 Einheiten'),
        findsOneWidget,
      );
    });

    testWidgets('das Delta trägt die Richtung als Wort, den Glyph nur sichtbar',
        (tester) async {
      await _pump(tester, series: [bench], candidates: [bench]);
      expect(find.text('▲ 6 kg seit der ersten Einheit'), findsOneWidget);
      expect(find.bySemanticsLabel('mehr 6 Kilogramm seit der ersten Einheit'),
          findsOneWidget);
      // Der Glyph steht in keinem Label.
      expect(find.bySemanticsLabel(RegExp('▲')), findsNothing);
    });

    testWidgets('ein fallendes Delta heisst weniger', (tester) async {
      await _pump(tester, series: [row], candidates: [row]);
      expect(find.text('▼ 5 kg seit der ersten Einheit'), findsOneWidget);
      expect(
          find.bySemanticsLabel('weniger 5 Kilogramm seit der ersten Einheit'),
          findsOneWidget);
    });

    testWidgets('die Formel steht sichtbar unter der Kurve', (tester) async {
      await _pump(tester, series: [bench], candidates: [bench]);
      expect(
        find.textContaining('Epley: Gewicht × (1 + Wdh ÷ 30)'),
        findsOneWidget,
      );
    });

    testWidgets('200 % auf 320 dp läuft nicht über', (tester) async {
      await _pump(tester,
          series: [squat, bench, row],
          candidates: [squat, bench, row],
          scale: 2.0,
          width: 320);
      expect(tester.takeException(), isNull);
    });
  });

  group('dünn', () {
    testWidgets('ohne Übung mit fünf Einheiten stehen die Kandidaten',
        (tester) async {
      final two = _series('bench', [80, 82]);
      final four = _series('squat', [100, 101, 102, 103]);
      await _pump(tester, series: const [], candidates: [two, four]);
      expect(find.text('Noch keine Übung mit genug Einheiten'), findsOneWidget);
      expect(find.text('Kniebeuge: 4 von 5 Einheiten'), findsOneWidget);
      expect(find.text('Bankdrücken: 2 von 5 Einheiten'), findsOneWidget);
      // Die Schwelle steht mit beiden Zahlen im Satz.
      expect(find.textContaining('Ab 5 Einheiten je Übung'), findsOneWidget);
      expect(
          find.textContaining('höchstens 12 Wiederholungen'), findsOneWidget);
    });

    testWidgets('höchstens drei Kandidaten, die nächsten zuerst',
        (tester) async {
      final candidates = [
        _series('a', [1]),
        _series('b', [1, 2, 3, 4]),
        _series('c', [1, 2]),
        _series('d', [1, 2, 3]),
      ];
      await _pump(tester, series: const [], candidates: candidates);
      expect(find.text('b: 4 von 5 Einheiten'), findsOneWidget);
      expect(find.text('d: 3 von 5 Einheiten'), findsOneWidget);
      expect(find.text('c: 2 von 5 Einheiten'), findsOneWidget);
      expect(find.text('a: 1 von 5 Einheiten'), findsNothing);
    });

    testWidgets('ohne einen einzigen Kandidaten rendert die Karte nicht',
        (tester) async {
      await _pump(tester, series: const [], candidates: const []);
      expect(find.byType(EstimatedMaxCard), findsOneWidget);
      expect(find.text('Geschätztes Maximum'), findsNothing);
      expect(find.text('Noch keine Übung mit genug Einheiten'), findsNothing);
    });
  });

  group('immer zeigen (Auswertung)', () {
    testWidgets('ohne Kandidaten der Schwellenblock mit 0 von 5',
        (tester) async {
      await _pump(tester,
          series: const [], candidates: const [], alwaysShow: true);
      expect(find.text('Geschätztes Maximum'), findsOneWidget);
      expect(find.text('0 von 5'), findsOneWidget);
      expect(
          find.text('Erscheint ab 5 Einheiten einer Übung mit Gewicht und '
              'höchstens 12 Wiederholungen'),
          findsOneWidget);
      expect(find.textContaining('Übungen mit Körpergewicht'), findsOneWidget);
      // Ein Knoten, der die Bedingung und den Stand nennt.
      expect(
          find.bySemanticsLabel(RegExp(r'Bisher 0 von 5\.$')), findsOneWidget);
    });

    testWidgets('mit Kandidaten bleibt der dünne Zustand, mit Titel',
        (tester) async {
      final two = _series('bench', [80, 82]);
      await _pump(tester,
          series: const [], candidates: [two], alwaysShow: true);
      expect(find.text('Geschätztes Maximum'), findsOneWidget);
      expect(find.text('Bankdrücken: 2 von 5 Einheiten'), findsOneWidget);
      expect(find.text('0 von 5'), findsNothing);
    });

    testWidgets('mit Kurve ändert alwaysShow nichts', (tester) async {
      final bench = _series('bench', [80, 82.5, 84, 84, 86]);
      await _pump(tester,
          series: [bench], candidates: [bench], alwaysShow: true);
      expect(find.textContaining('Epley: Gewicht'), findsOneWidget);
      expect(find.text('0 von 5'), findsNothing);
    });

    testWidgets('Schwellenblock bei 200 % auf 320 dp ohne Überlauf',
        (tester) async {
      await _pump(tester,
          series: const [],
          candidates: const [],
          alwaysShow: true,
          scale: 2.0,
          width: 320);
      expect(tester.takeException(), isNull);
    });
  });
}
