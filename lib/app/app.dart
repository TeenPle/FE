import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class TeenpleApp extends StatelessWidget {
  const TeenpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Teenple',
      debugShowCheckedModeBanner: false,
      theme: buildTeenpleTheme(),
      routerConfig: router,
    );
  }
}