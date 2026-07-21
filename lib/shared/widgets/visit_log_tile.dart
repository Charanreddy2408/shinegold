import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/farm.dart';
import '../providers/repository_providers.dart';
import '../utils/media_url.dart';
import 'shine_buttons.dart';
import 'ux_components.dart';

class VisitLogTile extends StatelessWidget {
  const VisitLogTile({
    super.key,
    required this.log,
    this.onViewReport,
  });

  final VisitLog log;
  final VoidCallback? onViewReport;

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '—';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final dateOnlyFormat = DateFormat('dd MMM yyyy');
    final dateLabel = dateOnlyFormat.format(log.date);
    final durationLabel = formatDuration(log.durationMinutes);
    final canViewReport = onViewReport != null && log.id.isNotEmpty;
    final photoUrls = log.photoUrls
        .map(resolveMediaUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    final voiceUrl = log.voiceNoteUrl != null && log.voiceNoteUrl!.trim().isNotEmpty
        ? resolveMediaUrl(log.voiceNoteUrl!)
        : null;

    final events = <_TimelineEvent>[
      _TimelineEvent('Visit completed', dateLabel),
      if (photoUrls.isNotEmpty)
        _TimelineEvent('${photoUrls.length} photo(s) added', null),
      if (voiceUrl != null) _TimelineEvent('Voice note added', null),
      if (log.report != null && log.report!.isNotEmpty)
        _TimelineEvent('Notes', log.report),
      _TimelineEvent('Duration', durationLabel),
      _TimelineEvent('Visited by', log.visitedBy),
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
              dateLabel,
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
            if (voiceUrl != null) ...[
              const SizedBox(height: 12),
              _RecoverableVoiceNote(url: voiceUrl),
            ],
            if (photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = photoUrls[i];
                    return GestureDetector(
                      onTap: () => showPhotoGallery(
                        context,
                        urls: photoUrls,
                        initialIndex: i,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceElevated,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (canViewReport) ...[
              const SizedBox(height: 16),
              ShineSecondaryButton(
                label: 'View full report',
                onPressed: onViewReport,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecoverableVoiceNote extends ConsumerWidget {
  const _RecoverableVoiceNote({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VoiceNotePlayer(
      url: url,
      resolveUrl: (u) =>
          ref.read(uploadServiceProvider).resolvePlayableUrl(u),
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
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
