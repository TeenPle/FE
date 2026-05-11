import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

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
    scaffoldBackgroundColor: AppColors.light().pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light().pageBg,
      foregroundColor: AppColors.light().textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.light().popupBg,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.light().cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.light().cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    extensions: [AppColors.light()],
    pageTransitionsTheme: _transitions,
  );
}

ThemeData buildTeenpleDarkTheme() {
  final colors = AppColors.dark();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colors.pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.dark,
    ).copyWith(
      surface: colors.cardBg,
      surfaceContainer: colors.cardBg,
      onSurface: colors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.pageBg,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardColor: colors.cardBg,
    dividerColor: colors.divider,
    popupMenuTheme: PopupMenuThemeData(
      color: colors.popupBg,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      contentTextStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBg,
      hintStyle: TextStyle(color: colors.textHint),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF229BF3),
    ),
    extensions: [colors],
    pageTransitionsTheme: _transitions,
  );
}

// kept for backwards compat — returns light theme
ThemeData buildTeenpleTheme() => buildTeenpleLightTheme();
