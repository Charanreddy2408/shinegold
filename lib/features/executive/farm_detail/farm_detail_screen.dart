import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/fade_slide_in.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../features/super_admin/farms/admin_farm_assign_sheet.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/farm_map_preview.dart';
import '../../../shared/widgets/info_metric_tile.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/utils/media_url.dart';
import '../../../shared/widgets/visit_log_tile.dart';

class FarmDetailScreen extends ConsumerStatefulWidget {
  const FarmDetailScreen({super.key, required this.farmId});

  final String farmId;

  @override
  ConsumerState<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends ConsumerState<FarmDetailScreen> {
  Farm? _farm;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final farm =
          await ref.read(farmRepositoryProvider).getFarmById(widget.farmId);
      if (mounted) {
        setState(() {
          _farm = farm;
          _loading = false;
          if (farm == null) {
            _error = 'Farm not found.';
          }
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
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) _load();
    });

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.canvasDeep,
        body: const ListLoadingSkeleton(itemCount: 5, itemHeight: 64),
      );
    }

    if (_error != null || _farm == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: FriendlyErrorBanner(message: _error!, onRetry: _load),
        ),
      );
    }

    final farm = _farm!;
    final dateFormat = DateFormat('dd MMM yyyy');
    final farmerPhoto = farm.farmer.photoUrl != null &&
            farm.farmer.photoUrl!.trim().isNotEmpty
        ? resolveMediaUrl(farm.farmer.photoUrl!)
        : null;
    final isExecutive =
        ref.watch(currentUserProvider)?.role == UserRole.executive;
    final isAdmin =
        ref.watch(currentUserProvider)?.role == UserRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: Text(
          farm.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.gradientHeader,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Assign executives',
              onPressed: () async {
                final updated = await showAdminFarmAssignSheet(
                  context,
                  ref,
                  farm,
                );
                if (updated == true) _load();
              },
              icon: const Icon(Icons.group_add_outlined),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          FadeSlideIn(
            child: ShineCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: farmerPhoto != null
                        ? CachedNetworkImageProvider(farmerPhoto)
                        : null,
                    child: farmerPhoto == null
                        ? Text(
                            farm.farmer.name.isNotEmpty
                                ? farm.farmer.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          farm.farmer.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          farm.farmer.mobile,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        StatusChip(status: farm.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Farm Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              InfoMetricTile(
                icon: Icons.grass_rounded,
                label: 'Crop',
                value: farm.crop,
                color: AppColors.secondary,
              ),
              InfoMetricTile(
                icon: Icons.square_foot_rounded,
                label: 'Acres',
                value: '${farm.totalAcres} ac',
                color: AppColors.primary,
              ),
              InfoMetricTile(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: farm.location,
                color: AppColors.info,
              ),
              InfoMetricTile(
                icon: Icons.person_rounded,
                label: farm.assignedExecutives.length > 1
                    ? 'Executives'
                    : 'Executive',
                value: farm.assignedExecutives.length > 1
                    ? farm.assignedExecutives.map((e) => e.name).join(', ')
                    : farm.assignedExecutiveName,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Harvest Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          HarvestInfoRow(
            type: farm.harvestType,
            date: dateFormat.format(farm.harvestDate),
          ),
          const SizedBox(height: 10),
          InfoMetricTile(
            icon: Icons.fact_check_rounded,
            label: 'Harvest Status',
            value: farm.harvestStatus.label,
            color: AppColors.secondary,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          CollapsibleSection(
            title: 'Map',
            icon: Icons.map_outlined,
            initiallyExpanded: false,
            child: FarmMapPreview(
              latitude: farm.latitude,
              longitude: farm.longitude,
              height: 180,
            ),
          ),
          if (farm.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Farm Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: farm.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = resolveMediaUrl(farm.photoUrls[i]);
                  return GestureDetector(
                    onTap: () => showPhotoGallery(
                      context,
                      urls: farm.photoUrls.map(resolveMediaUrl).toList(),
                      initialIndex: i,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 108,
                        height: 108,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 108,
                          height: 108,
                          color: AppColors.surfaceElevated,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 108,
                          height: 108,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          CollapsibleSection(
            title: 'Visit History',
            icon: Icons.history,
            initiallyExpanded: farm.visitLogs.isNotEmpty,
            child: farm.visitLogs.isEmpty
                ? Text(
                    'No visits recorded yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : Column(
                    children: farm.visitLogs
                        .map(
                          (l) => VisitLogTile(
                            log: l,
                            onViewReport: l.id.isNotEmpty
                                ? () => context.push(
                                      AppRoutes.visitDetail.replaceFirst(
                                        ':id',
                                        l.id,
                                      ),
                                    )
                                : null,
                          ),
                        )
                        .toList(),
                  ),
          ),
          SizedBox(height: isExecutive ? 80 : 24),
        ],
      ),
      bottomNavigationBar: isExecutive && farm.status != FarmVisitStatus.visited
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ShinePrimaryButton(
                  label: farm.status == FarmVisitStatus.ongoing
                      ? 'Continue Visit'
                      : 'Start Visit',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () async {
                    final done = await context.push<bool>(
                      AppRoutes.checkin.replaceFirst(':farmId', farm.id),
                    );
                    if (done == true && mounted) _load();
                  },
                ),
              ),
            )
          : null,
    );
  }
}
