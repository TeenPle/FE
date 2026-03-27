import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'theme.dart';

class TeenpleApp extends StatelessWidget {
  const TeenpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teenple',
      debugShowCheckedModeBanner: false,
      theme: buildTeenpleTheme(),
      home: const AppShell(),
    );
  }
}