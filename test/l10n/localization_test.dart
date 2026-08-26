import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendert einen Schlüssel unter einer Sprache.
Future<void> _pumpKey(
  WidgetTester tester,
  String locale,
  String Function(AppL10n) pick,
) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Builder(
      builder: (c) =>
          Text(pick(AppL10n.of(c)), textDirection: TextDirection.ltr),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('Deutsch und Englisch liefern unterschiedliche Texte',
      (tester) async {
    await _pumpKey(tester, 'de', (l) => l.commonCancel);
    expect(find.text('Abbrechen'), findsOneWidget);

    await _pumpKey(tester, 'en', (l) => l.commonCancel);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Beide Sprachen sind als unterstützt gemeldet', (tester) async {
    expect(
      AppL10n.supportedLocales.map((l) => l.languageCode),
      containsAll(<String>['de', 'en']),
    );
  });

  testWidgets('Platzhalter werden ersetzt, nicht durchgereicht',
      (tester) async {
    // Ein Schlüssel mit Interpolation — der Platzhalter darf nicht wörtlich
    // im Ergebnis stehen.
    await _pumpKey(tester, 'de', (l) => l.workoutScreenExerciseOf(1, 3));
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('1'), findsOneWidget);
  });
}
