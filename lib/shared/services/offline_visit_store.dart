import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/pending_visit.dart';

/// Durable queue of visits captured offline.
///
/// Visits are held in RAM for instant access and mirrored to a JSON file in
/// the app documents directory so nothing is lost if the app is killed
/// before connectivity returns. On web (no reliable file system) the queue
/// is RAM-only for the session.
class OfflineVisitStore {
  OfflineVisitStore._();
  static final instance = OfflineVisitStore._();

  static const _fileName = 'pending_visits.json';

  final List<PendingVisit> _visits = [];
  bool _loaded = false;

  /// Notifies listeners (UI badges, sync triggers) when the queue changes.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    if (kIsWeb) return;
    try {
      final file = await _storageFile();
      if (!await file.exists()) return;
      final raw = jsonDecode(await file.readAsString());
      if (raw is List) {
        _visits
          ..clear()
          ..addAll(
            raw
                .whereType<Map<String, dynamic>>()
                .map(PendingVisit.fromJson),
          );
        pendingCount.value = _visits.length;
      }
    } catch (e) {
      debugPrint('OfflineVisitStore load failed: $e');
    }
  }

  Future<File> _storageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _persist() async {
    pendingCount.value = _visits.length;
    if (kIsWeb) return;
    try {
      final file = await _storageFile();
      await file.writeAsString(
        jsonEncode(_visits.map((v) => v.toJson()).toList()),
        flush: true,
      );
    } catch (e) {
      debugPrint('OfflineVisitStore persist failed: $e');
    }
  }

  Future<List<PendingVisit>> all() async {
    await _ensureLoaded();
    return List.unmodifiable(_visits);
  }

  Future<void> enqueue(PendingVisit visit) async {
    await _ensureLoaded();
    _visits.removeWhere((v) => v.localId == visit.localId);
    _visits.add(visit);
    await _persist();
  }

  Future<void> update(PendingVisit visit) async {
    await _ensureLoaded();
    final index = _visits.indexWhere((v) => v.localId == visit.localId);
    if (index == -1) {
      _visits.add(visit);
    } else {
      _visits[index] = visit;
    }
    await _persist();
  }

  Future<void> remove(String localId) async {
    await _ensureLoaded();
    _visits.removeWhere((v) => v.localId == localId);
    await _persist();
  }

  Future<bool> hasPendingForFarm(String farmId) async {
    await _ensureLoaded();
    return _visits.any((v) => v.farmId == farmId);
  }

  Future<void> clear() async {
    await _ensureLoaded();
    _visits.clear();
    await _persist();
  }
}
