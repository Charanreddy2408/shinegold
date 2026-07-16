import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/password_reset_request.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve password reset?'),
        content: Text(
          'Allow ${request.userName} (${request.employeeId}) to set a new '
          'password from their profile. You will not set a temporary password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).approvePasswordReset(
            requestId: request.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approved — ${request.employeeId} can now set a new password',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                      'Review executive password-reset requests. Approve so they can set a new password themselves.',
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
                  ? const ListLoadingSkeleton(itemCount: 5, itemHeight: 120)
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
                                              label: 'Approve',
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
