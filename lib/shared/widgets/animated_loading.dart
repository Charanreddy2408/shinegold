import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
  const PulseLoader({super.key, this.size = 32, this.color = AppColors.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    );
  }
}

/// Timer-driven notice for operations that can legitimately take a while
/// (PDF export, offline sync, a cold-starting backend). Callers just flip
/// [active] on their existing loading bool — once it's stayed true past
/// [threshold] this swaps in reassuring copy instead of leaving the user
/// staring at a spinner that looks stuck.
class SlowOperationNotice extends StatefulWidget {
  const SlowOperationNotice({
    super.key,
    required this.active,
    this.threshold = const Duration(seconds: 5),
    this.message = 'This may take a few minutes…',
    this.icon = Icons.hourglass_top_rounded,
  });

  final bool active;
  final Duration threshold;
  final String message;
  final IconData icon;

  @override
  State<SlowOperationNotice> createState() => _SlowOperationNoticeState();
}

class _SlowOperationNoticeState extends State<SlowOperationNotice> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _arm();
  }

  @override
  void didUpdateWidget(covariant SlowOperationNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _arm();
    } else if (!widget.active && oldWidget.active) {
      _timer?.cancel();
      if (_slow) setState(() => _slow = false);
    }
  }

  void _arm() {
    _timer?.cancel();
    _slow = false;
    _timer = Timer(widget.threshold, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _slow
          ? Padding(
              key: const ValueKey('slow'),
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('idle')),
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
