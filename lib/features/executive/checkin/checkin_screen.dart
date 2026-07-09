import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/visit.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/ux_components.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, required this.farmId});

  final String farmId;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _pageController = PageController();
  int _step = 0;
  Visit? _visit;
  bool _loading = false;
  bool _recording = false;
  bool _voiceMarked = false;
  String? _voicePath;
  String? _errorMessage;
  final List<String> _photos = [];
  FarmHealthStatus? _condition;
  String? _farmName;

  static const _stepLabels = [
    'Start',
    'Photos',
    'Voice',
    'Condition',
    'Submit',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _startVisit() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final user = ref.read(currentUserProvider)!;
      final farm =
          await ref.read(farmRepositoryProvider).getFarmById(widget.farmId);
      if (farm == null) {
        setState(() => _errorMessage = 'Farm not found.');
        return;
      }

      _farmName = farm.name;
      final loc = ref.read(locationProvider);
      final lat = loc.position?.latitude ?? farm.latitude;
      final lng = loc.position?.longitude ?? farm.longitude;

      final ongoing =
          await ref.read(visitRepositoryProvider).getOngoingVisit(user.id);
      if (ongoing != null && ongoing.farmId == widget.farmId) {
        _visit = ongoing;
      } else if (ongoing != null) {
        setState(() {
          _errorMessage =
              'You already have a visit in progress at ${ongoing.farmName}. Finish that visit first.';
        });
        return;
      } else {
        _visit = await ref.read(visitRepositoryProvider).startVisit(
              farmId: farm.id,
              farmName: farm.name,
              executiveId: user.id,
              executiveName: user.name,
              latitude: lat,
              longitude: lng,
            );
      }
      _goToStep(1);
    } catch (e) {
      setState(() => _errorMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    _clearError();
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _photos.add(image.path));
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _errorMessage = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (_visit == null || _condition == null) {
      setState(() {
        _errorMessage = 'Select a farm condition before submitting.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final loc = ref.read(locationProvider);
      final checkoutLat =
          loc.position?.latitude ?? _visit!.latitude ?? 17.385;
      final checkoutLng =
          loc.position?.longitude ?? _visit!.longitude ?? 78.4867;

      await ref.read(visitRepositoryProvider).submitVisit(
            visitId: _visit!.id,
            photos: _photos,
            checkoutLat: checkoutLat,
            checkoutLng: checkoutLng,
            voiceNotePath: _voicePath,
            mcqAnswers: {'farm_condition': _condition!.name},
            condition: _condition,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visit submitted successfully'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: Text(
          _farmName ?? 'Farm Visit',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHeader),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final done = i < _step;
                final active = i == _step;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.secondary
                              : active
                                  ? AppColors.primaryBright
                                  : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepLabels[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.75),
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FriendlyErrorBanner(
                message: _errorMessage!,
                icon: Icons.error_outline_rounded,
                onRetry: _step == 0 ? _startVisit : _submit,
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StartStep(loading: _loading, onStart: _startVisit),
                _PhotosStep(
                  photos: _photos,
                  onAdd: _pickPhoto,
                  onNext: () => _goToStep(2),
                ),
                _VoiceStep(
                  isRecording: _recording,
                  hasVoice: _voiceMarked,
                  onToggle: () => setState(() {
                    _recording = !_recording;
                    if (!_recording) {
                      _voiceMarked = true;
                      _voicePath = null;
                    }
                  }),
                  onNext: () => _goToStep(3),
                ),
                _ConditionStep(
                  selected: _condition,
                  onSelected: (c) => setState(() => _condition = c),
                  onNext: () => _goToStep(4),
                ),
                _SubmitStep(
                  photos: _photos,
                  condition: _condition,
                  hasVoice: _voiceMarked,
                  loading: _loading,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartStep extends StatelessWidget {
  const _StartStep({required this.loading, required this.onStart});

  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondaryMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gps_fixed_rounded,
              size: 56,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Start Visit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your check-in time and location will be recorded automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          ShinePrimaryButton(
            label: 'Start Visit',
            isLoading: loading,
            icon: Icons.play_arrow_rounded,
            onPressed: loading ? null : onStart,
          ),
        ],
      ),
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({
    required this.photos,
    required this.onAdd,
    required this.onNext,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture Photos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional — add photos of the farm condition',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: photos.length + 1,
              itemBuilder: (context, i) {
                if (i == photos.length) {
                  return InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: AppColors.cardDecoration(radius: 14),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(photos[i]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              },
            ),
          ),
          ShinePrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _VoiceStep extends StatelessWidget {
  const _VoiceStep({
    required this.isRecording,
    required this.hasVoice,
    required this.onToggle,
    required this.onNext,
  });

  final bool isRecording;
  final bool hasVoice;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Voice Note',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasVoice ? 'Voice note marked' : 'Optional — tap to mark voice note',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          VoiceRecorderButton(isRecording: isRecording, onToggle: onToggle),
          const Spacer(),
          ShinePrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _ConditionStep extends StatelessWidget {
  const _ConditionStep({
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  final FarmHealthStatus? selected;
  final ValueChanged<FarmHealthStatus> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Condition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select the current health of the crop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConditionSelector(selected: selected, onSelected: onSelected),
          const SizedBox(height: AppSpacing.xl),
          ShinePrimaryButton(
            label: 'Review & Submit',
            onPressed: selected != null ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _SubmitStep extends StatelessWidget {
  const _SubmitStep({
    required this.photos,
    required this.condition,
    required this.hasVoice,
    required this.loading,
    required this.onSubmit,
  });

  final List<String> photos;
  final FarmHealthStatus? condition;
  final bool hasVoice;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review Visit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppColors.cardDecoration(radius: AppSpacing.radiusLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(
                    icon: Icons.photo_outlined,
                    label: 'Photos',
                    value: '${photos.length} attached',
                  ),
                  const Divider(height: 24),
                  _ReviewRow(
                    icon: Icons.mic_none_rounded,
                    label: 'Voice note',
                    value: hasVoice ? 'Marked' : 'Skipped',
                  ),
                  const Divider(height: 24),
                  _ReviewRow(
                    icon: Icons.eco_outlined,
                    label: 'Condition',
                    value: condition?.label ?? 'Not selected',
                    highlight: condition != null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ShinePrimaryButton(
            label: 'Submit Visit',
            isLoading: loading,
            icon: Icons.check_rounded,
            onPressed: loading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
