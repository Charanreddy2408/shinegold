import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/fade_slide_in.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/admin_farm_map.dart';
import '../../../shared/widgets/admin_network_hero.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../executives/admin_executive_profile_screen.dart';
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DashboardFilter _filter = DashboardFilter.all;
  dynamic _stats;
  List<Executive> _executives = [];
  List<Farm> _farms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dashboard = ref.read(dashboardRepositoryProvider);
    final executiveRepo = ref.read(executiveRepositoryProvider);
    final farmRepo = ref.read(farmRepositoryProvider);
    final results = await Future.wait([
      dashboard.getStats(_filter),
      executiveRepo.list(),
      farmRepo.getFarms(const FarmFilter()),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0];
        _executives = results[1] as List<Executive>;
        _farms = results[2] as List<Farm>;
        _loading = false;
      });
    }
  }

  void _openExecutive(Executive exec) {
    Navigator.of(context).push(
      adminPageRoute(AdminExecutiveProfileScreen(executive: exec)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      header: GradientHeader(
        title: 'Dashboard',
        subtitle: 'Shine Gold overview',
        trailing: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insights_rounded, color: Colors.white),
        ),
      ),
      child: _loading
          ? const DashboardLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminNetworkHero(
                      totalVisits: _stats.totalVisits,
                      totalFarms: _stats.totalFarms,
                      totalExecutives: _stats.totalExecutives,
                      farmersOnboarded: _stats.farmersOnboarded,
                      filter: _filter,
                      onFilterChanged: (f) {
                        setState(() => _filter = f);
                        _load();
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminIndiaFarmMap(
                      key: ValueKey('admin-dashboard-india-map-${_farms.length}'),
                      farms: _farms,
                      height: 280,
                      onFarmTap: (farm) => context.push(
                        AppRoutes.farmDetail.replaceFirst(':id', farm.id),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: FadeSlideIn(
                        child: Text(
                          'Operations',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            AdminMetricRow(
                              icon: Icons.eco_outlined,
                              label: 'REGISTERED FARMS',
                              value: '${_stats.totalFarms}',
                              subtitle: 'Active farms in the network',
                              color: AppColors.secondary,
                              progress: _stats.totalFarms > 0 ? 0.72 : 0,
                            ),
                            AdminMetricRow(
                              icon: Icons.people_outline,
                              label: 'FIELD EXECUTIVES',
                              value: '${_stats.totalExecutives}',
                              subtitle: 'Team members on ground',
                              color: AppColors.primary,
                              progress: _stats.totalExecutives > 0 ? 0.55 : 0,
                            ),
                            AdminMetricRow(
                              icon: Icons.history_rounded,
                              label: 'VISITS LOGGED',
                              value: '${_stats.totalVisits}',
                              subtitle: 'Completed & ongoing visits',
                              color: AppColors.info,
                              progress: _stats.totalVisits > 0 ? 0.68 : 0,
                            ),
                            AdminMetricRow(
                              icon: Icons.agriculture_rounded,
                              label: 'FARMERS ONBOARDED',
                              value: '${_stats.farmersOnboarded}',
                              subtitle: 'New farmers this season',
                              color: AppColors.secondarySoft,
                              progress:
                                  _stats.farmersOnboarded > 0 ? 0.45 : 0,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Field Team',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${_executives.length} members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 118,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _executives.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final exec = _executives[index];
                          return StaggeredListItem(
                            index: index,
                            child: _TeamMemberChip(
                              executive: exec,
                              onTap: () => _openExecutive(exec),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

class _TeamMemberChip extends StatelessWidget {
  const _TeamMemberChip({
    required this.executive,
    required this.onTap,
  });

  final Executive executive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = executive.profilePhotoUrl ??
        'https://i.pravatar.cc/150?u=${executive.employeeId}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: CachedNetworkImageProvider(photo),
            ),
            const SizedBox(height: 5),
            Text(
              executive.name.split(' ').first,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${executive.totalVisits} visits',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    height: 1.1,
                  ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
