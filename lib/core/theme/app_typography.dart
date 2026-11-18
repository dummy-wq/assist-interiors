import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

enum AppFontTheme {
  cascadiaCode('Cascadia Code', 'Technical CAD & Monospace Grid'),
  spaceGrotesk('Space Grotesk', 'Modern Architectural Grotesque'),
  plusJakartaSans('Plus Jakarta Sans', 'Clean Modern Studio Sans'),
  syne('Syne', 'Avant-Garde Architectural Editorial'),
  dmMono('DM Mono', 'Swiss Minimalist Monospace'),
  oswaldInter('Oswald & Inter', 'Original Curled Brand Font');

  final String label;
  final String description;
  const AppFontTheme(this.label, this.description);
}

class AppTypography {
  static AppFontTheme activeTheme = AppFontTheme.plusJakartaSans;

  static String? get fontFamily {
    switch (activeTheme) {
      case AppFontTheme.plusJakartaSans:
        return GoogleFonts.plusJakartaSans().fontFamily;
      case AppFontTheme.spaceGrotesk:
        return GoogleFonts.spaceGrotesk().fontFamily;
      case AppFontTheme.cascadiaCode:
        return GoogleFonts.cascadiaCode().fontFamily;
      case AppFontTheme.syne:
        return GoogleFonts.syne().fontFamily;
      case AppFontTheme.dmMono:
        return GoogleFonts.dmMono().fontFamily;
      case AppFontTheme.oswaldInter:
        return GoogleFonts.inter().fontFamily;
    }
  }

  static TextStyle _resolve({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
    bool isDisplay = false,
  }) {
    final baseStyle = const TextStyle(
      leadingDistribution: TextLeadingDistribution.even,
    );

    // Enhance stroke clarity and legibility across all display devices:
    // Any light/regular/medium weight (w100–w500) is elevated to w600 (SemiBold)
    // so text is crisp, prominent, and easy to read for all users without semi-light strokes.
    FontWeight resolvedWeight = fontWeight;
    if (resolvedWeight.value <= FontWeight.w500.value) {
      resolvedWeight = FontWeight.w600;
    }

    // Default letterSpacing:
    // Open tracking (+0.05 to +0.2) on smaller font sizes prevents glyph crowding and improves readability.
    final defaultSpacing = isDisplay
        ? (activeTheme == AppFontTheme.syne || activeTheme == AppFontTheme.oswaldInter ? 0.3 : -0.2)
        : (fontSize <= 11.5 ? 0.15 : (fontSize <= 13 ? 0.08 : 0.04));
    final resolvedSpacing = letterSpacing ?? defaultSpacing;
    final resolvedHeight = height ?? (isDisplay ? 1.26 : 1.40);

    switch (activeTheme) {
      case AppFontTheme.plusJakartaSans:
        return GoogleFonts.plusJakartaSans(
          textStyle: baseStyle,
          fontSize: fontSize,
          fontWeight: resolvedWeight,
          letterSpacing: resolvedSpacing,
          height: resolvedHeight,
          color: color,
        );
      case AppFontTheme.spaceGrotesk:
        return GoogleFonts.spaceGrotesk(
          textStyle: baseStyle,
          fontSize: fontSize,
          fontWeight: resolvedWeight,
          letterSpacing: resolvedSpacing,
          height: resolvedHeight,
          color: color,
        );
      case AppFontTheme.cascadiaCode:
        return GoogleFonts.cascadiaCode(
          textStyle: baseStyle,
          fontSize: fontSize,
          fontWeight: resolvedWeight,
          letterSpacing: resolvedSpacing,
          height: resolvedHeight,
          color: color,
        );
      case AppFontTheme.syne:
        return GoogleFonts.syne(
          textStyle: baseStyle,
          fontSize: fontSize,
          fontWeight: resolvedWeight,
          letterSpacing: resolvedSpacing,
          height: resolvedHeight,
          color: color,
        );
      case AppFontTheme.dmMono:
        return GoogleFonts.dmMono(
          textStyle: baseStyle,
          fontSize: fontSize,
          fontWeight: resolvedWeight,
          letterSpacing: resolvedSpacing,
          height: resolvedHeight,
          color: color,
        );
      case AppFontTheme.oswaldInter:
        return isDisplay
            ? GoogleFonts.oswald(
                textStyle: baseStyle,
                fontSize: fontSize,
                fontWeight: resolvedWeight,
                letterSpacing: letterSpacing ?? 0.8,
                height: resolvedHeight,
                color: color,
              )
            : GoogleFonts.inter(
                textStyle: baseStyle,
                fontSize: fontSize,
                fontWeight: resolvedWeight,
                letterSpacing: resolvedSpacing,
                height: resolvedHeight,
                color: color,
              );
    }
  }

  // Display Headers
  static TextStyle displayLarge(bool isDark) => _resolve(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
    isDisplay: true,
  );

  static TextStyle displayMedium(bool isDark) => _resolve(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
    isDisplay: true,
  );

  static TextStyle displaySmall(bool isDark) => _resolve(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
    isDisplay: true,
  );

  // Body & Titles
  static TextStyle titleLarge(bool isDark) => _resolve(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
    isDisplay: true,
  );

  static TextStyle titleMedium(bool isDark) => _resolve(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
  );

  static TextStyle bodyLarge(bool isDark) => _resolve(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
  );

  static TextStyle bodyMedium(bool isDark) => _resolve(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
  );

  static TextStyle bodySmall(bool isDark) => _resolve(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
  );

  static TextStyle labelLarge(bool isDark) => _resolve(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
  );

  static TextStyle labelSmall(bool isDark) => _resolve(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.25,
    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
  );

  static TextTheme textTheme(bool isDark) => TextTheme(
    displayLarge: displayLarge(isDark),
    displayMedium: displayMedium(isDark),
    displaySmall: displaySmall(isDark),
    headlineLarge: displayMedium(isDark),
    headlineMedium: displaySmall(isDark),
    headlineSmall: titleLarge(isDark),
    titleLarge: titleLarge(isDark),
    titleMedium: titleMedium(isDark),
    titleSmall: bodyLarge(isDark),
    bodyLarge: bodyLarge(isDark),
    bodyMedium: bodyMedium(isDark),
    bodySmall: bodySmall(isDark),
    labelLarge: labelLarge(isDark),
    labelSmall: labelSmall(isDark),
  );
}
