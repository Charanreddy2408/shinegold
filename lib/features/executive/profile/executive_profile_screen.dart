import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/harvest_reminder_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/utils/geocoding_service.dart';
import '../../../shared/utils/l10n_ext.dart';
import '../../../shared/widgets/address_autocomplete_field.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/profile_photo_editor.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/user_avatar.dart';

class ExecutiveProfileScreen extends ConsumerStatefulWidget {
  const ExecutiveProfileScreen({super.key});

  @override
  ConsumerState<ExecutiveProfileScreen> createState() =>
      _ExecutiveProfileScreenState();
}

class _ExecutiveProfileScreenState extends ConsumerState<ExecutiveProfileScreen> {
  bool _refreshing = true;
  bool _testingNotification = false;

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

  Future<void> _syncHarvestReminders() async {
    setState(() => _testingNotification = true);
    try {
      final count = await ref.read(harvestReminderSyncProvider).sync(
            showTestNotification: true,
          );
      if (!mounted) return;
      final message = switch (count) {
        -1 => context.l10n.couldNotSyncReminders,
        0 => context.l10n.noUpcomingHarvests,
        1 => context.l10n.oneHarvestReminderTest,
        _ => context.l10n.harvestRemindersScheduledTest(count),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _testingNotification = false);
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _testingNotification = true);
    try {
      await NotificationService.instance.showTestHarvestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.testNotificationSent)),
      );
    } finally {
      if (mounted) setState(() => _testingNotification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshProvider, (previous, next) {
      if (previous != null && previous != next) _refreshProfile();
    });

    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: ProfileLoadingSkeleton(),
      );
    }

    final photoUrl = user.profilePhotoUrl ?? '';

    return AppBackground(
      header: GradientHeader(
        title: user.name.split(' ').first,
        subtitle: context.l10n.fieldExecutive,
        compact: true,
        trailing: UserAvatar(
          name: user.name,
          photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
          radius: 20,
        ),
      ),
      child: _refreshing
          ? const ProfileLoadingSkeleton()
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
                  SizedBox(height: 8),
                  Text(
                    context.l10n.tapPhotoToUpdate,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      _StatPill(
                        label: context.l10n.farmsVisited,
                        value: '${user.farmsVisitedCount}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 10),
                      _StatPill(
                        label: context.l10n.onboarded,
                        value: '${user.onboardingCount}',
                        icon: Icons.add_location_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _ContactSection(
                    mobile: user.mobile ?? context.l10n.notSetNearbyFarms.split(' ').first,
                    address: user.address ?? context.l10n.notSetNearbyFarms.split(' ').first,
                    employeeId: user.employeeId,
                  ),
                  SizedBox(height: 16),
                  _HomeLocationCard(
                    user: user,
                    onUpdate: () => _openUpdateLocationSheet(user),
                  ),
                  SizedBox(height: 16),
                  _PasswordSecurityCard(employeeId: user.employeeId),
                  SizedBox(height: 24),
                  ShineSecondaryButton(
                    label: _testingNotification
                        ? context.l10n.syncing
                        : context.l10n.syncHarvestReminders,
                    onPressed: _testingNotification ? null : _syncHarvestReminders,
                  ),
                  SizedBox(height: 10),
                  ShineSecondaryButton(
                    label: context.l10n.sendTestNotification,
                    onPressed: _testingNotification ? null : _sendTestNotification,
                  ),
                  SizedBox(height: 10),
                  ShineSecondaryButton(
                    label: context.l10n.changeLanguage,
                    onPressed: () async {
                      await showLanguagePicker(context, ref: ref);
                    },
                  ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
                  SizedBox(height: 10),
                  ShineSecondaryButton(
                    label: context.l10n.logout,
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
                  SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  Future<void> _openUpdateLocationSheet(User user) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UpdateLocationSheet(user: user),
    );
    if (updated == true && mounted) {
      bumpAppRefresh(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.homeLocationUpdated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          ProfilePhotoEditor(
            photoUrl: photoUrl,
            fallbackSeed: employeeId,
            userName: name,
            radius: 32,
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
            SizedBox(width: 10),
            Text(
              context.l10n.contactDetails,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _ContactTile(
          icon: Icons.phone_rounded,
          label: context.l10n.mobile,
          value: mobile,
          color: AppColors.info,
          delay: 140.ms,
        ),
        SizedBox(height: 10),
        _ContactTile(
          icon: Icons.home_work_outlined,
          label: context.l10n.address,
          value: address,
          color: AppColors.secondary,
          delay: 200.ms,
        ),
        SizedBox(height: 10),
        _ContactTile(
          icon: Icons.badge_outlined,
          label: context.l10n.employeeIdLabel,
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

class _HomeLocationCard extends StatelessWidget {
  const _HomeLocationCard({
    required this.user,
    required this.onUpdate,
  });

  final User user;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final hasPin = user.homeLat != null && user.homeLng != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeLocation,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      hasPin
                          ? context.l10n.usedForNearbyFarms
                          : context.l10n.notSetNearbyFarms,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPin) ...[
            SizedBox(height: 12),
            Text(
              '${user.homeLat!.toStringAsFixed(5)}, ${user.homeLng!.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
            ),
          ],
          SizedBox(height: 14),
          ShineSecondaryButton(
            label: hasPin ? context.l10n.updateLocation : context.l10n.setHomeLocation,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}

/// Request admin-approved reset, then set a new password (no temp password).
class _PasswordSecurityCard extends ConsumerStatefulWidget {
  const _PasswordSecurityCard({required this.employeeId});

  final String employeeId;

  @override
  ConsumerState<_PasswordSecurityCard> createState() =>
      _PasswordSecurityCardState();
}

class _PasswordSecurityCardState extends ConsumerState<_PasswordSecurityCard> {
  bool _requesting = false;
  bool _checking = false;
  bool _changing = false;
  bool _approved = false;
  bool _pending = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _statusMessage;
  bool _statusIsError = false;

  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setStatus(String message, {bool error = false}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = error;
    });
  }

  Future<void> _refreshStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _checking = true;
        _statusMessage = null;
      });
    }
    try {
      final info = await ref
          .read(authProvider.notifier)
          .checkPasswordResetStatus(widget.employeeId);
      if (!mounted) return;
      setState(() {
        _approved = info.isApproved;
        _pending = info.isPending;
        if (info.isApproved || info.isPending || info.isCompleted) {
          _statusMessage = info.message;
          _statusIsError = false;
        } else if (!silent && info.message.isNotEmpty) {
          _statusMessage = info.message;
          _statusIsError = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) _setStatus(formatApiError(e), error: true);
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _requestReset() async {
    setState(() {
      _requesting = true;
      _statusMessage = null;
      _approved = false;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .requestPasswordReset(widget.employeeId);
      if (!mounted) return;
      setState(() => _pending = true);
      _setStatus(
        context.l10n.requestSentToAdmin,
      );
    } catch (e) {
      if (!mounted) return;
      _setStatus(formatApiError(e), error: true);
      await _refreshStatus(silent: true);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _setNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_approved) {
      _setStatus(
        context.l10n.adminMustApprove,
        error: true,
      );
      return;
    }
    setState(() {
      _changing = true;
      _statusMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).setNewPassword(
            employeeId: widget.employeeId,
            newPassword: _newPassword.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      _newPassword.clear();
      _confirm.clear();
      setState(() {
        _approved = false;
        _pending = false;
      });
      _setStatus(context.l10n.passwordUpdated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordUpdated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _setStatus(formatApiError(e), error: true);
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.password,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.l10n.adminApprovesPassword,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (_approved) ...[
            Text(
              context.l10n.resetApprovedSetPassword,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ] else if (_pending) ...[
            Text(
              context.l10n.waitingAdminApproval,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
          ] else ...[
            Text(
              context.l10n.requestResetSteps,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
          SizedBox(height: 14),
          if (!_approved) ...[
            ShineSecondaryButton(
              label: _requesting
                  ? context.l10n.sending
                  : (_pending
                      ? context.l10n.requestAlreadyPending
                      : context.l10n.requestPasswordReset),
              onPressed: (_requesting || _pending) ? null : _requestReset,
            ),
            SizedBox(height: 8),
            ShineSecondaryButton(
              label: _checking ? context.l10n.refreshing : context.l10n.refreshStatus,
              onPressed: _checking ? null : () => _refreshStatus(),
            ),
          ],
          if (_approved) ...[
            SizedBox(height: 4),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _newPassword,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: context.l10n.newPassword,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return context.l10n.enterNewPassword;
                      if (v.length < 6) {
                        return context.l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: context.l10n.confirmNewPassword,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return context.l10n.confirmYourPassword;
                      }
                      if (v != _newPassword.text) {
                        return context.l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14),
                  ShinePrimaryButton(
                    label: context.l10n.updatePassword,
                    isLoading: _changing,
                    onPressed: _changing ? null : _setNewPassword,
                  ),
                  SizedBox(height: 8),
                  ShineSecondaryButton(
                    label: _checking ? context.l10n.refreshing : context.l10n.refreshStatus,
                    onPressed: _checking ? null : () => _refreshStatus(),
                  ),
                ],
              ),
            ),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusIsError
                    ? AppColors.errorSoft
                    : AppColors.secondaryMuted.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_statusIsError ? AppColors.error : AppColors.secondary)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _statusMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _statusIsError
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateLocationSheet extends ConsumerStatefulWidget {
  const _UpdateLocationSheet({required this.user});

  final User user;

  @override
  ConsumerState<_UpdateLocationSheet> createState() =>
      _UpdateLocationSheetState();
}

class _UpdateLocationSheetState extends ConsumerState<_UpdateLocationSheet> {
  int _mode = 0; // 0 = manual, 1 = current GPS
  final _address = TextEditingController();
  final _pincode = TextEditingController();

  GeocodingService get _geo =>
      GeocodingService(dio: ref.read(dioClientProvider).dio);

  bool _busy = false;
  String? _status;
  String? _error;
  double? _lat;
  double? _lng;
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _address.text = widget.user.address ?? '';
    _lat = widget.user.homeLat;
    _lng = widget.user.homeLng;
  }

  @override
  void dispose() {
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _locateFromAddress() async {
    final addressText = _address.text.trim();
    final pinText = _pincode.text.trim();
    if (addressText.isEmpty) {
      setState(() => _error = context.l10n.enterAddressFirst);
      return;
    }
    if (pinText.isNotEmpty &&
        (pinText.length != 6 || int.tryParse(pinText) == null)) {
      setState(() => _error = context.l10n.pinMustBe6Digits);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _status = context.l10n.findingAddress;
    });

    try {
      final queries = <String>[
        [addressText, if (pinText.isNotEmpty) pinText, 'India'].join(', '),
        if (pinText.length == 6) '$pinText, India',
        '$addressText, India',
      ];

      GeocodingResult? best;
      for (final q in queries) {
        final results = await _geo.search(q);
        if (results.isNotEmpty) {
          best = results.first;
          break;
        }
      }

      if (!mounted) return;
      if (best == null) {
        setState(() {
          _busy = false;
          _status = null;
          _error =
              context.l10n.addressNotFound;
        });
        return;
      }

      setState(() {
        _lat = best!.point.latitude;
        _lng = best.point.longitude;
        _resolvedAddress = best.displayName;
        _busy = false;
        _status = context.l10n.pinReady;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _error = formatApiError(e);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = context.l10n.gettingCurrentLocation;
    });

    try {
      await ref.read(locationProvider.notifier).requestLocation();
      final pos = ref.read(locationProvider).position;
      if (pos == null) {
        final err = ref.read(locationProvider).error;
        setState(() {
          _busy = false;
          _status = null;
          _error = err ?? context.l10n.couldNotGetLocation;
        });
        return;
      }

      final point = LatLng(pos.latitude, pos.longitude);
      String? label;
      try {
        label = await _geo.reverseGeocode(point);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _resolvedAddress = label;
        if (label != null && label.isNotEmpty) {
          _address.text = label;
        }
        _busy = false;
        _status = context.l10n.currentLocationReady;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = null;
        _error = formatApiError(e);
      });
    }
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) {
      setState(() => _error = context.l10n.locateBeforeSaving);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final pinText = _pincode.text.trim();
      final addressText = (_resolvedAddress ?? _address.text).trim();
      final fullAddress = [
        if (addressText.isNotEmpty) addressText,
        if (pinText.isNotEmpty) pinText,
      ].join(', ');

      await ref.read(authProvider.notifier).updateHomeLocation(
            homeLat: _lat!,
            homeLng: _lng!,
            address: fullAddress.isEmpty ? null : fullAddress,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = formatApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(context.l10n.updateHomeLocation,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 6),
              Text(context.l10n.chooseHomeLocation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: 16),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(context.l10n.enterManually),
                    icon: Icon(Icons.edit_location_alt_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(context.l10n.currentLocation),
                    icon: Icon(Icons.gps_fixed_rounded),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy
                    ? null
                    : (values) => setState(() {
                          _mode = values.first;
                          _error = null;
                          _status = null;
                        }),
              ),
              SizedBox(height: 16),
              if (_mode == 0) ...[
                AddressAutocompleteField(
                  controller: _address,
                  pincodeController: _pincode,
                  label: context.l10n.address,
                  hint: context.l10n.startTypingToSearch,
                  onSelected: (result) {
                    setState(() {
                      _lat = result.point.latitude;
                      _lng = result.point.longitude;
                      _resolvedAddress = result.displayName;
                      _status = context.l10n.suggestionSelected;
                      _error = null;
                    });
                  },
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.pinCodeOptional,
                    hintText: context.l10n.pinCodeHint,
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ShineSecondaryButton(
                  label: _busy
                      ? context.l10n.locating
                      : context.l10n.locateFromAddress,
                  onPressed: _busy ? null : _locateFromAddress,
                ),
              ] else ...[
                Text(
                  context.l10n.weWillUsePhoneGps,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                ShineSecondaryButton(
                  label: _busy
                      ? context.l10n.fetching
                      : context.l10n.fetchCurrentLocation,
                  onPressed: _busy ? null : _fetchCurrentLocation,
                ),
              ],
              if (_lat != null && _lng != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.pinCoordinates(
                          _lat!.toStringAsFixed(5),
                          _lng!.toStringAsFixed(5),
                        ),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                      ),
                      if (_resolvedAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _resolvedAddress!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 10),
                Text(
                  _status!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (_error != null) ...[
                SizedBox(height: 10),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              SizedBox(height: 16),
              ShinePrimaryButton(
                label:
                    _busy ? context.l10n.saving : context.l10n.saveLocation,
                onPressed: _busy ? null : _save,
              ),
              SizedBox(height: 8),
              ShineSecondaryButton(
                label: context.l10n.cancel,
                onPressed: _busy ? null : () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
