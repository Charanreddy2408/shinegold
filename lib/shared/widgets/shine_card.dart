import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ShineCard extends StatelessWidget {
  const ShineCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EdgeInsets padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(
          color: accentColor != null
              ? accentColor!.withValues(alpha: 0.45)
              : AppColors.borderSubtle,
          width: accentColor != null ? 1.5 : 1.2,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: accentColor != null
                      ? accentColor!.withValues(alpha: 0.18)
                      : AppColors.shadowGold,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      foregroundDecoration: accentColor != null
          ? BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppColors.cardRadius),
              ),
              border: Border(
                left: BorderSide(color: accentColor!, width: 4),
              ),
            )
          : null,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        splashColor: AppColors.primarySoft.withValues(alpha: 0.5),
        child: card,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.accentColor = AppColors.primary,
    this.index = 0,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accentColor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.32),
                accentColor.withValues(alpha: 0.12),
                AppColors.surfaceCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.38),
                                accentColor.withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(icon, color: accentColor, size: 22),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: AppTypography.statNumber.copyWith(
                        color: accentColor,
                        fontSize: 26,
                        height: 1,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: (index * 100 + 200).ms,
                          duration: 500.ms,
                        )
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return card
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
