import 'dart:async';

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
import '../../../data/models/harvest_date_change.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/services/farm_brief_cache.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/farm_map_preview.dart';
import '../../../shared/widgets/info_metric_tile.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/utils/contact_launcher.dart';
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
  List<HarvestDateChange> _harvestHistory = [];
  bool _loading = true;
  bool _updatingHarvest = false;
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
      if (farm != null) {
        unawaited(
          FarmBriefCache.instance.save(
            id: farm.id,
            name: farm.name,
            latitude: farm.latitude,
            longitude: farm.longitude,
          ),
        );
      }

      List<HarvestDateChange> history = [];
      try {
        history = await ref
            .read(farmRepositoryProvider)
            .getHarvestDateHistory(widget.farmId);
      } catch (_) {
        // History is optional for first paint.
      }

      if (mounted) {
        setState(() {
          _farm = farm;
          _harvestHistory = history;
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

  Future<void> _editHarvestDate() async {
    final farm = _farm;
    if (farm == null || _updatingHarvest) return;

    final reasonController = TextEditingController();
    DateTime selected =
        farm.hasHarvestDate ? farm.harvestDate : DateTime.now();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update harvest date',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    farm.hasHarvestDate
                        ? 'Current: ${DateFormat('dd MMM yyyy').format(farm.harvestDate)}'
                        : 'Current: Not set',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_rounded, color: AppColors.primary),
                    title: Text(DateFormat('dd MMM yyyy').format(selected)),
                    subtitle: const Text('Tap to pick a new date'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selected,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setModalState(() => selected = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Why is the harvest date changing?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShinePrimaryButton(
                    label: 'Save harvest date',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                  const SizedBox(height: 8),
                  ShineSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    final sameDay = farm.hasHarvestDate &&
        selected.year == farm.harvestDate.year &&
        selected.month == farm.harvestDate.month &&
        selected.day == farm.harvestDate.day;
    if (sameDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a different date to save a change'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _updatingHarvest = true);
    try {
      await ref.read(farmRepositoryProvider).updateHarvestDate(
            farm.id,
            harvestDate: selected,
            reason: reason.isEmpty ? null : reason,
          );
      bumpAppRefresh(ref);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harvest date updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingHarvest = false);
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
        body: const DetailLoadingSkeleton(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: farm.farmer.mobile.trim().isEmpty
                                  ? null
                                  : () => ContactLauncher.callOrSnack(
                                        context,
                                        farm.farmer.mobile,
                                      ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      farm.farmer.mobile.isEmpty
                                          ? 'No mobile number'
                                          : farm.farmer.mobile,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (farm.farmer.aadharNumber != null &&
                                farm.farmer.aadharNumber!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Aadhar: ${farm.farmer.aadharNumber}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                            const SizedBox(height: 8),
                            StatusChip(status: farm.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (farm.farmer.mobile.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FarmerContactActions(
                      mobile: farm.farmer.mobile,
                      farmerName: farm.farmer.name,
                    ),
                  ],
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
                icon: Icons.spa_rounded,
                label: 'Plants',
                value: farm.plantCount != null ? '${farm.plantCount}' : '—',
                color: AppColors.secondary,
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
          ShineCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SET HARVEST DATE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            farm.hasHarvestDate
                                ? dateFormat.format(farm.harvestDate)
                                : 'Not set',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InfoMetricTile(
                        icon: Icons.spa_outlined,
                        label: 'Type',
                        value: farm.harvestType.isNotEmpty
                            ? farm.harvestType
                            : '—',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InfoMetricTile(
                        icon: Icons.grass_rounded,
                        label: 'Crop',
                        value: farm.crop.isNotEmpty ? farm.crop : '—',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InfoMetricTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Harvest Status',
                  value: farm.harvestStatus.label,
                  color: AppColors.secondary,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          if (isExecutive || isAdmin) ...[
            const SizedBox(height: 10),
            ShineSecondaryButton(
              label: _updatingHarvest ? 'Updating…' : 'Update harvest date',
              onPressed: _updatingHarvest ? null : _editHarvestDate,
            ),
          ],
          if (_harvestHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Harvest date history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ..._harvestHistory.take(10).map(
                  (change) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ShineCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dateFormat.format(change.oldDate)} → ${dateFormat.format(change.newDate)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${change.changedByName} · ${DateFormat('dd MMM yyyy, hh:mm a').format(change.changedAt.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          if (change.reason != null &&
                              change.reason!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              change.reason!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 16),
          CollapsibleSection(
            title: 'Map',
            icon: Icons.map_outlined,
            initiallyExpanded: true,
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
          SizedBox(
            height: (isExecutive || isAdmin) &&
                    farm.status != FarmVisitStatus.visited
                ? 80
                : 24,
          ),
        ],
      ),
      bottomNavigationBar:
          (isExecutive || isAdmin) && farm.status != FarmVisitStatus.visited
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
