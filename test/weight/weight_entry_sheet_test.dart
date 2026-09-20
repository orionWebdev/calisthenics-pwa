import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:atem/features/weight/application/weight_providers.dart';
import 'package:atem/features/weight/domain/weight_entry.dart';
import 'package:atem/features/weight/presentation/widgets/weight_entry_sheet.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/fake_auth.dart';

/// Das Eingabeblatt — Board 14, B und C2.
///
/// Geprüft wird, was das Blatt verspricht: Es startet beim zuletzt bekannten
/// Wert, es macht aus einem Tag nie zwei Punkte, und ein rückwirkender Eintrag
/// nennt genau das Fenster, auf das er wirkt.

WeightEntry _e(int month, int day, double kg,
        [WeightSource source = WeightSource.manual]) =>
    WeightEntry(date: DateTime(2026, month, day), kg: kg, source: source);

late FakeWeightRepository repository;

Future<void> _pump(
  WidgetTester tester,
  List<WeightEntry> entries, {
  WeightEntry? edit,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  repository = FakeWeightRepository(entries: entries);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c')),
      ),
      weightRepositoryProvider.overrideWithValue(repository),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(
        settings: const UserSettings(bodyWeightKg: 78),
      )),
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      historyReferenceProvider.overrideWithValue(DateTime.now()),
    ],
    child: MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Scaffold(
            backgroundColor: AtemColors.base,
            body: WeightEntrySheet(entry: edit),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

DateTime _daysAgo(int days) {
  final now = WeightEntry.dayOf(DateTime.now());
  return DateTime(now.year, now.month, now.day - days);
}

void main() {
  testWidgets('startet beim zuletzt bekannten Wert, nicht bei null',
      (tester) async {
    await _pump(tester, [
      WeightEntry(
          date: _daysAgo(5), kg: 78.9, source: WeightSource.manual),
    ]);

    expect(find.text('78,9'), findsOneWidget);
    expect(find.textContaining('ZULETZT 78,9 KG'), findsOneWidget);
    expect(find.textContaining('Heute'), findsOneWidget);
    expect(find.widgetWithText(AtemButton, 'Eintragen'), findsOneWidget);
  });

  testWidgets('ein Wert von heute wird ersetzt, nicht verdoppelt',
      (tester) async {
    await _pump(tester, [
      WeightEntry(
          date: DateTime.now(), kg: 78.7, source: WeightSource.manual),
    ]);

    // Die Notiz informiert und blockiert nichts (Modul 2).
    expect(find.textContaining('Heute bereits erfasst'), findsOneWidget);
    expect(find.widgetWithText(AtemButton, 'Aktualisieren'), findsOneWidget);

    await tester.tap(find.widgetWithText(AtemButton, 'Aktualisieren'));
    await tester.pumpAndSettle();

    expect(repository.entries.length, 1, reason: 'ein Tag, ein Wert');
  });

  testWidgets('ein unverändert bestätigter Messwert bleibt gemessen',
      (tester) async {
    await _pump(tester, [
      WeightEntry(
        date: DateTime.now(),
        kg: 78.7,
        source: WeightSource.healthConnect,
        externalId: 'hc-1',
      ),
    ]);

    await tester.tap(find.widgetWithText(AtemButton, 'Aktualisieren'));
    await tester.pumpAndSettle();

    // Entscheidung 10: Ein reines Anschauen darf keine Quelle umschreiben.
    expect(repository.entries.single.source, WeightSource.healthConnect);
    expect(repository.entries.single.externalId, 'hc-1');
  });

  testWidgets('ein rückwirkender Eintrag nennt sein Fenster', (tester) async {
    await _pump(
      tester,
      [
        _e(7, 21, 80.2),
        _e(7, 28, 80),
        WeightEntry(
            date: _daysAgo(3), kg: 79, source: WeightSource.manual),
      ],
      edit: _e(7, 21, 80.2),
    );

    // Von diesem Eintrag bis zum nächsten — nicht der ganze Verlauf
    // (Entscheidung 11).
    expect(find.textContaining('WIRKT AUF'), findsOneWidget);
    expect(find.text('BIS ZUM NÄCHSTEN EINTRAG · NICHT DEN GANZEN VERLAUF'),
        findsOneWidget);
    expect(find.textContaining('27. Jul'), findsOneWidget);
  });

  testWidgets('Löschen fragt in zwei Stufen und nennt die Folge',
      (tester) async {
    await _pump(
      tester,
      [_e(7, 21, 80.2), _e(7, 28, 80)],
      edit: _e(7, 21, 80.2),
    );

    await tester.tap(find.widgetWithText(AtemButton, 'Eintrag löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Eintrag löschen?'), findsOneWidget);
    expect(find.textContaining('gilt danach wieder der Wert davor'),
        findsOneWidget);
    // Genau zwei Wege, kein dritter.
    expect(find.text('Endgültig löschen'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });
}
