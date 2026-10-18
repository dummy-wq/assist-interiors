import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/core/widgets/pill_box.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
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
      expect(find.text('New Inquiry'), findsWidgets);
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

      // Filter by 'Closed Won'
      final wonPill = find.widgetWithText(PillBox, 'Closed Won');
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
}
