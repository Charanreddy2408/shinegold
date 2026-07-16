import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/fade_slide_in.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_logo.dart';

enum _ForgotStep { enterId, request, waiting, approved }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.enterId;
  final _employeeIdController = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _statusMessage;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _employeeId => _employeeIdController.text.trim().toUpperCase();

  void _applyStatus({
    required bool approved,
    required bool pending,
    required String message,
  }) {
    if (approved) {
      _step = _ForgotStep.approved;
    } else if (pending) {
      _step = _ForgotStep.waiting;
    } else {
      _step = _ForgotStep.request;
    }
    _statusMessage = message;
  }

  Future<void> _continueWithId() async {
    if (_employeeId.isEmpty) {
      setState(() => _statusMessage = 'Enter your employee ID.');
      return;
    }
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      final info = await ref
          .read(authProvider.notifier)
          .checkPasswordResetStatus(_employeeId);
      if (!mounted) return;
      setState(() {
        _applyStatus(
          approved: info.isApproved,
          pending: info.isPending,
          message: info.message,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestReset() async {
    if (_employeeId.isEmpty) return;
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(_employeeId);
      if (!mounted) return;
      setState(() {
        _step = _ForgotStep.waiting;
        _statusMessage = 'Request sent. Waiting for super admin approval.';
      });
    } catch (e) {
      if (!mounted) return;
      final message = formatApiError(e);
      if (message.toLowerCase().contains('already approved')) {
        setState(() {
          _step = _ForgotStep.approved;
          _statusMessage =
              'Your reset is already approved. Set your new password below.';
        });
      } else if (message.toLowerCase().contains('already pending')) {
        setState(() {
          _step = _ForgotStep.waiting;
          _statusMessage = 'A request is already pending admin approval.';
        });
      } else {
        setState(() => _statusMessage = message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      final info = await ref
          .read(authProvider.notifier)
          .checkPasswordResetStatus(_employeeId);
      if (!mounted) return;
      setState(() {
        _applyStatus(
          approved: info.isApproved,
          pending: info.isPending,
          message: info.isApproved
              ? 'Approved! Set your new password below.'
              : info.isPending
                  ? 'Still waiting for admin approval.'
                  : info.message,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).setNewPassword(
            employeeId: _employeeId,
            newPassword: _newPassword.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Sign in with your new password.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeEmployeeId() {
    setState(() {
      _step = _ForgotStep.enterId;
      _statusMessage = null;
      _newPassword.clear();
      _confirm.clear();
    });
  }

  Widget _statusCard({
    required String title,
    required String body,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: ShineLogo(size: 72)),
              const SizedBox(height: 24),
              FadeSlideIn(
                child: Text(
                  switch (_step) {
                    _ForgotStep.enterId =>
                      'Forgot your password? Enter your employee ID — we will show the right next step.',
                    _ForgotStep.request =>
                      'Request admin approval to reset your password.',
                    _ForgotStep.waiting =>
                      'Your request is with the super admin.',
                    _ForgotStep.approved =>
                      'Admin approved your reset. Choose a new password.',
                  },
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
              if (_step == _ForgotStep.enterId) ...[
                TextField(
                  controller: _employeeIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  onSubmitted: (_) => _continueWithId(),
                ),
                const SizedBox(height: 24),
                ShinePrimaryButton(
                  label: 'Continue',
                  isLoading: _loading,
                  onPressed: _continueWithId,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Employee ID: $_employeeId',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _changeEmployeeId,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_step == _ForgotStep.waiting)
                  _statusCard(
                    title: 'Status: Pending approval',
                    body:
                        'Super admin has not approved yet. Tap refresh after they approve.',
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                if (_step == _ForgotStep.approved)
                  _statusCard(
                    title: 'Status: Approved',
                    body:
                        'You can set a new password now. No login or temporary password needed.',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                const SizedBox(height: 20),
                if (_step == _ForgotStep.request) ...[
                  ShinePrimaryButton(
                    label: 'Request password reset',
                    isLoading: _loading,
                    onPressed: _requestReset,
                  ),
                ],
                if (_step == _ForgotStep.waiting) ...[
                  ShinePrimaryButton(
                    label: 'Refresh status',
                    isLoading: _loading,
                    onPressed: _refreshStatus,
                  ),
                ],
                if (_step == _ForgotStep.approved) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _newPassword,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'New password',
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
                            if (v == null || v.isEmpty) {
                              return 'Enter new password';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm new password',
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
                              return 'Confirm your new password';
                            }
                            if (v != _newPassword.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ShinePrimaryButton(
                          label: 'Update password',
                          isLoading: _loading,
                          onPressed: _loading ? null : _setPassword,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (_statusMessage != null &&
                  _step != _ForgotStep.waiting &&
                  _step != _ForgotStep.approved) ...[
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
