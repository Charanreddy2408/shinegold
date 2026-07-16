import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';

class GeocodingResult {
  const GeocodingResult({
    required this.displayName,
    required this.point,
  });

  final String displayName;
  final LatLng point;
}

/// Address search via ShineGold API (Nominatim proxy) with direct Nominatim
/// fallback when a bare [Dio] without auth is used / API is unreachable.
class GeocodingService {
  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: const {
                  'User-Agent': 'ShineGoldApp/1.0 (farm-boundary-picker)',
                  'Accept': 'application/json',
                },
              ),
            ),
        _usesApiClient = dio != null;

  final Dio _dio;
  final bool _usesApiClient;

  Future<List<GeocodingResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    if (_usesApiClient) {
      try {
        return await _searchViaApi(trimmed);
      } catch (_) {
        // Fall through — direct Nominatim may work on devices with internet.
      }
    }

    try {
      return await _searchNominatimDirect(trimmed);
    } catch (_) {
      if (_usesApiClient) rethrow;
      // Last resort: API base URL without injected auth (often fails 401).
      return _searchViaApiAbsolute(trimmed);
    }
  }

  Future<List<GeocodingResult>> _searchViaApi(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/geo/search',
      queryParameters: {'q': query, 'limit': 8},
    );
    return _parseApiItems(response.data?['items']);
  }

  Future<List<GeocodingResult>> _searchViaApiAbsolute(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${AppConfig.baseUrl}/api/v1/geo/search',
      queryParameters: {'q': query, 'limit': 8},
    );
    return _parseApiItems(response.data?['items']);
  }

  Future<List<GeocodingResult>> _searchNominatimDirect(String query) async {
    final response = await _dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': 8,
        'countrycodes': 'in',
        'addressdetails': 1,
      },
    );

    final data = response.data ?? [];
    return data
        .whereType<Map>()
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

  List<GeocodingResult> _parseApiItems(Object? raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) {
          final lat = (item['lat'] as num?)?.toDouble();
          final lng = (item['lng'] as num?)?.toDouble();
          final name = item['display_name'] as String?;
          if (lat == null || lng == null || name == null || name.isEmpty) {
            return null;
          }
          return GeocodingResult(
            displayName: name,
            point: LatLng(lat, lng),
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
