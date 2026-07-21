import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interaction.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/ux_components.dart';

class InteractionsListScreen extends ConsumerStatefulWidget {
  const InteractionsListScreen({super.key});

  @override
  ConsumerState<InteractionsListScreen> createState() =>
      _InteractionsListScreenState();
}

class _InteractionsListScreenState
    extends ConsumerState<InteractionsListScreen> {
  List<FarmerInteraction> _items = [];
  bool _loading = true;
  String? _error;
  InteractionStatus? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(interactionRepositoryProvider).listMine(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            status: _statusFilter,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatApiError(e);
      });
    }
  }

  Future<void> _openForm({FarmerInteraction? existing}) async {
    final changed = await context.push<bool>(
      existing == null
          ? AppRoutes.interactionNew
          : AppRoutes.interactionEdit.replaceFirst(':id', existing.id),
      extra: existing,
    );
    if (changed == true && mounted) await _load();
  }

  Color _statusColor(InteractionStatus status) {
    switch (status) {
      case InteractionStatus.readyToOnboard:
        return AppColors.secondary;
      case InteractionStatus.takingTime:
        return AppColors.warning;
      case InteractionStatus.uncertain:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record'),
      ),
      body: AppBackground(
        header: GradientHeader(
          title: 'Interactions',
          subtitle: _loading
              ? 'Loading...'
              : '${_items.length} prospect conversation${_items.length == 1 ? '' : 's'}',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name, phone, location',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _statusFilter == null,
                    onTap: () {
                      setState(() => _statusFilter = null);
                      _load();
                    },
                  ),
                  ...InteractionStatus.values.map(
                    (s) => _FilterChip(
                      label: s.label,
                      selected: _statusFilter == s,
                      color: _statusColor(s),
                      onTap: () {
                        setState(() => _statusFilter = s);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FriendlyErrorBanner(message: _error!, onRetry: _load),
              ),
            Expanded(
              child: _loading
                  ? const ListLoadingSkeleton()
                  : _items.isEmpty
                      ? ShineEmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No interactions yet',
                          subtitle:
                              'Log conversations with farmers you are trying to bring into the plan',
                          action: ShinePrimaryButton(
                            label: 'Record interaction',
                            icon: Icons.add_rounded,
                            onPressed: () => _openForm(),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return StaggeredListItem(
                                index: index,
                                child: _InteractionCard(
                                  item: item,
                                  statusColor: _statusColor(item.status),
                                  onTap: () => _openForm(existing: item),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: accent.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: selected ? accent : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        side: BorderSide(
          color: selected ? accent.withValues(alpha: 0.4) : AppColors.borderSubtle,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _InteractionCard extends StatelessWidget {
  const _InteractionCard({
    required this.item,
    required this.statusColor,
    required this.onTap,
  });

  final FarmerInteraction item;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(item.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          child: Ink(
            decoration: AppColors.cardDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.farmerName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              item.phoneNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                        child: Text(
                          item.status.label,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${item.landLocation} · ${item.acres} ac · ${item.currentCrop}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Planning ${item.plannedMonths} month${item.plannedMonths == 1 ? '' : 's'} · $dateStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
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
}
