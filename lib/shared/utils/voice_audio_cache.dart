import 'dart:io';

import 'package:dio/dio.dart';

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

  static Future<String> ensureLocal(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw Exception('Voice note URL is empty');
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
    final cachePath =
        '${Directory.systemTemp.path}/sg_voice_${resolved.hashCode.abs()}.m4a';
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
}
