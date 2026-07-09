import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/farm_boundary.dart';
import '../../../shared/utils/geo_area.dart';
import '../../../shared/utils/geocoding_service.dart';
import '../../../shared/utils/india_map_bounds.dart';

/// Full-screen map for searching land and pinning a farm boundary polygon.
class FarmBoundaryPickerScreen extends StatefulWidget {
  const FarmBoundaryPickerScreen({
    super.key,
    this.initialCenter,
    this.initialPins = const [],
    this.initialAddress,
  });

  final LatLng? initialCenter;
  final List<LatLng> initialPins;
  final String? initialAddress;

  @override
  State<FarmBoundaryPickerScreen> createState() =>
      _FarmBoundaryPickerScreenState();
}

class _FarmBoundaryPickerScreenState extends State<FarmBoundaryPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geocoding = GeocodingService();
  final List<LatLng> _pins = [];
  final List<GeocodingResult> _searchResults = [];

  Timer? _searchDebounce;
  bool _searching = false;
  bool _showClear = false;
  String? _selectedAddress;

  late final LatLng _mapCenter;
  late final double _mapZoom;
  late final MapOptions _mapOptions;

  double get _areaAcres => GeoArea.polygonAreaAcres(_pins);

  bool get _canConfirm => _pins.length >= 3;

  @override
  void initState() {
    super.initState();
    _mapCenter = _resolveInitialCenter();
    _mapZoom = widget.initialPins.isNotEmpty ? 15.0 : IndiaMapBounds.pickerZoom;
    _mapOptions = MapOptions(
      initialCenter: _mapCenter,
      initialZoom: _mapZoom,
      minZoom: 4.5,
      maxZoom: 18,
      cameraConstraint: CameraConstraint.containCenter(
        bounds: IndiaMapBounds.bounds,
      ),
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom |
            InteractiveFlag.drag |
            InteractiveFlag.doubleTapZoom |
            InteractiveFlag.flingAnimation,
      ),
      onTap: _onMapTap,
    );
    _pins.addAll(widget.initialPins.where(IndiaMapBounds.contains));
    _selectedAddress = widget.initialAddress;
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!.split(',').first;
      _showClear = _searchController.text.isNotEmpty;
    }
  }

  LatLng _resolveInitialCenter() {
    if (widget.initialCenter != null &&
        IndiaMapBounds.contains(widget.initialCenter!)) {
      return widget.initialCenter!;
    }
    if (widget.initialPins.isNotEmpty) {
      final centroid = GeoArea.centroid(widget.initialPins);
      if (IndiaMapBounds.contains(centroid)) return centroid;
    }
    return IndiaMapBounds.center;
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

  void _moveMap(LatLng point, double zoom) {
    final target = IndiaMapBounds.clamp(point);
    try {
      _mapController.move(target, zoom.clamp(4.5, 18));
    } catch (_) {
      // Map may not be ready on first frame; ignore.
    }
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
    _moveMap(result.point, 15);
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
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: const Text('Select Farm Boundary'),
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fitIndia,
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Show India',
          ),
        ],
      ),
      body: Column(
        children: [
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
                child: Stack(
                  children: [
                    FlutterMap(
                      key: const ValueKey('farm-boundary-india-map'),
                      mapController: _mapController,
                      options: _mapOptions,
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.shinegold.shine_gold',
                        ),
                        if (_pins.length >= 3)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: _pins,
                                color: AppColors.secondary
                                    .withValues(alpha: 0.22),
                                borderColor: AppColors.secondary,
                                borderStrokeWidth: 2.5,
                              ),
                            ],
                          ),
                        if (_pins.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _pins,
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ],
                          ),
                        CircleLayer(
                          circles: [
                            for (final pin in _pins)
                              CircleMarker(
                                point: pin,
                                radius: 10,
                                color: AppColors.primary,
                                borderColor: Colors.white,
                                borderStrokeWidth: 2,
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'India only',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                    'Tap the map to drop pins around your farm boundary (India only)',
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
