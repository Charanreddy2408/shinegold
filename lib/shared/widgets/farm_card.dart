import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../../data/models/farm.dart';
import 'status_chip.dart';
import 'ux_components.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({
    super.key,
    required this.farm,
    required this.onTap,
    this.index = 0,
  });

  final Farm farm;
  final VoidCallback onTap;
  final int index;

  Color get _accentColor {
    switch (farm.healthStatus) {
      case FarmHealthStatus.healthy:
        return AppColors.secondary;
      case FarmHealthStatus.needsWater:
      case FarmHealthStatus.needsAttention:
        return AppColors.warning;
      case FarmHealthStatus.critical:
      case FarmHealthStatus.urgentVisit:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            splashColor: AppColors.primarySoft.withValues(alpha: 0.4),
            child: Ink(
              decoration: AppColors.cardDecoration(),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppColors.cardRadius),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Icon(
                                Icons.agriculture_rounded,
                                color: _accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farm.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    farm.location.isNotEmpty
                                        ? farm.location
                                        : (farm.farmer.name != '—'
                                            ? farm.farmer.name
                                            : farm.crop),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (farm.totalAcres > 0 ||
                                      (farm.onboardedByName != null &&
                                          farm.onboardedByName!.isNotEmpty)) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (farm.totalAcres > 0)
                                          '${farm.totalAcres == farm.totalAcres.roundToDouble() ? farm.totalAcres.toInt() : farm.totalAcres.toStringAsFixed(1)} ac',
                                        if (farm.onboardedByName != null &&
                                            farm.onboardedByName!.isNotEmpty)
                                          'Onboarded by ${farm.onboardedByName}',
                                      ].join(' · '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (farm.assignedExecutives.isNotEmpty ||
                                      farm.assignedExecutiveName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      farm.assignedExecutives.length > 1
                                          ? 'Assigned: ${farm.assignedExecutives.map((e) => e.name).join(', ')}'
                                          : 'Assigned: ${farm.assignedExecutiveName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (farm.hasHarvestDate) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft
                                            .withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.event_rounded,
                                            size: 14,
                                            color: AppColors.primaryDark,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              farm.harvestType.isNotEmpty
                                                  ? 'Harvest ${dateFormat.format(farm.harvestDate)} · ${farm.harvestType}'
                                                  : 'Harvest ${dateFormat.format(farm.harvestDate)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors.primaryDark,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      HealthBadge(status: farm.healthStatus),
                                      const Spacer(),
                                      StatusChip(status: farm.status),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      if (farm.distanceKm != null) ...[
                                        Icon(
                                          Icons.near_me_rounded,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${farm.distanceKm!.toStringAsFixed(1)} km',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                      ],
                                      Expanded(
                                        child: Text(
                                          farm.nextVisitAvailabilityLabel ??
                                              (farm.lastVisited != null
                                                  ? 'Last visit: ${dateFormat.format(farm.lastVisited!)}'
                                                  : 'Not visited yet'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: farm.isInVisitCooldown
                                                    ? AppColors.warning
                                                    : null,
                                                fontWeight: farm.isInVisitCooldown
                                                    ? FontWeight.w600
                                                    : null,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
