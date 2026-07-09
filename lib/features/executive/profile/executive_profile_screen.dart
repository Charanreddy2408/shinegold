import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_buttons.dart';

class ExecutiveProfileScreen extends ConsumerStatefulWidget {
  const ExecutiveProfileScreen({super.key});

  @override
  ConsumerState<ExecutiveProfileScreen> createState() =>
      _ExecutiveProfileScreenState();
}

class _ExecutiveProfileScreenState extends ConsumerState<ExecutiveProfileScreen> {
  bool _refreshing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  Future<void> _refreshProfile() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (_) {
      // Keep cached profile if refresh fails.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photoUrl = user.profilePhotoUrl ??
        'https://i.pravatar.cc/150?u=${user.employeeId}';

    return AppBackground(
      header: GradientHeader(
        title: user.name.split(' ').first,
        subtitle: 'Field Executive',
        compact: true,
        trailing: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          backgroundImage: CachedNetworkImageProvider(photoUrl),
        ),
      ),
      child: _refreshing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _ProfileHero(
                    name: user.name,
                    employeeId: user.employeeId,
                    photoUrl: photoUrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatPill(
                        label: 'Farms Visited',
                        value: '${user.farmsVisitedCount}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        label: 'Onboarded',
                        value: '${user.onboardingCount}',
                        icon: Icons.add_location_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ContactSection(
                    mobile: user.mobile ?? 'Not set',
                    address: user.address ?? 'Not set',
                    employeeId: user.employeeId,
                  ),
                  const SizedBox(height: 24),
                  ShineSecondaryButton(
                    label: 'Logout',
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.employeeId,
    required this.photoUrl,
  });

  final String name;
  final String employeeId;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHeader,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: CachedNetworkImageProvider(photoUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  employeeId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        decoration: AppColors.cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 380.ms)
        .slideY(begin: 0.06, end: 0);
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.mobile,
    required this.address,
    required this.employeeId,
  });

  final String mobile;
  final String address;
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.gradientBrand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Contact Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.phone_rounded,
          label: 'Mobile',
          value: mobile,
          color: AppColors.info,
          delay: 140.ms,
        ),
        const SizedBox(height: 10),
        _ContactTile(
          icon: Icons.home_work_outlined,
          label: 'Address',
          value: address,
          color: AppColors.secondary,
          delay: 200.ms,
        ),
        const SizedBox(height: 10),
        _ContactTile(
          icon: Icons.badge_outlined,
          label: 'Employee ID',
          value: employeeId,
          color: AppColors.primary,
          delay: 260.ms,
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 350.ms)
        .slideX(begin: 0.04, end: 0, delay: delay, curve: Curves.easeOutCubic);
  }
}
