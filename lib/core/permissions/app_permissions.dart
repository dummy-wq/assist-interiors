import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../../features/auth/models/user_model.dart';

/// Granular, checkable capabilities that the Proprietor can assign to custom
/// roles or per-applicant access configurations.
/// Note: Staff/Role Governance (`canManageTeam`) is intentionally excluded and
/// reserved strictly for the Master Proprietor account to prevent privilege escalation.
enum AppPermissionKey {
  manageSales,
  createProject,
  editProjectDetails,
  modifyProjectStatus,
  toggleOrReorderStages,
  addProjectPhotos,
  manageDesignAssets,
  createTask,
  updateTaskStatus,
  deleteTask,
  manageVendors,
  manageAccounts,
  exportFinancials,
}

extension AppPermissionKeyMeta on AppPermissionKey {
  String get label {
    switch (this) {
      case AppPermissionKey.manageSales:
        return 'Manage Sales Leads & Pipeline';
      case AppPermissionKey.createProject:
        return 'Create & Launch Projects';
      case AppPermissionKey.editProjectDetails:
        return 'Edit Project Budgets & Details';
      case AppPermissionKey.modifyProjectStatus:
        return 'Modify Project Status / Delays';
      case AppPermissionKey.toggleOrReorderStages:
        return 'Update & Reorder Site Stages';
      case AppPermissionKey.addProjectPhotos:
        return 'Capture & Attach Site Photos';
      case AppPermissionKey.manageDesignAssets:
        return 'Upload & Manage Design Deliverables';
      case AppPermissionKey.createTask:
        return 'Create & Assign Tasks / Milestones';
      case AppPermissionKey.updateTaskStatus:
        return 'Complete & Update Task Deliverables';
      case AppPermissionKey.deleteTask:
        return 'Delete Tasks';
      case AppPermissionKey.manageVendors:
        return 'Onboard & Manage Vendors';
      case AppPermissionKey.manageAccounts:
        return 'Create Invoices, Expenses & Upload QR';
      case AppPermissionKey.exportFinancials:
        return 'View & Export Financial P&L Reports';
    }
  }

  String get category {
    switch (this) {
      case AppPermissionKey.manageSales:
        return 'Sales & Client Pipeline';
      case AppPermissionKey.createProject:
      case AppPermissionKey.editProjectDetails:
      case AppPermissionKey.modifyProjectStatus:
      case AppPermissionKey.toggleOrReorderStages:
      case AppPermissionKey.addProjectPhotos:
        return 'Projects & Site Execution';
      case AppPermissionKey.manageDesignAssets:
        return 'Design Studio';
      case AppPermissionKey.createTask:
      case AppPermissionKey.updateTaskStatus:
      case AppPermissionKey.deleteTask:
        return 'Tasks & Milestones';
      case AppPermissionKey.manageVendors:
      case AppPermissionKey.manageAccounts:
      case AppPermissionKey.exportFinancials:
        return 'Accounts & Vendors';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPermissionKey.manageSales:
        return Icons.campaign_rounded;
      case AppPermissionKey.createProject:
        return Icons.add_business_rounded;
      case AppPermissionKey.editProjectDetails:
        return Icons.edit_note_rounded;
      case AppPermissionKey.modifyProjectStatus:
        return Icons.flag_outlined;
      case AppPermissionKey.toggleOrReorderStages:
        return Icons.checklist_rounded;
      case AppPermissionKey.addProjectPhotos:
        return Icons.add_a_photo_outlined;
      case AppPermissionKey.manageDesignAssets:
        return Icons.draw_rounded;
      case AppPermissionKey.createTask:
        return Icons.add_task_rounded;
      case AppPermissionKey.updateTaskStatus:
        return Icons.task_alt_rounded;
      case AppPermissionKey.deleteTask:
        return Icons.delete_outline_rounded;
      case AppPermissionKey.manageVendors:
        return Icons.storefront_outlined;
      case AppPermissionKey.manageAccounts:
        return Icons.receipt_long_rounded;
      case AppPermissionKey.exportFinancials:
        return Icons.analytics_outlined;
    }
  }
}

/// Centralized Role-Based Access Control (RBAC) Permissions System.
/// Supports both built-in [UserRole] templates and custom Proprietor-configured
/// per-role / per-user [AppPermissionKey] sets.
class AppPermissions {
  AppPermissions._();

