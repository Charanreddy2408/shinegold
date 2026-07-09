import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/farm.dart';

class VisitLogTile extends StatelessWidget {
  const VisitLogTile({super.key, required this.log});

  final VisitLog log;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final events = <_TimelineEvent>[
      _TimelineEvent('Visit completed', dateFormat.format(log.date)),
      if (log.photoUrls.isNotEmpty)
        _TimelineEvent('${log.photoUrls.length} photo(s) added', null),
      if (log.voiceNoteUrl != null)
        _TimelineEvent('Voice note added', null),
      if (log.report != null) _TimelineEvent('Report submitted', log.report),
      _TimelineEvent('Duration: ${log.durationMinutes} min', null),
      _TimelineEvent('Visited by ${log.visitedBy}', null),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(log.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...events.asMap().entries.map((entry) {
              final isLast = entry.key == events.length - 1;
              final event = entry.value;
              return _TimelineRow(
                title: event.title,
                subtitle: event.subtitle,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent(this.title, this.subtitle);
  final String title;
  final String? subtitle;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    this.subtitle,
    required this.isLast,
  });

  final String title;
  final String? subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
