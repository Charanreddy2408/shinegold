import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/farm_boundary.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/utils/geo_area.dart';
import '../../../shared/utils/geocoding_service.dart';
import '../../../shared/utils/india_map_bounds.dart';
import '../../../shared/widgets/farm_boundary_map_view.dart';

/// Full-screen map — opens at employee GPS, then pins farm boundary polygon.
class FarmBoundaryPickerScreen extends ConsumerStatefulWidget {
  const FarmBoundaryPickerScreen({
    super.key,
    this.initialCenter,
    this.initialPins = const [],
    this.initialAddress,
    this.userLocation,
  });

  final LatLng? initialCenter;
  final List<LatLng> initialPins;
  final String? initialAddress;

  /// Employee GPS — map opens here and shows a "you are here" marker.
  final LatLng? userLocation;

  @override
  ConsumerState<FarmBoundaryPickerScreen> createState() =>
      _FarmBoundaryPickerScreenState();
}

class _FarmBoundaryPickerScreenState
    extends ConsumerState<FarmBoundaryPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geocoding = GeocodingService();
  final List<LatLng> _pins = [];
  final List<GeocodingResult> _searchResults = [];

  Timer? _searchDebounce;
  bool _searching = false;
  bool _showClear = false;
  bool _locating = false;
  bool _mapReady = false;
  String? _selectedAddress;
  LatLng? _employeeLocation;

  late final MapOptions _mapOptions;

  static const _employeeZoom = 16.5;

  double get _areaAcres => GeoArea.polygonAreaAcres(_pins);

  bool get _canConfirm => _pins.length >= 3;

  bool get _hasEmployeeLocation => _employeeLocation != null;

  bool get _employeeInIndia =>
      _employeeLocation != null && IndiaMapBounds.contains(_employeeLocation!);

  @override
  void initState() {
    super.initState();
    _employeeLocation = widget.userLocation ?? widget.initialCenter;
    _pins.addAll(widget.initialPins.where(IndiaMapBounds.contains));
    _selectedAddress = widget.initialAddress;
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!.split(',').first;
      _showClear = _searchController.text.isNotEmpty;
    }

    final start = resolveFarmMapCenter(
      employeeLocation: _employeeLocation,
      initialCenter: widget.initialCenter,
      pins: _pins,
    );

    _mapOptions = MapOptions(
      initialCenter: start,
      initialZoom: resolveFarmMapZoom(
        employeeLocation: _employeeLocation,
        pins: _pins,
        employeeZoom: _employeeZoom,
      ),
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
            InteractiveFlag.flingAnimation |
            InteractiveFlag.scrollWheelZoom,
        enableMultiFingerGestureRace: true,
        pinchZoomThreshold: 0.25,
      ),
      onTap: _onMapTap,
      onMapReady: () {
        _mapReady = true;
        if (_employeeLocation != null) {
          _moveToEmployee(_employeeLocation!);
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapEmployeeLocation(forceRefresh: true));
    });
  }

  Future<void> _bootstrapEmployeeLocation({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _locating = true);

    try {
      if (_employeeLocation == null || forceRefresh) {
        await ref.read(locationProvider.notifier).requestLocation();
        await ref.read(locationProvider.notifier).refreshLocation();
      } else {
        await ref.read(locationProvider.notifier).refreshLocation();
      }

      final pos = ref.read(locationProvider).position;
      if (pos != null) {
        _employeeLocation = LatLng(pos.latitude, pos.longitude);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }

    if (!mounted) return;

    if (_employeeLocation == null) {
      _showMessage(
        'Could not get GPS. Enable location, then tap Recenter.',
      );
      return;
    }

    _moveToEmployee(_employeeLocation!);
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      unawaited(_fillAddressFromLocation(_employeeLocation!));
    }
  }

  Future<void> _recenterOnEmployee() async {
    await _bootstrapEmployeeLocation(forceRefresh: true);
  }

  void _moveToEmployee(LatLng loc) {
    if (!IndiaMapBounds.contains(loc)) {
      _showMessage(
        'Your GPS is outside India. Search for the farm village, then mark pins.',
      );
      // Still show the closest view inside India so the map isn't blank.
      if (_mapReady) {
        _mapController.move(IndiaMapBounds.center, IndiaMapBounds.pickerZoom);
      }
      return;
    }

    centerFarmMapOn(
      _mapController,
      loc,
      zoom: _employeeZoom,
      animate: true,
    );
  }

  Future<void> _fillAddressFromLocation(LatLng point) async {
    if (!IndiaMapBounds.contains(point)) return;
    final address = await _geocoding.reverseGeocode(point);
    if (!mounted || address == null || address.isEmpty) return;
    setState(() {
      _selectedAddress = address;
      if (_searchController.text.isEmpty) {
        _searchController.text = address.split(',').first;
        _showClear = true;
      }
    });
  }

  void _onMapTap(TapPosition _, LatLng point) => _addPin(point);

  void _fitIndia() {
    _mapController.move(IndiaMapBounds.center, IndiaMapBounds.overviewZoom);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _showClear = query.isNotEmpty);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    if (query.trim().length < 3) {
      setState(() => _searchResults.clear());
      return;
    }

    setState(() => _searching = true);
    try {
      final results = await _geocoding.search(query);
      if (!mounted) return;
      setState(() {
        _searchResults
          ..clear()
          ..addAll(
            results.where((r) => IndiaMapBounds.contains(r.point)),
          );
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Location search failed. Try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _selectSearchResult(GeocodingResult result) {
    if (!IndiaMapBounds.contains(result.point)) {
      _showMessage('Please pick a location inside India.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _searchController.text = result.displayName.split(',').first;
    setState(() {
      _selectedAddress = result.displayName;
      _showClear = true;
      _searchResults.clear();
    });
    centerFarmMapOn(_mapController, result.point, zoom: 15, animate: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showClear = false;
      _searchResults.clear();
    });
  }

  void _addPin(LatLng point) {
    if (!IndiaMapBounds.contains(point)) {
      _showMessage('Farm boundary must be inside India.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _pins.add(point));
  }

  void _undoLastPin() {
    if (_pins.isEmpty) return;
    setState(() => _pins.removeLast());
  }

  void _clearPins() => setState(_pins.clear);

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    FocusManager.instance.primaryFocus?.unfocus();

    var address = _selectedAddress;
    final center = GeoArea.centroid(_pins);
    if (address == null || address.isEmpty) {
      address = await _geocoding.reverseGeocode(center);
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      FarmBoundarySelection(
        pins: List.unmodifiable(_pins),
        latitude: center.latitude,
        longitude: center.longitude,
        totalAcres: _areaAcres,
        address: address,
        boundaryGeojson: GeoArea.toGeoJsonPolygon(_pins),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationProvider, (prev, next) {
      final pos = next.position;
      if (pos == null) return;
      final updated = LatLng(pos.latitude, pos.longitude);
      final prevPos = _employeeLocation;
      final moved = prevPos == null ||
          (prevPos.latitude - updated.latitude).abs() > 0.00005 ||
          (prevPos.longitude - updated.longitude).abs() > 0.00005;
      if (!moved) return;
      _employeeLocation = updated;
      if (mounted) {
        setState(() {});
        if (_mapReady && IndiaMapBounds.contains(updated)) {
          _moveToEmployee(updated);
        }
      }
    });

    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: const Text('Select Farm Boundary'),
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _locating ? null : () => unawaited(_recenterOnEmployee()),
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Recenter on my location',
          ),
          IconButton(
            onPressed: _fitIndia,
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Show India',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_locating || locationState.loading)
            const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search village, district in India...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _showClear
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearSearch,
                          )
                        : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: (_hasEmployeeLocation
                        ? (_employeeInIndia ? AppColors.info : AppColors.warning)
                        : AppColors.textMuted)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: (_hasEmployeeLocation
                          ? (_employeeInIndia
                              ? AppColors.info
                              : AppColors.warning)
                          : AppColors.borderSubtle)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasEmployeeLocation
                        ? (_employeeInIndia
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_not_fixed_rounded)
                        : Icons.gps_off_rounded,
                    size: 18,
                    color: _hasEmployeeLocation
                        ? (_employeeInIndia
                            ? AppColors.info
                            : AppColors.warning)
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        !_hasEmployeeLocation
                            ? 'Fetching your GPS… tap Recenter if this takes too long.'
                            : _employeeInIndia
                                ? 'Location OK · Lat ${_employeeLocation!.latitude.toStringAsFixed(4)}, Lng ${_employeeLocation!.longitude.toStringAsFixed(4)}. Blue pin = you — tap to mark boundary.'
                                : 'GPS is working but outside India '
                                    '(${_employeeLocation!.latitude.toStringAsFixed(4)}, '
                                    '${_employeeLocation!.longitude.toStringAsFixed(4)}). '
                                    'On emulator: Extended Controls → Location → set an India city, then tap Recenter.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: AppColors.cardDecoration(),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    title: Text(
                      result.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: FarmBoundaryMapView(
                  mapController: _mapController,
                  mapOptions: _mapOptions,
                  employeeLocation: _employeeLocation,
                  boundaryPins: _pins,
                  showRecenterFab: true,
                  onRecenterEmployee: () => unawaited(_recenterOnEmployee()),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _employeeInIndia
                        ? 'Blue pin = your GPS. Tap the map to drop boundary corners around the farm.'
                        : 'Tap the map to drop pins around your farm boundary (India only)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _statChip(Icons.place_rounded, '${_pins.length} pins'),
                      const SizedBox(width: AppSpacing.sm),
                      _statChip(
                        Icons.square_foot_rounded,
                        _pins.length >= 3
                            ? '${_areaAcres.toStringAsFixed(2)} acres'
                            : 'Min 3 pins',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pins.isEmpty ? null : _undoLastPin,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pins.isEmpty ? null : _clearPins,
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: AppSpacing.buttonHeight,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canConfirm ? _confirm : null,
                      child: const Text('Confirm boundary'),
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

  Widget _statChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
