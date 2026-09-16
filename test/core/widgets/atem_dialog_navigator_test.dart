import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ein Bestätigungsdialog **aus einem Tab heraus**.
///
/// Wie beim Start-Blatt (Commit 2e39a40) ist der verschachtelte Navigator
/// der Punkt: Der Dialog liegt auf dem Wurzel-Navigator, der Bildschirm im
/// Tab. Bestätigte `onConfirm` mit `Navigator.of(context)`, schloss es den
/// Bildschirm statt des Dialogs — Einheiten, Pläne und Übungen liessen sich
/// bis zum 16.09.2026 nicht löschen.
void main() {
  Future<({bool? result, bool pageStillThere, bool dialogGone})> confirmFromTab(
    WidgetTester tester, {
    required bool rootNavigator,
  }) async {
    bool? result;
    var finished = false;

    await tester.pumpWidget(MaterialApp(
      theme: AtemTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Wurzel des Tabs')),
        ),
      ),
    ));
    final tabNavigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    tabNavigator.push(MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await AtemDialog.show<bool>(
                context,
                kind: AtemDialogKind.destructive,
                title: 'Einheit löschen?',
                message: 'Folgen',
                confirmLabel: 'Weiter',
                dismissLabel: 'Abbrechen',
                barrierLabel: 'Einheit löschen?',
                onConfirm: () => Navigator.of(context,
                        rootNavigator: rootNavigator)
                    .pop(true),
              );
              finished = true;
            },
            child: const Text('Detail: Löschen'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Detail: Löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    return (
      result: finished ? result : null,
      pageStillThere: find.text('Detail: Löschen').evaluate().isNotEmpty,
      dialogGone: find.text('Weiter').evaluate().isEmpty,
    );
  }

  testWidgets('mit rootNavigator schliesst Weiter den Dialog, nicht den Bildschirm',
      (tester) async {
    final r = await confirmFromTab(tester, rootNavigator: true);
    expect(r.result, isTrue);
    expect(r.dialogGone, isTrue);
    expect(r.pageStillThere, isTrue,
        reason: 'Der Bildschirm im Tab muss stehen bleiben');
  });

  testWidgets('ohne rootNavigator bleibt der Dialog stehen — der alte Fehler',
      (tester) async {
    final r = await confirmFromTab(tester, rootNavigator: false);
    expect(r.result, isNull);
    expect(r.dialogGone, isFalse);
    expect(r.pageStillThere, isFalse);
  });
}
