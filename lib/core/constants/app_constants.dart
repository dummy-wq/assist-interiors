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
    'New Inquiry',
    'Site Visit Scheduled',
    'Design Pitch & BOQ',
    'Negotiation',
    'Closed Won',
    'Lost / Dropped',
  ];
}
