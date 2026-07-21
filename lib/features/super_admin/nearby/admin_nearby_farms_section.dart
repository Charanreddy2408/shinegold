import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/admin_nearby_farms_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/farm_card.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/ux_components.dart';

/// Dashboard section — farms within 5 km, auto-refreshed every 3 minutes.
class AdminNearbyFarmsSection extends ConsumerWidget {
  const AdminNearbyFarmsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(adminNearbyFarmsProvider);
    final location = ref.watch(locationProvider);
    final timeFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.info,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farms Near You',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Within ${AdminNearbyConfig.radiusKm.toStringAsFixed(0)} km · updates every 3 min',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (nearby.loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: 'Refresh now',
                      onPressed: () =>
                          ref.read(adminNearbyFarmsProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LocationStatusRow(
                location: location,
                lastRefresh: nearby.lastRefresh,
                timeFormat: timeFormat,
                usingHomeLocation: nearby.usingHomeLocation,
              ),
            ),
            const SizedBox(height: 12),
            if (nearby.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FriendlyErrorBanner(
                  message: nearby.error!,
                  icon: nearby.error!.toLowerCase().contains('location')
                      ? Icons.location_off_outlined
                      : Icons.error_outline_rounded,
                  onRetry: () =>
                      ref.read(adminNearbyFarmsProvider.notifier).refresh(),
                ),
              )
            else if (nearby.farms.isEmpty && !nearby.loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  nearby.closestOutsideKm == null
                      ? 'No farms within ${AdminNearbyConfig.radiusKm.toStringAsFixed(0)} km of your current location.'
                      : 'No farms within ${AdminNearbyConfig.radiusKm.toStringAsFixed(0)} km. Closest farm is ${nearby.closestOutsideKm!.toStringAsFixed(1)} km away.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ...nearby.farms.take(3).map(
                    (farm) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _CompactNearbyFarmTile(
                        farm: farm,
                        onTap: () => context.push(
                          AppRoutes.farmDetail.replaceFirst(':id', farm.id),
                        ),
                      ),
                    ),
                  ),
            if (nearby.farms.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      adminPageRoute(const AdminNearbyFarmsScreen()),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: Text('View all ${nearby.farms.length} nearby farms'),
                ),
              )
            else if (nearby.farms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      adminPageRoute(const AdminNearbyFarmsScreen()),
                    );
                  },
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  label: const Text('Open full map list'),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class AdminNearbyFarmsScreen extends ConsumerWidget {
  const AdminNearbyFarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(adminNearbyFarmsProvider);
    final location = ref.watch(locationProvider);
    final timeFormat = DateFormat('dd MMM · hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: 'Nearby Farms',
          subtitle:
              'Within ${AdminNearbyConfig.radiusKm.toStringAsFixed(0)} km radius',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          trailing: IconButton(
            onPressed: () =>
                ref.read(adminNearbyFarmsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _LocationStatusRow(
                location: location,
                lastRefresh: nearby.lastRefresh,
                timeFormat: timeFormat,
                expanded: true,
                usingHomeLocation: nearby.usingHomeLocation,
              ),
            ),
            Expanded(
              child: nearby.loading && nearby.farms.isEmpty
                  ? const ListLoadingSkeleton()
                  : nearby.error != null && nearby.farms.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: FriendlyErrorBanner(
                            message: nearby.error!,
                            onRetry: () => ref
                                .read(adminNearbyFarmsProvider.notifier)
                                .refresh(),
                          ),
                        )
                      : nearby.farms.isEmpty
                          ? ShineEmptyState(
                              icon: Icons.explore_off_rounded,
                              title: 'No farms nearby',
                              subtitle: nearby.closestOutsideKm == null
                                  ? 'No farms found near your current position yet.'
                                  : 'Closest farm is ${nearby.closestOutsideKm!.toStringAsFixed(1)} km away (outside the ${AdminNearbyConfig.radiusKm.toStringAsFixed(0)} km radius).',
                              action: FilledButton.icon(
                                onPressed: () => ref
                                    .read(adminNearbyFarmsProvider.notifier)
                                    .refresh(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh nearby'),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(adminNearbyFarmsProvider.notifier)
                                  .refresh(),
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: nearby.farms.length,
                                itemBuilder: (context, index) {
                                  final farm = nearby.farms[index];
                                  return FarmCard(
                                    farm: farm,
                                    index: index,
                                    onTap: () => context.push(
                                      AppRoutes.farmDetail.replaceFirst(
                                        ':id',
                                        farm.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStatusRow extends StatelessWidget {
  const _LocationStatusRow({
    required this.location,
    required this.lastRefresh,
    required this.timeFormat,
    this.expanded = false,
    this.usingHomeLocation = false,
  });

  final LocationState location;
  final DateTime? lastRefresh;
  final DateFormat timeFormat;
  final bool expanded;
  final bool usingHomeLocation;

  @override
  Widget build(BuildContext context) {
    final hasFix = location.hasFix;
    final waiting = location.loading && !hasFix;
    final statusColor = hasFix
        ? AppColors.success
        : usingHomeLocation
            ? AppColors.info
            : waiting
                ? AppColors.info
                : AppColors.warning;
    final statusLabel = hasFix
        ? 'Location active'
        : usingHomeLocation
            ? 'Using your home location'
            : waiting
                ? 'Getting location…'
                : location.permissionGranted
                    ? 'Waiting for GPS fix'
                    : 'Location needed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            hasFix
                ? Icons.gps_fixed_rounded
                : usingHomeLocation
                    ? Icons.home_rounded
                    : waiting
                        ? Icons.gps_not_fixed_rounded
                        : Icons.gps_off_rounded,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                ),
                if (expanded && location.position != null)
                  Text(
                    'Lat ${location.position!.latitude.toStringAsFixed(4)}, '
                    'Lng ${location.position!.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                if (lastRefresh != null)
                  Text(
                    'Updated ${timeFormat.format(lastRefresh!.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Live',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactNearbyFarmTile extends StatelessWidget {
  const _CompactNearbyFarmTile({
    required this.farm,
    required this.onTap,
  });

  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvasDeep,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      farm.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              if (farm.distanceKm != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${farm.distanceKm!.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
