import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/haptics.dart';

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
    final color =
        widget.liked ? const Color(0xFF14A3F7) : const Color(0xFF6E7B87);
    final backgroundColor =
        widget.liked ? const Color(0xFFEAF7FF) : c.cardBg;
    final borderColor =
        widget.liked ? const Color(0xFFBFE6FF) : const Color(0xFFE6EDF3);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      widget.liked
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      key: ValueKey(widget.liked),
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    child: Text('공감 ${widget.likeCount}'),
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
  static const _color = Color(0xFF14A3F7);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = progress < _fadeStart
        ? 1.0
        : 1.0 - (progress - _fadeStart) / (1.0 - _fadeStart);
    final paint = Paint()
      ..color = _color.withValues(alpha: opacity.clamp(0.0, 1.0));
    final radius = progress * _maxRadius;
    final pSize = _particleSize * (1 - progress * 0.4);

    for (var i = 0; i < _count; i++) {
      final angle = (2 * math.pi / _count) * i - math.pi / 2;
      final pos = center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(pos, pSize, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
