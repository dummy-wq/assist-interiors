import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Centralized design tokens for sizes, radii, and spacing.
/// Standardizes geometry across all cards, dialogs, buttons, and pillboxes.
class AppSizes {
  AppSizes._();

  // Corner Radii Tokens
  // sm = 4.0 (interactive controls, pillboxes, chips, buttons, small tags)
  // md = 6.0 (containers, cards, dialogs, bottom sheets)
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  // Spacing Scale
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Typography Size Tokens
  static const double fontXs = 11.0;
  static const double fontSm = 12.0;
  static const double fontBase = 13.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 20.0;
  static const double fontDisplay = 24.0;

  // Standardized Chiplet / PillBox Tokens
  static const double chipHeight = 35.0;
  static const double chipFontSize = 12.0;
  static const double chipIconSize = 14.0;
  static const double chipRadius = 6.0;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 0,
  );

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
