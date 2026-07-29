import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/location_coords.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dashboard_overview.dart';
import '../../../shared/widgets/greeting_header.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/utils/acres_format.dart';
import '../../../shared/utils/l10n_ext.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Farm> _todayFarms = [];
  List<OnboardedFarmSummary> _onboardedFarms = [];
  int _total = 0;
  int _visited = 0;
  int _pending = 0;
  int _upcoming = 0;
  int _onboardedCount = 0;
  double _onboardedAcres = 0;
  bool _loading = true;
  String? _error;
  String _displayName = '';
  DateTime _dashboardDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _displayName = ref.read(currentUserProvider)?.name ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard =
          await ref.read(dashboardRepositoryProvider).getExecutiveDashboard();
      final user = ref.read(currentUserProvider);
      var priorityFarms = dashboard.priorityFarms;
      if (priorityFarms.isEmpty && user != null) {
        try {
          final coords = resolveLocationCoords(
            devicePosition: ref.read(locationProvider).position,
            user: user,
          );
          priorityFarms = (await ref.read(farmRepositoryProvider).getFarms(
                const FarmFilter(
                  quickFilter: QuickFarmFilter.pending,
                  sortOrder: SortOrder.nameAsc,
                ),
                userLat: coords.latitude,
                userLng: coords.longitude,
              ))
              .take(3)
              .toList();
        } catch (_) {
          // Dashboard loaded; priority farms are optional.
        }
      }
      if (!mounted) return;
      final greeting = dashboard.greetingName.isNotEmpty
          ? dashboard.greetingName
          : user?.name ?? '';
      setState(() {
        _displayName = greeting;
        _dashboardDate = dashboard.dashboardDate;
        _total = dashboard.totalFarms;
        _visited = dashboard.visitedCount;
        _pending = dashboard.pendingCount;
        _upcoming = dashboard.harvestSoonCount;
        _onboardedCount = dashboard.onboardedFarmsCount;
        _onboardedAcres = dashboard.onboardedAcresTotal;
        _onboardedFarms = dashboard.onboardedFarms;
        _todayFarms = priorityFarms;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatApiError(e);
      });
    }
  }

  String _formatAcres(double acres) => formatAcres(acres);

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) _load();
    });

    return AppBackground(
      header: BrandGreetingHeader(
        name: _displayName,
        date: _dashboardDate,
      ),
      child: _loading
          ? const DashboardLoadingSkeleton()
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: FriendlyErrorBanner(message: _error!, onRetry: _load),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      DashboardOverviewCard(
                        onboardedCount: _onboardedCount,
                        onboardedAcres: _onboardedAcres,
                        pendingVisits: _pending,
                        completedVisits: _visited,
                        harvestSoon: _upcoming,
                        assignedFarms: _total,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          0,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                context.push(AppRoutes.interactions),
                            borderRadius:
                                BorderRadius.circular(AppColors.cardRadius),
                            child: Ink(
                              decoration: AppColors.cardDecoration(),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.forum_rounded,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(context.l10n.interactions,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          SizedBox(height: 2),
                                          Text(context.l10n.recordConversations,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SectionHeader(
                        label: context.l10n.onboarded,
                        title: context.l10n.farmsYouOnboarded,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryMuted,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Text(
                            '$_onboardedCount · ${_formatAcres(_onboardedAcres)} ac',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                      if (_onboardedFarms.isEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ShineEmptyState(
                            icon: Icons.add_business_outlined,
                            title: context.l10n.noFarmsOnboardedYet,
                            subtitle: context.l10n.farmsFromOnboardTab,
                          ),
                        )
                      else ...[
                        const OnboardedFarmsTableHeader(),
                        ..._onboardedFarms.take(8).map(
                              (farm) => OnboardedFarmTableRow(
                                farmName: farm.farmName,
                                acres: farm.totalAcres,
                                crop: farm.crop,
                                onTap: () => context.push(
                                  AppRoutes.farmDetail.replaceFirst(
                                    ':id',
                                    farm.farmId,
                                  ),
                                ),
                              ),
                            ),
                        if (_onboardedCount > 8)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              context.l10n.moreOnboardedFarms(_onboardedCount - 8),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                      ],
                      if (_todayFarms.isEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: ShineEmptyState(
                            icon: Icons.eco_outlined,
                            title: context.l10n.noPriorityFarms,
                            subtitle: context.l10n.pendingVisitsToday,
                          ),
                        )
                      else ...[
                        SectionHeader(
                          label: context.l10n.farmsForToday,
                          title: context.l10n.farmsForToday,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            child: Text(
                              '${_todayFarms.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        ..._todayFarms.map(_farmTile),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _farmTile(Farm farm) {
    final accent = _brandAccent(farm.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.farmDetail.replaceFirst(':id', farm.id),
          ),
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          child: Ink(
            decoration: AppColors.cardDecoration(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppColors.cardRadius),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(Icons.eco_rounded, color: accent, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  farm.crop.isNotEmpty
                                      ? '${farm.crop} · ${farm.location}'
                                      : farm.location.isNotEmpty
                                          ? farm.location
                                          : context.l10n.tapToViewDetails,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (farm.hasHarvestDate) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Harvest ${DateFormat('dd MMM yyyy').format(farm.harvestDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                StatusChip(status: farm.status),
                              ],
                            ),
                          ),
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
    );
  }

  Color _brandAccent(FarmVisitStatus status) {
    switch (status) {
      case FarmVisitStatus.pending:
        return AppColors.primary;
      case FarmVisitStatus.ongoing:
        return AppColors.secondarySoft;
      case FarmVisitStatus.visited:
        return AppColors.secondary;
      case FarmVisitStatus.harvested:
        return AppColors.fieldGreen;
      case FarmVisitStatus.blocked:
        return AppColors.primaryDark;
    }
  }
}
