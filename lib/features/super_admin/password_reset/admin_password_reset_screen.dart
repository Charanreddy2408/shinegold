import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/password_reset_request.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/gold_shimmer.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_empty_state.dart';

class AdminPasswordResetScreen extends ConsumerStatefulWidget {
  const AdminPasswordResetScreen({super.key});

  @override
  ConsumerState<AdminPasswordResetScreen> createState() =>
      _AdminPasswordResetScreenState();
}

class _AdminPasswordResetScreenState
    extends ConsumerState<AdminPasswordResetScreen> {
  List<PasswordResetRequestItem> _requests = [];
  bool _loading = true;
  bool _pendingOnly = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authRepositoryProvider).listPasswordResetRequests(
            status: _pendingOnly ? 'pending' : null,
            pageSize: 50,
          );
      if (mounted) {
        setState(() {
          _requests = result.items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = formatApiError(e);
        });
      }
    }
  }

  Future<void> _approve(PasswordResetRequestItem request) async {
    final tempPassword = TextEditingController();
    final approved = await showAdminFormSheet<bool>(
      context: context,
      title: 'Approve Reset',
      subtitle: 'Set a temporary password for ${request.employeeId}',
      icon: Icons.lock_reset_rounded,
      submitLabel: 'Approve & Set Password',
      fields: [
        AdminFormField(
          controller: tempPassword,
          label: 'Temporary password',
          icon: Icons.key_rounded,
          obscureText: true,
          hint: 'Min. 6 characters — share with the executive',
        ),
      ],
      onSubmit: () async {
        final password = tempPassword.text.trim();
        if (password.length < 6) {
          throw Exception('Temporary password must be at least 6 characters');
        }
        await ref.read(authRepositoryProvider).approvePasswordReset(
              requestId: request.id,
              tempPassword: password,
            );
      },
    );
    disposeSheetControllers([tempPassword]);

    if (approved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset approved for ${request.employeeId}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Password Resets'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Review executive forgot-password requests and issue temporary passwords.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Pending'),
                    icon: Icon(Icons.pending_actions_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('All'),
                    icon: Icon(Icons.history_rounded, size: 18),
                  ),
                ],
                selected: {_pendingOnly},
                onSelectionChanged: (value) {
                  setState(() => _pendingOnly = value.first);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => const ShimmerBox(height: 120),
                    )
                  : _error != null
                      ? ShineEmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load requests',
                          subtitle: _error!,
                          action: ShineSecondaryButton(
                            label: 'Retry',
                            onPressed: _load,
                          ),
                        )
                      : _requests.isEmpty
                          ? ShineEmptyState(
                              icon: Icons.verified_user_outlined,
                              title: _pendingOnly
                                  ? 'No pending requests'
                                  : 'No reset requests yet',
                              subtitle: _pendingOnly
                                  ? 'Requests from the forgot-password screen will appear here.'
                                  : 'Approved and pending requests will show in this list.',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _requests.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final request = _requests[index];
                                  return StaggeredListItem(
                                    index: index,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.borderSubtle,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      request.userName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      request.employeeId,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .textMuted,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                    request.status,
                                                  ).withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    20,
                                                  ),
                                                ),
                                                child: Text(
                                                  _statusLabel(request.status),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: _statusColor(
                                                          request.status,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Requested ${dateFormat.format(request.requestedAt.toLocal())}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                          if (request.isPending) ...[
                                            const SizedBox(height: 14),
                                            ShinePrimaryButton(
                                              label: 'Approve with temp password',
                                              icon: Icons.check_circle_outline,
                                              onPressed: () =>
                                                  _approve(request),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
