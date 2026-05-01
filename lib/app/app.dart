import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme_provider.dart';
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
      routerConfig: router,
    );
  }
}
