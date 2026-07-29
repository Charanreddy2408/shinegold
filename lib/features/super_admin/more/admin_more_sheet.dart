import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/l10n_ext.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/language_picker.dart';
import '../farmers/farmers_screen.dart';
import '../nearby/admin_nearby_farms_section.dart';
import '../password_reset/admin_password_reset_screen.dart';
import '../profile/admin_profile_screen.dart';



class AdminMoreSheet extends ConsumerWidget {

  const AdminMoreSheet({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGold,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      // The tile list is taller than a small phone at the app's 1.3x text
      // scale. Unbounded it overflowed and clipped the last tiles (language,
      // logout) off-screen, where they could not be tapped at all.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientBrand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.apps_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.moreOptions,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Text(
                          context.l10n.manageAdminWorkspace,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, end: 0),
              SizedBox(height: 20),
              AdminMenuTile(
                icon: Icons.near_me_rounded,
                title: context.l10n.nearbyFarms,
                subtitle: context.l10n.nearbyFarmsWithinKm,
                color: AppColors.info,
                delay: 30.ms,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    adminPageRoute(const AdminNearbyFarmsScreen()),
                  );
                },
              ),
              AdminMenuTile(
                icon: Icons.agriculture_rounded,
                title: context.l10n.farmers,
                subtitle: context.l10n.farmersSubtitle,
                color: AppColors.secondary,
                delay: 60.ms,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    adminPageRoute(const FarmersScreen()),
                  );
                },
              ),
              AdminMenuTile(
                icon: Icons.lock_reset_rounded,
                title: context.l10n.passwordResets,
                subtitle: context.l10n.passwordResetsSubtitle,
                color: AppColors.warning,
                delay: 90.ms,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    adminPageRoute(const AdminPasswordResetScreen()),
                  );
                },
              ),
              AdminMenuTile(
                icon: Icons.person_rounded,
                title: context.l10n.profile,
                subtitle: context.l10n.profileSubtitle,
                color: AppColors.primary,
                delay: 120.ms,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    adminPageRoute(const AdminProfileScreen()),
                  );
                },
              ),
              AdminMenuTile(
                icon: Icons.language_rounded,
                title: context.l10n.changeLanguage,
                subtitle: context.l10n.changeLanguageSubtitle,
                color: AppColors.info,
                delay: 150.ms,
                onTap: () async {
                  // Anchor the dialog to the root navigator, not this sheet:
                  // the sheet is on its way out once popped. The picker builds
                  // its own ref, so nothing here has to outlive the sheet.
                  final rootContext =
                      Navigator.of(context, rootNavigator: true).context;
                  Navigator.pop(context);
                  await showLanguagePicker(rootContext);
                },
              ),
              AdminMenuTile(
                icon: Icons.logout_rounded,
                title: context.l10n.logout,
                subtitle: context.l10n.logoutSubtitle,
                color: AppColors.error,
                delay: 180.ms,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}


