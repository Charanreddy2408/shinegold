import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Branded Shine Gold logo (transparent PNG) — use across auth, welcome, and headers.
class ShineLogo extends StatelessWidget {
  const ShineLogo({
    super.key,
    this.size = 120,
    this.fit = BoxFit.contain,
  });

  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco_rounded,
        size: size * 0.65,
        color: AppColors.secondary,
      ),
    );
  }
}
