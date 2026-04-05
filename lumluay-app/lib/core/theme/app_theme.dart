import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Vibrant Modern Design System (Loyverse/Grab style) ─────────────────────
class AppColors {
  AppColors._();

  // Primary – warm orange gradient base
  static const primary = Color(0xFFFF6B2C);
  static const primaryDark = Color(0xFFE8551A);
  static const primaryLight = Color(0xFFFF8E53);
  static const primarySoft = Color(0xFFFFF3ED);

  // Secondary – deep teal for contrast
  static const secondary = Color(0xFF1A7F64);
  static const secondaryDark = Color(0xFF136350);
  static const secondaryLight = Color(0xFF2AAF8E);
  static const secondarySoft = Color(0xFFE8F8F3);

  // Accent – vibrant blue for info/links
  static const accent = Color(0xFF4E7BFF);
  static const accentLight = Color(0xFFEEF2FF);

  // Neutrals
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF2F3F5);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EAED);
  static const borderLight = Color(0xFFF0F1F3);
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status – vibrant and modern
  static const success = Color(0xFF22C55E);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFEFF6FF);

  // Dark mode – elevated surfaces
  static const backgroundDark = Color(0xFF0F1117);
  static const surfaceDark = Color(0xFF1A1D27);
  static const surfaceVariantDark = Color(0xFF252836);
  static const surfaceElevatedDark = Color(0xFF2A2D3A);
  static const borderDark = Color(0xFF353849);
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B2C), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF1A7F64), Color(0xFF2AAF8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF4E7BFF), Color(0xFF7C9FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFFFF6B2C), Color(0xFFFF8E53), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkHeroGradient = LinearGradient(
    colors: [Color(0xFFE8551A), Color(0xFFFF6B2C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Shared Radii & Shadows ─────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static double get xs => 6.r;
  static double get sm => 10.r;
  static double get md => 14.r;
  static double get lg => 18.r;
  static double get xl => 24.r;
  static double get pill => 100.r;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> primaryGlow(double opacity) => [
        BoxShadow(
          color: AppColors.primary.withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];
}

// ─── Theme ──────────────────────────────────────────────────────────────────
class AppTheme {
  // ── LIGHT ───────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          primaryContainer: AppColors.primarySoft,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textOnPrimary,
          secondaryContainer: AppColors.secondarySoft,
          tertiary: AppColors.accent,
          tertiaryContainer: AppColors.accentLight,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceVariant,
          error: AppColors.error,
          onError: AppColors.textOnPrimary,
          outline: AppColors.border,
          outlineVariant: AppColors.borderLight,
        ),
        textTheme: _textTheme(Brightness.light),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
            side: const BorderSide(color: AppColors.border),
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          hintStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 15.sp,
            color: AppColors.textTertiary,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primarySoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          side: BorderSide.none,
          labelStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 14.sp,
            color: Colors.white,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
          space: 1,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.surface,
          selectedIconTheme: const IconThemeData(color: AppColors.primary),
          unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
          selectedLabelTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          unselectedLabelTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
          indicatorColor: AppColors.primarySoft,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              );
            }
            return TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            );
          }),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Sarabun',
      );

  // ── DARK ────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          primaryContainer: Color(0xFF3D2012),
          secondary: AppColors.secondaryLight,
          onSecondary: AppColors.textOnPrimary,
          secondaryContainer: Color(0xFF12352A),
          tertiary: AppColors.accent,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainerHighest: AppColors.surfaceVariantDark,
          error: AppColors.error,
          onError: AppColors.textOnPrimary,
          outline: AppColors.borderDark,
          outlineVariant: Color(0xFF2A2D3A),
        ),
        textTheme: _textTheme(Brightness.dark),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          color: AppColors.surfaceElevatedDark,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceElevatedDark,
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            elevation: 0,
            side: const BorderSide(color: AppColors.borderDark),
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariantDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          hintStyle: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 15.sp,
            color: AppColors.textSecondaryDark,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariantDark,
          selectedColor: const Color(0xFF3D2012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          side: BorderSide.none,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceElevatedDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          backgroundColor: AppColors.surfaceElevatedDark,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 1,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedIconTheme: const IconThemeData(color: AppColors.primary),
          unselectedIconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
          indicatorColor: const Color(0xFF3D2012),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          indicatorColor: const Color(0xFF3D2012),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        fontFamily: 'Sarabun',
      );

  // ── TEXT THEME ──────────────────────────────────────────────────────────
  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.textPrimaryDark;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.textSecondaryDark;

    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 57.sp, color: primary, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 45.sp, color: primary, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(fontFamily: 'Sarabun', fontSize: 36.sp, color: primary, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 32.sp, fontWeight: FontWeight.w800, color: primary),
      headlineMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 28.sp, fontWeight: FontWeight.w700, color: primary),
      headlineSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 24.sp, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 22.sp, fontWeight: FontWeight.w700, color: primary),
      titleMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 16.sp, fontWeight: FontWeight.w600, color: primary),
      titleSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 16.sp, color: primary, height: 1.5),
      bodyMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, color: primary, height: 1.5),
      bodySmall: TextStyle(fontFamily: 'Sarabun', fontSize: 12.sp, color: secondary, height: 1.4),
      labelLarge: TextStyle(fontFamily: 'Sarabun', fontSize: 14.sp, fontWeight: FontWeight.w700, color: primary),
      labelMedium: TextStyle(fontFamily: 'Sarabun', fontSize: 12.sp, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: TextStyle(fontFamily: 'Sarabun', fontSize: 11.sp, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
