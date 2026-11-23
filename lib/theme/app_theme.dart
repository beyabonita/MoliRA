import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primaryGreen = Color(0xFF1B4332);
  static const primaryGreenDark = Color(0xFF163729);
  static const softGreenBg = Color(0xFFEBF2ED);
  static const warmCreamBg = Color(0xFFF9F8F3);
  static const warmBeigeCard = Color(0xFFF3EBDD);
  static const amberAccent = Color(0xFFB08434);
  static const softAmberBg = Color(0xFFF7EFE0);
  static const overdueRed = Color(0xFFB9382C);
  static const softRedBg = Color(0xFFFCECEB);
  static const blueAccent = Color(0xFF345F7D);
  static const softBlueBg = Color(0xFFEAF1F6);
  static const cardWhite = Color(0xFFFFFFFF);
  static const borderSubtle = Color(0xFFE5E2D8);
  static const textPrimary = Color(0xFF1D2420);
  static const textSecondary = Color(0xFF5D6660);
  static const textMuted = Color(0xFF7C847E);
}

ThemeData buildChmsuTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.warmCreamBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      primary: AppColors.primaryGreen,
      surface: AppColors.cardWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.warmCreamBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
