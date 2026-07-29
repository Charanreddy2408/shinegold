import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/farm.dart';
import '../../../shared/models/farm_boundary.dart';
import '../../../shared/providers/app_refresh_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/executive_tab_provider.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/geo_area.dart';
import '../../../shared/utils/india_map_bounds.dart';
import '../../../shared/utils/photo_picker.dart';
import '../../../shared/widgets/farm_boundary_map_view.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/utils/l10n_ext.dart';

class OnboardFarmScreen extends ConsumerStatefulWidget {
  const OnboardFarmScreen({super.key, this.isAdminCreate = false});

  final bool isAdminCreate;

  @override
  ConsumerState<OnboardFarmScreen> createState() => _OnboardFarmScreenState();
}

class _OnboardFarmScreenState extends ConsumerState<OnboardFarmScreen> {
  int _step = 0;
  bool _loading = false;
  bool _success = false;
  bool _openingBoundary = false;
  bool _previewMapCentered = false;
  FarmBoundarySelection? _boundary;
  final _previewMapController = MapController();
  late final MapOptions _previewMapOptions;

  final _farmName = TextEditingController();
  final _location = TextEditingController();
  final _crop = TextEditingController();
  final _harvestType = TextEditingController();
  final _acres = TextEditingController();
  final _farmerName = TextEditingController();
  final _farmerMobile = TextEditingController();
  final _farmerAge = TextEditingController();
  final _farmerAadhar = TextEditingController();
  final _plantCount = TextEditingController();
  DateTime _harvestDate = DateTime.now().add(const Duration(days: 90));
  Gender? _gender;
  final List<XFile> _farmPhotos = [];
  static const _maxFarmPhotos = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPhoto());
    _previewMapOptions = MapOptions(
      initialCenter: IndiaMapBounds.center,
      initialZoom: IndiaMapBounds.pickerZoom,
      minZoom: 4.5,
      maxZoom: 19,
      cameraConstraint: CameraConstraint.containCenter(
        bounds: IndiaMapBounds.bounds,
      ),
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom |
            InteractiveFlag.pinchMove |
            InteractiveFlag.drag |
            InteractiveFlag.doubleTapZoom |
            InteractiveFlag.scrollWheelZoom,
        enableMultiFingerGestureRace: true,
        pinchZoomThreshold: 0.25,
      ),
      onMapReady: () {
        final loc = _employeeLocationFromState(ref.read(locationProvider));
        if (loc != null && IndiaMapBounds.contains(loc)) {
          _previewMapCentered = true;
          _centerPreviewMap(loc);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationProvider.notifier).requestLocation();
      await ref.read(locationProvider.notifier).refreshLocation();
      if (!mounted) return;
      final loc = _employeeLocationFromState(ref.read(locationProvider));
      if (loc != null && IndiaMapBounds.contains(loc)) {
        _previewMapCentered = true;
        _centerPreviewMap(loc);
      }
    });
  }

  @override
  void dispose() {
    _previewMapController.dispose();
    _farmName.dispose();
    _location.dispose();
    _crop.dispose();
    _harvestType.dispose();
    _acres.dispose();
    _farmerName.dispose();
    _farmerMobile.dispose();
    _farmerAge.dispose();
    _farmerAadhar.dispose();
    _plantCount.dispose();
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
    _farmerAadhar.clear();
    _plantCount.clear();
    _gender = null;
    _farmPhotos.clear();
    _previewMapCentered = false;
  }

  Future<void> _openBoundaryPicker() async {
    setState(() => _openingBoundary = true);
    try {
      await ref.read(locationProvider.notifier).requestLocation();
      await ref.read(locationProvider.notifier).refreshLocation();

      if (!mounted) return;

      final loc = ref.read(locationProvider).position;
      if (loc == null) {
        _showError(
          context.l10n.turnOnLocationToOpenMap,
        );
        return;
      }

      final employeeLocation = LatLng(loc.latitude, loc.longitude);
      final initialCenter = _boundary != null && _boundary!.pins.isNotEmpty
          ? GeoArea.centroid(_boundary!.pins)
          : employeeLocation;

      final result = await context.push<FarmBoundarySelection>(
        AppRoutes.boundaryPicker,
        extra: BoundaryPickerArgs(
          userLocation: employeeLocation,
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
      if (result.pins.isNotEmpty) {
        centerFarmMapOn(
          _previewMapController,
          GeoArea.centroid(result.pins),
          zoom: 15.5,
        );
      }
    } finally {
      if (mounted) setState(() => _openingBoundary = false);
    }
  }

  LatLng? _employeeLocationFromState(LocationState locationState) {
    final pos = locationState.position;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  void _centerPreviewMap(LatLng employeeLocation) {
    if (!IndiaMapBounds.contains(employeeLocation)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      centerFarmMapOn(
        _previewMapController,
        employeeLocation,
        zoom: 16,
        animate: true,
      );
    });
  }

  Future<void> _recenterPreviewMap() async {
    await ref.read(locationProvider.notifier).requestLocation();
    await ref.read(locationProvider.notifier).refreshLocation();
    if (!mounted) return;
    final loc = _employeeLocationFromState(ref.read(locationProvider));
    if (loc == null) {
      _showError(context.l10n.couldNotGetGpsEnableLocation);
      return;
    }
    if (!IndiaMapBounds.contains(loc)) {
      _showError(
        context.l10n.gpsOutsideIndiaSearchVillage,
      );
      return;
    }
    _previewMapCentered = true;
    _centerPreviewMap(loc);
    setState(() {});
  }

  bool _validateFarmStep() {
    if (_farmName.text.trim().isEmpty) {
      _showError(context.l10n.enterFarmName);
      return false;
    }
    if (_boundary == null || _boundary!.pins.length < 3) {
      _showError(context.l10n.pinFarmBoundaryMinimum3);
      return false;
    }
    if (_crop.text.trim().isEmpty) {
      _showError(context.l10n.enterCropName);
      return false;
    }
    final plants = int.tryParse(_plantCount.text.trim());
    if (plants == null || plants < 1) {
      _showError(context.l10n.enterNumberOfPlants);
      return false;
    }
    return true;
  }

  bool _validateFarmerStep() {
    if (_farmerName.text.trim().isEmpty) {
      _showError(context.l10n.enterFarmerName);
      return false;
    }
    if (_farmerMobile.text.trim().isEmpty) {
      _showError(context.l10n.enterFarmerMobile);
      return false;
    }
    final aadhar = _farmerAadhar.text.replaceAll(RegExp(r'\D'), '');
    if (aadhar.length != 12) {
      _showError(context.l10n.enterValid12DigitAadhar);
      return false;
    }
    if (_gender == null) {
      _showError(context.l10n.pleaseSelectGender);
      return false;
    }
    final age = int.tryParse(_farmerAge.text.trim());
    if (age == null || age <= 0) {
      _showError(context.l10n.enterValidFarmerAge);
      return false;
    }
    if (_harvestType.text.trim().isEmpty) {
      _showError(context.l10n.enterHarvestTypeOnFarmDetails);
      return false;
    }
    if (_boundary == null || _boundary!.pins.length < 3) {
      _showError(context.l10n.farmBoundaryRequiredGoBack);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickFarmPhoto() async {
    if (_farmPhotos.length >= _maxFarmPhotos) {
      _showError(context.l10n.maximumPhotosAllowed(_maxFarmPhotos));
      return;
    }

    final image = await PhotoPicker.pick(context);
    if (image != null && mounted) {
      setState(() => _farmPhotos.add(image));
    }
  }

  /// Android kills memory-hungry apps while the camera is open. Reclaim the
  /// capture on the way back instead of losing it silently.
  Future<void> _recoverLostPhoto() async {
    final recovered = await PhotoPicker.recoverLostPhoto();
    if (recovered == null || !mounted) return;
    setState(() => _farmPhotos.add(recovered));
  }

  Future<void> _replaceFarmPhoto(int index) async {
    final image = await PhotoPicker.pick(context);
    if (image != null && mounted) {
      setState(() => _farmPhotos[index] = image);
    }
  }

  void _removeFarmPhoto(int index) {
    setState(() => _farmPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_validateFarmerStep()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showError(context.l10n.youMustBeSignedInToOnboard);
      return;
    }

    setState(() => _loading = true);
    final boundary = _boundary!;
    try {
      List<String>? uploadedPhotoUrls;
      if (_farmPhotos.isNotEmpty) {
        uploadedPhotoUrls = await ref.read(uploadServiceProvider).uploadXFiles(
              files: _farmPhotos,
              context: 'farm_photo',
            );
      }

      final request = OnboardFarmRequest(
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
        plantCount: int.parse(_plantCount.text.trim()),
        boundaryGeojson: boundary.boundaryGeojson,
        farmerName: _farmerName.text.trim(),
        farmerMobile: _farmerMobile.text.trim(),
        farmerGender: _gender!,
        farmerAge: int.parse(_farmerAge.text.trim()),
        farmerAadhar: _farmerAadhar.text.replaceAll(RegExp(r'\D'), ''),
      );

      if (widget.isAdminCreate) {
        await ref.read(farmRepositoryProvider).createFarmAsAdmin(
              request,
              uploadedPhotoUrls: uploadedPhotoUrls,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.farmCreatedSuccessfully)),
          );
          context.pop();
        }
      } else {
        await ref.read(farmRepositoryProvider).onboardFarm(
              request,
              user.id,
              user.name,
              uploadedPhotoUrls: uploadedPhotoUrls,
            );
        if (mounted) setState(() => _success = true);
        bumpAppRefresh(ref);
        unawaited(ref.read(authProvider.notifier).refreshUser());
      }
    } catch (e) {
      if (mounted) {
        _showError(formatApiError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationProvider, (prev, next) {
      if (_step != 0) return;
      final loc = _employeeLocationFromState(next);
      if (loc != null && IndiaMapBounds.contains(loc)) {
        if (!_previewMapCentered) {
          _previewMapCentered = true;
          _centerPreviewMap(loc);
        }
      }
    });

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
              SizedBox(height: AppSpacing.xxl),
              Text(
                widget.isAdminCreate
                    ? context.l10n.farmCreated
                    : context.l10n.farmOnboardedExclaim,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: AppSpacing.md),
              Text(context.l10n.farmAddedSuccessfully,
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: AppSpacing.xxxl),
              if (!widget.isAdminCreate) ...[
                ShinePrimaryButton(
                  label: context.l10n.viewDashboard,
                  onPressed: () {
                    bumpAppRefresh(ref);
                    switchExecutiveTab(ref, 0);
                    setState(_resetForm);
                  },
                ),
                SizedBox(height: AppSpacing.md),
              ],
              ShineSecondaryButton(
                label: context.l10n.onboardAnother,
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
                  Text(context.l10n.onboardFarmTitleCase,
                      style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: AppSpacing.md),
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
                      label: context.l10n.nextFarmerDetails,
                      onPressed: () {
                        if (_validateFarmStep()) setState(() => _step = 1);
                      },
                    )
                  : ShinePrimaryButton(
                      label: context.l10n.submit,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmStep() {
    final locationState = ref.watch(locationProvider);
    final employeeLocation = _employeeLocationFromState(locationState);
    final hasBoundary = _boundary != null && _boundary!.pins.length >= 3;

    return Column(
      children: [
        TextField(
          controller: _farmName,
          decoration: InputDecoration(labelText: context.l10n.farmNameInput),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FarmBoundaryMapView(
                  mapController: _previewMapController,
                  mapOptions: _previewMapOptions,
                  employeeLocation: employeeLocation,
                  boundaryPins: _boundary?.pins ?? const [],
                  showIndiaBadge: false,
                ),
                if (locationState.loading)
                  const ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(28),
                    color: AppColors.surfaceCard,
                    child: InkWell(
                      onTap: () => unawaited(_recenterPreviewMap()),
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: employeeLocation != null
                              ? AppColors.info
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: FilledButton.icon(
                    onPressed:
                        _openingBoundary ? null : () => _openBoundaryPicker(),
                    icon: _openingBoundary
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            hasBoundary
                                ? Icons.edit_location_alt_rounded
                                : Icons.add_location_alt_rounded,
                          ),
                    label: Text(
                      hasBoundary
                          ? context.l10n.editFarmBoundary
                          : context.l10n.markFarmBoundaryOnMap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              employeeLocation != null
                  ? Icons.gps_fixed_rounded
                  : Icons.gps_off_rounded,
              size: 16,
              color: employeeLocation != null
                  ? AppColors.info
                  : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                employeeLocation != null
                    ? hasBoundary
                        ? context.l10n.yourLocationShownOnMap(
                            _boundary!.pins.length,
                            _boundary!.totalAcres.toStringAsFixed(2),
                          )
                        : context.l10n.yourCurrentGpsShown
                    : context.l10n.waitingForGpsEnableLocation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _location,
          decoration: InputDecoration(
            labelText: context.l10n.locationAddressOptional,
            hintText: context.l10n.locationAddressHint,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _crop,
          decoration: InputDecoration(labelText: context.l10n.cropInput),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _harvestType,
          decoration: InputDecoration(labelText: context.l10n.harvestTypeInput),
        ),
        SizedBox(height: AppSpacing.md),
        _farmPhotosSection(),
        SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.harvestDateInput),
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
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _acres,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: hasBoundary,
          decoration: InputDecoration(
            labelText: context.l10n.totalAcresInput,
            hintText: hasBoundary ? null : context.l10n.calculatedFromBoundary,
            suffixIcon: hasBoundary
                ? const Icon(Icons.lock_outline, size: 18)
                : null,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _plantCount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.numberOfPlantsInput,
            hintText: context.l10n.totalPlantsOnFarm,
          ),
        ),
      ],
    );
  }

  Widget _farmPhotosSection({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.farmPhotosLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (_farmPhotos.isNotEmpty)
              Text(
                '${_farmPhotos.length}/$_maxFarmPhotos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          compact
              ? context.l10n.tapPhotoToReplace
              : context.l10n.optionalAddPhotos(_maxFarmPhotos),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _farmPhotos.length; i++)
              _FarmPhotoTile(
                file: _farmPhotos[i],
                onReplace: () => _replaceFarmPhoto(i),
                onRemove: () => _removeFarmPhoto(i),
              ),
            if (_farmPhotos.length < _maxFarmPhotos)
              InkWell(
                onTap: _pickFarmPhoto,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 108,
                  height: 128,
                  decoration: AppColors.cardDecoration(radius: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.addPhotoLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _farmerStep() {
    return Column(
      children: [
        if (_farmPhotos.isNotEmpty) ...[
          _farmPhotosSection(compact: true),
          SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          controller: _farmerName,
          decoration: InputDecoration(labelText: context.l10n.farmerName),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _farmerMobile,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: context.l10n.mobileNumber),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _farmerAadhar,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: InputDecoration(
            labelText: context.l10n.aadharNumberInput,
            hintText: context.l10n.aadharHint,
            counterText: '',
          ),
        ),
        SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<Gender>(
          value: _gender,
          decoration: InputDecoration(labelText: context.l10n.gender),
          items: Gender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _farmerAge,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.age),
        ),
      ],
    );
  }
}

class _FarmPhotoTile extends StatelessWidget {
  const _FarmPhotoTile({
    required this.file,
    required this.onReplace,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onReplace,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: 108,
                    height: 108,
                    color: AppColors.surfaceElevated,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: 108,
                  height: 108,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        SizedBox(height: 6),
        TextButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: Text(context.l10n.removeLabel),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
