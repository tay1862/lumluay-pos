import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  // Primary - orange brand
  static const primary = Color(0xFFFF6B2C);
  static const primaryDark = Color(0xFFE55A1F);
  static const primaryLight = Color(0xFFFF8F5E);

  // Secondary - deep teal
  static const secondary = Color(0xFF1A7F64);
  static const secondaryDark = Color(0xFF136350);
  static const secondaryLight = Color(0xFF2AAF8E);

  // Neutrals
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F0F0);
  static const border = Color(0xFFE0E0E0);

  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // Dark mode
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceVariantDark = Color(0xFF2C2C2C);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: _textTheme(Brightness.light),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          color: AppColors.surface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(0, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Sarabun',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        ),
        textTheme: _textTheme(Brightness.dark),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        fontFamily: 'Sarabun',
      );

  static TextTheme _textTheme(Brightness brightness) {
    final color =
        brightness == Brightness.light ? Colors.black87 : Colors.white;
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 57.sp, color: color),
      displayMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 45.sp, color: color),
      displaySmall: TextStyle(fontFamily: 'Sarabun', fontSize: 36.sp, color: color),
      headlineLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 32.sp, fontWeight: FontWeight.w700, color: color),
      headlineMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 28.sp, fontWeight: FontWeight.w600, color: color),
      headlineSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 24.sp, fontWeight: FontWeight.w600, color: color),
      titleLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 22.sp, fontWeight: FontWeight.w600, color: color),
      titleMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 16.sp, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 16.sp, color: color),
      bodyMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, color: color),
      bodySmall: TextStyle(fontFamily: 'Sarabun', fontSize: 12.sp, color: color),
      labelLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, fontWeight: FontWeight.w600, color: color),
      labelMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 12.sp, color: color),
      labelSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 11.sp, color: color),
    );
  }
}
