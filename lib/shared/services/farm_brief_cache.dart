import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny cache of recently opened farms so check-in can start offline
/// without round-tripping to the API for name/coords.
class FarmBriefCache {
  FarmBriefCache._();
  static final instance = FarmBriefCache._();

  static const _keyPrefix = 'farm_brief_';

  Future<void> save({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix$id',
        jsonEncode({
          'id': id,
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } catch (e) {
      debugPrint('FarmBriefCache save failed: $e');
    }
  }

  Future<FarmBrief?> load(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$id');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FarmBrief(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('FarmBriefCache load failed: $e');
      return null;
    }
  }
}

class FarmBrief {
  const FarmBrief({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}
