import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.point,
  });

  final String displayName;
  final LatLng point;
}

/// OpenStreetMap Nominatim search (no API key required).
class GeocodingService {
  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {
                  'User-Agent': 'ShineGoldApp/1.0 (farm-boundary-picker)',
                },
              ),
            );

  final Dio _dio;

  Future<List<GeocodingResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final response = await _dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'limit': 6,
        'countrycodes': 'in',
      },
    );

    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final name = item['display_name'] as String?;
          if (lat == null || lon == null || name == null) return null;
          return GeocodingResult(
            displayName: name,
            point: LatLng(lat, lon),
          );
        })
        .whereType<GeocodingResult>()
        .toList();
  }

  Future<String?> reverseGeocode(LatLng point) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': point.latitude,
        'lon': point.longitude,
        'format': 'json',
      },
    );

    return response.data?['display_name'] as String?;
  }
}
