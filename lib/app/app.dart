import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/app_snack_bar.dart';
import 'routes.dart';
import 'theme.dart';

class TeenpleApp extends ConsumerWidget {
  const TeenpleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Teenple',
      debugShowCheckedModeBanner: false,
      theme: buildTeenpleLightTheme(),
      darkTheme: buildTeenpleDarkTheme(),
      themeMode: themeMode,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: appScaffoldMessengerKey,
      builder: (context, child) {
        // 앱 전체 기본 글자 크기 보정: 하드코딩된 fontSize 값들이 11–13px 중심이라
        // 시스템 보통 상태에서도 읽기 편하도록 1.1배 기본 배수를 적용한다.
        // 시스템 설정 반영: small(≈0.85) → ~0.94×, normal(1.0) → 1.1×, large(1.3) → 1.35× (상한)
        final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
        final effective = (systemScale * 1.1).clamp(0.85, 1.35);
        final clamped = MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(effective));
        return MediaQuery(
          data: clamped,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
