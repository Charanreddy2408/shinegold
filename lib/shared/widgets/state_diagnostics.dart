import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/utils/l10n_ext.dart';

/// Health of one step in a flow.
enum DiagnosticStatus {
  /// Working as expected.
  ok,

  /// Still running — no verdict yet.
  pending,

  /// Degraded, but the flow can continue.
  warning,

  /// Broken. The flow cannot continue until this is resolved.
  failed,
}

extension DiagnosticStatusUi on DiagnosticStatus {
  Color get color => switch (this) {
        DiagnosticStatus.ok => AppColors.success,
        DiagnosticStatus.pending => AppColors.info,
        DiagnosticStatus.warning => AppColors.warning,
        DiagnosticStatus.failed => AppColors.error,
      };

  IconData get icon => switch (this) {
        DiagnosticStatus.ok => Icons.check_circle_rounded,
        DiagnosticStatus.pending => Icons.hourglass_top_rounded,
        DiagnosticStatus.warning => Icons.warning_amber_rounded,
        DiagnosticStatus.failed => Icons.error_rounded,
      };

  String get label => switch (this) {
        DiagnosticStatus.ok => 'OK',
        DiagnosticStatus.pending => 'Checking',
        DiagnosticStatus.warning => 'Degraded',
        DiagnosticStatus.failed => 'Failed',
      };
}

/// One line in a diagnostics report: what was checked, how it went, and — when
/// something went wrong — the raw error plus what to do about it.
class DiagnosticItem {
  const DiagnosticItem({
    required this.label,
    required this.status,
    this.detail,
    this.hint,
  });

  final String label;
  final DiagnosticStatus status;

  /// Human-readable outcome, including the raw error text when there is one.
  final String? detail;

  /// What the user can do to clear it.
  final String? hint;

  bool get isProblem =>
      status == DiagnosticStatus.failed || status == DiagnosticStatus.warning;

  String toPlainText() {
    final buffer = StringBuffer('[${status.label}] $label');
    if (detail != null && detail!.isNotEmpty) buffer.write('\n    $detail');
    if (hint != null && hint!.isNotEmpty) buffer.write('\n    → $hint');
    return buffer.toString();
  }
}

/// Compact status strip: one glanceable summary line that opens the full report.
///
/// Use this above an action the user might find "unresponsive" — it turns a
/// dead-looking button into a visible, explained state.
class StateDiagnosticsBar extends StatelessWidget {
  const StateDiagnosticsBar({
    super.key,
    required this.items,
    required this.title,
    this.okMessage = 'All checks passed',
  });

  final List<DiagnosticItem> items;
  final String title;
  final String okMessage;

  DiagnosticStatus get _worst {
    if (items.any((i) => i.status == DiagnosticStatus.failed)) {
      return DiagnosticStatus.failed;
    }
    if (items.any((i) => i.status == DiagnosticStatus.warning)) {
      return DiagnosticStatus.warning;
    }
    if (items.any((i) => i.status == DiagnosticStatus.pending)) {
      return DiagnosticStatus.pending;
    }
    return DiagnosticStatus.ok;
  }

  @override
  Widget build(BuildContext context) {
    final worst = _worst;
    final problems = items.where((i) => i.isProblem).toList();
    final summary = problems.isEmpty
        ? okMessage
        : problems.length == 1
            ? '${problems.first.label}: ${problems.first.detail ?? problems.first.status.label}'
            : '${problems.length} checks need attention';

    return Material(
      color: worst.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => showStateDiagnostics(context, title: title, items: items),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: worst.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(worst.icon, size: 18, color: worst.color),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Text(context.l10n.details,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: worst.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: worst.color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full report sheet — every check, its raw error, and the fix. Copyable so the
/// executive can paste the exact failure into a support message.
Future<void> showStateDiagnostics(
  BuildContext context, {
  required String title,
  required List<DiagnosticItem> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusHeader),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy report',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    final report = items.map((i) => i.toPlainText()).join('\n');
                    Clipboard.setData(ClipboardData(text: '$title\n\n$report'));
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text('Report copied')),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) => _DiagnosticTile(item: items[index]),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(context.l10n.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({required this.item});

  final DiagnosticItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.status.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.status.icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      item.status.label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
                if (item.detail != null && item.detail!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.detail!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (item.hint != null && item.hint!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '→ ${item.hint!}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
