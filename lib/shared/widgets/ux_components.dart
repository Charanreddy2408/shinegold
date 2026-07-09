import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';

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
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = widget.isRecording ? 1.0 + _pulse.value * 0.08 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: AppColors.minTouchTarget * 1.6,
                  height: AppColors.minTouchTarget * 1.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isRecording
                        ? AppColors.secondaryMuted
                        : AppColors.surfaceElevated,
                    border: Border.all(
                      color: widget.isRecording
                          ? AppColors.secondarySoft
                          : AppColors.borderSubtle,
                      width: widget.isRecording ? 3 : 1,
                    ),
                    boxShadow: widget.isRecording
                        ? [
                            BoxShadow(
                              color: AppColors.secondarySoft.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 36,
                    color: widget.isRecording
                        ? AppColors.secondarySoft
                        : AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isRecording) _Waveform(isActive: true) else _Waveform(isActive: false),
        const SizedBox(height: 12),
        Text(
          widget.isRecording ? 'Tap to stop recording' : 'Tap to start recording',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
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
              color: isActive ? AppColors.secondarySoft : AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
