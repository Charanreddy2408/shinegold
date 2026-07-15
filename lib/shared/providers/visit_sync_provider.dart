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

  /// Latest sync outcome for UI feedback (snackbars, badges).
  final ValueNotifier<VisitSyncResult?> lastResult =
      ValueNotifier<VisitSyncResult?>(null);

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return;
    // Ensure disk queue is loaded after cold start before skipping.
    final pending = await OfflineVisitStore.instance.all();
    if (pending.isEmpty) return;
    await syncNow();
  }

  Future<VisitSyncResult> syncNow() async {
    final result = await _ref.read(visitSyncServiceProvider).sync();
    lastResult.value = result;
    if (result.synced > 0) {
      // Refresh dashboards / visit lists that now include synced visits.
      _ref.read(appRefreshProvider.notifier).bump();
    }
    return result;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final visitSyncCoordinatorProvider = Provider<VisitSyncCoordinator>((ref) {
  final coordinator = VisitSyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
