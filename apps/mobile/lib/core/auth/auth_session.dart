import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/breezze_api.dart';

/// Auth session state — what the UI renders.
sealed class AuthState {
  const AuthState();
}

class AuthUninitialized extends AuthState {
  const AuthUninitialized();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSignedIn extends AuthState {
  final String userId;
  final String email;
  const AuthSignedIn({required this.userId, required this.email});
}

class AuthError extends AuthState {
  final String code;
  const AuthError(this.code);
}

/// Session controller: owns the API client instance, the tokens, and the
/// auth state. Tokens are held in memory for now; secure storage lands
/// with the Drift migration (plan §5.5).
class AuthSessionController extends Notifier<AuthState> {
  late final BreezzeApi _api = BreezzeApi(
    baseUrl: const String.fromEnvironment(
      'BREEZZE_API_URL',
      defaultValue: 'http://localhost:3000',
    ),
  );

  @override
  AuthState build() {
    return const AuthUninitialized();
  }

  BreezzeApi get api => _api;

  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = const AuthSigningIn();
    try {
      final response = await _api.register(email, password,
          displayName: displayName);
      _api.accessToken = response.accessToken;
      state = AuthSignedIn(userId: response.userId, email: response.email);
    } on BreezzeApiException catch (e) {
      state = AuthError(e.code);
    } catch (_) {
      state = const AuthError('NETWORK_ERROR');
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthSigningIn();
    try {
      final response = await _api.login(email, password);
      _api.accessToken = response.accessToken;
      state = AuthSignedIn(userId: response.userId, email: response.email);
    } on BreezzeApiException catch (e) {
      state = AuthError(e.code);
    } catch (_) {
      state = const AuthError('NETWORK_ERROR');
    }
  }

  Future<void> signOut() async {
    _api.accessToken = null;
    state = const AuthSignedOut();
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthState>(
  AuthSessionController.new,
);
