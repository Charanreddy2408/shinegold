import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SunRayReveal extends StatefulWidget {
  const SunRayReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<SunRayReveal> createState() => _SunRayRevealState();
}

class _SunRayRevealState extends State<SunRayReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rayOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rayOpacity = Tween<double>(begin: 0, end: 0.18).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _rayOpacity.value,
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _SunRayPainter(progress: _controller.value),
              ),
            ),
            Transform.scale(scale: _scale.value, child: child),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _SunRayPainter extends CustomPainter {
  _SunRayPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const rayCount = 8;
    final maxRadius = size.width / 2 * progress;
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2;
      final end = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
