import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Geodesic helpers for farm boundary pins.
class GeoArea {
  GeoArea._();

  static const _earthRadiusM = 6378137.0;
  static const _sqMetersPerAcre = 4046.8564224;

  static double polygonAreaSquareMeters(List<LatLng> points) {
    if (points.length < 3) return 0;

    var area = 0.0;
    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      area += _toRad(p2.longitude - p1.longitude) *
          (2 +
              math.sin(_toRad(p1.latitude)) +
              math.sin(_toRad(p2.latitude)));
    }
    return (area * _earthRadiusM * _earthRadiusM / 2).abs();
  }

  static double squareMetersToAcres(double sqMeters) =>
      sqMeters / _sqMetersPerAcre;

  static double polygonAreaAcres(List<LatLng> points) =>
      squareMetersToAcres(polygonAreaSquareMeters(points));

  static LatLng centroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;

    var lat = 0.0;
    var lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  static Map<String, dynamic> toGeoJsonPolygon(List<LatLng> points) {
    final ring = [
      for (final p in points) [p.longitude, p.latitude],
      [points.first.longitude, points.first.latitude],
    ];
    return {
      'type': 'Polygon',
      'coordinates': [ring],
    };
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
