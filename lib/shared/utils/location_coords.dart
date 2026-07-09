import 'package:geolocator/geolocator.dart';

import '../../data/models/user.dart';

class LocationCoords {
  const LocationCoords({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  bool get hasCoords => latitude != null && longitude != null;
}

/// Device GPS first, then executive home location from profile.
LocationCoords resolveLocationCoords({
  Position? devicePosition,
  User? user,
}) {
  if (devicePosition != null) {
    return LocationCoords(
      latitude: devicePosition.latitude,
      longitude: devicePosition.longitude,
    );
  }
  if (user?.homeLat != null && user?.homeLng != null) {
    return LocationCoords(
      latitude: user!.homeLat,
      longitude: user.homeLng,
    );
  }
  return const LocationCoords();
}
