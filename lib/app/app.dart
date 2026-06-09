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
        // 시스템 글자 크기 설정은 반영하되 앱 자체 추가 확대는 적용하지 않는다.
        final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
        final effective = systemScale.clamp(0.85, 1.35);
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
              bottom: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
