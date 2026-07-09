import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/farm_card.dart';
import '../../../shared/widgets/shine_empty_state.dart';

class AdminFarmsScreen extends ConsumerStatefulWidget {
  const AdminFarmsScreen({super.key});

  @override
  ConsumerState<AdminFarmsScreen> createState() => _AdminFarmsScreenState();
}

class _AdminFarmsScreenState extends ConsumerState<AdminFarmsScreen> {
  final _searchController = TextEditingController();
  List<Farm> _farms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).requestLocation();
      _load();
    });
    _searchController.addListener(_load);
  }

  @override
  void dispose() {
    _searchController.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loc = ref.read(locationProvider);
    final farms = await ref.read(farmRepositoryProvider).getFarms(
          FarmFilter(search: _searchController.text),
          userLat: loc.position?.latitude,
          userLng: loc.position?.longitude,
        );
    if (mounted) {
      setState(() {
        _farms = farms;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      header: GradientHeader(
        title: 'All Farms',
        subtitle: _loading ? 'Loading...' : '${_farms.length} farms total',
        compact: true,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ShineSearchBar(
              controller: _searchController,
              hint: 'Search farms...',
            ),
          ),
          Expanded(
            child: _loading
                ? const ListLoadingSkeleton()
                : _farms.isEmpty
                    ? const ShineEmptyState(
                        icon: Icons.eco_outlined,
                        title: 'No farms found',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          addRepaintBoundaries: true,
                          itemCount: _farms.length,
                          itemBuilder: (context, index) {
                            return StaggeredListItem(
                              index: index,
                              child: FarmCard(
                                farm: _farms[index],
                                index: index,
                                onTap: () => context.push(
                                  AppRoutes.farmDetail.replaceFirst(
                                    ':id',
                                    _farms[index].id,
                                  ),
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
