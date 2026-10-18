import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/supervisor_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/pm_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/designer_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/accounts_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/proprietor_dashboard.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
  });

  Widget createTestWidget(Widget child, {UserRole role = UserRole.proprietor}) {
    final authProvider = AuthProvider();
    authProvider.switchRole(role);

    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'Sales: Add Lead persists to StorageService and updates SalesDashboard',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.sales),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Client Inquiries'), findsOneWidget);
      expect(find.text('0 Leads'), findsOneWidget);

      // Open Add Lead Sheet
      final addLeadBtn = find.widgetWithText(ElevatedButton, 'Add New Lead');
      if (addLeadBtn.evaluate().isNotEmpty) {
        await tester.tap(addLeadBtn.first);
      } else {
        MobileActionSheets.showAddLeadSheet(
          tester.element(find.byType(SalesView)),
        );
      }
      await tester.pumpAndSettle();

      // Enter lead details
      final nameField = find.widgetWithText(TextField, 'Client / Company Name');
      await tester.enterText(nameField, 'Ambience Towers Penthouse');

      final scopeField = find.widgetWithText(
        TextField,
        'Project Scope (e.g. 4BHK Villa / 5000 sq ft)',
      );
      await tester.enterText(scopeField, '5BHK Ultra Luxury');

      final budgetField = find.widgetWithText(
        TextField,
        'Est. Budget (e.g. ₹60L)',
      );
      await tester.enterText(budgetField, '7500000');

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Lead to Pipeline',
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify dynamic update
      expect(find.text('Ambience Towers Penthouse'), findsOneWidget);
      expect(find.text('1 Leads'), findsOneWidget);
      expect(find.text('₹ 75,00,000'), findsWidgets);

      // Verify persistent storage
      final storedLeads = StorageService.getLeads();
      expect(storedLeads.length, 1);
      expect(storedLeads.first['client'], 'Ambience Towers Penthouse');
    },
  );

  testWidgets(
    'Supervisor: Site log submission and labour attendance update SupervisorDashboard',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const SupervisorDashboard(),
          role: UserRole.supervisor,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Site Logs Today'), findsOneWidget);
      expect(find.text('0 Workers'), findsOneWidget);

      // 1. Log Attendance
      final logAttBtn = find.widgetWithText(OutlinedButton, 'Log Attendance');
      await tester.tap(logAttBtn);
      await tester.pumpAndSettle();

      final saveAttBtn = find.widgetWithText(
        ElevatedButton,
        'Verify & Submit Daily Muster Roll',
      );
      await tester.tap(saveAttBtn);
      await tester.pumpAndSettle();

      expect(find.text('26 Workers'), findsOneWidget);

      // 2. Post Daily Site Log
      final postLogBtn = find.widgetWithText(
        ElevatedButton,
        'Post Daily Site Log',
      );
      await tester.tap(postLogBtn.first);
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(
        TextField,
        'Daily Progress & Work Completed Notes',
      );
      await tester.enterText(
        titleField,
        'Italian Marble Flooring Ground Floor',
      );

      final saveLogBtn = find.widgetWithText(
        ElevatedButton,
        'Submit Site Report to PM',
      );
      await tester.tap(saveLogBtn);
      await tester.pumpAndSettle();

      // Verify feed and counter updated
      expect(find.text('1 Logged'), findsOneWidget);
      expect(
        find.textContaining('Italian Marble Flooring Ground Floor'),
        findsOneWidget,
      );

      // Verify storage
      final storedLogs = StorageService.getSiteLogs();
      expect(storedLogs.length, 1);
      expect(storedLogs.first['title'], 'Italian Marble Flooring Ground Floor');
    },
  );

  testWidgets(
    'Project Manager: Assign Milestone updates PM dashboard and dispatches task',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const ProjectManagerDashboard(),
          role: UserRole.projectManager,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Milestones Scheduled'), findsOneWidget);
      expect(find.text('0 Tasks'), findsOneWidget);

      // Open Assign Milestone Sheet
      final assignBtn = find.widgetWithText(
        ElevatedButton,
        'Assign New Milestone',
      );
      await tester.tap(assignBtn.first);
      await tester.pumpAndSettle();

      final taskField = find.widgetWithText(
        TextField,
        'Task / Milestone Description',
      );
      await tester.enterText(taskField, 'HVAC Ducting & AC Piping Signoff');

      final assignMilestoneBtn = find.widgetWithText(
        ElevatedButton,
        'Dispatch Task Milestone',
      );
      await tester.tap(assignMilestoneBtn);
      await tester.pumpAndSettle();

      // Verify PM timeline updated
      expect(find.text('1 Tasks'), findsOneWidget);
      expect(find.text('HVAC Ducting & AC Piping Signoff'), findsOneWidget);

      // Verify persistent storage
      final storedMilestones = StorageService.getMilestones();
      expect(storedMilestones.length, 1);
      expect(
        storedMilestones.first['task'],
        'HVAC Ducting & AC Piping Signoff',
      );

      // Verify cross-dispatched task was queued
      final lastDispatchedTask = MobileActionSheets.taskCreatedNotifier.value;
      expect(lastDispatchedTask, isNotNull);
      expect(lastDispatchedTask!['title'], 'HVAC Ducting & AC Piping Signoff');
    },
  );

  testWidgets(
    'Designer: Upload 3D Render / BOQ updates DesignerDashboard deliverables grid',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DesignerDashboard(), role: UserRole.designer),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Design Deliverables'), findsOneWidget);
      expect(find.text('0 Views'), findsOneWidget);

      // Open Upload Render Sheet
      final uploadBtn = find.widgetWithText(
        ElevatedButton,
        'Upload Render / BOQ',
      );
      await tester.tap(uploadBtn.first);
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Deliverable for Client Review',
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify Designer deliverables grid updated
      expect(find.text('1 Views'), findsOneWidget);
      expect(find.text('3D Photorealistic Render & BOQ'), findsOneWidget);

      // Verify persistent storage
      final storedItems = StorageService.getDesignItems();
      expect(storedItems.length, 1);
      expect(storedItems.first['title'], '3D Photorealistic Render & BOQ');
    },
  );

  testWidgets(
    'Accounts: Log Expense Voucher updates AccountsDashboard expenses list and disbursed total',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const AccountsDashboard(), role: UserRole.accounts),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 active billings'), findsNothing);
      expect(find.text('₹ 0'), findsWidgets);

      // Open Log Expense Voucher
      MobileActionSheets.showAddExpenseSheet(
        tester.element(find.byType(AccountsDashboard)),
      );
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(
        TextField,
        'Expense Description (e.g. Hardware fittings, Petty cash)',
      );
      await tester.enterText(titleField, 'Kajaria Vitrified Tiles Procurement');

      final amountField = find.widgetWithText(TextField, 'Amount (₹)');
      await tester.enterText(amountField, '145000');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Record Expense');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Switch to Expense Vouchers tab
      final expenseTab = find.text('Expense Vouchers (1)');
      expect(expenseTab, findsOneWidget);
      await tester.tap(expenseTab);
      await tester.pumpAndSettle();

      // Verify voucher is listed
      expect(find.text('Kajaria Vitrified Tiles Procurement'), findsOneWidget);
      expect(find.text('₹ 145000'), findsOneWidget);
      expect(find.text('1 expense vouchers'), findsOneWidget);

      // Verify persistent storage
      final storedExpenses = StorageService.getExpenses();
      expect(storedExpenses.length, 1);
      expect(
        storedExpenses.first['title'],
        'Kajaria Vitrified Tiles Procurement',
      );
    },
  );

  testWidgets(
    'Proprietor: Launching project updates upcoming handovers and active sites count',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const ProprietorDashboard(),
          role: UserRole.proprietor,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Handovers Scheduled'), findsOneWidget);
      expect(find.text('0 Active Sites'), findsOneWidget);

      // Open Initiate Project Sheet
      final initiateBtn = find.widgetWithText(
        ElevatedButton,
        'Initiate Project',
      );
      await tester.tap(initiateBtn.first);
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(
        TextField,
        'Project Name (e.g. DLF Magnolias 4BHK)',
      );
      await tester.enterText(nameField, 'The Camellias Villa 12');

      final budgetField = find.widgetWithText(TextField, 'Budget (₹)');
      await tester.enterText(budgetField, '12000000');

      final launchBtn = find.widgetWithText(ElevatedButton, 'Launch Project');
      await tester.tap(launchBtn);
      await tester.pumpAndSettle();

      // Verify dynamic update
      expect(find.text('1 Active Sites'), findsOneWidget);
      expect(find.text('The Camellias Villa 12'), findsOneWidget);

      // Verify persistent storage
      final storedProjects = StorageService.getProjects();
      expect(storedProjects.length, 1);
      expect(storedProjects.first['name'], 'The Camellias Villa 12');
    },
  );
}
