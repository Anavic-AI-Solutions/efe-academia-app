import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Color palette for professor role screens.
/// Mirrors the blue theme from AppColors with professor-specific naming.
class ProfessorColors {
  ProfessorColors._();

  // Primary blues
  static const Color primary = AppColors.primary;
  static const Color primarySoft = AppColors.primarySoft;
  static const Color primaryLight = AppColors.primaryLight;

  // Surface colors
  static const Color surface = AppColors.lightBackground;
  static const Color surfaceElevated = AppColors.lightSurface;

  // Text colors
  static const Color onPrimary = AppColors.onPrimary;
  static const Color onPrimaryMuted = AppColors.onPrimaryMuted;
  static const Color sectionLabel = AppColors.sectionLabel;

  // Overlay colors for gradient header stats
  static const Color overlay = AppColors.overlay;
  static const Color overlayStrong = AppColors.overlayStrong;
}
