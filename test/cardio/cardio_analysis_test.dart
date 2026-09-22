import 'package:atem/app/application/tab_providers.dart';
import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/cardio/presentation/screens/cardio_screen.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/pulse/presentation/widgets/zone_five_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// „Zone 5 je Woche" in der Cardio-Auswertung.
///
/// Der Block stand bis `b5a6665` in der Kraft-Auswertung und wurde dort mit
/// der Begründung entfernt, er gehöre in den Cardio-Teil — eingesetzt wurde er
/// dabei nicht. Diese Prüfung hält fest, dass er jetzt dort steht und dass er
/// **immer** rendert: Auf Auswertungsbildschirmen zeigt ein Block unter seiner
/// Schwelle Umriss und Bedingung, statt zu verschwinden.
///
/// Die Fixtures kennen nur Krafteinheiten; ohne eine Cardio-Einheit zeigt der
/// Tab seinen Leerzustand und hat gar keine Auswertung. Darum ein eigener
/// Bestand mit beidem — er ist zugleich der Fall, für den der Nenner der Karte
/// gedacht ist: Puls gibt es nur für Uhr-Einheiten, gezählt wird gegen **alle**.
class _MixedSessionRepository extends FakeSessionRepository {
  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(_sessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => _sessions;
}

final _sessions = <TrainingSession>[
  ...fixtureSessions,
  for (var i = 0; i < 6; i++)
    CardioSession(
      id: 'c$i',
      userId: 'u',
      date: DateTime(2026, 8, 10 + i * 2),
      createdAt: DateTime(2026, 8, 10 + i * 2),
      activity: CardioActivity.run,
      duration: const Duration(minutes: 40),
      distanceKm: 7.5,
      rpe: 3,
    ),
];

void main() {
  Future<AppL10n> pump(
    WidgetTester tester, {
    Size size = const Size(361, 900),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      // Ein Provider darf nicht zweimal überschrieben werden — der Eintrag
      // wird ersetzt, nicht ergänzt (Stelle 6 in `fixtureOverrides`, wie in
      // `detailOverrides`).
      overrides: [
        for (var i = 0; i < fixtureOverrides.length; i++)
          if (i != 6) fixtureOverrides[i],
        sessionRepositoryProvider.overrideWithValue(_MixedSessionRepository()),
      ],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const CardioScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(CardioScreen));
    ProviderScope.containerOf(element)
        .read(appTabsProvider.notifier)
        .setCardioSegment(CardioSegment.analysis);
    await tester.pumpAndSettle();
    return AppL10n.of(element);
  }

  testWidgets('die Auswertung trägt den Zone-5-Block', (tester) async {
    await pump(tester);
    expect(find.byType(ZoneFiveCard), findsOneWidget);
  });

  testWidgets('ohne Puls steht er als Schwellenblock, nicht als Lücke',
      (tester) async {
    final l10n = await pump(tester);

    // Keine Uhr-Einheit im Bestand — also fehlt eine von zwei Bedingungen,
    // und der Block nennt sie, statt zu verschwinden.
    expect(
      find.descendant(
        of: find.byType(ZoneFiveCard),
        matching: find.byType(AtemThresholdBlock),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ZoneFiveCard),
        matching: find.text(l10n.zoneFiveTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('bei 200 % auf 320 dp wird keine Grundlage abgeschnitten',
      (tester) async {
    final l10n = await pump(tester,
        size: const Size(320, 2400), textScale: 2.0);

    /// Ob dieser Text an seiner Zeilengrenze gekürzt wurde. `find.text` allein
    /// beweist nichts: Das Widget trägt die volle Zeichenkette auch dann, wenn
    /// auf dem Schirm „6 von 6 Einheiten m…" steht.
    bool truncated(Finder finder) =>
        tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

    final basis = l10n.analysisDistBasis(6, 6);
    expect(find.text(l10n.analysisDistTitle), findsOneWidget);
    expect(find.text(basis), findsOneWidget);
    expect(truncated(find.text(l10n.analysisDistTitle)), isFalse,
        reason: 'Ein abgeschnittener Titel ist ein verlorener Titel');
    expect(truncated(find.text(basis)), isFalse,
        reason: 'Eine Zahl ohne ihre Grundlage ist keine Zahl');
  });
}
