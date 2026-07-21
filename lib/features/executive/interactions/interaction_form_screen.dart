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
              DropdownButtonFormField<int>(
                value: _plannedMonths,
                decoration: const InputDecoration(
                  labelText: 'Planning to take (months)',
                ),
                items: _monthOptions
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text('$m month${m == 1 ? '' : 's'}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _plannedMonths = v),
                validator: (v) => v == null ? 'Select months' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<InteractionStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Onboarding status',
                ),
                items: InteractionStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
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