  /// Returns the canonical permission set for any built-in [UserRole].
  static Set<AppPermissionKey> defaultPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.proprietor:
        return Set<AppPermissionKey>.from(AppPermissionKey.values);
      case UserRole.sales:
        return const {AppPermissionKey.manageSales};
      case UserRole.projectManager:
        return const {
          AppPermissionKey.createProject,
          AppPermissionKey.editProjectDetails,
          AppPermissionKey.modifyProjectStatus,
          AppPermissionKey.toggleOrReorderStages,
          AppPermissionKey.addProjectPhotos,
          AppPermissionKey.manageDesignAssets,
          AppPermissionKey.createTask,
          AppPermissionKey.updateTaskStatus,
          AppPermissionKey.deleteTask,
          AppPermissionKey.manageVendors,
          AppPermissionKey.exportFinancials,
        };
      case UserRole.designer:
        return const {
          AppPermissionKey.toggleOrReorderStages,
          AppPermissionKey.addProjectPhotos,
          AppPermissionKey.manageDesignAssets,
          AppPermissionKey.updateTaskStatus,
        };
      case UserRole.accounts:
        return const {
          AppPermissionKey.manageVendors,
          AppPermissionKey.manageAccounts,
          AppPermissionKey.exportFinancials,
        };
      case UserRole.supervisor:
        return const {
          AppPermissionKey.toggleOrReorderStages,
          AppPermissionKey.addProjectPhotos,
          AppPermissionKey.updateTaskStatus,
        };
      case UserRole.siteEngineer:
        return const {
          AppPermissionKey.editProjectDetails,
          AppPermissionKey.modifyProjectStatus,
          AppPermissionKey.toggleOrReorderStages,
          AppPermissionKey.addProjectPhotos,
          AppPermissionKey.createTask,
          AppPermissionKey.updateTaskStatus,
        };
    }
  }

  /// Resolves the effective permission set for [user] (or [role] fallback).
  /// Pending or rejected users always receive an empty set (deny by default).
  static Set<AppPermissionKey> resolvePermissions(
    UserRole role, {
    AppUser? user,
  }) {
    if (user != null) {
      if (user.status != UserAccountStatus.approved) {
        return const <AppPermissionKey>{};
      }
      if (user.role == UserRole.proprietor && !user.hasCustomAccess) {
        return Set<AppPermissionKey>.from(AppPermissionKey.values);
      }
      if (user.hasCustomAccess) {
        return Set<AppPermissionKey>.from(
          user.customPermissions ?? const <AppPermissionKey>{},
        );
      }
      return defaultPermissionsForRole(user.role);
    }
    return defaultPermissionsForRole(role);
  }

  static bool hasPermission(
    UserRole role,
    AppPermissionKey key, {
    AppUser? user,
  }) {
    return resolvePermissions(role, user: user).contains(key);
  }

  // ===============================================================
  // 1. Projects & Architecture Portfolio
  // ===============================================================

  /// Whether this role/user can create new projects/sites.
  static bool canCreateProject(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.createProject, user: user);

  /// Whether this role/user can edit project metadata (budget, client, handover, PM, etc.).
  static bool canEditProjectDetails(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.editProjectDetails, user: user);

  /// Whether this role/user can mark project delay or archive/delete projects.
  static bool canModifyProjectStatus(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.modifyProjectStatus, user: user);

  /// Whether this role/user can check off, add, or reorder physical site stages.
  static bool canToggleOrReorderStages(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.toggleOrReorderStages, user: user);

  /// Whether this role/user can capture or attach site photos to a project.
  static bool canAddProjectPhotos(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.addProjectPhotos, user: user);

  /// Whether this role/user can upload, modify, or delete architectural design deliverables.
  static bool canManageDesignAssets(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.manageDesignAssets, user: user);

  // ===============================================================
  // 2. Tasks & Site Deliverables
  // ===============================================================

  /// Whether this role/user can author and assign new tasks or milestones.
  static bool canCreateTask(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.createTask, user: user);

  /// Whether this role/user can check off, execute, or update deliverables.
  static bool canUpdateTaskStatus(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.updateTaskStatus, user: user);

  /// Whether this role/user can delete deliverables.
  static bool canDeleteTask(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.deleteTask, user: user);

  // ===============================================================
  // 3. Vendors & Trade Suppliers
  // ===============================================================

  /// Whether this role/user can register or edit trade partner profiles.
  static bool canManageVendors(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.manageVendors, user: user);

  // ===============================================================
  // 4. Accounts, Invoicing & Billing Ledgers
  // ===============================================================

  /// Whether this role/user can create client invoices and log expense vouchers.
  static bool canManageAccounts(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.manageAccounts, user: user);

  /// Whether this role/user can export P&L reports and view financial movement details.
  static bool canExportFinancials(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.exportFinancials, user: user);

  // ===============================================================
  // 5. Sales & Lead Acquisition
  // ===============================================================

  /// Whether this role/user can create new leads, update pipeline stages, or schedule calls.
  static bool canManageSales(UserRole role, {AppUser? user}) =>
      hasPermission(role, AppPermissionKey.manageSales, user: user);

  // ===============================================================
  // 6. Team & Staff Governance (STRICTLY MASTER PROPRIETOR ONLY)
  // ===============================================================

  /// Strictly limited to built-in Proprietor (Master Owner). Custom roles can
  /// never acquire team-governance or role-authoring privileges.
  static bool canManageTeam(UserRole role, {AppUser? user}) {
    if (user != null) {
      return user.status == UserAccountStatus.approved &&
          user.role == UserRole.proprietor &&
          !user.hasCustomAccess;
    }
    return role == UserRole.proprietor;
  }

  // ===============================================================
  // Descriptive Badges & Explainers
  // ===============================================================

  static String getRoleAccessSummary(UserRole role, {AppUser? user}) {
    if (user != null && user.hasCustomAccess) {
      final count = resolvePermissions(role, user: user).length;
      return 'Custom Role • $count Permission${count == 1 ? '' : 's'}';
    }
    switch (role) {
      case UserRole.proprietor:
        return 'Full Studio Authority';
      case UserRole.projectManager:
        return 'Operations & Sites Lead';
      case UserRole.designer:
        return 'Creative & Stage Progress';
      case UserRole.supervisor:
        return 'Site Logs & Stage Progress';
      case UserRole.siteEngineer:
        return 'Site Engineering, Snags & Stage Progress';
      case UserRole.accounts:
        return 'Finance & Billing Lead (Projects Read-Only)';
      case UserRole.sales:
        return 'Client Acquisition (Projects Read-Only)';
    }
  }
}
