import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final int delay;
  final Duration? duration;
  final double offset;
  final Curve curve;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.delay = 0,
    this.duration,
    this.offset = 0.2,
    this.curve = Curves.easeOutQuad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
      duration: duration ?? 500.ms,
      delay: delay.ms,
    )
        .slideY(
      begin: offset,
      end: 0,
      curve: curve,
      duration: duration ?? 600.ms,
      delay: delay.ms,
    );
  }
}

