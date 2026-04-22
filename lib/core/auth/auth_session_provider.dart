import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSession {
  final String? accessToken;
  final String? refreshToken;

  const AuthSession({this.accessToken, this.refreshToken});
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  return AuthSessionNotifier();
});

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier() : super(const AuthSession());

  void setTokens(String accessToken, String refreshToken) {
    state = AuthSession(accessToken: accessToken, refreshToken: refreshToken);
  }

  void clearTokens() => state = const AuthSession();
}
