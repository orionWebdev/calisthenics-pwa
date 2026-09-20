import 'dart:async';

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/presentation/widgets/weight_card.dart';
import 'package:atem/features/weight/presentation/widgets/weight_chart.dart';
import 'package:atem/features/settings/domain/settings_repository.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';

/// Der Gewichtsblock — Board 14, Abschnitt A.
///
/// Geprüft wird, was der Leitsatz verlangt: jede Zahl mit Nenner, die
/// Veränderung ohne Ampelfarbe, die Lücke als Lücke, und ein Block, der auch
/// bei einem einzigen Wert nicht verschwindet.

WeightEntry _e(int month, int day, double kg,
        [WeightSource source = WeightSource.manual]) =>
    WeightEntry(date: DateTime(2026, month, day), kg: kg, source: source);

/// Einstellungen, die nie eintreffen — das Profil lädt noch.
class _PendingSettings implements SettingsRepository {
  @override
  Stream<UserSettings> watch(String userId) => const Stream.empty();

  @override
  Future<UserSettings> fetch(String userId) => Completer<UserSettings>().future;

  @override
  Future<void> save(String userId, UserSettings settings) async {}
}

Future<void> _pump(
  WidgetTester tester,
  List<WeightEntry> entries, {
  double? profileKg = 78,
  double scale = 1.0,
  double width = 361,
  bool denied = false,
  SettingsRepository? settings,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    // Nur was der Block liest — `fixtureOverrides` belegt dieselben Provider
    // schon, und Riverpod 3 lässt eine zweite Belegung im selben Behälter
    // nicht zu.
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      weightRepositoryProvider.overrideWithValue(
          FakeWeightRepository(entries: entries, denied: denied)),
      settingsRepositoryProvider.overrideWithValue(settings ??
          FakeSettingsRepository(
            settings: UserSettings(bodyWeightKg: profileKg),
          )),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        backgroundColor: AtemColors.base,
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: const SingleChildScrollView(
                padding: EdgeInsets.all(16), child: WeightCard()),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Normalfall: Wert, Nenner, Veränderung, Kurve, zwei Anker',
      (tester) async {
    await _pump(tester, [
      _e(7, 1, 80.9),
      _e(7, 12, 80.4),
      _e(7, 22, 80.1),
      _e(8, 3, 79.6),
      _e(8, 14, 79.2),
      _e(8, 25, 78.9),
    ]);

    // Die Hauptzahl mit Einheit.
    expect(find.text('78,9'), findsOneWidget);

    // **Jede Zahl nennt ihre Grundlage** — nie ein Wert ohne Nenner.
    expect(find.text('6 EINTRÄGE'), findsOneWidget);

    // Die Veränderung ist ein Satz mit Datum und Abstand, kein nacktes Delta.
    expect(find.textContaining('0,3 kg seit dem'), findsOneWidget);

    // Kurve und beide Datumsanker — Datum und Wert, nicht nur das Datum.
    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.text('1. Juli · 80,9 kg'), findsOneWidget);
    expect(find.text('25. Aug. · 78,9 kg'), findsOneWidget);
  });

  testWidgets('die Veränderung trägt keine Ampelfarbe', (tester) async {
    await _pump(tester, [_e(8, 1, 78), _e(8, 20, 79.4)]);

    final text = tester.widget<Text>(
      find.textContaining('kg seit dem'),
    );
    // Zunahme in derselben Textfarbe wie eine Abnahme: #CDD3EA, nicht grün
    // oder rot (Board 14, Entscheidung 4).
    expect(text.style?.color, AtemColors.textTertiary);
  });

  testWidgets('ein einziger Wert: kein Verlauf, keine Kurve, aber ein Weg',
      (tester) async {
    await _pump(tester, [_e(8, 25, 82.4)]);

    expect(find.text('82,4'), findsOneWidget);
    expect(find.byType(WeightChart), findsNothing);
    expect(find.textContaining('aus einem Wert folgt keine Reihe'),
        findsOneWidget);
    expect(find.text('Ersten Verlaufswert eintragen'), findsOneWidget);
  });

  testWidgets('ohne Verlaufseintrag steht der Profilwert mit seiner Herkunft',
      (tester) async {
    await _pump(tester, []);

    expect(find.text('78'), findsOneWidget);
    expect(find.textContaining('Aus den Einstellungen übernommen'),
        findsOneWidget);
  });

  testWidgets('ohne jeden Wert rendert der Block nicht', (tester) async {
    await _pump(tester, [], profileKg: null);

    expect(find.byType(WeightChart), findsNothing);
    expect(find.text('Gewicht'), findsNothing);
  });

  testWidgets('eine Lücke wird benannt, nicht überbrückt', (tester) async {
    await _pump(tester, [
      _e(6, 20, 80.2),
      _e(6, 27, 80.1),
      // Sechs Wochen ohne Eintrag.
      _e(8, 12, 79.1),
      _e(8, 25, 78.9),
    ]);

    // Die Notiz steht als eigene Zeile unter der Kurve — in der Kurve wäre
    // sie bei zulässiger Schriftgrösse fast nie lesbar.
    expect(find.text('6 Wochen ohne Eintrag'), findsOneWidget);

    final chart = tester.widget<WeightChart>(find.byType(WeightChart));
    expect(chart.semanticLabel, contains('Lücke von 6 Wochen'));
  });

  testWidgets('die Karte ist ein Knoten, die Eintragen-Zeile ein zweiter',
      (tester) async {
    await _pump(tester, [_e(8, 14, 79.2), _e(8, 25, 78.9)]);

    final handle = tester.ensureSemantics();
    // Ein Satz statt vier Werten — Wert, Grundlage und Veränderung zusammen.
    expect(
      find.bySemanticsLabel(RegExp(r'^Gewicht, 78,9 Kilogramm, 2 Einträge')),
      findsOneWidget,
    );
    // Die Zeile „Eintragen" hat einen eigenen Fokusstopp.
    expect(find.bySemanticsLabel('Eintragen'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('200 % Systemschrift auf 320 dp läuft nicht über',
      (tester) async {
    await _pump(
      tester,
      [_e(7, 1, 80.9), _e(8, 14, 79.2), _e(8, 25, 78.9)],
      scale: 2.0,
      width: 320,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('78,9'), findsOneWidget);
  });

  testWidgets('abgewiesener Zugriff: der letzte bekannte Wert bleibt stehen',
      (tester) async {
    await _pump(tester, [], denied: true);

    // Der Wert ist ja nicht falsch, nur nicht mehr bestätigt frisch.
    expect(find.text('78'), findsOneWidget);
    expect(find.text('Verlauf konnte nicht aktualisiert werden.'),
        findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);

    // **Kein erfundenes Datum.** Der Profilwert hat keines; „Zuletzt bekannt ·
    // 1. Januar" wäre eine Angabe, die niemand gemacht hat.
    expect(find.textContaining('ZULETZT BEKANNT'), findsNothing);
  });

  testWidgets('solange das Profil lädt, steht das Skelett — nicht nichts',
      (tester) async {
    await _pump(tester, [], settings: _PendingSettings());

    // Der Block verschwindet nicht, während eine seiner beiden Quellen noch
    // unterwegs ist: erst weg, dann da, und die halbe Seite springt.
    expect(find.byType(AtemSkeleton), findsOneWidget);
    expect(find.text('Gewicht'), findsOneWidget);
  });
}
