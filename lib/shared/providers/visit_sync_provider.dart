import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/offline_visit_store.dart';
import '../services/visit_sync_service.dart';
import 'app_refresh_provider.dart';

/// Watches connectivity and drains the offline visit queue whenever the
/// device comes back online. Also exposes a manual [syncNow] trigger.
class VisitSyncCoordinator {
  VisitSyncCoordinator(this._ref) {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _disposed = false;
  bool _syncing = false;

  /// Latest sync outcome for UI feedback (snackbars, badges).
  final ValueNotifier<VisitSyncResult?> lastResult =
      ValueNotifier<VisitSyncResult?>(null);

  /// True while a sync is in flight, including the silent auto-sync
  /// triggered on shell init/app-resume — lets any screen show progress,
  /// not just the manual "Sync now" button.
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    if (_disposed) return;
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return;
    // Ensure disk queue is loaded after cold start before skipping.
    final pending = await OfflineVisitStore.instance.all();
    if (_disposed || pending.isEmpty) return;
    await syncNow();
  }

  Future<VisitSyncResult> syncNow() async {
    if (_disposed) {
      return const VisitSyncResult(synced: 0, failed: 0, remaining: 0);
    }
    if (_syncing) {
      return lastResult.value ??
          const VisitSyncResult(synced: 0, failed: 0, remaining: 0);
    }
    _syncing = true;
    isSyncing.value = true;
    try {
      final result = await _ref.read(visitSyncServiceProvider).sync();
      if (_disposed) return result;
      lastResult.value = result;
      if (result.synced > 0) {
        // Refresh dashboards / visit lists that now include synced visits.
        _ref.read(appRefreshProvider.notifier).bump();
      }
      return result;
    } finally {
      _syncing = false;
      if (!_disposed) isSyncing.value = false;
    }
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    lastResult.dispose();
    isSyncing.dispose();
  }
}

final visitSyncCoordinatorProvider = Provider<VisitSyncCoordinator>((ref) {
  final coordinator = VisitSyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
