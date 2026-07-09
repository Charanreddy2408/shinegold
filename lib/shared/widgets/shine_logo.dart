import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Branded Shine Gold logo — use across auth, welcome, and headers.
class ShineLogo extends StatelessWidget {
  const ShineLogo({
    super.key,
    this.size = 120,
    this.fit = BoxFit.contain,
    this.inCard = false,
    this.cardPadding = AppSpacing.xl,
    this.cardRadius = AppSpacing.radiusXl,
  });

  final double size;
  final BoxFit fit;
  final bool inCard;
  final double cardPadding;
  final double cardRadius;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );

    if (!inCard) return logo;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: AppColors.cardDecoration(radius: cardRadius),
      child: logo,
    );
  }
}
