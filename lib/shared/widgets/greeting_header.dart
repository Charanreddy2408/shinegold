import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../utils/l10n_ext.dart';
import 'app_background.dart';
import 'shine_logo.dart';

/// Time-of-day greeting shared by the executive and admin dashboards.
String greetingForTimeOfDay(BuildContext context, [DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return context.l10n.goodMorning;
  if (hour < 17) return context.l10n.goodAfternoon;
  return context.l10n.goodEvening;
}

/// Dashboard header: brand logo on the left, date + greeting + name stacked
/// on the right.
class BrandGreetingHeader extends StatelessWidget {
  const BrandGreetingHeader({
    super.key,
    required this.name,
    this.date,
    this.logoSize = 112,
  });

  /// Already-formatted name line, e.g. `G. Muddugangappa` or `Hi, Priya`.
  final String name;
  final DateTime? date;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateStr = DateFormat('EEEE, dd MMM').format(date ?? DateTime.now());

    return GradientHeader(
      titleWidget: ShineLogo(size: logoSize),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateStr,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            greetingForTimeOfDay(context),
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              name,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
