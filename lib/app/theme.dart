import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

TextTheme _teenpleTextTheme(AppColors colors) {
  return TextTheme(
    displayLarge: AppTextStyles.displayLarge.copyWith(
      color: colors.textPrimary,
    ),
    displayMedium: AppTextStyles.displaySmall.copyWith(
      color: colors.textPrimary,
    ),
    displaySmall: AppTextStyles.displaySmall.copyWith(
      color: colors.textPrimary,
    ),
    headlineLarge: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
    headlineMedium: AppTextStyles.titleMedium.copyWith(
      color: colors.textPrimary,
    ),
    headlineSmall: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
    titleLarge: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
    titleMedium: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary),
    titleSmall: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
    bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colors.textBody),
    bodyMedium: AppTextStyles.bodyMedium.copyWith(color: colors.textBody),
    bodySmall: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
    labelLarge: AppTextStyles.labelLarge.copyWith(color: colors.textPrimary),
    labelMedium: AppTextStyles.labelMedium.copyWith(
      color: colors.textSecondary,
    ),
    labelSmall: AppTextStyles.labelSmall.copyWith(color: colors.textTertiary),
  );
}

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
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // 이 페이지가 다른 페이지에 덮일 때: 약간 왼쪽으로 밀리며 살짝 어두워짐
    final slideOut =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.12, 0.0),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInCubic,
          ),
        );

    final dimOut = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
    );

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: dimOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(opacity: fadeIn, child: child),
        ),
      ),
    );
  }
}

const _transitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _TeenplePageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
);

ThemeData buildTeenpleLightTheme() {
  final colors = AppColors.light();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colors.pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DA1F2),
      brightness: Brightness.light,
    ),
    textTheme: _teenpleTextTheme(colors),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.pageBg,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.popupBg,
      surfaceTintColor: Colors.transparent,
      textStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        color: colors.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodySmall.copyWith(
        color: colors.textSecondary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF171A20),
      contentTextStyle: AppTextStyles.labelMedium.copyWith(
        color: const Color(0xFFE7ECF2),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: AppTextStyles.labelMedium,
        minimumSize: const Size(52, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBg,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textHint),
    ),
    extensions: [colors],
    pageTransitionsTheme: _transitions,
  );
}

ThemeData buildTeenpleDarkTheme() {
  final colors = AppColors.dark();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colors.pageBg,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DA1F2),
          brightness: Brightness.dark,
        ).copyWith(
          surface: colors.cardBg,
          surfaceContainer: colors.cardBg,
          onSurface: colors.textPrimary,
        ),
    textTheme: _teenpleTextTheme(colors),
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
      textStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.titleMedium.copyWith(
        color: colors.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodySmall.copyWith(
        color: colors.textSecondary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF171A20),
      contentTextStyle: AppTextStyles.labelMedium.copyWith(
        color: const Color(0xFFE7ECF2),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: AppTextStyles.labelMedium,
        minimumSize: const Size(52, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBg,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textHint),
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
