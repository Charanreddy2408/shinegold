import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final dynamic status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = _resolve(status);

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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(dynamic status) {
    if (status is FarmVisitStatus) {
      switch (status) {
        case FarmVisitStatus.pending:
          return ('Pending', AppColors.primaryDark, AppColors.primarySoft);
        case FarmVisitStatus.ongoing:
          return ('Ongoing', AppColors.secondary, AppColors.secondaryMuted);
        case FarmVisitStatus.visited:
          return ('Completed', AppColors.secondary, AppColors.secondaryMuted);
        case FarmVisitStatus.harvested:
          return ('Harvested', AppColors.secondary, AppColors.secondaryMuted);
        case FarmVisitStatus.blocked:
          return ('Blocked', AppColors.error, AppColors.errorSoft);
      }
    }
    if (status is VisitStatus) {
      switch (status) {
        case VisitStatus.ongoing:
          return ('Ongoing', AppColors.secondary, AppColors.secondaryMuted);
        case VisitStatus.completed:
          return ('Completed', AppColors.secondary, AppColors.secondaryMuted);
        case VisitStatus.cancelled:
          return ('Cancelled', AppColors.error, AppColors.errorSoft);
      }
    }
    if (status is ExecutiveStatus) {
      switch (status) {
        case ExecutiveStatus.active:
          return ('Active', AppColors.secondary, AppColors.secondaryMuted);
        case ExecutiveStatus.blocked:
          return ('Blocked', AppColors.error, AppColors.errorSoft);
      }
    }
    return (
      status.toString(),
      AppColors.textSecondary,
      AppColors.surfaceElevated
    );
  }
}
