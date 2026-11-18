import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum UserRole {
  proprietor,
  sales,
  projectManager,
  designer,
  accounts,
  supervisor,
}

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.proprietor:
        return 'Proprietor (Admin)';
      case UserRole.sales:
        return 'Sales & Client Acquisition';
      case UserRole.projectManager:
        return 'Project Manager';
      case UserRole.designer:
        return 'Designer';
      case UserRole.accounts:
        return 'Accounts';
      case UserRole.supervisor:
        return 'Site Supervisor';
    }
  }

  String get shortCode {
    switch (this) {
      case UserRole.proprietor:
        return 'PRO';
      case UserRole.sales:
        return 'SALES';
      case UserRole.projectManager:
        return 'PM';
      case UserRole.designer:
        return 'DES';
      case UserRole.accounts:
        return 'ACC';
      case UserRole.supervisor:
        return 'SUP';
    }
  }

  String get description {
    switch (this) {
      case UserRole.proprietor:
        return 'Full business oversight, financial health, & high-level approvals';
      case UserRole.sales:
        return 'Lead pipeline, client consultations, estimates & token advance conversion';
      case UserRole.projectManager:
        return 'Project timelines, task delegations, budgets & client milestones';
      case UserRole.designer:
        return 'CAD 2D/3D deliverables, mood boards & material BOQs';
      case UserRole.accounts:
        return 'Invoicing, vendor payments, expense vouchers & ledger';
      case UserRole.supervisor:
        return 'Daily site logs, labour attendance, photos & material requests';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.proprietor:
        return Icons.admin_panel_settings_rounded;
      case UserRole.sales:
        return Icons.campaign_rounded;
      case UserRole.projectManager:
        return Icons.assignment_turned_in_rounded;
      case UserRole.designer:
        return Icons.draw_rounded;
      case UserRole.accounts:
        return Icons.account_balance_wallet_rounded;
      case UserRole.supervisor:
        return Icons.engineering_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.proprietor:
        return AppColors.roleProprietor;
      case UserRole.sales:
        return AppColors.roleSales;
      case UserRole.projectManager:
        return AppColors.roleProjectManager;
      case UserRole.designer:
        return AppColors.roleDesigner;
      case UserRole.accounts:
        return AppColors.roleAccounts;
      case UserRole.supervisor:
        return AppColors.roleSupervisor;
    }
  }
}

class AppConstants {
  static const String appName = 'Assist Interiors';
  static const String appTagline = 'Interior Architecture & Project Management';
  static const String logoPath = 'assets/images/logo.png';

  static final List<String> preExistingProjects = <String>[];

  static const List<String> salesReferralSources = [
    'Client Referral',
    'Architect Partner',
    'Real Estate Consultant',
    'Instagram / Social Media',
    'Direct Walk-in',
    'Website / Online Inquiry',
    'Builder / Contractor',
    'Other',
  ];

  static const List<String> salesPipelineStages = [
    'Lead',
    'Followup (Call)',
    'Site Visit',
    'BOQ',
    'Approved',
    'Lost / Dropped',
  ];

  static const String defaultUpiId = 'assistinteriors@hdfcbank';
  static const String companyName = 'Assist Interiors Private Limited';

  /// Pre-rendered base64 PNG of a valid high-contrast UPI QR code for Assist Interiors
  static const String samplePaymentQrBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAASIAAAEiCAIAAADS3EjhAAAE2UlEQVR4nO3dQW4jORQFwdGg'
      '739lz9YrogffaZJVEXtZsqAEF3qgPl9fX/8ApX93vwB4PplBTmaQkxnkZAY5mUFOZpCTGeRk'
      'BjmZQU5mkJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpD7M3nw5/P5qddxiMnNKOt3Y/2XJ+/k5C/v'
      'euyNJp8NpxnkZAY5mUFOZpCTGeRkBjmZQU5mkJMZ5EYrkLUzf2vmeeuEyVZjlzNfVffZcJpB'
      'TmaQkxnkZAY5mUFOZpCTGeRkBjmZQS5cgax137h3C4Mz79XoHrvLjZ+NNacZ5GQGOZlBTmaQ'
      'kxnkZAY5mUFOZpCTGeS2rUBu9Ly9Bb/DaQY5mUFOZpCTGeRkBjmZQU5mkJMZ5GQGOSuQ/+Ft'
      'd3LwU5xmkJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpDbtgJ53u5h187jeduU5302nGaQkxnkZAY5'
      'mUFOZpCTGeRkBjmZQU5mkAtXIOuFwfPs2lt0z9u95rd9NpxmkJMZ5GQGOZlBTmaQkxnkZAY5'
      'mUFOZpAbrUCed2cD33XblLdxmkFOZpCTGeRkBjmZQU5mkJMZ5GQGOZlBbrQC2XXPRHeTxNu2'
      'C5N3ctddIDfefeI0g5zMICczyMkMcjKDnMwgJzPIyQxyMoNceBfImRuR5/32yq5FxdqZK59d'
      'v0TjNIOczCAnM8jJDHIyg5zMICczyMkMcjKD3GgFsrbrm/61M7caz9uIPO8/mnCaQU5mkJMZ'
      '5GQGOZlBTmaQkxnkZAY5mUEuXIGceRvE25534sydx66NyITTDHIyg5zMICczyMkMcjKDnMwg'
      'JzPIyQxyoxXIjd/0v+1516xevut+S8hpBjmZQU5mkJMZ5GQGOZlBTmaQkxnkZAa50Qrkxtsg'
      'Jt/ln/maz/yFlLetXtacZpCTGeRkBjmZQU5mkJMZ5GQGOZlBTmaQC38R5szbIM7cajxvI/K8'
      '/2jCaQY5mUFOZpCTGeRkBjmZQU5mkJMZ5GQGuXAFcuZtEG973okzdx67NiITTjPIyQxyMoNc'
      'zCAnM8jJDHIyg5zMICczyH0m33zf+E3/2o3Lhhv3JZ1dn+c1pxnkZAY5mUFOZpCTGeRkBjmZ'
      'QU5mkJMZ5EZ3gUy+F9/1WL7r1icT3XJl13/kNIOczCAnM8jJDHIyg5zMICczyMkMcjKD3GgF'
      '8rx7JtY7ALd9/L1de4szOc0gJzPIyQxyMoOczCAnM8jJDHIyg5zMIDdagayd+U3/ZDOxa6vR'
      'LTp2/bbO2zjNICczyMkMcjKDnMwgJzPIyQxyMoOczCAXrkDW7A++O3NBsn7srjtIzryRZc1p'
      'BjmZQU5mkJMZ5GQGOZlBTmaQkxnkZAa5bSuQG934yyydM9+NM1+V0wxyMoOczCAnM8jJDHIy'
      'g5zMICczyMkMclYgv+TMGyzOvDnjzLtPJpxmkJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpDbtgK5'
      '8Xdbbtxb7FpFTJ73zPs8JpxmkJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpALVyA3flu/duNWw30e'
      'P/WXJ5xmkJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpD73HgnB9zFaQY5mUFOZpCTGeRkBjmZQU5m'
      'kJMZ5GQGOZlBTmaQkxnkZAY5mUFOZpCTGeRkBjmZQU5mkPsPHFzEilZhE2wAAAAASUVORK5C'
      'YII=';
}
