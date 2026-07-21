import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_endpoints.dart';
import 'dio_client.dart';

class UploadService {
  UploadService(this._client);

  final DioClient _client;

  Future<String> uploadXFile({
    required XFile file,
    required String context,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _resolveContentType(
      name: file.name,
      path: file.path,
      mimeType: file.mimeType,
    );
    return _uploadBytes(bytes: bytes, contentType: contentType, context: context);
  }

  Future<String> uploadFile({
    required String localPath,
    required String context,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'uploadFile is not supported on web. Use uploadXFile instead.',
      );
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File not found: $localPath');
    }

    final contentType = _resolveContentType(name: localPath, path: localPath);
    return _uploadBytes(
      bytes: await file.readAsBytes(),
      contentType: contentType,
      context: context,
    );
  }

  Future<List<String>> uploadFiles({
    required List<String> localPaths,
    required String context,
  }) async {
    final urls = <String>[];
    for (final path in localPaths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
      } else {
        urls.add(await uploadFile(localPath: path, context: context));
      }
    }
    return urls;
  }

  Future<List<String>> uploadXFiles({
    required List<XFile> files,
    required String context,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadXFile(file: file, context: context));
    }
    return urls;
  }

  Future<String> _uploadBytes({
    required List<int> bytes,
    required String contentType,
    required String context,
  }) async {
    final presignResponse = await _client.dio.post(
      ApiEndpoints.uploadPresign,
      data: {
        'file_type': contentType,
        'context': context,
      },
    );

    final data = presignResponse.data as Map<String, dynamic>;
    final uploadUrl =
        data['upload_url'] as String? ?? data['presigned_url'] as String;
    final publicUrl = data['public_url'] as String? ??
        data['file_url'] as String? ??
        data['url'] as String;

    try {
      await Dio().put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': contentType},
          contentType: contentType,
        ),
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? body['detail'])?.toString()
          : body?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
      rethrow;
    }

    return publicUrl;
  }

  /// Ask the API for a fresh playable URL (signed) when public playback fails.
  Future<String> resolvePlayableUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final response = await _client.dio.post(
        ApiEndpoints.uploadResolve,
        data: {'url': trimmed},
      );
      final data = response.data as Map<String, dynamic>;
      final resolved = data['url'] as String?;
      if (resolved != null && resolved.isNotEmpty) return resolved;
    } catch (_) {
      // Fall through to the original URL.
    }
    return trimmed;
  }

  String _resolveContentType({
    required String path,
    String? name,
    String? mimeType,
  }) {
    if (mimeType != null && mimeType.isNotEmpty) {
      return mimeType;
    }
    return _contentTypeFor(name?.isNotEmpty == true ? name! : path);
  }

  String _contentTypeFor(String localPath) {
    final filename = localPath.split(RegExp(r'[/\\]')).last;
    final ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.')).toLowerCase()
        : '';
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.webm':
        return 'audio/webm';
      default:
        return 'image/jpeg';
    }
  }
}
