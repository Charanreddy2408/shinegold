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

  /// Copies photos and voice note into app documents so they survive OS
  /// temp cleanup while the visit waits for sync.
  Future<PendingVisit> persistMedia(PendingVisit visit) async {
    if (kIsWeb) return visit;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docs.path}/pending_media/${visit.localId}');
      await mediaDir.create(recursive: true);

      final photoPaths = <String>[];
      for (final path in visit.photoPaths) {
        final copied = await _copyIntoDir(path, mediaDir);
        if (copied != null) photoPaths.add(copied);
      }

      String? voicePath = visit.voiceNotePath;
      if (voicePath != null) {
        voicePath = await _copyIntoDir(voicePath, mediaDir) ?? voicePath;
      }

      return visit.copyWith(photoPaths: photoPaths, voiceNotePath: voicePath);
    } catch (e) {
      debugPrint('OfflineVisitStore persistMedia failed: $e');
      return visit;
    }
  }

  Future<String?> _copyIntoDir(String path, Directory dir) async {
    if (path.startsWith('http')) return path;
    try {
      final source = File(path);
      if (!await source.exists()) return null;
      final name = source.uri.pathSegments.isNotEmpty
          ? source.uri.pathSegments.last
          : 'media_${DateTime.now().millisecondsSinceEpoch}';
      final dest = '${dir.path}/$name';
      if (dest == path) return path;
      await source.copy(dest);
      return dest;
    } catch (e) {
      debugPrint('OfflineVisitStore media copy failed: $e');
      return null;
    }
  }

  /// Removes the durable media folder once a visit has synced.
  Future<void> deleteMedia(String localId) async {
    if (kIsWeb) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docs.path}/pending_media/$localId');
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
    } catch (_) {
      // Leftover files are harmless.
    }
  }

  Future<void> clear() async {
    await _ensureLoaded();
    _visits.clear();
    await _persist();
  }
}
