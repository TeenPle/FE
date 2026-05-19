import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../core/network/base_url.dart';
import '../../../core/storage/token_storage.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage>
    with SingleTickerProviderStateMixin {
  static const Duration splashDelay = Duration(milliseconds: 1500);
  static const String _landingAsset = 'assets/images/teenple_landing.png';
  static const Size _landingImageSize = Size(941, 1672);

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(splashDelay, _handleAutoLogin);
  }

  Future<void> _handleAutoLogin() async {
    if (!mounted) return;

    final tokenStorage = ref.read(tokenStorageProvider);
    final autoLogin = await tokenStorage.getAutoLogin();

    if (autoLogin) {
      final accessToken = await tokenStorage.getAccessToken();
      final refreshToken = await tokenStorage.getRefreshToken();
      final userId = await tokenStorage.getUserId();

      if (accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        // 서버 refresh 호출로 토큰 갱신 + 계정 상태 검증
        // (탈퇴 유예 계정이면 USER4051을 반환하므로 여기서 잡아낼 수 있음)
        try {
          final plainDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
          final response = await plainDio.post(
            '/api/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final result = response.data['result'] as Map<String, dynamic>;
          final newAccessToken = result['accessToken'] as String;
          final newRefreshToken = result['refreshToken'] as String;

          // 갱신된 토큰을 메모리 세션에 반영 (userId는 저장된 값 유지)
          ref.read(authSessionProvider.notifier).setTokens(
            newAccessToken,
            newRefreshToken,
            userId: userId,
          );

          // 자동로그인 유저이므로 디스크 토큰도 최신으로 갱신
          await tokenStorage.saveAccessToken(newAccessToken);
          await tokenStorage.saveRefreshToken(newRefreshToken);

          final role = await tokenStorage.getUserRole();
          if (!mounted) return;

          if (role == 'ADMIN') {
            context.go(AppRoutes.adminHome);
          } else {
            context.go(AppRoutes.school);
          }
          return;
        } on DioException catch (e) {
          // 탈퇴 유예 계정(USER4051) → 복구 화면으로 분기
          if (_extractBackendCode(e.response?.data) == 'USER4051') {
            if (!mounted) return;
            context.go(AppRoutes.accountRecovery);
            return;
          }
          // 그 외 refresh 실패(만료·서버 오류 등) → 토큰 정리 후 로그인
        } catch (_) {
          // 네트워크 오류 등 → 토큰 정리 후 로그인
        }

        await tokenStorage.clearAll();
        if (!mounted) return;
        context.go(AppRoutes.login);
        return;
      }

      // 자동로그인 플래그는 있지만 토큰이 없는 경우 → 정리 후 로그인
      await tokenStorage.clearAll();
    }

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  /// 서버 응답 바디에서 백엔드 오류 코드를 추출한다.
  String? _extractBackendCode(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final direct = data['code'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final nested = result['code'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFBFDFF), Color(0xFFEAF8FF)],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Semantics(
                  label: 'TeenPle, 우리 학교와 동네를 잇는 학생 커뮤니티',
                  image: true,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _landingImageSize.width,
                      height: _landingImageSize.height,
                      child: Image.asset(
                        _landingAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
