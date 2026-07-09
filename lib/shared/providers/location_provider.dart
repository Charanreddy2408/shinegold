import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  const LocationState({
    this.position,
    this.permissionGranted = false,
    this.loading = false,
    this.error,
  });

  final Position? position;
  final bool permissionGranted;
  final bool loading;
  final String? error;

  LocationState copyWith({
    Position? position,
    bool? permissionGranted,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      LocationState(
        position: position ?? this.position,
        permissionGranted: permissionGranted ?? this.permissionGranted,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  Future<void> requestLocation() async {
    if (state.loading) return;

    state = state.copyWith(loading: true, clearError: true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        state = LocationState(
          position: lastKnown,
          permissionGranted: true,
          loading: false,
        );
        return;
      }
      state = state.copyWith(
        loading: false,
        permissionGranted: false,
        error:
            'Location services are off. Turn on GPS or set your home location in Profile.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        loading: false,
        permissionGranted: false,
        error:
            'Location permission is blocked. Enable it in Settings or set your home location in Profile.',
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(
        loading: false,
        permissionGranted: false,
        error:
            'Location permission denied. Set your home location in Profile to sort farms by distance.',
      );
      return;
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        state = LocationState(
          position: lastKnown,
          permissionGranted: true,
          loading: true,
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        position = lastKnown ?? await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        state = LocationState(
          position: position,
          permissionGranted: true,
          loading: false,
        );
        return;
      }

      // Permission granted but no GPS fix (common on emulators without mock location).
      state = const LocationState(
        permissionGranted: true,
        loading: false,
      );
    } catch (_) {
      if (state.position != null) {
        state = state.copyWith(loading: false, permissionGranted: true);
        return;
      }
      state = const LocationState(
        permissionGranted: true,
        loading: false,
      );
    }
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
