import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthStepLayout extends StatelessWidget {
  final Widget child;
  final Widget bottom;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const AuthStepLayout({
    super.key,
    required this.child,
    required this.bottom,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 40),
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final bottomPad = keyboard > 0
        ? keyboard + 8.0
        : safeBottom + (media.size.height * 0.024).clamp(14.0, 24.0);

    final content = Padding(padding: padding, child: child);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: context.colors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: content,
                    )
                  : content,
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
              child: SizedBox(width: double.infinity, child: bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBottomActionArea extends StatelessWidget {
  final Widget child;

  const AuthBottomActionArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final bottomPad = keyboard > 0
        ? 8.0
        : safeBottom + (media.size.height * 0.024).clamp(14.0, 24.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
      child: child,
    );
  }
}
