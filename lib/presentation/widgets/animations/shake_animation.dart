// lib/presentation/widgets/animations/shake_animation.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration duration;

  const ShakeAnimation({
    Key? key,
    required this.child,
    required this.shake,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _ShakeAnimationState createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shake && !oldWidget.shake) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _offsetAnimation.value * sin(_controller.value * pi * 4),
            0,
          ),
          child: widget.child,
        );
      },
    );
  }
}