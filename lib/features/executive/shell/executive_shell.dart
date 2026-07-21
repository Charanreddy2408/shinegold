import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../farms/farms_screen.dart';
import '../home/home_screen.dart';
import '../my_visits/my_visits_screen.dart';
import '../onboard_farm/onboard_farm_screen.dart';
import '../profile/executive_profile_screen.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/executive_tab_provider.dart';
import '../../../shared/providers/harvest_reminder_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/visit_sync_provider.dart';
import '../../../shared/services/offline_visit_store.dart';
import '../../../shared/services/visit_sync_service.dart';

class ExecutiveShell extends ConsumerStatefulWidget {
  const ExecutiveShell({super.key});

  @override
  ConsumerState<ExecutiveShell> createState() => _ExecutiveShellState();
}

class _ExecutiveShellState extends ConsumerState<ExecutiveShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keep the coordinator alive so connectivity changes drain the queue.
      ref.read(visitSyncCoordinatorProvider);
      unawaited(_bootstrapLocation());
      unawaited(_syncHarvestReminders(showSnack: true));
      unawaited(_syncOfflineVisits(showSnack: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncHarvestReminders());
      unawaited(_syncOfflineVisits());
    }
  }

  Future<void> _syncOfflineVisits({bool showSnack = false}) async {
    if (OfflineVisitStore.instance.pendingCount.value == 0) {
      // Still load disk queue so count is accurate after cold start.
      await OfflineVisitStore.instance.all();
      if (OfflineVisitStore.instance.pendingCount.value == 0) return;
    }

    final result = await ref.read(visitSyncCoordinatorProvider).syncNow();
    if (!mounted || !showSnack) return;
    _showSyncSnack(result);
  }

  void _showSyncSnack(VisitSyncResult result) {
    if (result.synced <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.synced == 1
                ? '1 offline visit synced'
                : '${result.synced} offline visits synced',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _syncHarvestReminders({bool showSnack = false}) async {
    final count = await ref.read(harvestReminderSyncProvider).sync();
    if (!mounted || !showSnack || count <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1
                ? '1 harvest reminder scheduled'
                : '$count harvest reminders scheduled',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _bootstrapLocation() async {
    await ref.read(locationProvider.notifier).requestLocation();
    final pos = ref.read(locationProvider).position;
    final user = ref.read(currentUserProvider);
    if (user?.requiresLocationSetup == true && pos != null) {
      await ref.read(authProvider.notifier).setupHomeLocationIfNeeded(
            homeLat: pos.latitude,
            homeLng: pos.longitude,
          );
    } else if (user?.requiresLocationSetup == true) {
      await ref.read(authProvider.notifier).setupHomeLocationIfNeeded();
    }
  }

  void _onTabSelected(int index) {
    if (index == 0) {
      bumpAppRefresh(ref);
    }
    ref.read(executiveTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(executiveTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: IndexedStack(
        index: tabIndex,
        children: const [
          HomeScreen(),
          FarmsScreen(),
          MyVisitsScreen(),
          OnboardFarmScreen(),
          ExecutiveProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: tabIndex,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primarySoft,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: AppSpacing.navBarHeight,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _onTabSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco_rounded),
                label: 'Farms',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Visits',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_location_alt_outlined),
                selectedIcon: Icon(Icons.add_location_alt_rounded),
                label: 'Onboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
