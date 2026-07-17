import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/enums.dart';
import '../../data/models/farm.dart';
import 'app_refresh_provider.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'repository_providers.dart';

/// Admin nearby farm discovery — refreshed every 3 minutes.
class AdminNearbyConfig {
  AdminNearbyConfig._();

  /// Hyderabad-area farms are often 8–20 km from a city pin; 5 km was too tight.
  static const radiusKm = 25.0;
  static const refreshInterval = Duration(minutes: 3);
}

class AdminNearbyFarmsState {
  const AdminNearbyFarmsState({
    this.farms = const [],
    this.loading = false,
    this.error,
    this.lastRefresh,
    this.tracking = false,
    this.closestOutsideKm,
  });

  final List<Farm> farms;
  final bool loading;
  final String? error;
  final DateTime? lastRefresh;
  final bool tracking;

  /// When the radius is empty, nearest farm distance outside the radius (if any).
  final double? closestOutsideKm;

  AdminNearbyFarmsState copyWith({
    List<Farm>? farms,
    bool? loading,
    String? error,
    DateTime? lastRefresh,
    bool? tracking,
    double? closestOutsideKm,
    bool clearError = false,
    bool clearClosestOutside = false,
  }) =>
      AdminNearbyFarmsState(
        farms: farms ?? this.farms,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        lastRefresh: lastRefresh ?? this.lastRefresh,
        tracking: tracking ?? this.tracking,
        closestOutsideKm: clearClosestOutside
            ? null
            : (closestOutsideKm ?? this.closestOutsideKm),
      );
}

class AdminNearbyFarmsNotifier extends StateNotifier<AdminNearbyFarmsState> {
  AdminNearbyFarmsNotifier(this.ref) : super(const AdminNearbyFarmsState()) {
    ref.listen<int>(appRefreshProvider, (prev, next) {
      if (state.tracking) unawaited(refresh());
    });
  }

  final Ref ref;
  Timer? _refreshTimer;
  ProviderSubscription<LocationState>? _locationSub;
  Position? _lastFetchPosition;

  Future<void> start() async {
    if (state.tracking) return;

    state = state.copyWith(tracking: true, clearError: true);

    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.startPeriodicTracking(
      interval: AdminNearbyConfig.refreshInterval,
    );

    _locationSub?.close();
    _locationSub = ref.listen<LocationState>(locationProvider, (prev, next) {
      final pos = next.position;
      if (pos == null) return;
      if (_shouldRefetchForMovement(pos)) {
        unawaited(refresh());
      }
    });

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AdminNearbyConfig.refreshInterval, (_) {
      unawaited(refresh());
    });

    await refresh();
  }

  bool _shouldRefetchForMovement(Position pos) {
    final last = _lastFetchPosition;
    if (last == null) return true;
    final meters = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      pos.latitude,
      pos.longitude,
    );
    return meters >= 200;
  }

  ({double lat, double lng})? _resolveCoords(LocationState loc) {
    final position = loc.position;
    if (position != null) {
      return (lat: position.latitude, lng: position.longitude);
    }
    final user = ref.read(currentUserProvider);
    if (user?.homeLat != null && user?.homeLng != null) {
      return (lat: user!.homeLat!, lng: user.homeLng!);
    }
    return null;
  }

  Future<void> refresh() async {
    final loc = ref.read(locationProvider);
    var position = loc.position;

    if (position == null || !loc.permissionGranted) {
      await ref.read(locationProvider.notifier).requestLocation();
      position = ref.read(locationProvider).position;
    } else {
      await ref.read(locationProvider.notifier).refreshLocation();
      position = ref.read(locationProvider).position ?? position;
    }

    final coords = _resolveCoords(ref.read(locationProvider));
    if (coords == null) {
      state = state.copyWith(
        loading: false,
        clearClosestOutside: true,
        error: ref.read(locationProvider).error ??
            'Turn on location to see farms near you while travelling.',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final allSorted = await ref.read(farmRepositoryProvider).getFarms(
            const FarmFilter(
              sortOrder: SortOrder.nearbyToFarthest,
              pageSize: 100,
            ),
            userLat: coords.lat,
            userLng: coords.lng,
          );
      final nearby = allSorted
          .where(
            (f) =>
                f.distanceKm != null &&
                f.distanceKm! <= AdminNearbyConfig.radiusKm,
          )
          .toList();
      final closestOutside = nearby.isEmpty
          ? allSorted
              .where((f) => f.distanceKm != null)
              .map((f) => f.distanceKm!)
              .fold<double?>(
                null,
                (best, d) => best == null || d < best ? d : best,
              )
          : null;

      if (position != null) {
        _lastFetchPosition = position;
      }
      state = state.copyWith(
        farms: nearby,
        loading: false,
        lastRefresh: DateTime.now(),
        clearError: true,
        closestOutsideKm: closestOutside,
        clearClosestOutside: closestOutside == null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: formatApiError(e),
      );
    }
  }

  void stop() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _locationSub?.close();
    _locationSub = null;
    ref.read(locationProvider.notifier).stopPeriodicTracking();
    state = state.copyWith(tracking: false);
  }
}

final adminNearbyFarmsProvider = StateNotifierProvider.autoDispose<
    AdminNearbyFarmsNotifier, AdminNearbyFarmsState>((ref) {
  final notifier = AdminNearbyFarmsNotifier(ref);
  ref.onDispose(notifier.stop);
  return notifier;
});
