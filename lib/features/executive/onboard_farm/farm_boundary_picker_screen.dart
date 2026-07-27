import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/farm_boundary.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/utils/geo_area.dart';
import '../../../shared/utils/geocoding_service.dart';
import '../../../shared/utils/india_map_bounds.dart';
import '../../../shared/widgets/farm_boundary_map_view.dart';
import '../../../shared/widgets/state_diagnostics.dart';

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
  final List<LatLng> _pins = [];
  final List<GeocodingResult> _searchResults = [];

  GeocodingService get _geocoding =>
      GeocodingService(dio: ref.read(dioClientProvider).dio);

  Timer? _searchDebounce;
  bool _searching = false;
  bool _showClear = false;
  bool _locating = false;
  bool _mapReady = false;
  bool _confirming = false;
  String? _selectedAddress;
  LatLng? _employeeLocation;

  // Failure state kept visible instead of swallowed — surfaced in the
  // diagnostics bar above the Confirm button.
  String? _gpsError;
  String? _searchError;
  String? _addressError;
  bool _addressLookupRan = false;

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
    setState(() {
      _locating = true;
      _gpsError = null;
    });

    try {
      if (_employeeLocation == null || forceRefresh) {
        await ref.read(locationProvider.notifier).requestLocation();
        await ref.read(locationProvider.notifier).refreshLocation();
      } else {
        await ref.read(locationProvider.notifier).refreshLocation();
      }

      final locationState = ref.read(locationProvider);
      final pos = locationState.position;
      if (pos != null) {
        _employeeLocation = LatLng(pos.latitude, pos.longitude);
      } else {
        _gpsError = locationState.error ?? 'No GPS fix returned.';
      }
    } catch (e) {
      _gpsError = 'GPS lookup failed: $e';
    } finally {
      if (mounted) setState(() => _locating = false);
    }

    if (!mounted) return;

    if (_employeeLocation == null) {
      _showMessage(
        'Could not get GPS — you can still pin the boundary by hand. '
        'Tap the status bar for details.',
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

    String? address;
    String? error;
    try {
      address = await _geocoding
          .reverseGeocode(point)
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (e) {
      error = 'Could not fetch address: $e';
    }

    if (!mounted) return;
    setState(() {
      _addressLookupRan = true;
      _addressError = error;
      if (address == null || address.isEmpty) return;
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
        _searchError = null;
        _searchResults
          ..clear()
          ..addAll(
            results.where((r) => IndiaMapBounds.contains(r.point)),
          );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = 'Search failed: $e');
      _showMessage('Location search failed — you can still pin on the map.');
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

  /// Live health of every dependency this screen has. Drives the status bar so
  /// a stuck flow always names its own cause instead of looking unresponsive.
  List<DiagnosticItem> _diagnostics() {
    final hasPins = _pins.length >= 3;
    return [
      DiagnosticItem(
        label: 'Boundary pins',
        status: hasPins ? DiagnosticStatus.ok : DiagnosticStatus.failed,
        detail: hasPins
            ? '${_pins.length} pins · ${_areaAcres.toStringAsFixed(2)} acres'
            : '${_pins.length} of 3 minimum pins placed',
        hint: hasPins ? null : 'Tap the map at each corner of the farm.',
      ),
      DiagnosticItem(
        label: 'GPS location',
        status: _locating
            ? DiagnosticStatus.pending
            : !_hasEmployeeLocation
                ? DiagnosticStatus.warning
                : !_employeeInIndia
                    ? DiagnosticStatus.warning
                    : DiagnosticStatus.ok,
        detail: _locating
            ? 'Getting a fix…'
            : !_hasEmployeeLocation
                ? (_gpsError ?? 'No GPS fix yet.')
                : _employeeInIndia
                    ? 'Lat ${_employeeLocation!.latitude.toStringAsFixed(4)}, '
                        'Lng ${_employeeLocation!.longitude.toStringAsFixed(4)}'
                    : 'Fix is outside India '
                        '(${_employeeLocation!.latitude.toStringAsFixed(4)}, '
                        '${_employeeLocation!.longitude.toStringAsFixed(4)}).',
        hint: _hasEmployeeLocation && _employeeInIndia
            ? null
            : 'GPS is optional here — you can still pin the boundary manually. '
                'Tap Recenter to retry.',
      ),
      DiagnosticItem(
        label: 'Address lookup',
        status: _addressError != null
            ? DiagnosticStatus.warning
            : (_selectedAddress?.isNotEmpty ?? false)
                ? DiagnosticStatus.ok
                : _addressLookupRan
                    ? DiagnosticStatus.warning
                    : DiagnosticStatus.pending,
        detail: _addressError ??
            (_selectedAddress?.isNotEmpty ?? false
                ? _selectedAddress
                : _addressLookupRan
                    ? 'No address found for this location.'
                    : 'Not looked up yet.'),
        hint: (_selectedAddress?.isNotEmpty ?? false)
            ? null
            : 'Optional — you can type the address on the previous screen. '
                'This never blocks Confirm.',
      ),
      if (_searchError != null)
        DiagnosticItem(
          label: 'Location search',
          status: DiagnosticStatus.warning,
          detail: _searchError,
          hint: 'Search is optional — pin the boundary directly on the map.',
        ),
    ];
  }

  /// Builds the selection. Confirm must always succeed once 3+ pins exist, so
  /// every optional step here is allowed to fail without taking the flow down.
  Future<void> _confirm() async {
    if (!_canConfirm || _confirming) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _confirming = true);

    final pins = List<LatLng>.unmodifiable(_pins);
    final center = GeoArea.centroid(pins);

    String? address = _selectedAddress;
    if (address == null || address.isEmpty) {
      // Address is a nicety, the polygon is the payload — never block on it.
      try {
        address = await _geocoding
            .reverseGeocode(center)
            .timeout(const Duration(seconds: 8), onTimeout: () => null);
        if (mounted) {
          _addressLookupRan = true;
          _addressError = null;
        }
      } catch (e) {
        if (mounted) {
          _addressLookupRan = true;
          _addressError = 'Could not fetch address: $e';
        }
        address = null;
      }
    }

    Map<String, dynamic> geojson;
    try {
      geojson = GeoArea.toGeoJsonPolygon(pins);
    } catch (_) {
      // Unreachable with 3+ pins, but a malformed polygon must never strand the
      // executive on this screen with a dead button — hand-build the ring.
      geojson = {
        'type': 'Polygon',
        'coordinates': [
          [
            for (final p in pins) [p.longitude, p.latitude],
            [pins.first.longitude, pins.first.latitude],
          ],
        ],
      };
    }

    var acres = 0.0;
    try {
      acres = GeoArea.polygonAreaAcres(pins);
    } catch (_) {
      acres = 0.0;
    }

    if (!mounted) return;
    setState(() => _confirming = false);
    Navigator.of(context).pop(
      FarmBoundarySelection(
        pins: pins,
        latitude: center.latitude,
        longitude: center.longitude,
        totalAcres: acres,
        address: address,
        boundaryGeojson: geojson,
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
            child: StateDiagnosticsBar(
              title: 'Farm boundary — status',
              okMessage: _canConfirm
                  ? 'Ready to confirm · ${_pins.length} pins, '
                      '${_areaAcres.toStringAsFixed(2)} acres'
                  : 'Tap the map to drop boundary corners',
              items: _diagnostics(),
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
                      onPressed: (_canConfirm && !_confirming)
                          ? () => unawaited(_confirm())
                          : null,
                      child: _confirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _canConfirm
                                  ? 'Confirm boundary'
                                  : 'Add ${3 - _pins.length} more pin${_pins.length == 2 ? '' : 's'}',
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
