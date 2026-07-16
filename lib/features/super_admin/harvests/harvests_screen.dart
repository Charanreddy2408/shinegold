import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/executive.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/async_ui.dart';
import '../../../shared/utils/list_search.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/ux_components.dart';

class HarvestsScreen extends ConsumerStatefulWidget {
  const HarvestsScreen({super.key});

  @override
  ConsumerState<HarvestsScreen> createState() => _HarvestsScreenState();
}

class _HarvestsScreenState extends ConsumerState<HarvestsScreen> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debouncer(delay: const Duration(milliseconds: 250));
  final _loadGen = LoadGeneration();
  final Map<String, List<Harvest>> _monthCache = {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Harvest> _harvests = [];
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMonth(_focusedDay, isRefresh: false);
  }

  void _onSearchChanged() {
    _searchDebounce.run(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchDebounce.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  Future<void> _load() => _loadMonth(_focusedDay, isRefresh: true);

  Future<void> _loadMonth(DateTime month, {bool isRefresh = true}) async {
    final key = _monthKey(month);
    final gen = _loadGen.next();
    final cached = _monthCache[key];

    if (cached != null && isRefresh) {
      // Soft: show cached month immediately, refresh in background.
      if (mounted) {
        setState(() {
          _focusedDay = month;
          _harvests = cached;
          _refreshing = true;
          _error = null;
        });
      }
    } else if (cached != null) {
      if (mounted) {
        setState(() {
          _focusedDay = month;
          _harvests = cached;
          _initialLoading = false;
          _refreshing = false;
          _error = null;
        });
      }
      return;
    } else if (mounted) {
      setState(() {
        _focusedDay = month;
        if (_harvests.isEmpty) {
          _initialLoading = true;
        } else {
          _refreshing = true;
        }
        _error = null;
      });
    }

    try {
      final harvests =
          await ref.read(harvestRepositoryProvider).getByMonth(month);
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      _monthCache[key] = harvests;
      setState(() {
        _harvests = harvests;
        _initialLoading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _initialLoading = false;
        _refreshing = false;
        // Keep prior month data visible when a soft refresh fails.
        if (_harvests.isEmpty) {
          _error = formatApiError(e);
        }
      });
    }
  }

  List<Harvest> _forDay(DateTime day) {
    return _harvests
        .where(
          (h) =>
              h.harvestDate.year == day.year &&
              h.harvestDate.month == day.month &&
              h.harvestDate.day == day.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) {
        _monthCache.clear();
        _loadMonth(_focusedDay, isRefresh: true);
      }
    });

    final selected = _selectedDay ?? _focusedDay;
    final dayHarvests = _forDay(selected).where((h) {
      return matchesListSearch(_searchQuery, [
        h.farmName,
        h.crop,
        h.harvestType,
      ]);
    }).toList();

    return AppBackground(
      header: GradientHeader(
        title: 'Harvests',
        subtitle: _initialLoading
            ? 'Loading...'
            : '${_harvests.length} scheduled',
        compact: true,
      ),
      child: _initialLoading
          ? const ListLoadingSkeleton(itemCount: 3, itemHeight: 72)
          : _error != null && _harvests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FriendlyErrorBanner(
                      message: _error!,
                      onRetry: _load,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoftRefreshBar(visible: _refreshing),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TableCalendar<Harvest>(
                          firstDay: DateTime.utc(2020),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: _forDay,
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                            selectedDecoration: const BoxDecoration(
                              gradient: AppColors.gradientBrand,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            markerSize: 6,
                            outsideDaysVisible: false,
                            weekendTextStyle: TextStyle(
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.w700),
                            leftChevronIcon: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.primary,
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(fontWeight: FontWeight.w600),
                            weekendStyle: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            // Keep current calendar/list visible while the month loads.
                            _loadMonth(focusedDay, isRefresh: true);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: ShineSearchBar(
                        controller: _searchController,
                        hint: 'Search harvests by farm or crop...',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Harvests on ${selected.day}/${selected.month}/${selected.year}',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: dayHarvests.isEmpty
                          ? ShineEmptyState(
                              icon: Icons.search_off_rounded,
                              title: _searchQuery.isEmpty
                                  ? 'No harvests'
                                  : 'No matches',
                              subtitle: _searchQuery.isEmpty
                                  ? 'Nothing scheduled for this date'
                                  : 'Try a different search term',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: dayHarvests.length,
                              itemBuilder: (_, i) {
                                final h = dayHarvests[i];
                                return AdminHarvestRow(
                                  key: ValueKey(
                                    '${h.farmId}-${h.harvestDate.toIso8601String()}',
                                  ),
                                  farmName: h.farmName,
                                  crop: h.crop,
                                  harvestType: h.harvestType,
                                  isLast: i == dayHarvests.length - 1,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
