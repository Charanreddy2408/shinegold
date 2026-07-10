import '../../core/config/app_config.dart';

/// Resolves relative media paths to absolute URLs for images and audio.
String resolveMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${AppConfig.baseUrl}$trimmed';
  }
  return trimmed;
}

bool isRemoteMediaUrl(String url) {
  final trimmed = url.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}
