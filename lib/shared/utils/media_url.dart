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

/// MIME type for voice playback / uploads, inferred from URL or path.
String mediaMimeTypeFromUrl(String url) {
  final path = Uri.tryParse(url.trim())?.path.toLowerCase() ?? url.toLowerCase();
  if (path.endsWith('.wav')) return 'audio/wav';
  if (path.endsWith('.webm')) return 'audio/webm';
  if (path.endsWith('.ogg') || path.endsWith('.opus')) return 'audio/ogg';
  if (path.endsWith('.mp3')) return 'audio/mpeg';
  if (path.endsWith('.m4a') || path.endsWith('.mp4') || path.endsWith('.aac')) {
    return 'audio/mp4';
  }
  if (path.endsWith('.3gp') || path.endsWith('.3gpp')) return 'audio/3gpp';
  if (path.endsWith('.amr')) return 'audio/amr';
  return 'audio/mpeg';
}
