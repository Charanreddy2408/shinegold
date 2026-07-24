import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/providers/session_expired_provider.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/shine_buttons.dart';
import '../../shared/widgets/shine_logo.dart';

/// Shown instead of silently bouncing the user to /login when their
/// session dies mid-app (token refresh failed). A route rather than a
/// dialog so it can't race go_router's own redirect-on-auth-change logic.
class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShineLogo(size: 72),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.errorSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 36,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Your session has expired',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please log in again to continue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                ShinePrimaryButton(
                  label: 'Log In Again',
                  onPressed: () {
                    ref.read(sessionExpiredProvider.notifier).clear();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
