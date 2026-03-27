import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/api/mock_home_repository.dart';
import '../features/home/provider/home_provider.dart';
import 'app_shell.dart';
import 'theme.dart';

class TeenpleApp extends StatelessWidget {
  const TeenpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            repository: const MockHomeRepository(),
          )..loadInitialHome(1),
        ),
      ],
      child: MaterialApp(
        title: 'Teenple',
        debugShowCheckedModeBanner: false,
        theme: buildTeenpleTheme(),
        home: const AppShell(),
      ),
    );
  }
}