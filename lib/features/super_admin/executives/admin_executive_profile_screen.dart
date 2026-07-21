import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../data/models/visit.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/utils/contact_launcher.dart';

class AdminExecutiveProfileScreen extends ConsumerStatefulWidget {
  const AdminExecutiveProfileScreen({
    super.key,
    required this.executive,
  });

  final Executive executive;

  @override
  ConsumerState<AdminExecutiveProfileScreen> createState() =>
      _AdminExecutiveProfileScreenState();
}

class _AdminExecutiveProfileScreenState
    extends ConsumerState<AdminExecutiveProfileScreen> {
  late Executive _executive;
  final _searchController = TextEditingController();
  VisitStatus? _visitFilter;
  List<Visit> _visits = [];
  List<Farm> _assignedFarms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _executive = widget.executive;
    _searchController.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail =
          await ref.read(executiveRepositoryProvider).getById(_executive.id);
      final assignedFarms = await ref
          .read(executiveRepositoryProvider)
          .getVisitHistoryFarms(_executive.id);
      final visits = await ref.read(visitRepositoryProvider).getExecutiveVisits(
            _executive.id,
            VisitFilter(
              search: _searchController.text,
              status: _visitFilter,
            ),
          );
      if (mounted) {
        setState(() {
          _executive = detail;
          _assignedFarms = assignedFarms;
          _visits = visits;
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

  Future<void> _toggleBlock() async {
    try {
      final updated = await ref
          .read(executiveRepositoryProvider)
          .toggleBlock(_executive.id);
      if (mounted) setState(() => _executive = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatApiError(e))),
        );
      }
    }
  }

  int get _ongoingCount =>
      _visits.where((v) => v.status == VisitStatus.ongoing).length;

  int get _completedCount =>
      _visits.where((v) => v.status == VisitStatus.completed).length;

  String _formatAcres(double acres) {
    if (acres <= 0) return '0';
    if (acres == acres.roundToDouble()) return acres.toInt().toString();
    return acres.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _executive.profilePhotoUrl ??
        'https://i.pravatar.cc/150?u=${_executive.employeeId}';
    final dateFormat = DateFormat('dd MMM yyyy · hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: _executive.name.split(' ').first,
          subtitle: 'Field Executive · ${_executive.employeeId}',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          trailing: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: CachedNetworkImageProvider(photo),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _ProfileHeader(
                          executive: _executive,
                          photo: photo,
                          onToggleBlock: _toggleBlock,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.05, end: 0),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _OnboardingCoverageCard(
                          farmsCount: _executive.onboardedFarmsCount,
                          acresTotal: _executive.onboardedAcresTotal,
                          formatAcres: _formatAcres,
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 400.ms)
                            .slideY(begin: 0.04, end: 0),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            _StatPill(
                              label: 'Total',
                              value: '${_visits.length}',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: 'Ongoing',
                              value: '$_ongoingCount',
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: 'Done',
                              value: '$_completedCount',
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: 'Farms',
                              value: '${_executive.farmsAssigned}',
                              color: AppColors.secondarySoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Assigned Farms',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${_assignedFarms.length} farms',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_assignedFarms.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text('No farms assigned yet'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final farm = _assignedFarms[index];
                              return _AssignedFarmTile(
                                farm: farm,
                                onTap: farm.id.isEmpty
                                    ? null
                                    : () => context.push(
                                          AppRoutes.farmDetail.replaceFirst(
                                            ':id',
                                            farm.id,
                                          ),
                                        ),
                              );
                            },
                            childCount: _assignedFarms.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Visit History',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${_visits.length} records',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: ShineSearchBar(
                          controller: _searchController,
                          hint: 'Search visits by farm name...',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SegmentedButton<VisitStatus?>(
                          segments: const [
                            ButtonSegment(value: null, label: Text('All')),
                            ButtonSegment(
                              value: VisitStatus.ongoing,
                              label: Text('Ongoing'),
                            ),
                            ButtonSegment(
                              value: VisitStatus.completed,
                              label: Text('Completed'),
                            ),
                          ],
                          selected: {_visitFilter},
                          onSelectionChanged: (s) {
                            setState(() => _visitFilter = s.first);
                            _load();
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (_loading)
                      const SliverToBoxAdapter(
                        child: ListLoadingSkeleton(itemCount: 4, itemHeight: 72),
                      )
                    else if (_error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: FriendlyErrorBanner(
                              message: _error!,
                              onRetry: _load,
                            ),
                          ),
                        ),
                      )
                    else if (_visits.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ShineEmptyState(
                          icon: Icons.search_off_rounded,
                          title: _searchController.text.isEmpty
                              ? 'No visits yet'
                              : 'No matches',
                          subtitle: _searchController.text.isEmpty
                              ? 'This executive has no visit records'
                              : 'Try a different farm name',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final visit = _visits[index];
                              final isLast = index == _visits.length - 1;
                              return StaggeredListItem(
                                index: index,
                                child: _VisitTimelineTile(
                                  visit: visit,
                                  dateLabel: dateFormat.format(visit.startedAt),
                                  isLast: isLast,
                                  onTap: () {
                                    if (visit.status == VisitStatus.completed &&
                                        visit.id.isNotEmpty) {
                                      context.push(
                                        AppRoutes.visitDetail.replaceFirst(
                                          ':id',
                                          visit.id,
                                        ),
                                      );
                                      return;
                                    }
                                    if (visit.farmId.isEmpty) return;
                                    context.push(
                                      AppRoutes.farmDetail.replaceFirst(
                                        ':id',
                                        visit.farmId,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: _visits.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.executive,
    required this.photo,
    required this.onToggleBlock,
  });

  final Executive executive;
  final String photo;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final isBlocked = executive.status == ExecutiveStatus.blocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: CachedNetworkImageProvider(photo),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      executive.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      executive.employeeId,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(status: executive.status),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            executive.mobile,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (executive.mobile.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ContactLauncher.callOrSnack(
                      context,
                      executive.mobile,
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B7A4E),
                      side: const BorderSide(
                        color: Color(0xFF1B7A4E),
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ContactLauncher.whatsappOrSnack(
                      context,
                      executive.mobile,
                      message:
                          'Hello ${executive.name.split(' ').first}, this is Shine Gold.',
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 20),
                    label: const Text('WhatsApp'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onToggleBlock,
            icon: Icon(
              isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              size: 20,
            ),
            label: Text(isBlocked ? 'Unblock executive' : 'Block executive'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isBlocked ? AppColors.secondary : AppColors.error,
              side: BorderSide(
                color: isBlocked ? AppColors.secondary : AppColors.error,
                width: 1.4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitTimelineTile extends StatelessWidget {
  const _VisitTimelineTile({
    required this.visit,
    required this.dateLabel,
    required this.isLast,
    required this.onTap,
  });

  final Visit visit;
  final String dateLabel;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = visit.status == VisitStatus.ongoing
        ? AppColors.info
        : AppColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.borderSubtle,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.farmName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (visit.durationMinutes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${visit.durationMinutes} min on site',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                            if (visit.textNote != null &&
                                visit.textNote!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                visit.textNote!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusChip(status: visit.status),
                          const SizedBox(height: 6),
                          SyncStatusChip(status: visit.syncStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCoverageCard extends StatelessWidget {
  const _OnboardingCoverageCard({
    required this.farmsCount,
    required this.acresTotal,
    required this.formatAcres,
  });

  final int farmsCount;
  final double acresTotal;
  final String Function(double) formatAcres;

  @override
  Widget build(BuildContext context) {
    final acresLabel = formatAcres(acresTotal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryMuted.withValues(alpha: 0.55),
            AppColors.primarySoft.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onboarding coverage',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  farmsCount == 1
                      ? '1 farm onboarded · $acresLabel acres'
                      : '$farmsCount farms onboarded · $acresLabel acres',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedFarmTile extends StatelessWidget {
  const _AssignedFarmTile({
    required this.farm,
    this.onTap,
  });

  final Farm farm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final subtitle = farm.nextVisitAvailabilityLabel ??
        (farm.lastVisited != null
            ? 'Last visit: ${dateFormat.format(farm.lastVisited!)}'
            : 'Not visited yet');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: farm.isInVisitCooldown
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                              fontWeight: farm.isInVisitCooldown
                                  ? FontWeight.w600
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: farm.status),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
