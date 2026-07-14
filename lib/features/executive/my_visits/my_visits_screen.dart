import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/visit.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/async_ui.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_card.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';

class MyVisitsScreen extends ConsumerStatefulWidget {
  const MyVisitsScreen({super.key});

  @override
  ConsumerState<MyVisitsScreen> createState() => _MyVisitsScreenState();
}

class _MyVisitsScreenState extends ConsumerState<MyVisitsScreen> {
  VisitStatus? _tab;
  final _searchController = TextEditingController();
  final _searchDebounce = Debouncer();
  final _loadGen = LoadGeneration();
  List<Visit> _visits = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(isRefresh: false);
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool isRefresh = true}) async {
    final gen = _loadGen.next();
    if (mounted) {
      setState(() {
        if (_visits.isEmpty) {
          _initialLoading = true;
        } else {
          _refreshing = true;
        }
        _error = null;
      });
    }
    try {
      final user = ref.read(currentUserProvider)!;
      final visits = await ref.read(visitRepositoryProvider).getMyVisits(
            user.id,
            VisitFilter(search: _searchController.text, status: _tab),
          );
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _visits = visits;
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
      if (previous != null && previous != next) _load();
    });

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return AppBackground(
      header: GradientHeader(
        title: 'My Visits',
        subtitle: _initialLoading
            ? 'Loading...'
            : '${_visits.length} visit records',
        compact: true,
      ),
      child: Column(
        children: [
          SoftRefreshBar(visible: _refreshing),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _searchDebounce.run(
                () => _load(isRefresh: _visits.isNotEmpty),
              ),
              decoration: const InputDecoration(
                hintText: 'Search by farm name...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
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
              selected: {_tab},
              onSelectionChanged: (s) {
                setState(() => _tab = s.first);
                _load(isRefresh: _visits.isNotEmpty);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _initialLoading
                ? const ListLoadingSkeleton(itemCount: 4, itemHeight: 88)
                : _error != null && _visits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: FriendlyErrorBanner(
                            message: _error!,
                            onRetry: () => _load(isRefresh: false),
                          ),
                        ),
                      )
                : _visits.isEmpty
                    ? const ShineEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No visits yet',
                        subtitle: 'Your farm visits will appear here',
                      )
                    : RefreshIndicator(
                        onRefresh: () => _load(isRefresh: true),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          addRepaintBoundaries: true,
                          itemCount: _visits.length,
                          itemBuilder: (context, index) {
                            final visit = _visits[index];
                            return StaggeredListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ShineCard(
                                  onTap: () {
                                    if (visit.status == VisitStatus.completed &&
                                        visit.id.isNotEmpty) {
                                      context.push(
                                        AppRoutes.visitDetail.replaceFirst(
                                          ':id',
                                          visit.id,
                                        ),
                                      );
                                    } else {
                                      context.push(
                                        AppRoutes.farmDetail.replaceFirst(
                                          ':id',
                                          visit.farmId,
                                        ),
                                      );
                                    }
                                  },
                                  accentColor: visit.status == VisitStatus.ongoing
                                      ? AppColors.info
                                      : AppColors.secondary,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              visit.farmName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateFormat.format(visit.startedAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            if (visit.formAnswers.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                visit.formAnswers
                                                    .take(2)
                                                    .map(
                                                      (a) =>
                                                          '${a.questionLabel}: ${a.displayValue()}',
                                                    )
                                                    .join(' · '),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ] else if (visit.textNote != null &&
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
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          StatusChip(status: visit.status),
                                          const SizedBox(height: 6),
                                          SyncStatusChip(
                                              status: visit.syncStatus),
                                        ],
                                      ),
                                    ],
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
