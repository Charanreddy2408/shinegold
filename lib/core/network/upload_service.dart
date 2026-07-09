import 'dart:io';

import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'dio_client.dart';

class UploadService {
  UploadService(this._client);

  final DioClient _client;

  Future<String> uploadFile({
    required String localPath,
    required String context,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File not found: $localPath');
    }

    final contentType = _contentTypeFor(localPath);

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

    await Dio().put(
      uploadUrl,
      data: await file.readAsBytes(),
      options: Options(
        headers: {'Content-Type': contentType},
        contentType: contentType,
      ),
    );

    return publicUrl;
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
      default:
        return 'application/octet-stream';
    }
  }
}
