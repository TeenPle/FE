import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const TapScale({super.key, required this.child, this.scale = 0.96});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _downPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _downPosition = event.localPosition;
        _controller.forward();
      },
      onPointerMove: (event) {
        if (_downPosition == null) return;
        if ((event.localPosition - _downPosition!).distance > 8) {
          _controller.reverse();
          _downPosition = null;
        }
      },
      onPointerUp: (_) {
        _controller.reverse();
        _downPosition = null;
      },
      onPointerCancel: (_) {
        _controller.reverse();
        _downPosition = null;
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) =>
            Transform.scale(scale: _animation.value, child: child),
        child: widget.child,
      ),
    );
  }
}
