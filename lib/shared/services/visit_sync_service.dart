import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/pending_visit.dart';
import '../../data/repositories/visit_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/repository_providers.dart';
import 'offline_visit_store.dart';

/// Result of one sync pass over the offline visit queue.
class VisitSyncResult {
  const VisitSyncResult({
    this.synced = 0,
    this.failed = 0,
    this.remaining = 0,
    this.wentOffline = false,
  });

  final int synced;
  final int failed;
  final int remaining;

  /// True when the pass stopped early because the network dropped again.
  final bool wentOffline;
}

/// Replays offline-captured visits against the API in check-in order.
///
/// Each visit replays as: check-in -> form answers + media -> text note ->
/// submit. The server visit id is persisted after check-in so an interrupted
/// sync resumes mid-flow instead of double-checking-in.
class VisitSyncService {
  VisitSyncService(this._ref);

  final Ref _ref;
  bool _syncing = false;

  OfflineVisitStore get _store => OfflineVisitStore.instance;
  VisitRepository get _visits => _ref.read(visitRepositoryProvider);

  Future<VisitSyncResult> sync() async {
    if (_syncing) return const VisitSyncResult();
    _syncing = true;
    try {
      return await _syncAll();
    } finally {
      _syncing = false;
    }
  }

  Future<VisitSyncResult> _syncAll() async {
    final pending = await _store.all();
    if (pending.isEmpty) return const VisitSyncResult();

    // Oldest first — the server allows one in-progress visit at a time.
    final ordered = [...pending]
      ..sort((a, b) => a.checkinAt.compareTo(b.checkinAt));

    var synced = 0;
    var failed = 0;

    for (final visit in ordered) {
      try {
        await _replay(visit);
        await _store.deleteMedia(visit.localId);
        await _store.remove(visit.localId);
        synced++;
      } catch (e) {
        if (isNetworkError(e)) {
          // Still offline — leave the queue untouched and stop.
          final left = (await _store.all()).length;
          return VisitSyncResult(
            synced: synced,
            failed: failed,
            remaining: left,
            wentOffline: true,
          );
        }
        failed++;
        await _store.update(
          visit.copyWith(
            attempts: visit.attempts + 1,
            lastError: formatApiError(e),
          ),
        );
        debugPrint('Visit sync failed for ${visit.localId}: $e');
      }
    }

    final remaining = (await _store.all()).length;
    return VisitSyncResult(
      synced: synced,
      failed: failed,
      remaining: remaining,
    );
  }

  Future<void> _replay(PendingVisit visit) async {
    var current = visit;

    if (current.serverVisitId == null) {
      // The server rejects a second in-progress visit; clear any stale one.
      try {
        final user = _ref.read(currentUserProvider);
        if (user != null) {
          final ongoing = await _visits.getOngoingVisit(user.id);
          if (ongoing != null) {
            await _visits.cancelVisit(ongoing.id);
          }
        }
      } catch (e) {
        if (isNetworkError(e)) rethrow;
        // Non-network cleanup issues shouldn't block the replay attempt.
      }

      final created = await _visits.startVisit(
        farmId: current.farmId,
        farmName: current.farmName,
        executiveId: '',
        executiveName: '',
        latitude: current.checkinLat,
        longitude: current.checkinLng,
      );
      current = current.copyWith(serverVisitId: created.id, clearError: true);
      await _store.update(current);
    }

    await _visits.submitVisit(
      visitId: current.serverVisitId!,
      photos: current.photoPaths,
      checkoutLat: current.checkoutLat,
      checkoutLng: current.checkoutLng,
      voiceNotePath: current.voiceNotePath,
      textNote: current.textNote,
      formAnswers: current.formAnswers,
    );
  }
}

final visitSyncServiceProvider = Provider<VisitSyncService>((ref) {
  return VisitSyncService(ref);
});
