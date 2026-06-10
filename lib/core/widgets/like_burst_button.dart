import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/haptics.dart';

const bool _useHeartLikeStyle = true;
const Color _heartLikeColor = Color(0xFFE2556F);
const Color _heartLikeBackgroundColor = Color(0xFFFFF1F4);
const Color _heartLikeBorderColor = Color(0xFFFFC9D3);
const Color _heartLikeDarkBackgroundColor = Color(0xFF3A2028);
const Color _heartLikeDarkBorderColor = Color(0xFF6E2E3E);
const Color _thumbLikeColor = Color(0xFF14A3F7);
const Color _thumbLikeBackgroundColor = Color(0xFFEAF7FF);
const Color _thumbLikeBorderColor = Color(0xFFBFE6FF);
const Color _thumbLikeDarkBackgroundColor = Color(0xFF152240);
const Color _thumbLikeDarkBorderColor = Color(0xFF1E3550);

class LikeBurstButton extends StatefulWidget {
  final bool liked;
  final int likeCount;
  final VoidCallback onTap;

  const LikeBurstButton({
    super.key,
    required this.liked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  State<LikeBurstButton> createState() => _LikeBurstButtonState();
}

class _LikeBurstButtonState extends State<LikeBurstButton>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _burstController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.94), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 30),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.medium();
    widget.onTap();
    _scaleController.forward(from: 0);
    if (!widget.liked) {
      _burstController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _useHeartLikeStyle ? _heartLikeColor : _thumbLikeColor;
    final activeBackgroundColor = _useHeartLikeStyle
        ? (isDark ? _heartLikeDarkBackgroundColor : _heartLikeBackgroundColor)
        : (isDark ? _thumbLikeDarkBackgroundColor : _thumbLikeBackgroundColor);
    final activeBorderColor = _useHeartLikeStyle
        ? (isDark ? _heartLikeDarkBorderColor : _heartLikeBorderColor)
        : (isDark ? _thumbLikeDarkBorderColor : _thumbLikeBorderColor);
    final color = widget.liked ? activeColor : const Color(0xFF6E7B87);
    final backgroundColor = widget.liked ? activeBackgroundColor : c.cardBg;
    final borderColor = widget.liked ? activeBorderColor : c.border;
    final activeIcon = _useHeartLikeStyle
        ? Icons.favorite_rounded
        : Icons.thumb_up;
    final inactiveIcon = _useHeartLikeStyle
        ? Icons.favorite_border_rounded
        : Icons.thumb_up_outlined;
    // 아이콘 스타일(하트/엄지)과 무관하게 용어는 '좋아요'로 통일한다.
    // (알림 문구·설정 화면의 '좋아요 알림'과 표기 일치)
    const label = '좋아요';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.liked ? activeIcon : inactiveIcon,
                      key: ValueKey(widget.liked),
                      size: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    child: Text('$label ${widget.likeCount}'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -28,
          right: -28,
          top: -28,
          bottom: -28,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _burstController,
              builder: (context, _) {
                if (_burstController.value == 0) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _BurstPainter(progress: _burstController.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;

  const _BurstPainter({required this.progress});

  static const _count = 7;
  static const _maxRadius = 26.0;
  static const _particleSize = 4.5;
  static const _fadeStart = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = progress < _fadeStart
        ? 1.0
        : 1.0 - (progress - _fadeStart) / (1.0 - _fadeStart);
    final paint = Paint()
      ..color = (_useHeartLikeStyle ? _heartLikeColor : _thumbLikeColor)
          .withValues(alpha: opacity.clamp(0.0, 1.0));
    final radius = progress * _maxRadius;
    final pSize = _particleSize * (1 - progress * 0.4);

    for (var i = 0; i < _count; i++) {
      final angle = (2 * math.pi / _count) * i - math.pi / 2;
      final pos =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(pos, pSize, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
