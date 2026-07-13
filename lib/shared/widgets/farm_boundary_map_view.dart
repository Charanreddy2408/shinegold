import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../utils/geo_area.dart';
import '../utils/india_map_bounds.dart';

/// Map for farm boundary picking — shows employee GPS + optional boundary pins.
class FarmBoundaryMapView extends StatelessWidget {
  const FarmBoundaryMapView({
    super.key,
    required this.mapController,
    required this.mapOptions,
    this.employeeLocation,
    this.boundaryPins = const [],
    this.showIndiaBadge = true,
    this.showRecenterFab = false,
    this.onRecenterEmployee,
  });

  final MapController mapController;
  final MapOptions mapOptions;
  final LatLng? employeeLocation;
  final List<LatLng> boundaryPins;
  final bool showIndiaBadge;
  final bool showRecenterFab;
  final VoidCallback? onRecenterEmployee;

  bool get _employeeInIndia =>
      employeeLocation != null && IndiaMapBounds.contains(employeeLocation!);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: mapOptions,
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.shinegold.shine_gold',
            ),
            if (boundaryPins.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: boundaryPins,
                    color: AppColors.secondary.withValues(alpha: 0.22),
                    borderColor: AppColors.secondary,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),
            if (boundaryPins.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: boundaryPins,
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ],
              ),
            if (employeeLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: employeeLocation!,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.info.withValues(alpha: 0.2),
                        border: Border.all(
                          color: _employeeInIndia
                              ? AppColors.info
                              : AppColors.warning,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_pin_circle_rounded,
                        color: _employeeInIndia
                            ? AppColors.info
                            : AppColors.warning,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            CircleLayer(
              circles: [
                for (final pin in boundaryPins)
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
        if (showIndiaBadge)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        if (showRecenterFab && onRecenterEmployee != null)
          Positioned(
            right: 10,
            bottom: 10,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(28),
              color: AppColors.surfaceCard,
              child: InkWell(
                onTap: onRecenterEmployee,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
      ],
    );
  }
}

/// Centers the map on [point] once the map controller is ready.
void centerFarmMapOn(
  MapController controller,
  LatLng point, {
  double zoom = 16,
  bool animate = false,
}) {
  final target = IndiaMapBounds.contains(point)
      ? point
      : IndiaMapBounds.clamp(point);
  final z = zoom.clamp(4.5, 19).toDouble();

  void move() {
    try {
      controller.move(target, z);
    } catch (_) {
      // Map not ready yet.
    }
  }

  move();
  Future<void>.delayed(const Duration(milliseconds: 80), move);
  Future<void>.delayed(const Duration(milliseconds: 250), move);
  Future<void>.delayed(const Duration(milliseconds: 600), move);
}

LatLng resolveFarmMapCenter({
  LatLng? employeeLocation,
  LatLng? initialCenter,
  List<LatLng> pins = const [],
}) {
  if (employeeLocation != null && IndiaMapBounds.contains(employeeLocation)) {
    return employeeLocation;
  }
  if (initialCenter != null && IndiaMapBounds.contains(initialCenter)) {
    return initialCenter;
  }
  if (pins.isNotEmpty) {
    final centroid = GeoArea.centroid(pins);
    if (IndiaMapBounds.contains(centroid)) return centroid;
  }
  return IndiaMapBounds.center;
}

double resolveFarmMapZoom({
  LatLng? employeeLocation,
  List<LatLng> pins = const [],
  double employeeZoom = 16,
}) {
  if (employeeLocation != null && IndiaMapBounds.contains(employeeLocation)) {
    return employeeZoom;
  }
  if (pins.isNotEmpty) return 15;
  return IndiaMapBounds.pickerZoom;
}
