import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/contact_launcher.dart';
import '../../../shared/utils/list_search.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
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
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(farmerRepositoryProvider).list();
      if (mounted) {
        setState(() {
          _farmers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = formatApiError(e);
        });
      }
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
                  ? const ListLoadingSkeleton(itemCount: 5, itemHeight: 80)
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: FriendlyErrorBanner(
                              message: _error!,
                              onRetry: _load,
                            ),
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
                                  return StaggeredListItem(
                                    index: index,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _FarmerExpansionTile(
                                        farmer: item.farmer,
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

class _FarmerExpansionTile extends ConsumerStatefulWidget {
  const _FarmerExpansionTile({
    required this.farmer,
    required this.index,
  });

  final Farmer farmer;
  final int index;

  @override
  ConsumerState<_FarmerExpansionTile> createState() =>
      _FarmerExpansionTileState();
}

class _FarmerExpansionTileState extends ConsumerState<_FarmerExpansionTile> {
  FarmerWithFarms? _detail;
  bool _loadingDetail = false;
  String? _detailError;

  Future<void> _loadDetail() async {
    if (_detail != null || _loadingDetail) return;
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail =
          await ref.read(farmerRepositoryProvider).getById(widget.farmer.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = formatApiError(e);
      });
    }
  }

  String _genderLabel(Gender? gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case null:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = _detail?.farmer ?? widget.farmer;
    final farms = _detail?.farms ?? const <Farm>[];
    final farmCountLabel = farmer.farmsCount == 1
        ? '1 farm'
        : '${farmer.farmsCount} farms';

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
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (expanded) {
            if (expanded) _loadDetail();
          },
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
            child: farmer.photoUrl != null && farmer.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: farmer.photoUrl!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.agriculture_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.agriculture_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
          ),
          title: Text(
            farmer.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            farmer.mobile.isNotEmpty
                ? '${farmer.mobile} · $farmCountLabel'
                : farmCountLabel,
          ),
          children: [
            if (_loadingDetail)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_detailError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _detailError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              )
            else ...[
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Gender',
                value: _genderLabel(farmer.gender),
              ),
              if (farmer.age != null)
                _DetailRow(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: '${farmer.age} years',
                ),
              if (farmer.aadharNumber != null &&
                  farmer.aadharNumber!.isNotEmpty)
                _DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Aadhar',
                  value: farmer.aadharNumber!,
                ),
              if (farmer.mobile.isNotEmpty) ...[
                const SizedBox(height: 8),
                FarmerContactActions(
                  mobile: farmer.mobile,
                  farmerName: farmer.name,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Linked Farms',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: 8),
              if (farms.isEmpty)
                Text(
                  'No farm linked to this farmer yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                ...farms.map(
                  (farm) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.canvasDeep,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: farm.id.isNotEmpty
                            ? () => context.push(
                                  AppRoutes.farmDetail.replaceFirst(
                                    ':id',
                                    farm.id,
                                  ),
                                )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.eco_rounded,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farm.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      farm.crop.isNotEmpty
                                          ? 'Crop: ${farm.crop}'
                                          : 'Crop not set',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(status: farm.status),
                              if (farm.id.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * widget.index), duration: 350.ms)
        .slideX(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 50 * widget.index),
        );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
