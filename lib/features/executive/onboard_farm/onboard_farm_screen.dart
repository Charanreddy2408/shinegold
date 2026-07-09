import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/farm.dart';
import '../../../shared/models/farm_boundary.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/shine_buttons.dart';

class OnboardFarmScreen extends ConsumerStatefulWidget {
  const OnboardFarmScreen({super.key});

  @override
  ConsumerState<OnboardFarmScreen> createState() => _OnboardFarmScreenState();
}

class _OnboardFarmScreenState extends ConsumerState<OnboardFarmScreen> {
  int _step = 0;
  bool _loading = false;
  bool _success = false;
  FarmBoundarySelection? _boundary;

  final _farmName = TextEditingController();
  final _location = TextEditingController();
  final _crop = TextEditingController();
  final _harvestType = TextEditingController();
  final _acres = TextEditingController();
  final _farmerName = TextEditingController();
  final _farmerMobile = TextEditingController();
  final _farmerAge = TextEditingController();
  DateTime _harvestDate = DateTime.now().add(const Duration(days: 90));
  Gender? _gender;

  @override
  void dispose() {
    _farmName.dispose();
    _location.dispose();
    _crop.dispose();
    _harvestType.dispose();
    _acres.dispose();
    _farmerName.dispose();
    _farmerMobile.dispose();
    _farmerAge.dispose();
    super.dispose();
  }

  void _resetForm() {
    _success = false;
    _step = 0;
    _boundary = null;
    _farmName.clear();
    _location.clear();
    _crop.clear();
    _harvestType.clear();
    _acres.clear();
    _farmerName.clear();
    _farmerMobile.clear();
    _farmerAge.clear();
    _gender = null;
  }

  Future<void> _openBoundaryPicker() async {
    final loc = ref.read(locationProvider).position;
    final initialCenter = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(17.385, 78.4867);

    final result = await context.push<FarmBoundarySelection>(
      AppRoutes.boundaryPicker,
      extra: BoundaryPickerArgs(
        initialCenter: initialCenter,
        initialPins: _boundary?.pins ?? const [],
        initialAddress: _boundary?.address,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _boundary = result;
      if (result.address != null && result.address!.isNotEmpty) {
        _location.text = result.address!;
      }
      _acres.text = result.totalAcres.toStringAsFixed(2);
    });
  }

  bool _validateFarmStep() {
    if (_farmName.text.trim().isEmpty) {
      _showError('Enter farm name');
      return false;
    }
    if (_boundary == null || _boundary!.pins.length < 3) {
      _showError('Pin the farm boundary on the map (minimum 3 pins)');
      return false;
    }
    if (_crop.text.trim().isEmpty) {
      _showError('Enter crop name');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (_gender == null || int.tryParse(_farmerAge.text) == null) {
      _showError('Please select gender and enter farmer age');
      return;
    }
    if (_boundary == null) {
      _showError('Farm boundary is required');
      return;
    }

    setState(() => _loading = true);
    final user = ref.read(currentUserProvider)!;
    final boundary = _boundary!;
    try {
      await ref.read(farmRepositoryProvider).onboardFarm(
            OnboardFarmRequest(
              farmName: _farmName.text.trim(),
              location: _location.text.trim().isNotEmpty
                  ? _location.text.trim()
                  : (boundary.address ?? 'Farm location'),
              latitude: boundary.latitude,
              longitude: boundary.longitude,
              crop: _crop.text.trim(),
              harvestDate: _harvestDate,
              harvestType: _harvestType.text.trim(),
              totalAcres: boundary.totalAcres,
              boundaryGeojson: boundary.boundaryGeojson,
              farmerName: _farmerName.text.trim(),
              farmerMobile: _farmerMobile.text.trim(),
              farmerGender: _gender!,
              farmerAge: int.parse(_farmerAge.text),
            ),
            user.id,
            user.name,
          );
      if (mounted) setState(() => _success = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                      size: 80, color: AppColors.fieldGreen)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: AppSpacing.xxl),
              Text('Farm Onboarded!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Text('The farm has been added successfully.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxxl),
              ShineSecondaryButton(
                label: 'Onboard Another',
                onPressed: () => setState(_resetForm),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Onboard Farm',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    value: (_step + 1) / 2,
                    backgroundColor: AppColors.borderSubtle,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _step == 0 ? _farmStep() : _farmerStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _step == 0
                  ? ShinePrimaryButton(
                      label: 'Next: Farmer Details',
                      onPressed: () {
                        if (_validateFarmStep()) setState(() => _step = 1);
                      },
                    )
                  : ShinePrimaryButton(
                      label: 'Submit',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmStep() {
    final hasBoundary = _boundary != null && _boundary!.pins.length >= 3;

    return Column(
      children: [
        TextField(
          controller: _farmName,
          decoration: const InputDecoration(labelText: 'Farm Name'),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openBoundaryPicker,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Ink(
              decoration: AppColors.cardDecoration(
                borderColor: hasBoundary
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : AppColors.borderSubtle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasBoundary
                            ? AppColors.secondaryMuted
                            : AppColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        hasBoundary
                            ? Icons.check_circle_rounded
                            : Icons.map_outlined,
                        color: hasBoundary
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasBoundary
                                ? 'Boundary selected'
                                : 'Pin farm boundary on map',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasBoundary
                                ? '${_boundary!.pins.length} pins · ${_boundary!.totalAcres.toStringAsFixed(2)} acres'
                                : 'Tap to search your land and drop boundary pins',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _location,
          decoration: const InputDecoration(
            labelText: 'Location address',
            hintText: 'Auto-filled from map search',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _crop,
          decoration: const InputDecoration(labelText: 'Crop'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _harvestType,
          decoration: const InputDecoration(labelText: 'Harvest Type'),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Harvest Date'),
          subtitle: Text(
            '${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _harvestDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) setState(() => _harvestDate = picked);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _acres,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: hasBoundary,
          decoration: InputDecoration(
            labelText: 'Total Acres',
            hintText: hasBoundary ? null : 'Calculated from boundary pins',
            suffixIcon: hasBoundary
                ? const Icon(Icons.lock_outline, size: 18)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _farmerStep() {
    return Column(
      children: [
        TextField(
          controller: _farmerName,
          decoration: const InputDecoration(labelText: 'Farmer Name'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _farmerMobile,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile Number'),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<Gender>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: Gender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _farmerAge,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Age'),
        ),
      ],
    );
  }
}
