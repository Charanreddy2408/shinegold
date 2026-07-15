import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../farms/farms_screen.dart';
import '../home/home_screen.dart';
import '../my_visits/my_visits_screen.dart';
import '../onboard_farm/onboard_farm_screen.dart';
import '../profile/executive_profile_screen.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/harvest_reminder_provider.dart';
import '../../../shared/providers/location_provider.dart';

class ExecutiveShell extends ConsumerStatefulWidget {
  const ExecutiveShell({super.key});

  @override
  ConsumerState<ExecutiveShell> createState() => _ExecutiveShellState();
}

class _ExecutiveShellState extends ConsumerState<ExecutiveShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapLocation());
      unawaited(_syncHarvestReminders());
    });
  }

  Future<void> _syncHarvestReminders() async {
    final count = await ref.read(harvestReminderSyncProvider).sync(
          showTestNotification: kDebugMode,
        );
    if (!mounted || count <= 0) return;
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

  Widget _screenFor(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FarmsScreen();
      case 2:
        return const MyVisitsScreen();
      case 3:
        return const OnboardFarmScreen();
      case 4:
        return const ExecutiveProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: _screenFor(_index),
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
            selectedIndex: _index,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primarySoft,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: AppSpacing.navBarHeight,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _index = i),
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
