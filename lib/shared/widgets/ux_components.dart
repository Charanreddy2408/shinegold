import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../utils/media_url.dart';
import '../utils/voice_audio_cache.dart';

bool _audioContextReady = false;

Future<void> ensureVoiceAudioContext() async {
  if (_audioContextReady) return;
  await AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    ),
  );
  _audioContextReady = true;
}

class HealthBadge extends StatelessWidget {
  const HealthBadge({super.key, required this.status});

  final FarmHealthStatus status;

  Color get _color {
    switch (status) {
      case FarmHealthStatus.healthy:
        return AppColors.success;
      case FarmHealthStatus.needsWater:
        return AppColors.warning;
      case FarmHealthStatus.needsAttention:
        return AppColors.warning;
      case FarmHealthStatus.critical:
        return AppColors.error;
      case FarmHealthStatus.urgentVisit:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SyncStatus.synced => AppColors.success,
      SyncStatus.pendingSync => AppColors.warning,
      SyncStatus.syncFailed => AppColors.error,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status.emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class FriendlyErrorBanner extends StatelessWidget {
  const FriendlyErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        collapsedBackgroundColor: AppColors.surfaceCard,
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ConditionSelector extends StatelessWidget {
  const ConditionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FarmHealthStatus? selected;
  final ValueChanged<FarmHealthStatus> onSelected;

  static const _options = [
    FarmHealthStatus.healthy,
    FarmHealthStatus.needsWater,
    FarmHealthStatus.needsAttention,
    FarmHealthStatus.critical,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _options.map((option) {
        final isSelected = selected == option;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(option),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(option.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({
    super.key,
    required this.isRecording,
    required this.onToggle,
  });

  final bool isRecording;
  final VoidCallback onToggle;

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceRecorderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale =
                    widget.isRecording ? 1.0 + _pulse.value * 0.06 : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? AppColors.secondaryMuted
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color: widget.isRecording
                            ? AppColors.secondary
                            : AppColors.borderSubtle,
                        width: widget.isRecording ? 2.5 : 1.5,
                      ),
                      boxShadow: widget.isRecording
                          ? [
                              BoxShadow(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.25),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      size: 32,
                      color: widget.isRecording
                          ? AppColors.secondary
                          : AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 28,
            child: _Waveform(isActive: widget.isRecording),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isRecording
                ? 'Tap to stop recording'
                : 'Tap to record a voice note',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final h = isActive ? 8.0 + (i % 4) * 6.0 : 4.0;
          return Container(
            width: 4,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.secondary : AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key, required this.url});

  final String url;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late final AudioPlayer _player;
  bool _playing = false;
  bool _loading = false;
  String? _error;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_initPlayer());
  }

  Future<void> _initPlayer() async {
    await ensureVoiceAudioContext();
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setVolume(1.0);
    await _player.setReleaseMode(ReleaseMode.stop);

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });

    _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null || d.inSeconds <= 0) return '';
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ensureVoiceAudioContext();
      final localPath = await VoiceAudioCache.ensureLocal(widget.url);

      await _player.stop();
      await _player.setSource(DeviceFileSource(localPath));

      final duration = await _player.getDuration();
      if (duration == null || duration.inMilliseconds < 50) {
        final remote = resolveMediaUrl(widget.url);
        await _player.setSource(UrlSource(remote));
      }

      await _player.resume();

      if (!mounted) return;
      setState(() {
        _loading = false;
        _duration = duration;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = false;
        _error = 'Unable to play voice note';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _loading ? null : _togglePlayback,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.secondaryMuted,
              foregroundColor: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _playing ? 'Playing voice note...' : 'Recorded voice note',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error ??
                      (_playing
                          ? 'Playing${_duration != null && _duration!.inSeconds > 0 ? ' · ${_formatDuration(_duration)}' : ''}'
                          : _duration != null && _duration!.inSeconds > 0
                              ? 'Duration ${_formatDuration(_duration)} · Tap to play'
                              : 'Tap play to listen'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _error != null
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.mic_rounded, color: AppColors.secondary),
        ],
      ),
    );
  }
}

/// Opens a fullscreen swipeable photo viewer.
void showPhotoGallery(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => _PhotoGalleryDialog(
      urls: urls,
      initialIndex: initialIndex.clamp(0, urls.length - 1),
    ),
  );
}

class _PhotoGalleryDialog extends StatefulWidget {
  const _PhotoGalleryDialog({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = resolveMediaUrl(widget.urls[i]);
                final isRemote = isRemoteMediaUrl(url);
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: isRemote
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 64,
                            ),
                          )
                        : Image.file(
                            File(url),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${widget.urls.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
