import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foodbank/core/constants/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get errorSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
