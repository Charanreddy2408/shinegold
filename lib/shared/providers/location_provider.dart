import 'dart:async';

import 'package:flutter/foundation.dart';
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

  bool get hasFix => position != null;

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

  Timer? _trackingTimer;
  Future<void>? _inFlightRequest;

  Future<void> requestLocation() async {
    // Coalesce concurrent callers (admin shell + nearby refresh) so one prompt
    // / fix is shared instead of the second call exiting while loading.
    final existing = _inFlightRequest;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _requestLocationInternal();
    _inFlightRequest = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightRequest, future)) {
        _inFlightRequest = null;
      }
    }
  }

  Future<void> _requestLocationInternal() async {
    state = state.copyWith(loading: true, clearError: true);

    // On web, isLocationServiceEnabled() is unreliable and often false even
    // after the user grants browser location access. Still try GPS.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && !kIsWeb) {
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
        // Web: the browser permission prompt eats into the time limit, so give
        // it longer before falling back.
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: kIsWeb ? 30 : 15),
          ),
        );
      } catch (_) {
        // Low-accuracy retry rescues browsers/emulators that miss the first fix.
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {
          position = lastKnown ?? await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        state = LocationState(
          position: position,
          permissionGranted: true,
          loading: false,
        );
        return;
      }

      // Permission granted but no GPS fix (common on emulators / some browsers).
      state = LocationState(
        position: state.position,
        permissionGranted: true,
        loading: false,
        error: state.position == null
            ? 'Could not read your current location. Try again or set a home pin in Profile.'
            : null,
      );
    } catch (_) {
      if (state.position != null) {
        state = state.copyWith(loading: false, permissionGranted: true);
        return;
      }
      state = const LocationState(
        permissionGranted: true,
        loading: false,
        error:
            'Could not read your current location. Try again or set a home pin in Profile.',
      );
    }
  }

  /// Lightweight GPS refresh — no permission prompts if already granted.
  Future<void> refreshLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    // Web: service-enabled check is flaky; always attempt a fresh fix.
    if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      state = LocationState(
        position: position,
        permissionGranted: true,
        loading: false,
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        state = LocationState(
          position: lastKnown,
          permissionGranted: true,
          loading: false,
        );
      }
    }
  }

  Future<void> startPeriodicTracking({
    Duration interval = const Duration(minutes: 3),
  }) async {
    stopPeriodicTracking();
    await requestLocation();
    _trackingTimer = Timer.periodic(interval, (_) {
      unawaited(refreshLocation());
    });
  }

  void stopPeriodicTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  @override
  void dispose() {
    stopPeriodicTracking();
    super.dispose();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
