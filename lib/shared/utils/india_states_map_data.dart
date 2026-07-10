import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'india_map_projection.dart';

class IndiaStateShape {
  const IndiaStateShape({
    required this.name,
    required this.ring,
    required this.path,
    required this.centroid,
  });

  final String name;
  final List<LatLng> ring;
  final ui.Path path;
  final Offset centroid;
}

class IndiaStatesMapData {
  IndiaStatesMapData._();

  static List<IndiaStateShape>? _raw;

  static Future<List<IndiaStateShape>> loadRaw() async {
    if (_raw != null) return _raw!;
    final jsonStr = await rootBundle.loadString('assets/maps/india_states.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _raw = list.map((item) {
      final map = item as Map<String, dynamic>;
      final ring = (map['ring'] as List<dynamic>)
          .map(
            (p) => LatLng(
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            ),
          )
          .toList();
      return IndiaStateShape(
        name: map['name'] as String,
        ring: ring,
        path: ui.Path(),
        centroid: Offset.zero,
      );
    }).toList();
    return _raw!;
  }

  static List<IndiaStateShape> layout(List<IndiaStateShape> raw, Size size) {
    return raw.map((state) {
      final points =
          state.ring.map((p) => IndiaMapProjection.project(p, size)).toList();
      final path = ui.Path();
      if (points.isEmpty) {
        return state;
      }
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      var cx = 0.0;
      var cy = 0.0;
      for (final p in points) {
        cx += p.dx;
        cy += p.dy;
      }

      return IndiaStateShape(
        name: state.name,
        ring: state.ring,
        path: path,
        centroid: Offset(cx / points.length, cy / points.length),
      );
    }).toList();
  }

  static IndiaStateShape? stateAt(
    List<IndiaStateShape> states,
    Offset position,
  ) {
    for (final state in states) {
      if (state.path.contains(position)) return state;
    }
    return null;
  }

  static Color colorForCount(int count, {bool selected = false}) {
    if (selected) return const Color(0xFFB8860B);
    return switch (count) {
      0 => const Color(0xFFF3F6EF),
      1 => const Color(0xFFF9E4A8),
      2 => const Color(0xFFE8B84A),
      3 => const Color(0xFFD4943A),
      _ => const Color(0xFF9E5B2E),
    };
  }
}
