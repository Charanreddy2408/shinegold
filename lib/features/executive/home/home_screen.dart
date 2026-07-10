import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/location_coords.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/dashboard_overview.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Farm> _todayFarms = [];
  int _total = 0;
  int _visited = 0;
  int _pending = 0;
  int _upcoming = 0;
  bool _loading = true;
  String? _error;
  String _firstName = '';
  DateTime _dashboardDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _firstName =
        ref.read(currentUserProvider)?.name.split(' ').first ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
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
          ? dashboard.greetingName.split(' ').first
          : user?.name.split(' ').first ?? '';
      setState(() {
        _firstName = greeting;
        _dashboardDate = dashboard.dashboardDate;
        _total = dashboard.totalFarms;
        _visited = dashboard.visitedCount;
        _pending = dashboard.pendingCount;
        _upcoming = dashboard.harvestSoonCount;
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) _load();
    });

    final dateStr = DateFormat('EEEE, dd MMM').format(_dashboardDate);

    return AppBackground(
      header: GradientHeader(
        subtitle: dateStr,
        title: _firstName,
        trailing: Text(
          _greeting(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: FriendlyErrorBanner(message: _error!, onRetry: _load),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    DashboardOverviewCard(
                      totalFarms: _total,
                      completed: _visited,
                      pending: _pending,
                      harvestSoon: _upcoming,
                    ),
                    if (_todayFarms.isNotEmpty) ...[
                      SectionHeader(
                        label: 'PRIORITY',
                        title: 'Farms for today',
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
                                          : 'Tap to view details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
