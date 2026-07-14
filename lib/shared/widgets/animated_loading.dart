import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight loaders — static placeholders (no continuous shimmer).
class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _Bone(height: 88, radius: 18),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Bone(height: 72, radius: 14)),
            SizedBox(width: 10),
            Expanded(child: _Bone(height: 72, radius: 14)),
          ],
        ),
        SizedBox(height: 12),
        _Bone(height: 220, radius: 18),
        SizedBox(height: 12),
        _Bone(height: 96, radius: 16),
        SizedBox(height: 10),
        _Bone(height: 96, radius: 16),
      ],
    );
  }
}

class ListLoadingSkeleton extends StatelessWidget {
  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 96,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _Bone(height: itemHeight, radius: 16),
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
    return const LinearProgressIndicator(
      minHeight: 2.5,
      color: AppColors.primary,
      backgroundColor: AppColors.primarySoft,
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

class _Bone extends StatelessWidget {
  const _Bone({required this.height, this.radius = 12});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.canvasDeep,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderSubtle),
      ),
    );
  }
}
