import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/auth/domain/access.dart';
import 'package:atem/features/auth/domain/auth_user.dart';
import 'package:atem/features/auth/presentation/auth_gate.dart';
import 'package:atem/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:atem/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:atem/features/auth/presentation/screens/splash_screen.dart';
import 'package:atem/features/auth/presentation/screens/waiting_room_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

const _user = AuthUser(uid: 'u', email: 'a@b.c');

Widget _app({
  AuthRepository? auth,
  AllowlistRepository? allowlist,
  ProfileRepository? profile,
}) =>
    ProviderScope(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(auth ?? FakeAuthRepository(user: _user)),
        allowlistRepositoryProvider
            .overrideWithValue(allowlist ?? FakeAllowlistRepository()),
        profileRepositoryProvider
            .overrideWithValue(profile ?? FakeProfileRepository(weightKg: 78)),
      ],
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
        // Ohne das laufen die dekorativen Dauerschleifen endlos und
        // `pumpAndSettle` läuft in den Timeout — Vertrag R8.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );

void main() {
  testWidgets('der erste Frame ist der Splash, nicht die Anmeldung',
      (tester) async {
    await tester.pumpWidget(_app());
    // Bewusst kein pumpAndSettle: Es geht um genau den Moment, in dem noch
    // nichts entschieden ist. Stünde hier die Anmeldung, blitzte sie bei
    // jedem Start auf.
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('ohne Anmeldung führt das Tor auf die Anmeldung', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('geschützt'), findsNothing);
  });

  testWidgets(
      'nicht freigeschaltet führt in den Warteraum, nicht in den Fehler',
      (tester) async {
    await tester.pumpWidget(
      _app(allowlist: FakeAllowlistRepository(allowed: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WaitingRoomScreen), findsOneWidget);
    expect(find.text('geschützt'), findsNothing);

    // Die Anmeldung WAR erfolgreich — der Zustand darf nicht als Fehler
    // erscheinen.
    final l10n = AppL10n.of(tester.element(find.byType(WaitingRoomScreen)));
    expect(find.text(l10n.gateTitle), findsOneWidget);
    expect(find.text(l10n.authFailedTitle), findsNothing);
  });

  testWidgets('freigeschaltet ohne Körpergewicht führt ins Onboarding',
      (tester) async {
    await tester.pumpWidget(_app(profile: FakeProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('geschützt'), findsNothing);
  });

  testWidgets('mit allem führt das Tor auf den Inhalt', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('geschützt'), findsOneWidget);
  });

  testWidgets('Abmelden führt zurück auf die Anmeldung', (tester) async {
    final auth = FakeAuthRepository(user: _user);
    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();
    expect(find.text('geschützt'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('eine gescheiterte Zugangsprüfung sperrt niemanden aus',
      (tester) async {
    // Ohne Netz ist die Antwort unbekannt. Es muss trotzdem einen Weg geben.
    await tester.pumpWidget(
      _app(allowlist: FakeAllowlistRepository(throws: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
