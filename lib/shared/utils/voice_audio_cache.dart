import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'media_url.dart';

/// Downloads remote voice notes to a temp file for reliable playback.
class VoiceAudioCache {
  VoiceAudioCache._();

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
    if (bytes == null || bytes.length < 256) {
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
      if (await file.length() < 256) {
        throw Exception('Voice note file is empty');
      }
      return trimmed;
    }

    final resolved = resolveMediaUrl(trimmed);
    final ext = _mediaExtension(resolved);
    final cachePath =
        '${Directory.systemTemp.path}/sg_voice_${resolved.hashCode.abs()}$ext';
    final cacheFile = File(cachePath);

    if (await cacheFile.exists()) {
      final cachedLen = await cacheFile.length();
      if (cachedLen > 256) return cachePath;
    }

    final response = await _dio.download(
      resolved,
      cachePath,
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Could not download voice note (${response.statusCode})');
    }

    final len = await cacheFile.length();
    if (len < 256) {
      throw Exception('Downloaded voice note is empty');
    }

    return cachePath;
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
