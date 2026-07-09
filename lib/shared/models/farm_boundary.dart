import 'package:latlong2/latlong.dart';

/// Result of pinning a farm boundary on the map.
class FarmBoundarySelection {
  const FarmBoundarySelection({
    required this.pins,
    required this.latitude,
    required this.longitude,
    required this.totalAcres,
    required this.boundaryGeojson,
    this.address,
  });

  final List<LatLng> pins;
  final double latitude;
  final double longitude;
  final double totalAcres;
  final String? address;
  final Map<String, dynamic> boundaryGeojson;
}

/// Arguments passed when opening the boundary picker route.
class BoundaryPickerArgs {
  const BoundaryPickerArgs({
    this.initialCenter,
    this.initialPins = const [],
    this.initialAddress,
  });

  final LatLng? initialCenter;
  final List<LatLng> initialPins;
  final String? initialAddress;
}
