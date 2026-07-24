import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'media_url.dart';

/// Downloads remote voice notes to a temp file for reliable playback.
class VoiceAudioCache {
  VoiceAudioCache._();

  /// Below this size a "downloaded" file is almost certainly a truncated or
  /// header-only stub, not real audio.
  static const int _minValidBytes = 2048;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
    ),
  );

  static Future<Uint8List> loadBytes(String url) async {
    final resolved = resolveMediaUrl(url.trim());
    if (resolved.isEmpty) {
      throw Exception('Voice note URL is empty');
    }

    final response = await _dio.get<List<int>>(
      resolved,
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not download voice note (${response.statusCode})');
    }

    final bytes = response.data;
    if (bytes == null || bytes.length < _minValidBytes) {
      throw Exception('Downloaded voice note is empty');
    }

    return Uint8List.fromList(bytes);
  }

  static Future<String> ensureLocal(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw Exception('Voice note URL is empty');
    }

    if (kIsWeb) {
      return resolveMediaUrl(trimmed);
    }

    if (!isRemoteMediaUrl(trimmed)) {
      final file = File(trimmed);
      if (!await file.exists()) {
        throw Exception('Voice note file not found');
      }
      if (await file.length() < _minValidBytes) {
        throw Exception('Voice note file is empty');
      }
      return trimmed;
    }

    final resolved = resolveMediaUrl(trimmed);
    final ext = _mediaExtension(resolved);
    final cachePath =
        '${Directory.systemTemp.path}/sg_voice_${resolved.hashCode.abs()}$ext';
    final cacheFile = File(cachePath);

    // A stale/truncated cache entry from a prior interrupted download used to
    // be trusted forever (only a >64 byte check, never compared against the
    // server). Confirm the cached size still matches the server's reported
    // size before reusing it; on any mismatch or HEAD failure, fall through
    // to a fresh download rather than silently serving a broken file.
    if (await cacheFile.exists()) {
      final cachedLen = await cacheFile.length();
      if (cachedLen > _minValidBytes) {
        final remoteLen = await _remoteContentLength(resolved);
        if (remoteLen == null || remoteLen == cachedLen) {
          return cachePath;
        }
      }
      await cacheFile.delete().catchError((_) => cacheFile);
    }

    // Download to a temp part-file first and only move it into place once
    // fully written, so a crash/interruption mid-download can never leave a
    // partial file sitting at the real cache path for a later playback to
    // pick up as "valid".
    final partPath = '$cachePath.part';
    final partFile = File(partPath);
    try {
      final response = await _dio.download(
        resolved,
        partPath,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Could not download voice note (${response.statusCode})');
      }

      final len = await partFile.length();
      if (len < _minValidBytes) {
        throw Exception('Downloaded voice note is empty');
      }
      final expectedLen = _parseContentLength(response.headers.value(Headers.contentLengthHeader));
      if (expectedLen != null && expectedLen != len) {
        throw Exception('Downloaded voice note is incomplete');
      }

      await partFile.rename(cachePath);
      return cachePath;
    } finally {
      if (await partFile.exists()) {
        await partFile.delete().catchError((_) => partFile);
      }
    }
  }

  static int? _parseContentLength(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  static Future<int?> _remoteContentLength(String resolved) async {
    try {
      final response = await _dio.head(resolved);
      return _parseContentLength(response.headers.value(Headers.contentLengthHeader));
    } catch (_) {
      return null;
    }
  }

  static String _mediaExtension(String url) {
    final path = Uri.parse(url).path.toLowerCase();
    if (path.endsWith('.wav')) return '.wav';
    if (path.endsWith('.webm')) return '.webm';
    if (path.endsWith('.mp3')) return '.mp3';
    if (path.endsWith('.ogg')) return '.ogg';
    return '.m4a';
  }
}
