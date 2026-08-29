import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child,
    {double scale = 1.0, bool reduced = true}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AtemTheme.dark,
    home: Scaffold(body: child),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduced,
      ),
      child: w!,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('AtemEmptyState', () {
    testWidgets('meldet sich NICHT als Live-Region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemEmptyState(
          title: 'Noch kein Verlauf',
          body: 'Deine abgeschlossenen Sessions erscheinen hier.',
        ),
      );

      final node = tester.getSemantics(find.byType(AtemEmptyState));
      expect(node.label, contains('Noch kein Verlauf'));
      // Leere ist ein Ergebnis, kein Ereignis — sonst redet die App ungefragt.
      expect(node.flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('funktioniert ohne Handlung', (tester) async {
      await _pump(
        tester,
        const AtemEmptyState(title: 'Leer', body: 'Nichts da.'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('kürzt lange Texte auf zwei Zeilen', (tester) async {
      await _pump(
        tester,
        const AtemEmptyState(
          title: 'Leer',
          body: 'Ein sehr langer Text, der weit über zwei Zeilen hinausgeht '
              'und eigentlich erklären statt benennen will, was hier fehlt.',
        ),
      );
      expect(tester.takeException(), isNull);
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.any((t) => t.maxLines == 2), isTrue);
    });
  });

  group('AtemErrorState', () {
    testWidgets('meldet sich als Live-Region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemErrorState(
          title: 'Keine Verbindung',
          body: 'Wir versuchen es gleich noch einmal.',
        ),
      );

      final node = tester.getSemantics(find.byType(AtemErrorState));
      // Ein Fehlschlag ist ein Ereignis.
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('ohne onRetry gibt es keinen Knopf — endgültig',
        (tester) async {
      await _pump(
        tester,
        const AtemErrorState(title: 'Weg', body: 'Unwiederbringlich.'),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('Wiederholen-Knopf erreicht 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AtemErrorState(
          title: 'Fehlgeschlagen',
          body: 'Bitte erneut versuchen.',
          retryLabel: 'Erneut versuchen',
          onRetry: () {},
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('AtemSkeleton', () {
    testWidgets('terminiert bei reduzierter Bewegung', (tester) async {
      await _pump(
        tester,
        const AtemSkeleton(
          semanticLabel: 'Lädt',
          blocks: [
            AtemSkeletonBlock(height: 64),
            AtemSkeletonBlock(height: 200),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('erscheint erst nach 300 ms', (tester) async {
      // Firestore antwortet aus dem Zwischenspeicher in Millisekunden. Ein
      // Skelett, das sofort erscheint, blitzt dann für einen Frame auf und
      // verschwindet — das liest sich als Ruckeln, nicht als Laden.
      await _pump(
        tester,
        const AtemSkeleton(
          semanticLabel: 'Lädt',
          blocks: [AtemSkeletonBlock(height: 64)],
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.getSize(find.byType(AtemSkeleton)).height, 0,
          reason: 'vor der Schwelle keine Höhe — sonst springt das Layout');

      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getSize(find.byType(AtemSkeleton)).height,
          greaterThan(0));
    });

    testWidgets('ohne Verzögerung erscheint es sofort', (tester) async {
      await _pump(
        tester,
        const AtemSkeleton(
          semanticLabel: 'Lädt',
          delay: Duration.zero,
          blocks: [AtemSkeletonBlock(height: 64)],
        ),
      );
      expect(tester.getSize(find.byType(AtemSkeleton)).height,
          greaterThan(0));
    });

    testWidgets('meldet den Ladezustand, die Blöcke selbst nicht',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AtemSkeleton(
          semanticLabel: 'Dashboard wird geladen',
          // Ohne Verzögerung: Der Test prüft die Ansage, nicht die Schwelle.
          delay: Duration.zero,
          blocks: [AtemSkeletonBlock(height: 64)],
        ),
      );
      final node = tester.getSemantics(find.byType(AtemSkeleton));
      expect(node.label, 'Dashboard wird geladen');
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('AtemButtonSpinner', () {
    testWidgets('ist 16 dp und terminiert', (tester) async {
      await _pump(tester, const Center(child: AtemButtonSpinner()));
      expect(
          tester.getSize(find.byType(AtemButtonSpinner)), const Size(16, 16));
      expect(tester.takeException(), isNull);
    });
  });

  group('Bei 200 Prozent Schrift', () {
    testWidgets('laufen alle drei Zustände ohne Überlauf', (tester) async {
      for (final widget in <Widget>[
        const AtemEmptyState(title: 'Leer', body: 'Nichts da.'),
        const AtemErrorState(title: 'Fehler', body: 'Ging schief.'),
        const AtemSkeleton(
            semanticLabel: 'Lädt', blocks: [AtemSkeletonBlock(height: 64)]),
      ]) {
        await _pump(tester, widget, scale: 2.0);
        expect(tester.takeException(), isNull, reason: '${widget.runtimeType}');
      }
    });
  });
}
