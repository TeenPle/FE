import 'package:flutter/material.dart';

class KeyboardAwareBottomBar extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimum;

  const KeyboardAwareBottomBar({
    super.key,
    required this.child,
    this.minimum = const EdgeInsets.fromLTRB(24, 0, 24, 20),
  });

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(top: false, minimum: minimum, child: child),
    );
  }
}
