import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Warm brand canvas used behind main screens.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.header,
  });

  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientCanvas),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Expanded(child: child),
        ],
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.compact = false,
    this.brandLogoSize,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool compact;
  final double? brandLogoSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusHeader),
          bottomRight: Radius.circular(AppSpacing.radiusHeader),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGold,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        compact ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.xl,
        compact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 22 : 24,
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (brandLogoSize != null || compact)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  AppAssets.logo,
                  width: brandLogoSize ?? 32,
                  height: brandLogoSize ?? 32,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
