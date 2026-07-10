import '../../data/models/farm.dart';

/// Resolves a farm's Indian state for choropleth mapping.
class FarmStateResolver {
  FarmStateResolver._();

  static const _knownStates = {
    'andhra pradesh',
    'arunachal pradesh',
    'assam',
    'bihar',
    'chhattisgarh',
    'goa',
    'gujarat',
    'haryana',
    'himachal pradesh',
    'jharkhand',
    'karnataka',
    'kerala',
    'madhya pradesh',
    'maharashtra',
    'manipur',
    'meghalaya',
    'mizoram',
    'nagaland',
    'odisha',
    'punjab',
    'rajasthan',
    'sikkim',
    'tamil nadu',
    'telangana',
    'tripura',
    'uttar pradesh',
    'uttarakhand',
    'west bengal',
    'delhi',
    'jammu and kashmir',
    'ladakh',
    'puducherry',
    'chandigarh',
  };

  static const _cityToState = {
    'hyderabad': 'Telangana',
    'secunderabad': 'Telangana',
    'warangal': 'Telangana',
    'nalgonda': 'Telangana',
    'gachibowli': 'Telangana',
    'madhapur': 'Telangana',
    'bengaluru': 'Karnataka',
    'bangalore': 'Karnataka',
    'mumbai': 'Maharashtra',
    'pune': 'Maharashtra',
    'chennai': 'Tamil Nadu',
    'kolkata': 'West Bengal',
    'delhi': 'Delhi',
    'new delhi': 'Delhi',
    'jaipur': 'Rajasthan',
    'lucknow': 'Uttar Pradesh',
    'kochi': 'Kerala',
    'ahmedabad': 'Gujarat',
    'visakhapatnam': 'Andhra Pradesh',
    'vijayawada': 'Andhra Pradesh',
  };

  static String resolve(Farm farm) {
    final parts = farm.location
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final part in parts.reversed) {
      final lower = part.toLowerCase();
      if (_knownStates.contains(lower)) {
        return _titleCase(part);
      }
      final mapped = _cityToState[lower];
      if (mapped != null) return mapped;
    }

    if (parts.isNotEmpty) {
      final first = parts.first.toLowerCase();
      final mapped = _cityToState[first];
      if (mapped != null) return mapped;
    }

    return _guessFromCoords(farm.latitude, farm.longitude);
  }

  static String _guessFromCoords(double lat, double lng) {
    if (lat == 0 && lng == 0) return 'Unknown';
    if (lat >= 15.5 && lat <= 20.5 && lng >= 77 && lng <= 81.5) {
      return 'Telangana';
    }
    if (lat >= 12.5 && lat <= 19.5 && lng >= 74.5 && lng <= 78.5) {
      return 'Karnataka';
    }
    if (lat >= 8 && lat <= 13.5 && lng >= 76 && lng <= 80.5) {
      return 'Tamil Nadu';
    }
    if (lat >= 18 && lat <= 22.5 && lng >= 72.5 && lng <= 76.5) {
      return 'Maharashtra';
    }
    return 'Unknown';
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
