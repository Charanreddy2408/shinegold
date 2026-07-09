import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/location_coords.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/farm_card.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/ux_components.dart';

class FarmsScreen extends ConsumerStatefulWidget {
  const FarmsScreen({super.key});

  @override
  ConsumerState<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends ConsumerState<FarmsScreen> {
  final _searchController = TextEditingController();
  FarmFilter _filter = const FarmFilter();
  List<Farm> _farms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationProvider.notifier).requestLocation();
      if (mounted) _loadFarms();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _loadFarms();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = ref.read(locationProvider);
      final user = ref.read(currentUserProvider);
      final coords = resolveLocationCoords(
        devicePosition: loc.position,
        user: user,
      );
      var filter = _filter.copyWith(search: _searchController.text);
      if (user?.role == UserRole.executive) {
        filter = filter.copyWith(assignedExecutiveId: user!.id);
      }
      final farms = await ref.read(farmRepositoryProvider).getFarms(
            filter,
            userLat: coords.latitude,
            userLng: coords.longitude,
          );
      if (mounted) {
        setState(() {
          _farms = farms;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _formatError(e);
        });
      }
    }
  }

  String _formatError(Object e) => formatApiError(e);

  void _setQuickFilter(QuickFarmFilter? filter) {
    setState(() {
      _filter = _filter.copyWith(
        quickFilter: filter,
        clearQuickFilter: filter == null,
      );
    });
    _loadFarms();
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Filters',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() => _filter = const FarmFilter());
                        },
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOrder.values.map((s) {
                      return FilterChip(
                        label: Text(_sortLabel(s)),
                        selected: _filter.sortOrder == s,
                        onSelected: (_) {
                          setModalState(() {
                            _filter = _filter.copyWith(sortOrder: s);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _loadFarms();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _sortLabel(SortOrder s) {
    switch (s) {
      case SortOrder.nearbyToFarthest:
        return 'Nearby first';
      case SortOrder.farthestToNearby:
        return 'Farthest first';
      case SortOrder.nameAsc:
        return 'Name A-Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final user = ref.watch(currentUserProvider);
    final coords = resolveLocationCoords(
      devicePosition: loc.position,
      user: user,
    );
    final showLocationBanner =
        !loc.loading && loc.error != null && !coords.hasCoords;

    return AppBackground(
      header: GradientHeader(
        title: 'Farms',
        subtitle: _loading ? 'Loading...' : '${_farms.length} assigned farms',
        compact: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLocationBanner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FriendlyErrorBanner(
                message: loc.error!,
                icon: Icons.location_off_outlined,
                onRetry: () async {
                  await ref.read(locationProvider.notifier).requestLocation();
                  if (mounted) _loadFarms();
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ShineSearchBar(
              controller: _searchController,
              hint: 'Search farm, farmer, mobile...',
              onFilterTap: _showFilters,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: QuickFarmFilter.values.map((f) {
                final selected = _filter.quickFilter == f ||
                    (f == QuickFarmFilter.all && _filter.quickFilter == null);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => _setQuickFilter(
                      f == QuickFarmFilter.all ? null : f,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const ListLoadingSkeleton()
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: FriendlyErrorBanner(
                          message: _error!,
                          onRetry: _loadFarms,
                        ),
                      )
                    : _farms.isEmpty
                        ? ShineEmptyState(
                            icon: Icons.eco_outlined,
                            title: 'No farms found',
                            subtitle: 'Try adjusting your search or filters',
                            action: ShineSecondaryButton(
                              label: 'Clear Filters',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = const FarmFilter());
                                _loadFarms();
                              },
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFarms,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              addRepaintBoundaries: true,
                              itemCount: _farms.length,
                              itemBuilder: (context, index) {
                                return FarmCard(
                                  farm: _farms[index],
                                  index: index,
                                  onTap: () => context.push(
                                    AppRoutes.farmDetail.replaceFirst(
                                      ':id',
                                      _farms[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
