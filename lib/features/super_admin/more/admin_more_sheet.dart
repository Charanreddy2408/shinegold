import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../core/router/app_router.dart';

import '../../../core/theme/app_colors.dart';

import '../../../shared/providers/auth_provider.dart';

import '../../../shared/widgets/admin_ui.dart';

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

      child: SafeArea(

        child: Padding(

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

              const SizedBox(height: 18),

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

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'More Options',

                          style:

                              Theme.of(context).textTheme.titleLarge?.copyWith(

                                    fontWeight: FontWeight.w800,

                                  ),

                        ),

                        Text(

                          'Manage your admin workspace',

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

              const SizedBox(height: 20),

              AdminMenuTile(

                icon: Icons.near_me_rounded,

                title: 'Nearby Farms',

                subtitle: 'Farms within 5 km while travelling',

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

                title: 'Farmers',

                subtitle: 'View all onboarded farmers',

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

                title: 'Password Resets',

                subtitle: 'Approve executive forgot-password requests',

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

                title: 'Profile',

                subtitle: 'Your admin account details',

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

                icon: Icons.logout_rounded,

                title: 'Logout',

                subtitle: 'Sign out of Shine Gold',

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


