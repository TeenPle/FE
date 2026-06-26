import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSession {
  final String? accessToken;
  final String? refreshToken;
  final int? userId;

  const AuthSession({this.accessToken, this.refreshToken, this.userId});
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
      return AuthSessionNotifier();
    });

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier() : super(const AuthSession());

  void setTokens(String accessToken, String refreshToken, {int? userId}) {
    state = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId ?? state.userId,
    );
  }

  void clearTokens() => state = const AuthSession();
}
