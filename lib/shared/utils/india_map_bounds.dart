import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// India mainland bounds for farm maps and boundary picking.
class IndiaMapBounds {
  IndiaMapBounds._();

  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(8.0, 68.05),
    const LatLng(35.7, 97.5),
  );

  static const LatLng center = LatLng(22.5, 79.0);
  static const double overviewZoom = 5.0;
  static const double pickerZoom = 14.0;

  static bool contains(LatLng point) =>
      point.latitude >= bounds.south &&
      point.latitude <= bounds.north &&
      point.longitude >= bounds.west &&
      point.longitude <= bounds.east;

  static LatLng clamp(LatLng point) => LatLng(
        point.latitude.clamp(bounds.south, bounds.north),
        point.longitude.clamp(bounds.west, bounds.east),
      );
}
