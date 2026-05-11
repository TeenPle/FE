import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthStepLayout extends StatelessWidget {
  final Widget child;
  final Widget bottom;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final bool resizeToAvoidBottomInset;

  const AuthStepLayout({
    super.key,
    required this.child,
    required this.bottom,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 40),
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: context.colors.pageBg,
      bottomNavigationBar: AuthBottomActionArea(child: bottom),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: content,
              )
            : content,
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
    final bottomGap = media.viewInsets.bottom > 0
        ? 8.0
        : (media.size.height * 0.024).clamp(14.0, 24.0);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(left: 24, right: 24),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: child,
      ),
    );
  }
}
