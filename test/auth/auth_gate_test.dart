import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/auth/presentation/auth_gate.dart';
import 'package:atem/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

Widget _app(AuthRepository auth) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        theme: AtemTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const AuthGate(
          child: Scaffold(
            body: Text('geschützt', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

void main() {
  testWidgets('ohne Anmeldung führt das Tor auf die Anmeldung', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('geschützt'), findsNothing);
  });

  testWidgets('mit Anmeldung führt das Tor auf den Inhalt', (tester) async {
    await tester.pumpWidget(
      _app(FakeAuthRepository(user: const AuthUser(uid: 'u', email: 'a@b.c'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('geschützt'), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('Abmelden führt zurück auf die Anmeldung', (tester) async {
    final auth = FakeAuthRepository(user: const AuthUser(uid: 'u'));
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();
    expect(find.text('geschützt'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('ein Fehler beim Anmelden sperrt niemanden aus', (tester) async {
    // Der Bildschirm muss den Fehler zeigen und bedienbar bleiben — sonst
    // sitzt der Nutzer in einer App fest, aus der kein Weg herausführt.
    final auth = FakeAuthRepository(failure: AuthFailure.netzwerk);
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    final l10n = AppL10n.of(tester.element(find.byType(SignInScreen)));
    await tester.tap(find.text(l10n.authGoogle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authNetworkTitle), findsOneWidget);
    expect(find.text(l10n.authGoogle), findsOneWidget);
  });

  testWidgets('ein Abbruch durch den Nutzer erzeugt keine Meldung',
      (tester) async {
    final auth = FakeAuthRepository(failure: AuthFailure.abgebrochen);
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    final l10n = AppL10n.of(tester.element(find.byType(SignInScreen)));
    await tester.tap(find.text(l10n.authGoogle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.authFailedTitle), findsNothing);
    expect(find.text(l10n.authNetworkTitle), findsNothing);
  });
}
