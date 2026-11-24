import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/features/design/views/design_view.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/accounts_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/proprietor_dashboard.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';

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

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Lead to Pipeline',
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify dynamic update
      expect(find.text('Ambience Towers Penthouse'), findsOneWidget);
      expect(find.text('1 Leads'), findsOneWidget);
      expect(find.text('₹ 25,00,000'), findsWidgets);

      // Verify persistent storage
      final storedLeads = StorageService.getLeads();
      expect(storedLeads.length, 1);
      expect(storedLeads.first['client'], 'Ambience Towers Penthouse');
    },
  );

  testWidgets(
    'Supervisor: Site log submission and labour attendance work on unified Hub',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const ProprietorDashboard(),
          role: UserRole.supervisor,
        ),
      );
      await tester.pumpAndSettle();

      // Primary role CTA is visible on Hub
      expect(find.text('Take Site Photo'), findsOneWidget);

      final ctx = tester.element(find.byType(ProprietorDashboard));

      // 1. Log Attendance via sheet (Person name, Time in, Time out, Day, Taken by)
      MobileActionSheets.showLabourAttendanceSheet(ctx);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('labour_person_name_field')),
        'Ramesh Kumar',
      );
      await tester.enterText(
        find.byKey(const Key('labour_taken_by_field')),
        'Vikram (Site Engineer)',
      );
      await tester.tap(find.byKey(const Key('labour_add_entry_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Taken by: Vikram (Site Engineer)'), findsOneWidget);

      final saveAttBtn = find.widgetWithText(
        ElevatedButton,
        'Verify & Submit Daily Muster Roll',
      );
      await tester.ensureVisible(saveAttBtn);
      await tester.tap(saveAttBtn);
      await tester.pumpAndSettle();
      expect(MobileActionSheets.attendanceCountNotifier.value, 1);
      final roll = StorageService.getLabourRoll();
      expect(roll.length, 1);
      expect(roll.first['personName'], 'Ramesh Kumar');
      expect(roll.first['takenBy'], 'Vikram (Site Engineer)');
      expect(roll.first['timeIn'], isNotEmpty);
      expect(roll.first['timeOut'], isNotEmpty);
      expect(roll.first['day'], isNotEmpty);

      // 2. Post Daily Site Log via sheet
      MobileActionSheets.showSiteLogSheet(ctx);
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

      // Verify notifier emitted the submitted site log
      final emittedLog = MobileActionSheets.siteLogCreatedNotifier.value;
      expect(emittedLog, isNotNull);
      expect(emittedLog!['title'], 'Italian Marble Flooring Ground Floor');
    },
  );

  testWidgets(
    'Project Manager: Assign Milestone sheet dispatches task cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const ProprietorDashboard(),
          role: UserRole.projectManager,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Project'), findsWidgets);

      final ctx = tester.element(find.byType(ProprietorDashboard));
      MobileActionSheets.showAssignMilestoneSheet(ctx);
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

      // Verify cross-dispatched task was queued
      final lastDispatchedTask = MobileActionSheets.taskCreatedNotifier.value;
      expect(lastDispatchedTask, isNotNull);
      expect(lastDispatchedTask!['title'], 'HVAC Ducting & AC Piping Signoff');
    },
  );

  testWidgets(
    'Designer: Upload 3D Render / BOQ updates DesignView and persists locally',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DesignView(), role: UserRole.designer),
      );
      await tester.pumpAndSettle();

      // Open Upload Render Sheet via EmptyState CTA
      final uploadBtn = find.widgetWithText(ElevatedButton, 'Upload Drawing');
      await tester.tap(uploadBtn.first);
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Deliverable for Client Review',
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify DesignView updated
      expect(find.text('CAD Drawing Deliverable'), findsOneWidget);

      // Verify persistent storage
      final storedItems = StorageService.getDesignItems();
      expect(storedItems.length, 1);
      expect(storedItems.first['title'], 'CAD Drawing Deliverable');
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

      // Verify Outgoing pane displays the recorded voucher immediately
      expect(find.byKey(const Key('accounts_incoming_pane')), findsOneWidget);
      expect(find.byKey(const Key('accounts_outgoing_pane')), findsOneWidget);
      expect(find.text('1 Vouchers'), findsOneWidget);

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
    'Accounts: Receipts side displays, records, persists, and expands payment receipts',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const AccountsDashboard(), role: UserRole.accounts),
      );
      await tester.pumpAndSettle();

      // Switch to Receipts side
      final receiptsTab = find.text('Receipts (0)');
      expect(receiptsTab, findsOneWidget);
      await tester.tap(receiptsTab);
      await tester.pumpAndSettle();

      expect(find.text('No Receipts Logged'), findsOneWidget);

      // Tap Add Receipt from empty state
      await tester.tap(find.text('Add Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Add Payment Receipt'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Receipt Title / Description *'),
        'Mobilization Advance Receipt',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Received From / Party'),
        'Birla Residence',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount (₹) *'),
        '250000',
      );
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Receipt');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Receipts (1)'), findsOneWidget);
      expect(find.text('Mobilization Advance Receipt'), findsOneWidget);
      expect(find.text('₹ 2,50,000'), findsWidgets);
      expect(find.text('0 invoices • 1 receipts'), findsOneWidget);

      final storedReceipts = StorageService.getReceipts();
      expect(storedReceipts.length, 1);
      expect(storedReceipts.first['title'], 'Mobilization Advance Receipt');
      expect(storedReceipts.first['party'], 'Birla Residence');

      // Tap receipt item to view expanded detail dialog
      await tester.tap(find.text('Mobilization Advance Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('RECEIPT DETAILS'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Receipts (0)'), findsOneWidget);
      expect(StorageService.getReceipts(), isEmpty);
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

      // Mount ProjectsView and verify overview KPIs dynamically reflect current projects
      await tester.pumpWidget(
        createTestWidget(const ProjectsView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Sites'), findsOneWidget);
      expect(find.text('₹ 1,20,00,000'), findsWidgets);
      expect(find.text('0%'), findsWidgets);
      expect(find.text('1 Projects'), findsOneWidget);
      expect(find.text('₹ 4.62 Cr'), findsNothing);
      expect(find.text('68%'), findsNothing);
      expect(find.text('2 Projects'), findsNothing);
    },
  );

  testWidgets(
    'Sales Origin Pipeline: Selecting sales lead in CreateProjectSheet auto-populates fields and converts lead to Closed Won',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed a sales lead
      final lead = {
        'id': 'lead_dyn_convert_9',
        'client': 'Sunil Mittal',
        'name': 'Sunil Mittal',
        'phone': '+91 98100 99887',
        'scope': 'Penthouse Turnkey 8000 sqft',
        'location': 'Shanti Niketan, New Delhi',
        'estValue': '₹ 6,00,00,000',
        'referralSource': 'Client Referral',
        'stage': 'Negotiation & Final Terms',
        'status': 'Negotiation & Final Terms',
        'isConverted': false,
        'convertedToProject': null,
      };
      await StorageService.saveLeads([lead]);

      await tester.pumpWidget(
        createTestWidget(
          const ProprietorDashboard(),
          role: UserRole.proprietor,
        ),
      );
      await tester.pumpAndSettle();

      // Open Initiate Project Sheet
      final initiateBtn = find.widgetWithText(
        ElevatedButton,
        'Initiate Project',
      );
      await tester.tap(initiateBtn.first);
      await tester.pumpAndSettle();

      // Verify the dropdown has the sales lead
      final dropdown =
          find.byType(DropdownButtonFormField<String?>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select Sunil Mittal's lead
      final leadItem = find.textContaining('Sunil Mittal').last;
      await tester.tap(leadItem);
      await tester.pumpAndSettle();

      // Verify auto-populated values
      expect(
        find.widgetWithText(TextField, 'Sunil Mittal Residence'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Sunil Mittal'), findsOneWidget);
      expect(find.widgetWithText(TextField, '60000000'), findsOneWidget);

      // Launch project
      final launchBtn = find.widgetWithText(ElevatedButton, 'Launch Project');
      await tester.tap(launchBtn);
      await tester.pumpAndSettle();

      // Verify project is launched and lead converted
      final updatedLeads = StorageService.getLeads();
      expect(updatedLeads.first['isConverted'], isTrue);
      expect(updatedLeads.first['stage'], 'Approved');
      expect(
        updatedLeads.first['convertedToProject'],
        'Sunil Mittal Residence',
      );

      final projects = StorageService.getProjects();
      expect(
        projects.any((p) => p['name'] == 'Sunil Mittal Residence'),
        isTrue,
      );
      expect(
        AppConstants.preExistingProjects.contains('Sunil Mittal Residence'),
        isTrue,
      );
    },
  );
}
