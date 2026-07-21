import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/interaction.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_buttons.dart';

const _cropOptions = <String>[
  'Cotton',
  'Paddy',
  'Wheat',
  'Maize',
  'Groundnut',
  'Sugarcane',
  'Chilli',
  'Turmeric',
  'Vegetables',
  'Millets',
  'Other',
];

const _monthOptions = <int>[1, 2, 3, 4, 5, 6, 9, 12, 18, 24];

class InteractionFormScreen extends ConsumerStatefulWidget {
  const InteractionFormScreen({super.key, this.existing});

  final FarmerInteraction? existing;

  @override
  ConsumerState<InteractionFormScreen> createState() =>
      _InteractionFormScreenState();
}

class _InteractionFormScreenState extends ConsumerState<InteractionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _acres;
  late final TextEditingController _notes;
  late final TextEditingController _otherCrop;

  String? _crop;
  int? _plannedMonths;
  InteractionStatus _status = InteractionStatus.uncertain;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.farmerName ?? '');
    _phone = TextEditingController(text: e?.phoneNumber ?? '');
    _location = TextEditingController(text: e?.landLocation ?? '');
    _acres = TextEditingController(
      text: e == null ? '' : e.acres.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _otherCrop = TextEditingController();
    if (e != null) {
      _status = e.status;
      _plannedMonths = e.plannedMonths;
      if (_cropOptions.contains(e.currentCrop)) {
        _crop = e.currentCrop;
      } else {
        _crop = 'Other';
        _otherCrop.text = e.currentCrop;
      }
    } else {
      _plannedMonths = 6;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    _acres.dispose();
    _notes.dispose();
    _otherCrop.dispose();
    super.dispose();
  }

  String get _resolvedCrop {
    if (_crop == 'Other') return _otherCrop.text.trim();
    return _crop?.trim() ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_crop == null || _plannedMonths == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select crop and planned months')),
      );
      return;
    }
    if (_crop == 'Other' && _otherCrop.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the crop name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(interactionRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          widget.existing!.id,
          UpdateInteractionRequest(
            farmerName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            landLocation: _location.text.trim(),
            acres: double.parse(_acres.text.trim()),
            currentCrop: _resolvedCrop,
            plannedMonths: _plannedMonths!,
            status: _status,
            notes: _notes.text.trim().isEmpty ? '' : _notes.text.trim(),
          ),
        );
      } else {
        await repo.create(
          CreateInteractionRequest(
            farmerName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            landLocation: _location.text.trim(),
            acres: double.parse(_acres.text.trim()),
            currentCrop: _resolvedCrop,
            plannedMonths: _plannedMonths!,
            status: _status,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Interaction updated' : 'Interaction saved'),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: _isEdit ? 'Edit interaction' : 'Record interaction',
          subtitle: 'Capture prospect farmer details from your conversation',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Farmer name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: (v) {
                  if (v == null || v.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Land location',
                  hintText: 'Village / mandal / area',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _acres,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: 'Acres'),
                validator: (v) {
                  final value = double.tryParse(v?.trim() ?? '');
                  if (value == null || value <= 0) return 'Enter acres';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _crop,
                decoration: const InputDecoration(labelText: 'Current crop'),
                items: _cropOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _crop = v),
                validator: (v) => v == null ? 'Select a crop' : null,
              ),
              if (_crop == 'Other') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _otherCrop,
                  decoration:
                      const InputDecoration(labelText: 'Specify crop'),
                  validator: (v) {
                    if (_crop == 'Other' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _PlannedMonthsSlider(
                options: _monthOptions,
                value: _plannedMonths ?? 6,
                onChanged: (months) => setState(() => _plannedMonths = months),
              ),
              const SizedBox(height: AppSpacing.lg),
              _OnboardingStatusPicker(
                value: _status,
                onChanged: (status) => setState(() => _status = status),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ShinePrimaryButton(
                label: _isEdit ? 'Save changes' : 'Save interaction',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannedMonthsSlider extends StatelessWidget {
  const _PlannedMonthsSlider({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<int> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    var index = options.indexOf(value);
    if (index < 0) index = options.indexOf(6).clamp(0, options.length - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planning to take',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${options[index]} month${options[index] == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primarySoft,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 5,
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: AppColors.primaryDark.withValues(alpha: 0.5),
              inactiveTickMarkColor: AppColors.borderSubtle,
            ),
            child: Slider(
              value: index.toDouble(),
              min: 0,
              max: (options.length - 1).toDouble(),
              divisions: options.length - 1,
              label: '${options[index]} mo',
              onChanged: (v) => onChanged(options[v.round()]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${options.first} mo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  '${options.last} mo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStatusPicker extends StatelessWidget {
  const _OnboardingStatusPicker({
    required this.value,
    required this.onChanged,
  });

  final InteractionStatus value;
  final ValueChanged<InteractionStatus> onChanged;

  IconData _icon(InteractionStatus status) {
    switch (status) {
      case InteractionStatus.readyToOnboard:
        return Icons.verified_rounded;
      case InteractionStatus.takingTime:
        return Icons.schedule_rounded;
      case InteractionStatus.uncertain:
        return Icons.help_outline_rounded;
    }
  }

  Color _color(InteractionStatus status) {
    switch (status) {
      case InteractionStatus.readyToOnboard:
        return AppColors.secondary;
      case InteractionStatus.takingTime:
        return AppColors.warning;
      case InteractionStatus.uncertain:
        return AppColors.textMuted;
    }
  }

  String _hint(InteractionStatus status) {
    switch (status) {
      case InteractionStatus.readyToOnboard:
        return 'Farmer is ready for onboarding soon';
      case InteractionStatus.takingTime:
        return 'Needs more time before deciding';
      case InteractionStatus.uncertain:
        return 'Still evaluating or undecided';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Onboarding status',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...InteractionStatus.values.map((status) {
          final selected = value == status;
          final accent = _color(status);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(status),
                borderRadius: BorderRadius.circular(AppColors.cardRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.12)
                        : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppColors.cardRadius),
                    border: Border.all(
                      color: selected ? accent : AppColors.borderSubtle,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_icon(status), color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hint(status),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey(status),
                                color: accent,
                              )
                            : Icon(
                                Icons.circle_outlined,
                                key: ValueKey('${status}_off'),
                                color: AppColors.borderSubtle,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
