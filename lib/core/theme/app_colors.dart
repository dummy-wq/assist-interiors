import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Extracted directly from assistinteriors.in)
  static const Color brandPeach = Color(0xFFF3B9A8);
  static const Color brandPeachDark = Color(0xFFD48B77);
  static const Color brandOrange = Color(0xFFEF6700);
  static const Color brandBlue = Color(0xFF004187);

  // Dark Theme Surfaces & Backgrounds
  static const Color darkBackground = Color(0xFF0E1017);
  static const Color darkCard = Color(0xFF171A22);
  static const Color darkCardElevated = Color(0xFF1B1E25);
  static const Color darkBorder = Color(0xFF232730);
  static const Color darkDivider = Color(0xFF2A2E39);

  // Light Theme Surfaces & Backgrounds
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // Text Colors (High Contrast WCAG AA compliant)
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xFFD4D4D8);
  static const Color textLightMuted = Color(0xFFA1A1AA);

  static const Color textDarkPrimary = Color(0xFF171A22);
  static const Color textDarkSecondary = Color(0xFF4B5563);
  static const Color textDarkMuted = Color(0xFF6B7280);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Role Badge Accents
  static const Color roleProprietor = Color(0xFFF3B9A8);
  static const Color roleSales = Color(0xFF8B5CF6);
  static const Color roleProjectManager = Color(0xFF3B82F6);
  static const Color roleDesigner = Color(0xFFEC4899);
  static const Color roleAccounts = Color(0xFF10B981);
  static const Color roleSupervisor = Color(0xFFF59E0B);

  // Architectural Typology & Earth Pigments Palette (Option 3)
  static const List<Map<String, dynamic>> architecturalSwatches = [
    {
      'name': 'Terracotta Brick',
      'material': 'Kiln Fired Clay & Tuscan Brick',
      'color': Color(0xFFD96B43),
    },
    {
      'name': 'Forest Sage',
      'material': 'Milled Timber & Nordic Spruce',
      'color': Color(0xFF4E7D63),
    },
    {
      'name': 'Slate Steel',
      'material': 'Brushed Steel & Architectural Slate',
      'color': Color(0xFF4A6B82),
    },
    {
      'name': 'Golden Oak',
      'material': 'Warm Teak & Burnished Honey Wood',
      'color': Color(0xFFC99A45),
    },
    {
      'name': 'Raw Ochre',
      'material': 'Weathered Sandstone & Natural Ochre',
      'color': Color(0xFFB87333),
    },
    {
      'name': 'Indigo Denim',
      'material': 'Deep Lapiz & Structural Indigo',
      'color': Color(0xFF3B5B8C),
    },
    {
      'name': 'Plum Mineral',
      'material': 'Deep Amethyst & Polished Quartzite',
      'color': Color(0xFF8B526C),
    },
  ];

  /// Deterministically assigns an architectural material swatch based on project name or index
  static Map<String, dynamic> getProjectSwatch(String projectName) {
    if (projectName.isEmpty) return architecturalSwatches.first;
    int hash = 0;
    for (int i = 0; i < projectName.length; i++) {
      hash = (hash * 31 + projectName.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final index = hash.abs() % architecturalSwatches.length;
    return architecturalSwatches[index];
  }
}
