import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/shine_bottom_nav.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../executives/executives_screen.dart';
import '../farms/admin_farms_screen.dart';
import '../harvests/harvests_screen.dart';
import '../more/admin_more_sheet.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  late final _screens = [
    const AdminDashboardScreen(),
    const AdminFarmsScreen(),
    const ExecutivesScreen(),
    const HarvestsScreen(),
  ];

  static const _navItems = [
    ShineNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    ShineNavItem(
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco_rounded,
      label: 'Farms',
    ),
    ShineNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Team',
    ),
    ShineNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Harvests',
    ),
    ShineNavItem(
      icon: Icons.more_horiz,
      activeIcon: Icons.more_horiz,
      label: 'More',
    ),
  ];

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (_) => const AdminMoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: _screens[_index],
          ),
        ),
      bottomNavigationBar: ShineBottomNav(
        currentIndex: _index,
        onTap: (i) {
          if (i == 4) {
            _openMore();
          } else {
            setState(() => _index = i);
          }
        },
        items: _navItems,
      ),
    );
  }
}
