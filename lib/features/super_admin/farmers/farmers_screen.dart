import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/list_search.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/gold_shimmer.dart';
import '../../../shared/widgets/shine_empty_state.dart';

class FarmersScreen extends ConsumerStatefulWidget {
  const FarmersScreen({super.key});

  @override
  ConsumerState<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends ConsumerState<FarmersScreen> {
  final _searchController = TextEditingController();
  List<FarmerWithFarms> _farmers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FarmerWithFarms> get _filtered => _farmers.where((item) {
        final farmer = item.farmer;
        final farmFields = item.farms.expand(
          (f) => [f.name, f.location, f.crop],
        );
        return matchesListSearch(_searchController.text, [
          farmer.name,
          farmer.mobile,
          ...farmFields,
        ]);
      }).toList();

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ref.read(farmerRepositoryProvider).list();
    if (mounted) {
      setState(() {
        _farmers = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: 'Farmers',
          subtitle: _loading
              ? 'Loading...'
              : '${filtered.length} of ${_farmers.length} farmers',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        child: Column(
          children: [
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: ShineSearchBar(
                  controller: _searchController,
                  hint: 'Search farmers, farms, or location...',
                ),
              ),
            Expanded(
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 72),
                      ),
                    )
                  : filtered.isEmpty
                      ? ShineEmptyState(
                          icon: Icons.search_off_rounded,
                          title: _searchController.text.isEmpty
                              ? 'No farmers'
                              : 'No matches',
                          subtitle: _searchController.text.isEmpty
                              ? 'Onboarded farmers will appear here'
                              : 'Try a different search term',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final farmer = item.farmer;
                              return StaggeredListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FarmerExpansionTile(
                                    farmerName: farmer.name,
                                    mobile: farmer.mobile,
                                    farms: item.farms,
                                    index: index,
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

class _FarmerExpansionTile extends StatelessWidget {
  const _FarmerExpansionTile({
    required this.farmerName,
    required this.mobile,
    required this.farms,
    required this.index,
  });

  final String farmerName;
  final String mobile;
  final List<Farm> farms;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.18),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          title: Text(
            farmerName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(mobile),
          children: farms
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              f.location,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms)
        .slideX(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
        );
  }
}
