import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/profile_photo_editor.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/utils/l10n_ext.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final photoUrl = user.profilePhotoUrl ?? '';

    Future<void> editMobile() async {
      final mobile = TextEditingController(text: user.mobile ?? '');

      final saved = await showAdminFormSheet<bool>(
        context: context,
        title: context.l10n.editMobileNumber,
        subtitle: context.l10n.updateContactNumber,
        icon: Icons.phone_rounded,
        submitLabel: 'Save Mobile Number',
        fields: [
          AdminFormField(
            controller: mobile,
            label: context.l10n.mobileNumber,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
              if (digits.isEmpty) return 'Enter your mobile number';
              if (digits.length < 10) return 'Enter a valid mobile number';
              return null;
            },
          ),
        ],
        onSubmit: () async {
          await ref.read(authProvider.notifier).updateProfile(
                mobileNumber: mobile.text.trim(),
              );
        },
      );

      disposeSheetControllers([mobile]);

      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mobileNumberUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    Future<void> editAddress() async {
      final address = TextEditingController(text: user.address ?? '');

      final saved = await showAdminFormSheet<bool>(
        context: context,
        title: context.l10n.editOfficeAddress,
        subtitle: context.l10n.updateAdminAddress,
        icon: Icons.location_on_rounded,
        submitLabel: 'Save Address',
        fields: [
          AdminFormField(
            controller: address,
            label: context.l10n.officeAddress,
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your address';
              }
              return null;
            },
          ),
        ],
        onSubmit: () async {
          await ref.read(authProvider.notifier).updateProfile(
                address: address.text.trim(),
              );
        },
      );

      disposeSheetControllers([address]);

      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.officeAddressUpdated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    Future<void> changePassword() async {
      final newPassword = TextEditingController();
      final confirmPassword = TextEditingController();

      final changed = await showAdminFormSheet<bool>(
        context: context,
        title: 'Change Password',
        subtitle: context.l10n.chooseNewPassword,
        icon: Icons.lock_reset_rounded,
        submitLabel: 'Change Password',
        fields: [
          AdminFormField(
            controller: newPassword,
            label: context.l10n.newPassword,
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter a new password';
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          AdminFormField(
            controller: confirmPassword,
            label: context.l10n.confirmNewPassword,
            icon: Icons.lock_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm your new password';
              }
              if (value != newPassword.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
        onSubmit: () async {
          await ref.read(authProvider.notifier).changeAdminPassword(
                newPassword: newPassword.text,
                confirmPassword: confirmPassword.text,
              );
        },
      );

      disposeSheetControllers([newPassword, confirmPassword]);

      if (changed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordChangedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: user.name.split(' ').first,
          subtitle: 'Super Admin · ${user.employeeId}',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          trailing: UserAvatar(
            name: user.name,
            photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
            radius: 20,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ProfileHero(
                name: user.name,
                employeeId: user.employeeId,
                photoUrl: photoUrl,
              ),
              SizedBox(height: 8),
              Text(context.l10n.tapPhotoToUpdate,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 20),
              AdminContactHub(
                mobile: user.mobile ?? '—',
                address: user.address ?? '—',
                employeeId: user.employeeId,
                onEditMobile: editMobile,
                onEditAddress: editAddress,
              ),
              SizedBox(height: 24),
              ShineSecondaryButton(
                label: 'Change Password',
                onPressed: changePassword,
              ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
              SizedBox(height: 10),
              ShineSecondaryButton(
                label: context.l10n.changeLanguage,
                onPressed: () async {
                  await showLanguagePicker(context, ref: ref);
                },
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              SizedBox(height: 10),
              ShineSecondaryButton(
                label: context.l10n.logout,
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ).animate().fadeIn(delay: 320.ms, duration: 400.ms),
              const SizedBox(height: 8),
            ],
          ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHeader,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowGold,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfilePhotoEditor(
            photoUrl: photoUrl,
            fallbackSeed: employeeId,
            userName: name,
            radius: 38,
            showLabel: false,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      SizedBox(width: 5),
                      Text(context.l10n.superAdministrator,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(context.l10n.managingShineGold,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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
