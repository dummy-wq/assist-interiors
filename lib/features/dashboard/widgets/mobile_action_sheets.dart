import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/state/auth_provider.dart';

import '../../sales/sheets/add_lead_sheet.dart';
import '../../sales/sheets/schedule_call_sheet.dart';
import '../../sales/sheets/update_lead_status_sheet.dart';
import '../../projects/sheets/site_log_sheet.dart';
import '../../projects/sheets/assign_milestone_sheet.dart';
import '../../projects/sheets/upload_render_sheet.dart';
import '../../accounts/sheets/create_invoice_sheet.dart';
import '../../projects/sheets/labour_attendance_sheet.dart';
import '../../projects/sheets/create_project_sheet.dart';
import '../../projects/sheets/project_filter_sheet.dart';
import '../../vendors/sheets/add_vendor_sheet.dart';
import '../../tasks/sheets/create_task_sheet.dart';
import '../../accounts/sheets/add_expense_sheet.dart';
import '../../projects/sheets/review_snags_sheet.dart';
import '../../team/sheets/invite_staff_sheet.dart';

export '../../sales/sheets/add_lead_sheet.dart';
export '../../sales/sheets/schedule_call_sheet.dart';
export '../../sales/sheets/update_lead_status_sheet.dart';
export '../../projects/sheets/site_log_sheet.dart';
export '../../projects/sheets/assign_milestone_sheet.dart';
export '../../projects/sheets/upload_render_sheet.dart';
export '../../accounts/sheets/create_invoice_sheet.dart';
export '../../projects/sheets/labour_attendance_sheet.dart';
export '../../projects/sheets/create_project_sheet.dart';
export '../../projects/sheets/project_filter_sheet.dart';
export '../../projects/sheets/review_snags_sheet.dart';
export '../../vendors/sheets/add_vendor_sheet.dart';
export '../../tasks/sheets/create_task_sheet.dart';
export '../../accounts/sheets/add_expense_sheet.dart';
export '../../team/sheets/invite_staff_sheet.dart';

/// Central Facade for all bottom modal action sheets in Assist Interiors.
/// Maintains reactive [ValueNotifier] state dispatchers across all dashboard verticals.
class MobileActionSheets {
  MobileActionSheets._();

  // Reactive dispatch notifiers for real-time dashboard listeners & automated tests
  static final ValueNotifier<Map<String, dynamic>?> leadCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> leadUpdatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> siteLogCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> milestoneCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> renderCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> expenseCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<int> attendanceCountNotifier = ValueNotifier(0);
  static final ValueNotifier<Map<String, dynamic>?> invoiceCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> projectCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> projectUpdatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<String> projectFilterNotifier = ValueNotifier(
    'All',
  );
  static final ValueNotifier<Map<String, dynamic>?> vendorCreatedNotifier =
      ValueNotifier(null);
  static final ValueNotifier<Map<String, dynamic>?> taskCreatedNotifier =
      ValueNotifier(null);

  // 1. Sales Vertical Sheets
  static void showAddLeadSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageSales(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Action restricted: Only Proprietor and Sales can add leads.',
      );
      return;
    }
    AddLeadSheet.show(context);
  }

  static void showScheduleCallSheet(
    BuildContext context,
    Map<String, dynamic> lead, {
    VoidCallback? onUpdated,
  }) => ScheduleCallSheet.show(context, lead, onUpdated: onUpdated);

  static void showUpdateLeadStatusSheet(
    BuildContext context,
    Map<String, dynamic> lead, {
    VoidCallback? onUpdated,
  }) => UpdateLeadStatusSheet.show(context, lead, onUpdated: onUpdated);

  // 2. Project Execution & Site Management Sheets
  static void showSiteLogSheet(BuildContext context) =>
      SiteLogSheet.show(context);

  static void showAssignMilestoneSheet(BuildContext context) =>
      AssignMilestoneSheet.show(context);

  static void showUploadRenderSheet(BuildContext context) =>
      UploadRenderSheet.show(context);

  static void showLabourAttendanceSheet(BuildContext context) =>
      LabourAttendanceSheet.show(context);

  static void showInitiateProjectSheet(
    BuildContext context, {
    void Function(Map<String, dynamic> newProject)? onProjectCreated,
    String? initialName,
    String? initialClient,
    String? initialBudget,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canCreateProject(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Project Managers can create projects.',
      );
      return;
    }
    CreateProjectSheet.show(
      context,
      onProjectCreated: onProjectCreated,
      initialName: initialName,
      initialClient: initialClient,
      initialBudget: initialBudget,
    );
  }

  static void showCreateProjectSheet(
    BuildContext context, {
    void Function(Map<String, dynamic> newProject)? onProjectCreated,
    String? initialName,
    String? initialClient,
    String? initialBudget,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canCreateProject(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Project Managers can create projects.',
      );
      return;
    }
    CreateProjectSheet.show(
      context,
      onProjectCreated: onProjectCreated,
      initialName: initialName,
      initialClient: initialClient,
      initialBudget: initialBudget,
    );
  }

  static void showProjectFilterSheet(BuildContext context) =>
      ProjectFilterSheet.show(context);

  static void showReviewSnagsSheet(
    BuildContext context, {
    VoidCallback? onUpdated,
  }) =>
      ReviewSnagsSheet.show(context, onUpdated: onUpdated);

  // 3. Accounts & Financial Billing Sheets
  static void showCreateInvoiceSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageAccounts(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Accounts can generate invoices.',
      );
      return;
    }
    CreateInvoiceSheet.show(context);
  }

  static void showAddExpenseSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageAccounts(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Accounts can record expenses.',
      );
      return;
    }
    AddExpenseSheet.show(context);
  }

  // 4. Procurement & Vendor Onboarding
  static void showAddVendorSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageVendors(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor, Accounts, and Project Managers can onboard vendors.',
      );
      return;
    }
    AddVendorSheet.show(context);
  }

  // 5. Tasks Management
  static void showCreateTaskSheet(
    BuildContext context, {
    void Function(Map<String, dynamic> newTask)? onTaskCreated,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canCreateTask(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Project Managers can create tasks.',
      );
      return;
    }
    CreateTaskSheet.show(context, onTaskCreated: onTaskCreated);
  }

  // 6. Organization Team Management
  static void showInviteStaffSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageTeam(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Action restricted: Only Proprietor can invite staff.',
      );
      return;
    }
    InviteStaffSheet.show(context);
  }
}
