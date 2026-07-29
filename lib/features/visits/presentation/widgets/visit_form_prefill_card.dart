import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/visit_form.dart';
import '../../../../shared/utils/l10n_ext.dart';

class VisitFormPrefillCard extends StatelessWidget {
  const VisitFormPrefillCard({super.key, required this.prefill});

  final VisitFormPrefill prefill;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('dd MMM yyyy · hh:mm a');
    final rows = <_PrefillRow>[
      _PrefillRow(context.l10n.executiveLabel, prefill.executiveName),
      _PrefillRow(context.l10n.visitDateLabel, prefill.visitDate),
      if (prefill.farmLocation != null && prefill.farmLocation!.isNotEmpty)
        _PrefillRow(context.l10n.farmLocationLabel, prefill.farmLocation!),
      if (prefill.farmerContactName != null &&
          prefill.farmerContactName!.isNotEmpty)
        _PrefillRow(context.l10n.farmer, prefill.farmerContactName!),
      if (prefill.checkinTime != null)
        _PrefillRow(
          context.l10n.checkInLabel,
          timeFormat.format(prefill.checkinTime!.toLocal()),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(radius: AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.visitInformation,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefillRow {
  const _PrefillRow(this.label, this.value);
  final String label;
  final String value;
}
