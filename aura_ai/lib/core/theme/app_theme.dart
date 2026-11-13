import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        brightness: Brightness.dark,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.manrope().fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: _b(Colors.transparent),
        enabledBorder: _b(Colors.white.withValues(alpha: 0.10)),
        focusedBorder: _b(AppColors.violet.withValues(alpha: 0.9), 1.4),
        errorBorder: _b(AppColors.pink.withValues(alpha: 0.7)),
        focusedErrorBorder: _b(AppColors.pink, 1.4),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        helperStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1740),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF16133A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}