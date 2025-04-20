import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle heading = GoogleFonts.lato(
    color: AppColors.primary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle subheading = GoogleFonts.lato(
    color: AppColors.primary,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static TextStyle buttonText = GoogleFonts.lato(
    color: AppColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle linkText = GoogleFonts.lato(
    color: AppColors.secondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle heading1 = GoogleFonts.lato(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitle = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.lato(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.lato(
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.lato(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}