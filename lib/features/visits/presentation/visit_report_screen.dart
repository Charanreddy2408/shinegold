import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/visit.dart';
import '../../../data/models/visit_form.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/utils/media_url.dart';

class VisitReportScreen extends ConsumerStatefulWidget {
  const VisitReportScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<VisitReportScreen> createState() => _VisitReportScreenState();
}

class _VisitReportScreenState extends ConsumerState<VisitReportScreen> {
  Visit? _visit;
  VisitFormTemplate? _template;
  bool _loading = true;
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
      final repo = ref.read(visitRepositoryProvider);
      final visit = await repo.getVisitById(widget.visitId);
      VisitFormTemplate? template;
      try {
        template = (await repo.getVisitFormContext(widget.visitId)).template;
      } catch (_) {
        template = null;
      }
      if (!mounted) return;
      setState(() {
        _visit = visit;
        _template = template;
        _loading = false;
        if (visit == null) _error = 'Visit report not found.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatApiError(e);
      });
    }
  }

  static String formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  static String formatDurationFromVisit(Visit visit) {
    final mins = visit.durationMinutes;
    if (mins != null) return formatDuration(mins);
    if (visit.endedAt != null) {
      final seconds = visit.endedAt!.difference(visit.startedAt).inSeconds;
      return formatDuration((seconds / 60).round());
    }
    return '—';
  }

  String? get _voiceNoteUrl {
    final visit = _visit;
    if (visit == null) return null;
    final url = visit.voiceNotePath;
    if (url != null && url.trim().isNotEmpty) return resolveMediaUrl(url);
    return null;
  }

  bool get _showVoiceSection {
    final visit = _visit;
    if (visit == null) return false;
    return visit.hasVoiceNote || _voiceNoteUrl != null;
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd MMM yyyy · hh:mm a');
    final voiceUrl = _voiceNoteUrl;

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: const Text(
          'Visit Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const ListLoadingSkeleton(itemCount: 6, itemHeight: 72)
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: FriendlyErrorBanner(
                    message: _error!,
                    onRetry: _load,
                  ),
                )
              : _visit == null
                  ? const SizedBox.shrink()
                  : AppBackground(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _SummaryCard(
                            visit: _visit!,
                            dateTimeFormat: dateTimeFormat,
                            durationLabel: formatDurationFromVisit(_visit!),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Field Report',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_visit!.formAnswers.isEmpty &&
                              (_visit!.textNote == null ||
                                  _visit!.textNote!.isEmpty))
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: AppColors.cardDecoration(),
                              child: Text(
                                'No structured report answers were saved for this visit.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else ...[
                            ..._visit!.formAnswers.map(
                              (a) => _AnswerCard(
                                answer: a,
                                template: _template,
                              ),
                            ),
                            if (_visit!.textNote != null &&
                                _visit!.textNote!.isNotEmpty)
                              _AnswerCard(
                                answer: FormAnswerDisplay(
                                  questionKey: 'notes',
                                  questionLabel: 'Additional notes',
                                  questionType: FormQuestionType.textarea,
                                  answer: _visit!.textNote,
                                ),
                                template: _template,
                              ),
                          ],
                          if (_showVoiceSection) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Voice Note',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (voiceUrl != null)
                              VoiceNotePlayer(url: voiceUrl)
                            else
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: AppColors.cardDecoration(),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mic_off_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Voice note was recorded but the audio file is not available.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          if (_visit!.photos.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Photos (${_visit!.photos.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _visit!.photos.length,
                              itemBuilder: (context, i) {
                                final url =
                                    resolveMediaUrl(_visit!.photos[i]);
                                return GestureDetector(
                                  onTap: () => showPhotoGallery(
                                    context,
                                    urls: _visit!.photos
                                        .map(resolveMediaUrl)
                                        .toList(),
                                    initialIndex: i,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppColors.surfaceElevated,
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.surfaceElevated,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.visit,
    required this.dateTimeFormat,
    required this.durationLabel,
  });

  final Visit visit;
  final DateFormat dateTimeFormat;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(radius: AppSpacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.farmName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusChip(status: visit.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Row('Executive', visit.executiveName),
          _Row(
            'Check-in',
            dateTimeFormat.format(visit.startedAt.toLocal()),
          ),
          if (visit.endedAt != null)
            _Row(
              'Check-out',
              dateTimeFormat.format(visit.endedAt!.toLocal()),
            ),
          _Row('Duration', durationLabel),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.template,
  });

  final FormAnswerDisplay answer;
  final VisitFormTemplate? template;

  @override
  Widget build(BuildContext context) {
    if (answer.questionType == FormQuestionType.sectionHeader) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          answer.questionLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
        ),
      );
    }

    if (answer.questionType == FormQuestionType.matrix) {
      final entries = answer.matrixEntries(template: template);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppColors.cardDecoration(radius: AppSpacing.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              answer.questionLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text(
                '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              )
            else
              ...entries.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryMuted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            entry.value,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppColors.cardDecoration(radius: AppSpacing.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer.questionLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            answer.displayValue(template: template),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
