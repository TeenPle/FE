import 'package:flutter/material.dart';

/// 모든 페이지 전환에 적용되는 커스텀 트랜지션.
///
/// 진입: 오른쪽에서 슬라이드 + 초반 페이드인 (easeOutCubic)
/// 피복: 위 페이지가 올라올 때 현재 페이지가 약간 왼쪽으로 밀리며 살짝 어두워짐
class _TeenplePageTransitionsBuilder extends PageTransitionsBuilder {
  const _TeenplePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 이 페이지가 진입할 때: 오른쪽에서 슬라이드 + 앞 40% 구간 페이드인
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // 이 페이지가 다른 페이지에 덮일 때: 약간 왼쪽으로 밀리며 살짝 어두워짐
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.12, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    ));

    final dimOut = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeIn,
      ),
    );

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: dimOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      ),
    );
  }
}

const _transitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _TeenplePageTransitionsBuilder(),
    TargetPlatform.iOS: _TeenplePageTransitionsBuilder(),
  },
);

ThemeData buildTeenpleLightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFECF6FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
    pageTransitionsTheme: _transitions,
  );
}

ThemeData buildTeenpleDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      surfaceContainer: const Color(0xFF1E1E1E),
    ),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2C2C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFEEEEEE),
      elevation: 0,
    ),
    pageTransitionsTheme: _transitions,
  );
}

// kept for backwards compat — returns light theme
ThemeData buildTeenpleTheme() => buildTeenpleLightTheme();
