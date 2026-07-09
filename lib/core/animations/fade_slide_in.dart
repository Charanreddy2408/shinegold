import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: duration, delay: delay, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: duration,
          delay: delay,
          curve: Curves.easeOutCubic,
        );
  }
}
