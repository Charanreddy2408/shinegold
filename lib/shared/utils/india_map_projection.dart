import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'india_map_bounds.dart';

/// Layout box used to fit India with correct geographic proportions.
class IndiaMapLayout {
  const IndiaMapLayout({
    required this.mapWidth,
    required this.mapHeight,
    required this.offset,
  });

  final double mapWidth;
  final double mapHeight;
  final Offset offset;

  Rect get rect => Rect.fromLTWH(offset.dx, offset.dy, mapWidth, mapHeight);
}

/// Projects lat/lng within India bounds onto a widget canvas.
class IndiaMapProjection {
  IndiaMapProjection._();

  static const double _padding = 12;

  /// Simplified India mainland outline (lat/lng).
  static const List<LatLng> outline = [
    LatLng(23.65, 68.18),
    LatLng(24.35, 70.20),
    LatLng(23.85, 71.80),
    LatLng(22.30, 70.00),
    LatLng(20.20, 72.90),
    LatLng(15.50, 73.85),
    LatLng(11.20, 75.80),
    LatLng(8.40, 77.00),
    LatLng(8.08, 77.55),
    LatLng(10.50, 79.80),
    LatLng(13.10, 80.30),
    LatLng(15.80, 80.90),
    LatLng(17.50, 83.00),
    LatLng(19.50, 84.80),
    LatLng(21.50, 86.80),
    LatLng(22.50, 88.20),
    LatLng(24.60, 88.15),
    LatLng(25.60, 89.50),
    LatLng(26.50, 91.80),
    LatLng(27.80, 94.20),
    LatLng(28.20, 96.00),
    LatLng(27.40, 97.40),
    LatLng(28.80, 97.20),
    LatLng(29.50, 95.00),
    LatLng(28.00, 91.50),
    LatLng(26.20, 91.80),
    LatLng(24.80, 93.50),
    LatLng(22.50, 92.00),
    LatLng(21.00, 93.00),
    LatLng(24.00, 94.80),
    LatLng(26.00, 95.50),
    LatLng(27.00, 93.50),
    LatLng(32.00, 78.50),
    LatLng(34.80, 77.00),
    LatLng(33.50, 75.00),
    LatLng(32.50, 72.00),
    LatLng(23.65, 68.18),
  ];

  static IndiaMapLayout layoutFor(Size size) {
    final bounds = IndiaMapBounds.bounds;
    final latSpan = bounds.north - bounds.south;
    final lngSpan = bounds.east - bounds.west;
    final meanLatRad = ((bounds.north + bounds.south) / 2) * math.pi / 180;
    final geoAspect = (lngSpan * math.cos(meanLatRad)) / latSpan;

    final usableW = math.max(1.0, size.width - _padding * 2);
    final usableH = math.max(1.0, size.height - _padding * 2);

    late double mapW;
    late double mapH;
    late double offsetX;
    late double offsetY;

    if (usableW / usableH > geoAspect) {
      mapH = usableH;
      mapW = mapH * geoAspect;
      offsetX = _padding + (usableW - mapW) / 2;
      offsetY = _padding;
    } else {
      mapW = usableW;
      mapH = mapW / geoAspect;
      offsetX = _padding;
      offsetY = _padding + (usableH - mapH) / 2;
    }

    return IndiaMapLayout(
      mapWidth: mapW,
      mapHeight: mapH,
      offset: Offset(offsetX, offsetY),
    );
  }

  static Offset project(LatLng point, Size size) {
    final layout = layoutFor(size);
    final bounds = IndiaMapBounds.bounds;
    final x =
        (point.longitude - bounds.west) / (bounds.east - bounds.west);
    final y = 1 -
        (point.latitude - bounds.south) / (bounds.north - bounds.south);
    return Offset(
      layout.offset.dx + x.clamp(0.0, 1.0) * layout.mapWidth,
      layout.offset.dy + y.clamp(0.0, 1.0) * layout.mapHeight,
    );
  }

  static ui.Path buildOutlinePath(Size size) {
    final path = ui.Path();
    final points = outline.map((p) => project(p, size)).toList();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  static bool hasValidCoords(double lat, double lng) {
    if (lat == 0 && lng == 0) return false;
    return IndiaMapBounds.contains(LatLng(lat, lng));
  }
}
