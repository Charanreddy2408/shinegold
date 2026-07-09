import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/visit.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/repository_providers.dart';
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
  List<Visit> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider)!;
    final visits = await ref.read(visitRepositoryProvider).getMyVisits(
          user.id,
          VisitFilter(search: _searchController.text, status: _tab),
        );
    if (mounted) {
      setState(() {
        _visits = visits;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return AppBackground(
      header: GradientHeader(
        title: 'My Visits',
        subtitle: _loading ? 'Loading...' : '${_visits.length} visit records',
        compact: true,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _load(),
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
                _load();
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const ListLoadingSkeleton(itemCount: 4, itemHeight: 88)
                : _visits.isEmpty
                    ? const ShineEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No visits yet',
                        subtitle: 'Your farm visits will appear here',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
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
                                  onTap: () => context.push(
                                    AppRoutes.farmDetail.replaceFirst(
                                      ':id',
                                      visit.farmId,
                                    ),
                                  ),
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
