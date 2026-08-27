import 'dart:async';

import 'package:atem/features/auth/domain/access.dart';
import 'package:atem/features/auth/domain/auth_user.dart';

/// Anmeldung ohne Firebase.
///
/// Die echte Fassung spricht beim Bauen schon mit dem Plugin; im Test wäre das
/// eine Netzabhängigkeit in einem Widget-Test.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user, this.failure}) : _user = user;

  AuthUser? _user;

  /// Wenn gesetzt, schlägt jede Anmeldung damit fehl.
  final AuthFailure? failure;

  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get current => _user;

  @override
  Stream<AuthUser?> authState() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    if (failure != null) throw AuthException(failure!);
    _user = const AuthUser(uid: 'test-uid', email: 'test@atem.app');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

/// Zugangsliste ohne Firestore.
class FakeAllowlistRepository implements AllowlistRepository {
  FakeAllowlistRepository({this.allowed = true, this.throws = false});

  bool allowed;

  /// Simuliert „Prüfung nicht möglich" — etwa ohne Netz.
  bool throws;

  int calls = 0;

  @override
  Future<bool> isAllowed(AuthUser user) async {
    calls++;
    if (throws) throw StateError('keine Verbindung');
    return allowed;
  }
}

/// Profil ohne Firestore.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.weightKg});

  double? weightKg;
  String? savedUnitSystem;

  @override
  Future<double?> bodyWeightKg(String userId) async => weightKg;

  @override
  Future<void> saveBodyWeight(
    String userId, {
    required double kilograms,
    required String unitSystem,
  }) async {
    weightKg = kilograms;
    savedUnitSystem = unitSystem;
  }
}
