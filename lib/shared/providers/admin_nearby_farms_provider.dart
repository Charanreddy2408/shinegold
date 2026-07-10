import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/farm.dart';
import 'location_provider.dart';
import 'app_refresh_provider.dart';
import 'repository_providers.dart';

/// Admin nearby farm discovery — 5 km radius, refreshed every 3 minutes.
class AdminNearbyConfig {
  AdminNearbyConfig._();

  static const radiusKm = 5.0;
  static const refreshInterval = Duration(minutes: 3);
}

class AdminNearbyFarmsState {
  const AdminNearbyFarmsState({
    this.farms = const [],
    this.loading = false,
    this.error,
    this.lastRefresh,
    this.tracking = false,
  });

  final List<Farm> farms;
  final bool loading;
  final String? error;
  final DateTime? lastRefresh;
  final bool tracking;

  AdminNearbyFarmsState copyWith({
    List<Farm>? farms,
    bool? loading,
    String? error,
    DateTime? lastRefresh,
    bool? tracking,
    bool clearError = false,
  }) =>
      AdminNearbyFarmsState(
        farms: farms ?? this.farms,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        lastRefresh: lastRefresh ?? this.lastRefresh,
        tracking: tracking ?? this.tracking,
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

  Future<void> refresh() async {
    if (!state.tracking && !state.loading) {
      // Manual refresh from UI before start() — still allowed.
    }

    final loc = ref.read(locationProvider);
    var position = loc.position;

    if (position == null || !loc.permissionGranted) {
      await ref.read(locationProvider.notifier).requestLocation();
      position = ref.read(locationProvider).position;
    } else {
      await ref.read(locationProvider.notifier).refreshLocation();
      position = ref.read(locationProvider).position ?? position;
    }

    if (position == null) {
      state = state.copyWith(
        loading: false,
        error: loc.error ??
            'Turn on location to see farms near you while travelling.',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final farms = await ref.read(farmRepositoryProvider).getNearbyFarms(
            lat: position.latitude,
            lng: position.longitude,
            radiusKm: AdminNearbyConfig.radiusKm,
          );
      _lastFetchPosition = position;
      state = state.copyWith(
        farms: farms,
        loading: false,
        lastRefresh: DateTime.now(),
        clearError: true,
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
