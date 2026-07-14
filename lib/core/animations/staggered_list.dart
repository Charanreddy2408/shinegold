import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Staggers entrance once per widget identity — won't re-animate on filter rebuilds.
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerMs = 45,
    this.maxAnimated = 12,
  });

  final int index;
  final Widget child;
  final int staggerMs;
  /// Skip animation for items beyond this index (keeps long lists snappy).
  final int maxAnimated;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    if (_played || widget.index >= widget.maxAnimated) {
      return widget.child;
    }

    return widget.child
        .animate(
          onComplete: (_) {
            if (mounted) setState(() => _played = true);
          },
        )
        .fadeIn(
          delay: Duration(milliseconds: widget.index * widget.staggerMs),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          delay: Duration(milliseconds: widget.index * widget.staggerMs),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
  }
}
