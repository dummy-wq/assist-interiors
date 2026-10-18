import '../constants/app_constants.dart';

/// Centralized Role-Based Access Control (RBAC) Permissions System.
/// Enforces domain-level and UI-level authorization across the entire studio.
class AppPermissions {
  AppPermissions._();

  // ===============================================================
  // 1. Projects & Architecture Portfolio
  // ===============================================================

  /// Whether this role can create new projects/sites.
  static bool canCreateProject(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.projectManager;
  }

  /// Whether this role can edit project metadata (budget, client, handover, PM, etc.).
  static bool canEditProjectDetails(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.projectManager;
  }

  /// Whether this role can mark project delay or archive/delete projects.
  static bool canModifyProjectStatus(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.projectManager;
  }

  /// Whether this role can check off, add, or reorder physical site stages.
  static bool canToggleOrReorderStages(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.projectManager ||
        role == UserRole.designer ||
        role == UserRole.supervisor;
  }

  /// Whether this role can capture or attach site photos to a project.
  static bool canAddProjectPhotos(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.projectManager ||
        role == UserRole.designer ||
        role == UserRole.supervisor;
  }

  /// Whether this role can upload, modify, or delete architectural design deliverables (CAD drawings, 3D renders, BOQs, mood boards).
  static bool canManageDesignAssets(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.projectManager ||
        role == UserRole.designer;
  }

  // ===============================================================
  // 2. Tasks & Site Deliverables
  // ===============================================================

  /// Whether this role can author and assign new tasks or milestones.
  static bool canCreateTask(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.projectManager;
  }

  /// Whether this role can check off, execute, or update deliverables.
  static bool canUpdateTaskStatus(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.projectManager ||
        role == UserRole.designer ||
        role == UserRole.supervisor;
  }

  /// Whether this role can delete deliverables.
  static bool canDeleteTask(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.projectManager;
  }

  // ===============================================================
  // 3. Vendors & Trade Suppliers
  // ===============================================================

  /// Whether this role can register or edit trade partner profiles.
  static bool canManageVendors(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.accounts ||
        role == UserRole.projectManager;
  }

  // ===============================================================
  // 4. Accounts, Invoicing & Billing Ledgers
  // ===============================================================

  /// Whether this role can create client invoices and log expense vouchers.
  static bool canManageAccounts(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.accounts;
  }

  /// Whether this role can export P&L reports and view financial movement details.
  static bool canExportFinancials(UserRole role) {
    return role == UserRole.proprietor ||
        role == UserRole.accounts ||
        role == UserRole.projectManager;
  }

  // ===============================================================
  // 5. Sales & Lead Acquisition
  // ===============================================================

  /// Whether this role can create new leads, update pipeline stages, or schedule calls.
  static bool canManageSales(UserRole role) {
    return role == UserRole.proprietor || role == UserRole.sales;
  }

  // ===============================================================
  // 6. Team & Staff Governance
  // ===============================================================

  /// Whether this role can approve new staff sign-ups or change access roles.
  static bool canManageTeam(UserRole role) {
    return role == UserRole.proprietor;
  }

  // ===============================================================
  // Descriptive Badges & Explainers for Demo Mode
  // ===============================================================

  static String getRoleAccessSummary(UserRole role) {
    switch (role) {
      case UserRole.proprietor:
        return 'Full Studio Authority';
      case UserRole.projectManager:
        return 'Operations & Sites Lead';
      case UserRole.designer:
        return 'Creative & Stage Progress';
      case UserRole.supervisor:
        return 'Site Logs & Stage Progress';
      case UserRole.accounts:
        return 'Finance & Billing Lead (Projects Read-Only)';
      case UserRole.sales:
        return 'Client Acquisition (Projects Read-Only)';
    }
  }
}
