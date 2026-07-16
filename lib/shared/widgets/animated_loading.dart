import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// Brand shimmer wrapper used by all skeleton loaders.
class ShineShimmer extends StatelessWidget {
  const ShineShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4DA),
      highlightColor: const Color(0xFFFBF8F1),
      period: const Duration(milliseconds: 1200),
      direction: ShimmerDirection.ltr,
      child: child,
    );
  }
}

/// Single rounded bone used inside shimmer layouts.
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 10,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Dashboard / home overview shimmer.
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShineShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonBone(height: 96, radius: 20),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SkeletonBone(height: 78, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBone(height: 78, radius: 16)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: SkeletonBone(height: 78, radius: 16)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBone(height: 78, radius: 16)),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBone(height: 18, width: 140, radius: 8),
          SizedBox(height: 10),
          SkeletonBone(height: 200, radius: 18),
          SizedBox(height: 16),
          SkeletonBone(height: 18, width: 120, radius: 8),
          SizedBox(height: 10),
          _CardSkeleton(),
          SizedBox(height: 10),
          _CardSkeleton(),
        ],
      ),
    );
  }
}

/// Generic list shimmer (farms, executives, visits, harvests).
class ListLoadingSkeleton extends StatelessWidget {
  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 96,
    this.showAvatar = true,
  });

  final int itemCount;
  final double itemHeight;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return ShineShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => _CardSkeleton(
          height: itemHeight,
          showAvatar: showAvatar,
        ),
      ),
    );
  }
}

/// Detail screen shimmer (farm detail, profile sections).
class DetailLoadingSkeleton extends StatelessWidget {
  const DetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShineShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonBone(height: 180, radius: 18),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SkeletonBone(height: 64, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBone(height: 64, radius: 14)),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBone(height: 22, width: 160, radius: 8),
          SizedBox(height: 10),
          SkeletonBone(height: 88, radius: 16),
          SizedBox(height: 10),
          SkeletonBone(height: 88, radius: 16),
          SizedBox(height: 10),
          SkeletonBone(height: 88, radius: 16),
          SizedBox(height: 14),
          SkeletonBone(height: 48, radius: 14),
        ],
      ),
    );
  }
}

/// Profile / settings style shimmer.
class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShineShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Center(
            child: SkeletonBone(height: 88, width: 88, radius: 44),
          ),
          SizedBox(height: 16),
          Center(child: SkeletonBone(height: 18, width: 160, radius: 8)),
          SizedBox(height: 8),
          Center(child: SkeletonBone(height: 14, width: 100, radius: 8)),
          SizedBox(height: 20),
          SkeletonBone(height: 72, radius: 16),
          SizedBox(height: 10),
          SkeletonBone(height: 72, radius: 16),
          SizedBox(height: 10),
          SkeletonBone(height: 72, radius: 16),
          SizedBox(height: 10),
          SkeletonBone(height: 120, radius: 16),
        ],
      ),
    );
  }
}

/// Small inline progress used when refreshing without hiding content.
class SoftRefreshBar extends StatelessWidget {
  const SoftRefreshBar({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return ShineShimmer(
      child: Container(
        height: 3,
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class PulseLoader extends StatelessWidget {
  const PulseLoader({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.primary,
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({
    this.height = 96,
    this.showAvatar = true,
  });

  final double height;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            const SkeletonBone(height: 48, width: 48, radius: 14),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBone(height: 14, width: 160, radius: 7),
                SizedBox(height: 8),
                SkeletonBone(height: 12, width: 220, radius: 6),
                SizedBox(height: 8),
                SkeletonBone(height: 10, width: 100, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
