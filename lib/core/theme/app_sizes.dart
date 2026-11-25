import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized design tokens for sizes, radii, borders, and spacing.
/// Standardizes geometry across all cards, dialogs, buttons, sheets, and grids.
class AppSizes {
  AppSizes._();

  // Corner Radii Tokens
  // sm = 4.0 (micro indicators / inline tags / badges)
  // md = 6.0 (standardized buttons, chips, cards, inputs, dialogs)
  // lg = 12.0 (standardized modal bottom sheets)
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 12.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius sheetBorderRadius = BorderRadius.vertical(
    top: Radius.circular(radiusLg),
  );
  static const RoundedRectangleBorder sheetShape = RoundedRectangleBorder(
    borderRadius: sheetBorderRadius,
  );

  // Standardized Border & Surface Tokens
  static const double borderWidth = 0.8;
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardHeaderPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 14.0,
  );

  /// Canonical card surface decoration shared across all cards and panels.
  static BoxDecoration cardDecoration(
    bool isDark, {
    Color? color,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
      borderRadius: borderRadius ?? borderRadiusMd,
      border: Border.all(
        color: borderColor ??
            (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.75),
        width: borderWidth,
      ),
    );
  }

  // Spacing Scale
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Typography Size Tokens (aligned 1:1 with AppTypography)
  static const double fontXs = 11.0;
  static const double fontSm = 12.0;
  static const double fontBase = 13.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 18.0;
  static const double fontDisplay = 22.0;

  // Standardized Chiplet / PillBox Tokens
  static const double chipHeight = 35.0;
  static const double chipFontSize = 12.0;
  static const double chipIconSize = 14.0;
  static const double chipRadius = 6.0;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 0,
  );

  // Standardized Primary / Modal / Sheet Button Tokens
  static const double buttonHeight = 40.0;
  static const double buttonRadius = 6.0;
  static const double buttonFontSize = 13.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 0,
  );

  // Standardized Compact / Inline Card & Bar Action Button Tokens
  static const double compactButtonHeight = 38.0;
  static const double compactButtonRadius = 6.0;
  static const double compactButtonFontSize = 12.0;
  static const double compactButtonIconSize = 14.0;
  static const EdgeInsets compactButtonPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 0,
  );

  static ButtonStyle compactOutlinedStyle({
    required Color foregroundColor,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      elevation: 0,
      side: BorderSide(
        color: borderColor ?? foregroundColor,
        width: 0.9,
      ),
      minimumSize: const Size(0, compactButtonHeight),
      maximumSize: const Size(double.infinity, compactButtonHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding ?? compactButtonPadding,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
      textStyle: const TextStyle(
        fontSize: compactButtonFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle compactElevatedStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      minimumSize: const Size(0, compactButtonHeight),
      maximumSize: const Size(double.infinity, compactButtonHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding ?? compactButtonPadding,
      shape: const RoundedRectangleBorder(borderRadius: borderRadiusMd),
      textStyle: const TextStyle(
        fontSize: compactButtonFontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // Standardized Action / Header Button Tokens
  static const double topActionButtonSize = 34.0;
  static const double topActionIconSize = 18.0;
  static const double topActionRadius = 6.0;

  // Standardized Metric Card / StatCard Tokens
  static const double statCardHeightDesktop = 50.0;
  static const double statCardHeightMobile = 48.0;

  /// Computes safe bottom padding for modal sheets taking into account
  /// Android/iOS system navigation bar insets and software keyboard.
  static double sheetBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final navBarInset = math.max(
      mediaQuery.viewPadding.bottom,
      mediaQuery.padding.bottom,
    );
    if (mediaQuery.viewInsets.bottom > 0) {
      return mediaQuery.viewInsets.bottom + 20.0;
    }
    return navBarInset > 0 ? (navBarInset + 12.0) : 20.0;
  }
}
