import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constant/app_colors.dart';
import '../constant/app_sizes.dart';

/// Material 3 Themes strictly configured from UI_DESIGN_SYSTEM.md
class AppTheme {
  AppTheme._();

  // Dark Theme (Default)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.urbanistTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColor.primary,
      scaffoldBackgroundColor: AppColor.darkSurface,
      cardColor: AppColor.darkCard,
      colorScheme: const ColorScheme.dark(
        primary: AppColor.primary,
        secondary: AppColor.secondary,
        surface: AppColor.darkSurface,
        error: AppColor.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColor.textPrimaryDark,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColor.textPrimaryDark,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColor.textSecondaryDark,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColor.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: const BorderSide(color: AppColor.darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.darkDialog,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: const BorderSide(color: AppColor.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.darkSubCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 4,
        ),
        hintStyle: const TextStyle(color: AppColor.textMutedDark, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColor.darkBorder,
        thickness: 1,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.urbanistTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColor.primary,
      scaffoldBackgroundColor: AppColor.lightSurface,
      cardColor: AppColor.lightCard,
      colorScheme: const ColorScheme.light(
        primary: AppColor.primary,
        secondary: AppColor.secondary,
        surface: AppColor.lightSurface,
        error: AppColor.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColor.textPrimaryLight,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColor.textPrimaryLight,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColor.textSecondaryLight,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColor.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: const BorderSide(color: AppColor.lightBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.lightDialog,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          side: const BorderSide(color: AppColor.lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.lightSubCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 4,
        ),
        hintStyle: const TextStyle(color: AppColor.textMutedLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColor.lightBorder,
        thickness: 1,
      ),
    );
  }
}
