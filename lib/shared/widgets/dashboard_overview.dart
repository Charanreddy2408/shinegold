import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class DashboardOverviewCard extends StatelessWidget {
  const DashboardOverviewCard({
    super.key,
    required this.onboardedCount,
    required this.onboardedAcres,
    required this.pendingVisits,
    required this.completedVisits,
    required this.harvestSoon,
    this.assignedFarms = 0,
  });

  final int onboardedCount;
  final double onboardedAcres;
  final int pendingVisits;
  final int completedVisits;
  final int harvestSoon;
  final int assignedFarms;

  String _formatAcres(double acres) {
    if (acres <= 0) return '0';
    if (acres == acres.roundToDouble()) {
      return acres.toInt().toString();
    }
    return acres.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: AppColors.cardDecoration(radius: AppSpacing.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR COVERAGE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAcres(onboardedAcres),
                      style: AppTypography.statNumber.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'acres',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  onboardedCount == 1
                      ? 'Across 1 farm you onboarded'
                      : 'Across $onboardedCount farms you onboarded',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field activity',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _MetricTile(
                      icon: Icons.add_business_outlined,
                      value: '$onboardedCount',
                      label: 'Onboarded',
                      color: AppColors.secondary,
                      background: AppColors.secondaryMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricTile(
                      icon: Icons.pending_actions_outlined,
                      value: '$pendingVisits',
                      label: 'Pending',
                      color: AppColors.primaryDark,
                      background: AppColors.primarySoft,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricTile(
                      icon: Icons.check_circle_outline_rounded,
                      value: '$completedVisits',
                      label: 'Visits',
                      color: AppColors.info,
                      background: const Color(0xFFE3F2FD),
                    ),
                  ],
                ),
                if (assignedFarms > 0 || harvestSoon > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (assignedFarms > 0)
                        Expanded(
                          child: _InlineStat(
                            icon: Icons.map_outlined,
                            label: 'Assigned farms',
                            value: '$assignedFarms',
                          ),
                        ),
                      if (assignedFarms > 0 && harvestSoon > 0)
                        const SizedBox(width: AppSpacing.sm),
                      if (harvestSoon > 0)
                        Expanded(
                          child: _InlineStat(
                            icon: Icons.calendar_month_outlined,
                            label: 'Harvest soon',
                            value: '$harvestSoon',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact table header for onboarded-farm lists on the dashboard.
class OnboardedFarmsTableHeader extends StatelessWidget {
  const OnboardedFarmsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Farm', style: style)),
          Expanded(child: Text('Acres', style: style, textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text('Crop', style: style)),
        ],
      ),
    );
  }
}

/// Row for an onboarded farm on the executive dashboard.
class OnboardedFarmTableRow extends StatelessWidget {
  const OnboardedFarmTableRow({
    super.key,
    required this.farmName,
    required this.acres,
    required this.crop,
    this.onTap,
  });

  final String farmName;
  final double acres;
  final String crop;
  final VoidCallback? onTap;

  String _formatAcres(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      farmName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatAcres(acres),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      crop.isEmpty ? '—' : crop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
