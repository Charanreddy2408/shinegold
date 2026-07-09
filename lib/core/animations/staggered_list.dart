import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerMs = 60,
  });

  final int index;
  final Widget child;
  final int staggerMs;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * staggerMs),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: index * staggerMs),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
  }
}
