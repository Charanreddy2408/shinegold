import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/async_ui.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/farm_card.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/widgets/shine_empty_state.dart';

class AdminFarmsScreen extends ConsumerStatefulWidget {
  const AdminFarmsScreen({super.key});

  @override
  ConsumerState<AdminFarmsScreen> createState() => _AdminFarmsScreenState();
}

class _AdminFarmsScreenState extends ConsumerState<AdminFarmsScreen> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debouncer();
  final _loadGen = LoadGeneration();
  List<Farm> _farms = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationProvider.notifier).requestLocation();
      if (!mounted) return;
      await _load(isRefresh: false);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce.run(() => _load(isRefresh: _farms.isNotEmpty));
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchDebounce.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool isRefresh = true}) async {
    final gen = _loadGen.next();
    if (mounted) {
      setState(() {
        if (_farms.isEmpty) {
          _initialLoading = true;
        } else {
          _refreshing = true;
        }
        _error = null;
      });
    }
    try {
      final loc = ref.read(locationProvider);
      final farms = await ref.read(farmRepositoryProvider).getFarms(
            FarmFilter(search: _searchController.text),
            userLat: loc.position?.latitude,
            userLng: loc.position?.longitude,
          );
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _farms = farms;
        _initialLoading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _initialLoading = false;
        _refreshing = false;
        _error = formatApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        _load(isRefresh: true);
      }
    });
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.position == null && next.position != null) {
        _load(isRefresh: _farms.isNotEmpty);
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCreateFarm),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Create Farm'),
      ),
      body: AppBackground(
        header: GradientHeader(
          title: 'All Farms',
          subtitle: _initialLoading
              ? 'Loading...'
              : '${_farms.length} farms total',
          compact: true,
        ),
        child: Column(
          children: [
            SoftRefreshBar(visible: _refreshing),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ShineSearchBar(
                controller: _searchController,
                hint: 'Search farms...',
              ),
            ),
            Expanded(
              child: _initialLoading
                  ? const ListLoadingSkeleton()
                  : _error != null && _farms.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: FriendlyErrorBanner(
                              message: _error!,
                              onRetry: () => _load(isRefresh: false),
                            ),
                          ),
                        )
                      : _farms.isEmpty
                          ? const ShineEmptyState(
                              icon: Icons.eco_outlined,
                              title: 'No farms found',
                            )
                          : RefreshIndicator(
                              onRefresh: () => _load(isRefresh: true),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemCount: _farms.length,
                                itemBuilder: (context, index) {
                                  final farm = _farms[index];
                                  return StaggeredListItem(
                                    key: ValueKey(farm.id),
                                    index: index,
                                    child: FarmCard(
                                      farm: farm,
                                      index: index,
                                      onTap: () => context.push(
                                        AppRoutes.farmDetail.replaceFirst(
                                          ':id',
                                          farm.id,
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
      ),
    );
  }
}
