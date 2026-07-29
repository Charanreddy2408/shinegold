import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/fade_slide_in.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/l10n_ext.dart';
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
      setState(() => _statusMessage = context.l10n.enterYourEmployeeId);
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
        _statusMessage = '${ context.l10n.requestWithAdmin.split('.').first}. ${context.l10n.waitingAdminApproval.split('.').last}';
      });
    } catch (e) {
      if (!mounted) return;
      final message = formatApiError(e);
      if (message.toLowerCase().contains('already approved')) {
        setState(() {
          _step = _ForgotStep.approved;
          _statusMessage =
              context.l10n.resetApprovedSetPassword;
        });
      } else if (message.toLowerCase().contains('already pending')) {
        setState(() {
          _step = _ForgotStep.waiting;
          _statusMessage = context.l10n.requestAlreadyPendingApproval;
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
              ? context.l10n.statusApproved.split(':').last.trim() + '! ' + context.l10n.resetApprovedSetPassword
              : info.isPending
                  ? context.l10n.waitingAdminApproval
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
        SnackBar(
          content: Text(context.l10n.passwordUpdatedSignIn),
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
                SizedBox(height: 4),
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
        title: Text(context.l10n.forgotPasswordTitle),
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
              Center(child: ShineLogo(size: 72)),
              SizedBox(height: 24),
              FadeSlideIn(
                child: Text(
                  switch (_step) {
                    _ForgotStep.enterId =>
                      context.l10n.forgotYourPassword,
                    _ForgotStep.request =>
                      context.l10n.requestAdminApproval,
                    _ForgotStep.waiting =>
                      context.l10n.requestWithAdmin,
                    _ForgotStep.approved =>
                      context.l10n.adminApprovedChoose,
                  },
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              SizedBox(height: 24),
              if (_step == _ForgotStep.enterId) ...[
                TextField(
                  controller: _employeeIdController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: context.l10n.employeeId,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  onSubmitted: (_) => _continueWithId(),
                ),
                SizedBox(height: 24),
                ShinePrimaryButton(
                  label: context.l10n.continueButton,
                  isLoading: _loading,
                  onPressed: _continueWithId,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.l10n.employeeIdLabel}: $_employeeId',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _changeEmployeeId,
                      child: Text(context.l10n.change),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_step == _ForgotStep.waiting)
                  _statusCard(
                    title: context.l10n.statusPendingApproval,
                    body: context.l10n.adminNotApprovedYet,
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                if (_step == _ForgotStep.approved)
                  _statusCard(
                    title: context.l10n.statusApproved,
                    body: context.l10n.setNewPasswordNoLogin,
                    color: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                SizedBox(height: 20),
                if (_step == _ForgotStep.request) ...[
                  ShinePrimaryButton(
                    label: context.l10n.requestPasswordResetButton,
                    isLoading: _loading,
                    onPressed: _requestReset,
                  ),
                ],
                if (_step == _ForgotStep.waiting) ...[
                  ShinePrimaryButton(
                    label: context.l10n.refreshStatusButton,
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
                            if (v == null || v.isEmpty) {
                              return context.l10n.enterNewPassword;
                            }
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
                        SizedBox(height: 20),
                        ShinePrimaryButton(
                          label: context.l10n.updatePassword,
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
