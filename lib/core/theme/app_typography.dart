import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Roboto';

  static final TextTheme textTheme = TextTheme(
    displayLarge: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    headlineMedium: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 1.25,
      letterSpacing: -0.3,
    ),
    headlineSmall: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 1.3,
    ),
    titleLarge: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.3,
    ),
    titleMedium: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.35,
    ),
    titleSmall: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.35,
    ),
    bodyLarge: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textPrimary,
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.45,
    ),
    labelLarge: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      letterSpacing: 0.8,
    ),
    labelSmall: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.textMuted,
      fontSize: 12,
      height: 1.35,
    ),
  );

  static const TextStyle statNumber = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.1,
    letterSpacing: -0.5,
  );
}
