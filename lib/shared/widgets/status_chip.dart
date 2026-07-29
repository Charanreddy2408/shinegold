import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../utils/l10n_ext.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final dynamic status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = _resolve(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(BuildContext context, dynamic status) {
    if (status is FarmVisitStatus) {
      switch (status) {
        case FarmVisitStatus.pending:
          return (
            context.l10n.pending,
            AppColors.primaryDark,
            AppColors.primarySoft,
          );
        case FarmVisitStatus.ongoing:
          return (
            context.l10n.ongoingLabel,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case FarmVisitStatus.visited:
          return (
            context.l10n.completedLabel,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case FarmVisitStatus.harvested:
          return (
            context.l10n.harvestedLabel,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case FarmVisitStatus.blocked:
          return (
            context.l10n.blockedLabel,
            AppColors.error,
            AppColors.errorSoft,
          );
      }
    }
    if (status is VisitStatus) {
      switch (status) {
        case VisitStatus.ongoing:
          return (
            context.l10n.ongoingLabel,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case VisitStatus.completed:
          return (
            context.l10n.completedLabel,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case VisitStatus.cancelled:
          return (
            context.l10n.cancelledLabel,
            AppColors.error,
            AppColors.errorSoft,
          );
      }
    }
    if (status is ExecutiveStatus) {
      switch (status) {
        case ExecutiveStatus.active:
          return (
            context.l10n.active,
            AppColors.secondary,
            AppColors.secondaryMuted,
          );
        case ExecutiveStatus.blocked:
          return (
            context.l10n.blockedLabel,
            AppColors.error,
            AppColors.errorSoft,
          );
      }
    }
    return (
      status.toString(),
      AppColors.textSecondary,
      AppColors.surfaceElevated
    );
  }
}
