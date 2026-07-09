import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/fade_slide_in.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/shine_buttons.dart';
import '../../shared/widgets/shine_logo.dart';

enum _ForgotStep { request, approved, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.request;
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_employeeIdController.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .requestPasswordReset(_employeeIdController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset request sent to super admin for approval.'),
          ),
        );
        setState(() => _step = _ForgotStep.approved);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkApproval() async {
    setState(() => _loading = true);
    try {
      final approved = await ref.read(authProvider.notifier).checkPasswordResetApproved(
            _employeeIdController.text.trim(),
          );
      if (!mounted) return;
      if (approved) {
        setState(() => _step = _ForgotStep.reset);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still waiting for admin approval.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPassword() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).setNewPassword(
            _employeeIdController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: ShineLogo(size: 72, inCard: true)),
              const SizedBox(height: 24),
              FadeSlideIn(
                child: Text(
                  _step == _ForgotStep.request
                      ? 'Request a password reset from your super admin.'
                      : _step == _ForgotStep.approved
                          ? 'Waiting for super admin approval...'
                          : 'Set your new password',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
              if (_step != _ForgotStep.reset) ...[
                TextField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_step == _ForgotStep.request)
                ShinePrimaryButton(
                  label: 'Request Reset',
                  isLoading: _loading,
                  onPressed: _requestReset,
                ),
              if (_step == _ForgotStep.approved) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fieldGreenMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.fieldGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top,
                          color: AppColors.fieldGreenSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request is pending. Tap below to simulate admin approval (mock).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ShinePrimaryButton(
                  label: 'Check Approval Status',
                  isLoading: _loading,
                  onPressed: _checkApproval,
                ),
              ],
              if (_step == _ForgotStep.reset) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                ShinePrimaryButton(
                  label: 'Update Password',
                  isLoading: _loading,
                  onPressed: _setPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
