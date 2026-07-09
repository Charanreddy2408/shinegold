import 'package:flutter/material.dart';

/// Shine Gold brand palette — warm harvest gold + field green on clean surfaces.
class AppColors {
  AppColors._();

  // ── Brand gold ──
  static const primary = Color(0xFFE8A317);
  static const primaryBright = Color(0xFFF5B700);
  static const primarySoft = Color(0xFFFFF4D6);
  static const primaryDim = Color(0xFFC98E0A);
  static const primaryDark = Color(0xFF8A6508);

  static const harvestGold = primary;
  static const harvestGoldSoft = primarySoft;
  static const harvestGoldDim = primaryDim;

  // ── Field green ──
  static const secondary = Color(0xFF1A9B5C);
  static const secondarySoft = Color(0xFF22C06E);
  static const secondaryMuted = Color(0xFFD8F5E6);

  static const fieldGreen = secondary;
  static const fieldGreenSoft = secondarySoft;
  static const fieldGreenMuted = secondaryMuted;

  static const success = secondary;
  static const warning = Color(0xFFE6A817);
  static const error = Color(0xFFC62828);
  static const errorSoft = Color(0xFFFFEBEE);
  static const info = Color(0xFF2E7D9A);

  // ── Surfaces ──
  static const canvasDeep = Color(0xFFFAFAF8);
  static const canvasMid = Color(0xFFF7F4EE);
  static const canvasGradientEnd = Color(0xFFF0EBE0);
  static const surfaceWarm = Color(0xFFFFFBF7);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFFFBF5);

  static const textPrimary = Color(0xFF1C1917);
  static const textSecondary = Color(0xFF44403C);
  static const textMuted = Color(0xFF78716C);

  static const borderSubtle = Color(0xFFE7E2D9);
  static const borderAccent = Color(0xFFE8C96A);
  static const borderFocus = primary;

  static const shadowLight = Color(0x12000000);
  static const shadowMedium = Color(0x1A000000);
  static const shadowGold = Color(0x33E8A317);

  static const gradientBrand = LinearGradient(
    colors: [primaryBright, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientHeader = LinearGradient(
    colors: [Color(0xFFE8A317), Color(0xFF1A9B5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCanvas = LinearGradient(
    colors: [canvasDeep, canvasMid, canvasGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const double minTouchTarget = 48;
  static const double cardRadius = 16;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: shadowLight,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double? radius,
  }) =>
      BoxDecoration(
        color: color ?? surfaceCard,
        borderRadius: BorderRadius.circular(radius ?? cardRadius),
        border: Border.all(color: borderColor ?? borderSubtle),
        boxShadow: cardShadow,
      );
}
