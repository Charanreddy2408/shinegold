import 'dart:async';
import 'dart:io' show Directory;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/visit.dart';
import '../../../data/models/visit_form.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../visits/presentation/widgets/dynamic_visit_form.dart';
import '../../visits/presentation/widgets/visit_form_prefill_card.dart';

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
  VisitFormContext? _formContext;
  FormAnswersMap _answers = {};
  Map<String, String> _fieldErrors = {};
  bool _loading = false;
  bool _recording = false;
  bool _voiceMarked = false;
  bool _submitted = false;
  bool _cancelling = false;
  String? _voicePath;
  String? _uploadedVoiceUrl;
  final _audioRecorder = AudioRecorder();
  String? _apiErrorMessage;
  final List<XFile> _photos = [];
  String? _farmName;
  Timer? _saveDebounce;

  static const _stepLabels = ['Start', 'Report', 'Media', 'Submit'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cleanupStaleVisits());
  }

  Future<void> _cleanupStaleVisits() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final ongoing =
          await ref.read(visitRepositoryProvider).getOngoingVisit(user.id);
      if (ongoing == null) return;

      final now = DateTime.now();
      final started = ongoing.startedAt.toLocal();
      final sameDay = started.year == now.year &&
          started.month == now.month &&
          started.day == now.day;
      final sameFarm = ongoing.farmId == widget.farmId;
      if (!sameFarm || !sameDay) {
        await ref.read(visitRepositoryProvider).cancelVisit(ongoing.id);
      }
    } catch (_) {}
  }

  Future<void> _cancelActiveVisit() async {
    if (_submitted || _visit == null || _cancelling) return;
    _cancelling = true;
    try {
      await ref.read(visitRepositoryProvider).cancelVisit(_visit!.id);
    } catch (_) {}
    _cancelling = false;
  }

  Future<void> _handleExit() async {
    if (_recording) {
      await _audioRecorder.stop();
      if (mounted) setState(() => _recording = false);
    }
    await _cancelActiveVisit();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pageController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  void _clearApiError() {
    if (_apiErrorMessage != null) setState(() => _apiErrorMessage = null);
  }

  void _showValidationFeedback(int missingCount) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          missingCount == 1
              ? '1 required field still needs your answer'
              : '$missingCount required fields still need your answers',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _runFormValidation({bool showFeedback = true}) {
    if (_formContext == null) return true;
    final errors = DynamicVisitForm.validateRequired(
      _formContext!.template,
      _answers,
    );
    setState(() {
      _fieldErrors = errors;
      _apiErrorMessage = null;
    });
    if (errors.isNotEmpty && showFeedback) {
      _showValidationFeedback(errors.length);
    }
    return errors.isEmpty;
  }

  Future<void> _startVisit() async {
    setState(() {
      _loading = true;
      _apiErrorMessage = null;
    });
    try {
      final user = ref.read(currentUserProvider)!;
      final farm =
          await ref.read(farmRepositoryProvider).getFarmById(widget.farmId);
      if (farm == null) {
        setState(() => _apiErrorMessage = 'Farm not found.');
        return;
      }

      _farmName = farm.name;
      final loc = ref.read(locationProvider);
      final lat = loc.position?.latitude ?? farm.latitude;
      final lng = loc.position?.longitude ?? farm.longitude;

      final ongoing =
          await ref.read(visitRepositoryProvider).getOngoingVisit(user.id);
      if (ongoing != null) {
        await ref.read(visitRepositoryProvider).cancelVisit(ongoing.id);
      }

      _visit = await ref.read(visitRepositoryProvider).startVisit(
            farmId: farm.id,
            farmName: farm.name,
            executiveId: user.id,
            executiveName: user.name,
            latitude: lat,
            longitude: lng,
          );

      _formContext = await ref
          .read(visitRepositoryProvider)
          .getVisitFormContext(_visit!.id);
      _goToStep(1);
    } catch (e) {
      setState(() => _apiErrorMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onAnswersChanged(FormAnswersMap answers) {
    setState(() {
      _answers = answers;
      if (_fieldErrors.isNotEmpty) {
        _fieldErrors = Map.fromEntries(
          _fieldErrors.entries.where((e) {
            final raw = answers[e.key];
            if (raw == null) return true;
            if (raw is String && raw.trim().isEmpty) return true;
            if (raw is List && raw.isEmpty) return true;
            return false;
          }),
        );
      }
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _saveFormProgress);
  }

  Future<void> _saveFormProgress() async {
    if (_visit == null || _formContext == null) return;
    try {
      final entries = DynamicVisitForm.toFormAnswers(
        _formContext!.template,
        _answers,
      );
      if (entries.isEmpty) return;
      await ref.read(visitRepositoryProvider).saveVisitForm(
            visitId: _visit!.id,
            formAnswers: entries,
          );
    } catch (_) {}
  }

  RecordConfig get _voiceRecordConfig {
    if (kIsWeb) {
      return const RecordConfig(encoder: AudioEncoder.wav);
    }
    return const RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
      numChannels: 1,
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_recording) {
      try {
        final path = await _audioRecorder.stop();
        if (!mounted) return;
        setState(() {
          _recording = false;
          _voicePath = path;
          _voiceMarked = path != null && path.isNotEmpty;
        });
        if (path != null && path.isNotEmpty && _visit != null) {
          await _uploadVoiceNote(path);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _recording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not stop recording: ${formatApiError(e)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!kIsWeb) {
      var hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        final status = await Permission.microphone.request();
        hasPermission = status.isGranted;
      }
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final path = kIsWeb
        ? 'visit_voice_${const Uuid().v4()}.wav'
        : '${Directory.systemTemp.path}/visit_voice_${const Uuid().v4()}.m4a';

    try {
      await _audioRecorder.start(_voiceRecordConfig, path: path);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _voicePath = path;
        _voiceMarked = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start recording: ${formatApiError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadVoiceNote(String path) async {
    if (_visit == null) return;
    try {
      final uploads = ref.read(uploadServiceProvider);
      final url = kIsWeb || path.startsWith('blob:')
          ? await uploads.uploadXFile(
              file: XFile(
                path,
                mimeType: kIsWeb ? 'audio/wav' : null,
                name: 'visit_voice.wav',
              ),
              context: 'visit_voice',
            )
          : await uploads.uploadFile(
              localPath: path,
              context: 'visit_voice',
            );
      await ref.read(visitRepositoryProvider).saveVisitForm(
            visitId: _visit!.id,
            voiceNotePath: url,
          );
      if (mounted) setState(() => _uploadedVoiceUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice upload failed: ${formatApiError(e)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    _clearApiError();
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos allowed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ImageSource source = ImageSource.camera;
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      final picked = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      source = picked;
    }

    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _photos.add(image));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      if (step != 1) _apiErrorMessage = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (_visit == null) return;
    if (!_runFormValidation()) {
      _goToStep(1);
      return;
    }

    setState(() {
      _loading = true;
      _apiErrorMessage = null;
    });

    try {
      final loc = ref.read(locationProvider);
      final checkoutLat =
          loc.position?.latitude ?? _visit!.latitude ?? 17.385;
      final checkoutLng =
          loc.position?.longitude ?? _visit!.longitude ?? 78.4867;

      final formAnswers = _formContext != null
          ? DynamicVisitForm.toFormAnswers(_formContext!.template, _answers)
          : null;
      final actionPlan = _answers['action_plan']?.toString();

      await ref.read(visitRepositoryProvider).submitVisit(
            visitId: _visit!.id,
            photos: _photos.map((photo) => photo.path).toList(),
            checkoutLat: checkoutLat,
            checkoutLng: checkoutLng,
            voiceNotePath: _uploadedVoiceUrl ?? _voicePath,
            textNote: actionPlan,
            formAnswers: formAnswers,
          );

      if (!mounted) return;
      setState(() => _submitted = true);
      bumpAppRefresh(ref);
      unawaited(ref.read(authProvider.notifier).refreshUser());
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
      setState(() => _apiErrorMessage = formatApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _submitted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _loading ? null : _handleExit,
        ),
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
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
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
          if (_apiErrorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FriendlyErrorBanner(
                message: _apiErrorMessage!,
                icon: Icons.wifi_off_rounded,
                onRetry: _step == 0 ? _startVisit : _submit,
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StartStep(loading: _loading, onStart: _startVisit),
                _FormStep(
                  formContext: _formContext,
                  answers: _answers,
                  fieldErrors: _fieldErrors,
                  onChanged: _onAnswersChanged,
                  onNext: () {
                    if (_runFormValidation()) {
                      _goToStep(2);
                    }
                  },
                ),
                _MediaStep(
                  photos: _photos,
                  isRecording: _recording,
                  hasVoice: _voiceMarked,
                  onAddPhoto: _pickPhoto,
                  onRemovePhoto: _removePhoto,
                  onToggleVoice: _toggleVoiceRecording,
                  onNext: () => _goToStep(3),
                ),
                _SubmitStep(
                  formContext: _formContext,
                  answers: _answers,
                  photos: _photos,
                  hasVoice: _voiceMarked,
                  loading: _loading,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
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
            'Check-in records your time and location. You will then complete the field visit report.',
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

class _FormStep extends StatefulWidget {
  const _FormStep({
    required this.formContext,
    required this.answers,
    required this.fieldErrors,
    required this.onChanged,
    required this.onNext,
  });

  final VisitFormContext? formContext;
  final FormAnswersMap answers;
  final Map<String, String> fieldErrors;
  final ValueChanged<FormAnswersMap> onChanged;
  final VoidCallback onNext;

  @override
  State<_FormStep> createState() => _FormStepState();
}

class _FormStepState extends State<_FormStep> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FormStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fieldErrors.isNotEmpty &&
        oldWidget.fieldErrors.isEmpty &&
        _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.formContext == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final missingCount = widget.fieldErrors.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              missingCount == 1
                                  ? '1 required field needs your answer below'
                                  : '$missingCount required fields need your answers below',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                VisitFormPrefillCard(prefill: widget.formContext!.prefill),
                const SizedBox(height: AppSpacing.lg),
                DynamicVisitForm(
                  template: widget.formContext!.template,
                  answers: widget.answers,
                  fieldErrors: widget.fieldErrors,
                  onChanged: widget.onChanged,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ShinePrimaryButton(
            label: 'Continue to Media',
            onPressed: widget.onNext,
          ),
        ),
      ],
    );
  }
}

class _MediaStep extends StatelessWidget {
  const _MediaStep({
    required this.photos,
    required this.isRecording,
    required this.hasVoice,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onToggleVoice,
    required this.onNext,
  });

  final List<XFile> photos;
  final bool isRecording;
  final bool hasVoice;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onToggleVoice;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos & Voice',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional — up to 5 geotagged photos and a voice note',
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
                    onTap: onAddPhoto,
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
                return _VisitPhotoTile(
                  file: photos[i],
                  onRemove: () => onRemovePhoto(i),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: VoiceRecorderButton(
              isRecording: isRecording,
              onToggle: onToggleVoice,
            ),
          ),
          if (hasVoice)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Voice note marked',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          ShinePrimaryButton(label: 'Review & Submit', onPressed: onNext),
        ],
      ),
    );
  }
}

class _SubmitStep extends StatelessWidget {
  const _SubmitStep({
    required this.formContext,
    required this.answers,
    required this.photos,
    required this.hasVoice,
    required this.loading,
    required this.onSubmit,
  });

  final VisitFormContext? formContext;
  final FormAnswersMap answers;
  final List<XFile> photos;
  final bool hasVoice;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final requiredCount = formContext?.template.inputQuestions
            .where((q) => q.isRequired)
            .length ??
        0;
    final answeredRequired = formContext?.template.inputQuestions
            .where((q) => q.isRequired && answers.containsKey(q.questionKey))
            .length ??
        0;

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
                    icon: Icons.assignment_outlined,
                    label: 'Report fields',
                    value: '$answeredRequired / $requiredCount required',
                    highlight: answeredRequired == requiredCount,
                  ),
                  const Divider(height: 24),
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

class _VisitPhotoTile extends StatelessWidget {
  const _VisitPhotoTile({
    required this.file,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(Icons.broken_image_outlined),
                );
              }
              if (!snapshot.hasData) {
                return Container(
                  color: AppColors.surfaceElevated,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
