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
import '../../../shared/utils/l10n_ext.dart';

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
        _gpsError = locationState.error ?? context.l10n.noGpsFixReturned;
      }
    } catch (e) {
      _gpsError = context.l10n.gpsLookupFailed('$e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }

    if (!mounted) return;

    if (_employeeLocation == null) {
      _showMessage(context.l10n.couldNotGetGpsPinByHand);
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
      _showMessage(context.l10n.yourGpsOutsideIndiaSearch);
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
      error = context.l10n.couldNotFetchAddress('$e');
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
      setState(() => _searchError = context.l10n.searchFailedError('$e'));
      _showMessage(context.l10n.locationSearchFailed);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _selectSearchResult(GeocodingResult result) {
    if (!IndiaMapBounds.contains(result.point)) {
      _showMessage(context.l10n.pickLocationInsideIndia);
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
      _showMessage(context.l10n.farmBoundaryMustBeInIndia);
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
        label: context.l10n.boundaryPinsLabel,
        status: hasPins ? DiagnosticStatus.ok : DiagnosticStatus.failed,
        detail: hasPins
            ? '${_pins.length} pins · ${_areaAcres.toStringAsFixed(2)} acres'
            : '${_pins.length} of 3 minimum pins placed',
        hint: hasPins ? null : context.l10n.tapMapAtEachCorner,
      ),
      DiagnosticItem(
        label: context.l10n.gpsLocationLabel,
        status: _locating
            ? DiagnosticStatus.pending
            : !_hasEmployeeLocation
                ? DiagnosticStatus.warning
                : !_employeeInIndia
                    ? DiagnosticStatus.warning
                    : DiagnosticStatus.ok,
        detail: _locating
            ? context.l10n.gettingFix
            : !_hasEmployeeLocation
                ? (_gpsError ?? context.l10n.noGpsFixYet)
                : _employeeInIndia
                    ? context.l10n.latLngLabel(
                        _employeeLocation!.latitude.toStringAsFixed(4),
                        _employeeLocation!.longitude.toStringAsFixed(4),
                      )
                    : context.l10n.fixOutsideIndia(
                        _employeeLocation!.latitude.toStringAsFixed(4),
                        _employeeLocation!.longitude.toStringAsFixed(4),
                      ),
        hint: _hasEmployeeLocation && _employeeInIndia
            ? null
            : context.l10n.gpsOptionalPinManually,
      ),
      DiagnosticItem(
        label: context.l10n.addressLookup,
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
                    ? context.l10n.noAddressFound
                    : context.l10n.notLookedUpYet),
        hint: (_selectedAddress?.isNotEmpty ?? false)
            ? null
            : context.l10n.optionalTypeAddressPrevious,
      ),
      if (_searchError != null)
        DiagnosticItem(
          label: context.l10n.locationSearchLabel,
          status: DiagnosticStatus.warning,
          detail: _searchError,
          hint: context.l10n.searchOptionalPinDirectly,
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
          _addressError = context.l10n.couldNotFetchAddress('$e');
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
        title: Text(context.l10n.selectFarmBoundary),
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _locating ? null : () => unawaited(_recenterOnEmployee()),
            icon: const Icon(Icons.my_location_rounded),
            tooltip: context.l10n.recenterOnMyLocation,
          ),
          IconButton(
            onPressed: _fitIndia,
            icon: const Icon(Icons.public_rounded),
            tooltip: context.l10n.showIndia,
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
                hintText: context.l10n.searchVillageDistrict,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? Padding(
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
              title: context.l10n.farmBoundaryStatus,
              okMessage: _canConfirm
                  ? context.l10n.readyToConfirm(
                      _pins.length,
                      _areaAcres.toStringAsFixed(2),
                    )
                  : context.l10n.tapMapToDropBoundary,
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
                        ? context.l10n.bluePinYourGps
                        : context.l10n.tapMapToDropPinsIndia,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _statChip(
                        Icons.place_rounded,
                        context.l10n.pinsCount(_pins.length),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _statChip(
                        Icons.square_foot_rounded,
                        _pins.length >= 3
                            ? context.l10n.acresCount(
                                _areaAcres.toStringAsFixed(2),
                              )
                            : context.l10n.min3Pins,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pins.isEmpty ? null : _undoLastPin,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: Text(context.l10n.undoPoint),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pins.isEmpty ? null : _clearPins,
                          icon: const Icon(Icons.clear_all_rounded, size: 18),
                          label: Text(context.l10n.clearLabel),
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
                                  ? context.l10n.confirmBoundaryButton
                                  : context.l10n.addMorePins(
                                      3 - _pins.length,
                                      _pins.length == 2 ? '' : 's',
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
