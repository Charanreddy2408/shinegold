import 'package:flutter/material.dart';

import 'animated_loading.dart';

/// Back-compat alias — prefer [ShineShimmer] / [ListLoadingSkeleton].
class GoldShimmer extends StatelessWidget {
  const GoldShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShineShimmer(child: child);
}

/// Back-compat bone — prefer [SkeletonBone] inside a single [ShineShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ShineShimmer(
      child: SkeletonBone(
        height: height,
        width: width,
        radius: radius,
      ),
    );
  }
}
