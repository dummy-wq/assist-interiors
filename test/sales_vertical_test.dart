import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/services/backend_manager.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/design/views/design_view.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/accounts_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/core/widgets/pill_box.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await BackendManager.instance.clearAll();
  });

  Widget createTestWidget(Widget child, {UserRole role = UserRole.sales}) {
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
    'Sales Vertical: Adding lead with Referral Source, Status, and Next Call Date with Reminder',
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

      // Verify sections rendered in modal
      expect(find.text('REFERRAL & LEAD SOURCE'), findsOneWidget);
      expect(find.text('STATUS & NEXT CALL REMINDER'), findsOneWidget);

      // Enter lead details
      final nameField = find.widgetWithText(TextField, 'Client / Company Name');
      await tester.enterText(nameField, 'The Oberoi Sky Villa');

      final phoneField = find.widgetWithText(TextField, 'Phone Number');
      await tester.enterText(phoneField, '+91 98765 43210');

      final budgetField = find.widgetWithText(
        TextField,
        'Est. Budget (e.g. ₹60L)',
      );
      await tester.enterText(budgetField, '12000000');

      final scopeField = find.widgetWithText(
        TextField,
        'Project Scope (e.g. 4BHK Villa / 5000 sq ft)',
      );
      await tester.enterText(scopeField, 'Penthouse 6500 sqft');

      final referrerField = find.widgetWithText(
        TextField,
        'Referrer Name / Partner Details (Optional)',
      );
      await tester.enterText(referrerField, 'Ar. Karan Grover');

      final reminderNoteField = find.widgetWithText(
        TextField,
        'Call Reminder / Follow-up Note',
      );
      await tester.enterText(
        reminderNoteField,
        'Present Italian marble samples and 3D walkthrough',
      );

      // Submit lead
      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Lead to Pipeline',
      );
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify Lead card is rendered with 3-step vertical pipeline strip
      expect(find.text('The Oberoi Sky Villa'), findsOneWidget);
      expect(find.text('1 Leads'), findsOneWidget);
      expect(find.text('₹ 1,20,00,000'), findsWidgets);
      expect(
        find.text('Ref: Client Referral (Ar. Karan Grover)'),
        findsOneWidget,
      );
      expect(find.text('Lead'), findsWidgets);
      expect(
        find.text(
          'Reminder: "Present Italian marble samples and 3D walkthrough"',
        ),
        findsOneWidget,
      );

      // Verify persistence
      final stored = StorageService.getLeads();
      expect(stored.length, 1);
      expect(stored.first['client'], 'The Oberoi Sky Villa');
      expect(stored.first['referralBy'], 'Ar. Karan Grover');
      expect(
        stored.first['reminderNote'],
        'Present Italian marble samples and 3D walkthrough',
      );
    },
  );

  testWidgets(
    'Sales Vertical: Schedule call and update status sheets modify lead in real-time',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

      // Seed a lead
      final initialLead = {
        'id': 'lead_test_1',
        'client': 'Aman Gupta Mansion',
        'phone': '+91 99999 88888',
        'scope': '5BHK Villa',
        'location': 'Alibaug',
        'estValue': '₹ 85L',
        'referralSource': 'Architect Partner',
        'referralBy': 'Ar. Sanjay Puri',
        'stage': 'New Inquiry',
        'status': 'New Inquiry',
        'nextCallDate': todayStr,
        'nextCallTime': '04:30 PM',
        'reminderNote': 'Confirm site measurement visit',
        'hasReminder': true,
        'notes': <Map<String, dynamic>>[],
        'date': todayStr,
      };
      await StorageService.saveLeads([initialLead]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.sales),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aman Gupta Mansion'), findsOneWidget);
      expect(
        find.text('Ref: Architect Partner (Ar. Sanjay Puri)'),
        findsOneWidget,
      );
      expect(find.text('Due Today: 04:30 PM'), findsOneWidget);
      expect(find.text('1 Calls'), findsOneWidget); // Due calls KPI

      // Tap on Status to open update status sheet
      await tester.tap(find.text('New Inquiry').last);
      await tester.pumpAndSettle();

      expect(find.text('Update Pipeline Status'), findsOneWidget);
      expect(find.text('Client: Aman Gupta Mansion'), findsOneWidget);

      // Select 'Site Visit Scheduled'
      await tester.tap(find.text('Site Visit Scheduled').last);
      await tester.pumpAndSettle();

      final updateStatusBtn = find.widgetWithText(
        ElevatedButton,
        'Update Status to Site Visit Scheduled',
      );
      await tester.tap(updateStatusBtn);
      await tester.pumpAndSettle();

      // Verify stage updated
      expect(find.text('Site Visit Scheduled'), findsWidgets);

      // Tap 'Schedule Call' button on card
      final scheduleCallBtn = find.widgetWithText(
        OutlinedButton,
        'Schedule Call',
      );
      await tester.tap(scheduleCallBtn);
      await tester.pumpAndSettle();

      expect(find.text('Schedule Call & Reminder'), findsOneWidget);

      final reasonField = find.widgetWithText(
        TextField,
        'Reminder Reason / Deliverable Target',
      );
      await tester.enterText(
        reasonField,
        'Finalize electrical & plumbing layouts',
      );

      final saveScheduleBtn = find.widgetWithText(
        ElevatedButton,
        'Save Call Schedule & Reminder',
      );
      await tester.tap(saveScheduleBtn);
      await tester.pumpAndSettle();

      // Verify updated reminder note
      expect(
        find.text('Reminder: "Finalize electrical & plumbing layouts"'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Sales Vertical: Stage and Referral filters isolate matching leads',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

      final lead1 = {
        'id': 'lead_1',
        'client': 'Client Alpha',
        'phone': '+91 91111 11111',
        'scope': '3BHK Flat',
        'location': 'Mumbai',
        'estValue': '₹ 40L',
        'referralSource': 'Client Referral',
        'stage': 'New Inquiry',
        'nextCallDate': todayStr,
        'nextCallTime': '11:00 AM',
        'date': todayStr,
      };

      final lead2 = {
        'id': 'lead_2',
        'client': 'Client Beta',
        'phone': '+91 92222 22222',
        'scope': 'Corporate Office',
        'location': 'Gurgaon',
        'estValue': '₹ 95L',
        'referralSource': 'Architect Partner',
        'stage': 'Closed Won',
        'nextCallDate': '25 Dec 2026',
        'nextCallTime': '02:00 PM',
        'date': todayStr,
      };

      await StorageService.saveLeads([lead1, lead2]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.sales),
      );
      await tester.pumpAndSettle();

      expect(find.text('Client Alpha'), findsOneWidget);
      expect(find.text('Client Beta'), findsOneWidget);

      // Filter by 'Approved'
      final wonPill = find.widgetWithText(PillBox, 'Approved (1)');
      await tester.ensureVisible(wonPill);
      await tester.tap(wonPill);
      await tester.pumpAndSettle();

      expect(find.text('Client Beta'), findsOneWidget);
      expect(find.text('Client Alpha'), findsNothing);

      // Filter by 'Due Calls'
      final duePill = find.widgetWithText(PillBox, 'Due Calls (1)');
      await tester.ensureVisible(duePill);
      await tester.tap(duePill);
      await tester.pumpAndSettle();

      expect(find.text('Client Alpha'), findsOneWidget);
      expect(find.text('Client Beta'), findsNothing);
    },
  );

  testWidgets(
    'Sales Vertical: Convert to Project launches project and updates lead with badge and cross-tab effects',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());
      final lead = {
        'id': 'lead_convert_1',
        'client': 'Anand Mahindra',
        'name': 'Anand Mahindra',
        'phone': '+91 98200 11223',
        'scope': 'Penthouse Luxury Turnkey',
        'location': 'Worli, Mumbai',
        'estValue': '₹ 4,50,00,000',
        'referralSource': 'Architect Referral',
        'stage': 'Negotiation & Final Terms',
        'status': 'Negotiation & Final Terms',
        'nextCallDate': todayStr,
        'nextCallTime': '04:00 PM',
        'isConverted': false,
        'convertedToProject': null,
      };

      await StorageService.saveLeads([lead]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anand Mahindra'), findsOneWidget);

      // Verify "Launch" project conversion button is visible
      final convertBtn = find.widgetWithText(ElevatedButton, 'Launch');
      expect(convertBtn, findsOneWidget);

      await tester.tap(convertBtn);
      await tester.pumpAndSettle();

      // Verify CreateProjectSheet is displayed with pre-filled lead details
      expect(find.text('Initiate Turnkey Project'), findsOneWidget);
      expect(find.text('Originating from Sales Pipeline'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Anand Mahindra Residence'),
        findsOneWidget,
      );

      // Tap Launch Project
      final launchBtn = find.widgetWithText(ElevatedButton, 'Launch Project');
      await tester.tap(launchBtn);
      await tester.pumpAndSettle();

      // Verify lead is converted in StorageService
      final updatedLeads = StorageService.getLeads();
      expect(updatedLeads.first['isConverted'], isTrue);
      expect(updatedLeads.first['stage'], 'Closed Won');
      expect(
        updatedLeads.first['convertedToProject'],
        'Anand Mahindra Residence',
      );

      // Verify project is persisted in StorageService
      final projects = StorageService.getProjects();
      expect(
        projects.any((p) => p['name'] == 'Anand Mahindra Residence'),
        isTrue,
      );

      // Verify SalesView now displays the converted badge and "View in Projects" button
      expect(
        find.text('Turnkey Site Launched: "Anand Mahindra Residence"'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'View in Projects'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Sales Vertical: Project creation auto-provisions deliverables in Design and Advance Invoice in Accounts',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final newProj = {
        'id': 'proj_test_cascade_1',
        'name': 'Worli Sea Face 4BHK',
        'client': 'Karan Johar',
        'location': 'Worli, Mumbai',
        'budget': '₹ 3,00,00,000',
        'status': 'Design and Planning',
        'color': Colors.blue,
        'originLeadId': 'lead_test_1',
      };

      // Mount DesignView and notify
      await tester.pumpWidget(
        createTestWidget(const DesignView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      MobileActionSheets.projectCreatedNotifier.value = newProj;
      await tester.pumpAndSettle();

      // DesignView should have auto-created the deliverable
      expect(
        find.text('Worli Sea Face 4BHK - Concept Layout & Mood Board'),
        findsOneWidget,
      );
      final designItems = StorageService.getDesignItems();
      expect(
        designItems.any(
          (d) =>
              d['title'] ==
              'Worli Sea Face 4BHK - Concept Layout & Mood Board',
        ),
        isTrue,
      );

      // Mount AccountsDashboard
      await tester.pumpWidget(
        createTestWidget(const AccountsDashboard(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      // Trigger project creation while AccountsDashboard is mounted
      final newProj2 = {
        'id': 'proj_test_cascade_2',
        'name': 'Juhu Beachfront Villa',
        'client': 'Rohit Shetty',
        'location': 'Juhu, Mumbai',
        'budget': '₹ 5,00,00,000',
        'status': 'Design and Planning',
        'color': Colors.amber,
        'originLeadId': 'lead_test_2',
      };
      MobileActionSheets.projectCreatedNotifier.value = newProj2;
      await tester.pumpAndSettle();

      // Accounts should show the 10% mobilization advance invoice
      expect(
        find.text('Juhu Beachfront Villa - Mobilization Advance (10%)'),
        findsOneWidget,
      );
      final invoices = StorageService.getInvoices();
      expect(
        invoices.any(
          (i) =>
              i['title'] ==
              'Juhu Beachfront Villa - Mobilization Advance (10%)',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Sales Vertical: Detailed Project Report in Sales Tab classifies Ongoing, Completed, Delayed and allows filtering & Excel Timeline',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final projOngoing = {
        'id': 'proj_test_ongoing_1',
        'name': 'DLF Phase 5 Penthouse',
        'client': 'Rajesh Sharma',
        'location': 'Golf Course Road, Gurgaon',
        'budget': '₹ 1,50,00,000',
        'spent': '₹ 45,00,000',
        'status': 'In Progress',
        'isDelayed': false,
        'pm': 'Vikram Rao',
        'stages': <Map<String, dynamic>>[
          {'title': 'Demolition', 'isDone': true},
          {'title': 'Framing', 'isDone': false},
        ],
      };

      final projCompleted = {
        'id': 'proj_test_completed_1',
        'name': 'The Magnolias Suite',
        'client': 'Aarti Chawla',
        'location': 'DLF Phase 5, Gurgaon',
        'budget': '₹ 2,00,00,000',
        'spent': '₹ 1,95,00,000',
        'status': 'Completed',
        'isDelayed': false,
        'pm': 'Rahul Mehta',
        'stages': <Map<String, dynamic>>[
          {'title': 'Handover Sign-off', 'isDone': true},
        ],
      };

      final projDelayed = {
        'id': 'proj_test_delayed_1',
        'name': 'Oberoi Sky Mansion',
        'client': 'Sameer Kulkarni',
        'location': 'Borivali, Mumbai',
        'budget': '₹ 80,00,000',
        'spent': '₹ 60,00,000',
        'status': 'Delayed',
        'isDelayed': true,
        'pm': 'Rahul Mehta',
        'stages': <Map<String, dynamic>>[
          {'title': 'Flooring Alignment', 'isDone': false},
        ],
      };

      await StorageService.saveProjects([
        projOngoing,
        projCompleted,
        projDelayed,
      ]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      // 1. Verify Project Status Report switcher badge shows total project count (3)
      expect(find.text('Project Status Report'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // 2. Switch to Project Status Report tab
      await tester.tap(find.text('Project Status Report'));
      await tester.pumpAndSettle();

      expect(find.text('Executive Project Status Report'), findsOneWidget);

      // Verify StatCards in Project Report
      expect(find.text('ONGOING PROJECTS'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('COMPLETED PROJECTS'), findsOneWidget);
      expect(find.text('1 Delivered'), findsOneWidget);
      expect(find.text('DELAYED PROJECTS'), findsOneWidget);
      expect(find.text('1 Flagged'), findsOneWidget);
      expect(find.text('TOTAL PORTFOLIO VALUE'), findsOneWidget);
      expect(find.text('₹ 4,30,00,000'), findsOneWidget);

      // Verify All 3 project cards are present
      expect(find.text('DLF Phase 5 Penthouse'), findsOneWidget);
      expect(find.text('The Magnolias Suite'), findsOneWidget);
      expect(find.text('Oberoi Sky Mansion'), findsOneWidget);

      // 3. Filter by 'Ongoing (1)'
      final ongoingPill = find.widgetWithText(PillBox, 'Ongoing (1)');
      await tester.tap(ongoingPill);
      await tester.pumpAndSettle();

      expect(find.text('DLF Phase 5 Penthouse'), findsOneWidget);
      expect(find.text('The Magnolias Suite'), findsNothing);
      expect(find.text('Oberoi Sky Mansion'), findsNothing);

      // 4. Filter by 'Completed (1)'
      final completedPill = find.widgetWithText(PillBox, 'Completed (1)');
      await tester.tap(completedPill);
      await tester.pumpAndSettle();

      expect(find.text('The Magnolias Suite'), findsOneWidget);
      expect(find.text('DLF Phase 5 Penthouse'), findsNothing);
      expect(find.text('Oberoi Sky Mansion'), findsNothing);

      // 5. Filter by 'Delayed (1)'
      final delayedPill = find.widgetWithText(PillBox, 'Delayed (1)');
      await tester.tap(delayedPill);
      await tester.pumpAndSettle();

      expect(find.text('Oberoi Sky Mansion'), findsOneWidget);
      expect(find.text('The Magnolias Suite'), findsNothing);
      expect(find.text('DLF Phase 5 Penthouse'), findsNothing);

      // 6. Reset to 'All (3)'
      final allPill = find.widgetWithText(PillBox, 'All (3)');
      await tester.tap(allPill);
      await tester.pumpAndSettle();

      expect(find.text('DLF Phase 5 Penthouse'), findsOneWidget);
      expect(find.text('The Magnolias Suite'), findsOneWidget);
      expect(find.text('Oberoi Sky Mansion'), findsOneWidget);

      // Verify Excel Timeline button is rendered
      expect(find.widgetWithText(OutlinedButton, 'Excel Timeline'), findsWidgets);
    },
  );

  testWidgets(
    'Sales Vertical: Closing a lead as Closed Won updates projects list in StorageService and broadcasts real-time sync',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());
      final leadToClose = {
        'id': 'lead_close_won_99',
        'client': 'Kavita Verma',
        'name': 'Kavita Verma',
        'phone': '+91 98111 22334',
        'scope': 'Luxury Farmhouse 4BHK',
        'location': 'Chattarpur, New Delhi',
        'estValue': '₹ 75,00,000',
        'referralSource': 'Architect Partner',
        'stage': 'Negotiation',
        'status': 'Negotiation',
        'nextCallDate': todayStr,
        'nextCallTime': '03:00 PM',
        'isConverted': false,
        'date': todayStr,
      };

      await StorageService.saveLeads([leadToClose]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kavita Verma'), findsOneWidget);

      // Tap on status chip to open UpdateLeadStatusSheet
      await tester.tap(find.text('Negotiation').last);
      await tester.pumpAndSettle();

      expect(find.text('Update Pipeline Status'), findsOneWidget);
      expect(find.text('Client: Kavita Verma'), findsOneWidget);

      // Select 'Closed Won'
      await tester.tap(find.text('Closed Won').last);
      await tester.pumpAndSettle();

      // Submit update: 'Mark Won & Update Projects'
      final wonBtn = find.widgetWithText(
        ElevatedButton,
        'Mark Won & Update Projects',
      );
      expect(wonBtn, findsOneWidget);
      await tester.tap(wonBtn);
      await tester.pumpAndSettle();

      // 1. Verify Project list in StorageService contains newly provisioned project
      final storedProjects = StorageService.getProjects();
      expect(
        storedProjects.any((p) => p['name'] == 'Kavita Verma Residence'),
        isTrue,
      );
      final provisionedProj = storedProjects.firstWhere(
        (p) => p['name'] == 'Kavita Verma Residence',
      );
      expect(provisionedProj['status'], 'In Progress');
      expect(provisionedProj['originLeadId'], 'lead_close_won_99');
      expect(provisionedProj['client'], 'Kavita Verma');
      expect(provisionedProj['budget'], '₹ 75,00,000');
      expect(provisionedProj['stages'].length, 7);
      expect(provisionedProj['timelineSpreadsheet'], isNotNull);

      // 2. Verify lead is marked converted in StorageService
      final storedLeads = StorageService.getLeads();
      expect(storedLeads.first['isConverted'], isTrue);
      expect(storedLeads.first['stage'], 'Closed Won');
      expect(
        storedLeads.first['convertedToProject'],
        'Kavita Verma Residence',
      );

      // 3. Switch to Project Status Report tab in SalesView
      await tester.tap(find.text('Project Status Report'));
      await tester.pumpAndSettle();

      // Verify the new project appears in the report under Ongoing
      expect(find.text('Kavita Verma Residence'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
      expect(find.text('Originated from Sales Pipeline Lead'), findsOneWidget);
    },
  );

  testWidgets(
    'Sales Pipeline: 5-stage progression (Lead -> Followup -> Site Visit -> BOQ -> Approved) moves project to Projects and seeds Design, Materials, Accounts, and Amendments',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final lead = {
        'id': 'lead_pipeline_5_step',
        'name': 'Sunil Mittal Residence',
        'client': 'Sunil Mittal',
        'phone': '+91 98111 22334',
        'scope': 'Luxury Turnkey Villa',
        'location': 'Amrita Shergill Marg, New Delhi',
        'estValue': '₹ 1,50,00,000',
        'referralSource': 'Client Referral',
        'stage': 'Lead',
        'notes': <Map<String, dynamic>>[],
      };

      await StorageService.saveLeads([lead]);
      await StorageService.saveProjects([]);
      await StorageService.saveDesignItems([]);
      await StorageService.saveMaterialRequests([]);
      await StorageService.saveInvoices([]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunil Mittal'), findsOneWidget);
      expect(find.text('Stage 1/5: Lead'), findsOneWidget);
      expect(find.text('Next: Followup'), findsOneWidget);

      // 1. Advance to Followup (Call)
      await tester.tap(find.text('Next: Followup'));
      await tester.pumpAndSettle();

      expect(find.text('Stage 2/5: Followup (Call)'), findsOneWidget);
      expect(find.text('Next: Site Visit'), findsOneWidget);
      expect(StorageService.getLeads().first['stage'], 'Followup (Call)');

      // 2. Advance to Site Visit
      await tester.tap(find.text('Next: Site Visit'));
      await tester.pumpAndSettle();

      expect(find.text('Stage 3/5: Site Visit'), findsOneWidget);
      expect(find.text('Next: BOQ'), findsOneWidget);
      expect(StorageService.getLeads().first['stage'], 'Site Visit');

      // 3. Advance to BOQ
      await tester.tap(find.text('Next: BOQ'));
      await tester.pumpAndSettle();

      expect(find.text('Stage 4/5: BOQ'), findsOneWidget);
      expect(find.text('Approve BOQ'), findsOneWidget);
      expect(StorageService.getLeads().first['stage'], 'BOQ');

      // 4. Client Approves BOQ -> Tap 'Approve BOQ'
      await tester.tap(find.text('Approve BOQ'));
      await tester.pumpAndSettle();

      // Verify Lead has been converted & approved
      final updatedLeads = StorageService.getLeads();
      expect(updatedLeads.first['isConverted'], isTrue);
      expect(updatedLeads.first['stage'], 'Approved');
      expect(
        updatedLeads.first['convertedToProject'],
        'Sunil Mittal Residence',
      );

      // Verify Turnkey Project created with 7 stages & Excel spreadsheet
      final projects = StorageService.getProjects();
      expect(
        projects.any((p) => p['name'] == 'Sunil Mittal Residence'),
        isTrue,
      );
      final newProj = projects.firstWhere(
        (p) => p['name'] == 'Sunil Mittal Residence',
      );
      expect(newProj['status'], 'In Progress');
      expect(newProj['budget'], '₹ 1,50,00,000');
      expect(newProj['originLeadId'], 'lead_pipeline_5_step');
      expect(newProj['stages'].length, 7);
      expect(newProj['timelineSpreadsheet'], isNotNull);

      // Verify Cross-Tab Propagation:
      // a. Design Tab: Concept Layout deliverable created
      final designItems = StorageService.getDesignItems();
      expect(
        designItems.any(
          (d) =>
              d['title'] ==
              'Sunil Mittal Residence - Concept Layout & Mood Board',
        ),
        isTrue,
      );

      // b. Materials Tab: Phase 1 Core Procurement Requisition created
      final matRequests = StorageService.getMaterialRequests();
      expect(
        matRequests.any(
          (m) =>
              m['itemName'] ==
              'Phase 1 Core Procurement: Cement, GI Drywall Channels & Conduiting',
        ),
        isTrue,
      );

      // c. Accounts Tab: 10% Mobilization Advance Invoice generated
      final invoices = StorageService.getInvoices();
      expect(
        invoices.any(
          (i) =>
              i['title'] ==
              'Sunil Mittal Residence - Mobilization Advance (10%)',
        ),
        isTrue,
      );

      // d. Amendments Tab / System Constants: Project registered
      expect(
        AppConstants.preExistingProjects.contains('Sunil Mittal Residence'),
        isTrue,
      );

      // e. SalesView UI updates in real-time
      expect(
        find.text('Turnkey Site Launched: "Sunil Mittal Residence"'),
        findsOneWidget,
      );
      expect(find.text('Approved & Converted'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'View in Projects'),
        findsOneWidget,
      );

      // Switch to Project Status Report tab
      await tester.tap(find.text('Project Status Report'));
      await tester.pumpAndSettle();

      expect(find.text('Sunil Mittal Residence'), findsOneWidget);
      expect(find.text('1 Active'), findsOneWidget);
    },
  );

  testWidgets(
    'UpdateLeadStatusSheet keeps pipeline milestone stage order fixed when Site Visit Scheduled or Closed Won is selected',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.saveLeads([
        {
          'id': 'lead_order_1',
          'client': 'Order Stability Lead',
          'phone': '+91 98000 12345',
          'scope': '3BHK Turnkey',
          'location': 'Gurugram',
          'estValue': '₹ 40L',
          'stage': 'Lead',
          'status': 'Lead',
        },
      ]);

      await tester.pumpWidget(
        createTestWidget(const SalesView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      // Open Update Pipeline Status sheet from the stage pill on the card
      await tester.tap(find.text('Lead').last);
      await tester.pumpAndSettle();

      List<String> currentChipLabels() {
        final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
        return chips
            .map((c) => ((c.label as Text).data ?? '').trim())
            .toList();
      }

      const expectedOrder = [
        'Lead',
        'Followup (Call)',
        'Site Visit',
        'BOQ',
        'Approved',
        'Lost / Dropped',
        'Site Visit Scheduled',
        'Closed Won',
      ];

      expect(currentChipLabels(), expectedOrder);

      // Select Site Visit Scheduled -> order must stay identical
      await tester.tap(find.text('Site Visit Scheduled').last);
      await tester.pumpAndSettle();
      expect(currentChipLabels(), expectedOrder);

      // Select Closed Won -> order must stay identical
      await tester.tap(find.text('Closed Won').last);
      await tester.pumpAndSettle();
      expect(currentChipLabels(), expectedOrder);
    },
  );
}
