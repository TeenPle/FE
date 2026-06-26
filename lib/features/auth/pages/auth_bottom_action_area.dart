import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthStepLayout extends StatelessWidget {
  final Widget child;
  final Widget bottom;
  final bool scrollable;

  /// true면 버튼을 키보드 위에 띄우지 않고 본문 아래(스크롤 영역 안)에 배치한다.
  /// 입력 필드가 여러 개라 키보드 위 버튼이 아래 필드를 가리는 페이지에서 사용.
  final bool inlineBottom;
  final EdgeInsetsGeometry padding;

  const AuthStepLayout({
    super.key,
    required this.child,
    required this.bottom,
    this.scrollable = true,
    this.inlineBottom = false,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 40),
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final restingPad =
        safeBottom + (media.size.height * 0.024).clamp(14.0, 24.0);

    final content = Padding(padding: padding, child: child);

    if (inlineBottom && scrollable) {
      /// 버튼이 본문 흐름 안에 있으므로 Scaffold가 키보드만큼 줄어들게 두고,
      /// 포커스된 필드는 TextField의 ensureVisible 스크롤에 맡긴다.
      return Scaffold(
        backgroundColor: context.colors.pageBg,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  /// 내용이 짧을 때도 버튼이 화면 하단에 붙도록 최소 높이를 보장
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        content,
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            8,
                            24,
                            keyboard > 0 ? 16.0 : restingPad,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    final bottomPad = keyboard > 0 ? keyboard + 8.0 : restingPad;

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
              padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad),
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
