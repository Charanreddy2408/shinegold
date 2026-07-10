import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/fade_slide_in.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_logo.dart';

enum _ForgotStep { request, waiting, approved }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.request;
  final _employeeIdController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
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
        setState(() => _step = _ForgotStep.waiting);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkApproval() async {
    setState(() => _loading = true);
    try {
      final approved = await ref
          .read(authProvider.notifier)
          .checkPasswordResetApproved(_employeeIdController.text.trim());
      if (!mounted) return;
      if (approved) {
        setState(() => _step = _ForgotStep.approved);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still waiting for admin approval.')),
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
              const Center(child: ShineLogo(size: 72)),
              const SizedBox(height: 24),
              FadeSlideIn(
                child: Text(
                  _step == _ForgotStep.request
                      ? 'Request a password reset from your super admin.'
                      : _step == _ForgotStep.waiting
                          ? 'Waiting for super admin approval...'
                          : 'Your reset was approved',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
              if (_step != _ForgotStep.approved) ...[
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
              if (_step == _ForgotStep.waiting) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your request is pending. Check back after your admin approves it. '
                    'Once approved, log in with the temporary password your admin provides, '
                    'then change your password from your profile.',
                  ),
                ),
                const SizedBox(height: 24),
                ShinePrimaryButton(
                  label: 'Check Approval Status',
                  isLoading: _loading,
                  onPressed: _checkApproval,
                ),
              ],
              if (_step == _ForgotStep.approved) ...[
                const Text(
                  'Your password reset has been approved. Log in with the temporary '
                  'password from your admin, then use Change Password in your profile.',
                ),
                const SizedBox(height: 24),
                ShinePrimaryButton(
                  label: 'Go to Login',
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
