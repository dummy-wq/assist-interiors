import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/amendments/views/amendments_view.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/accounts_dashboard.dart';
import 'package:assist_interiors_dashboard/features/design/views/design_view.dart';
import 'package:assist_interiors_dashboard/features/material_requests/views/material_requests_view.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/tasks/views/tasks_view.dart';
import 'package:assist_interiors_dashboard/features/team/views/team_view.dart';
import 'package:assist_interiors_dashboard/features/vendors/views/vendors_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget wrapWithApp(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..switchRole(UserRole.proprietor),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  void verifyCentered75PercentBox(WidgetTester tester, Size viewportSize) {
    final containerFinder = find.byKey(
      const Key('expanded_detail_box_container'),
    );
    expect(containerFinder, findsOneWidget);

    final rect = tester.getRect(containerFinder);
    expect(rect.height, closeTo(viewportSize.height * 0.75, 2.0));

    final expectedWidth = viewportSize.width >= 600
        ? (viewportSize.width * 0.75).clamp(440.0, 900.0)
        : (viewportSize.width * 0.88).clamp(280.0, 520.0);
    expect(rect.width, closeTo(expectedWidth, 2.0));

    expect(rect.center.dx, closeTo(viewportSize.width / 2, 2.0));
    expect(rect.center.dy, closeTo(viewportSize.height / 2, 2.0));
  }

  group('Centered 75% Expanded Detail Box Template', () {
    testWidgets(
      'SalesView: clicking lead card expands into centered 75% detail box',
      (tester) async {
        const size = Size(800, 1000);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await StorageService.saveLeads([
          {
            'id': 'lead_expand_1',
            'client': 'Rohan Malhotra',
            'phone': '+91 98111 22334',
            'scope': 'Full 4BHK Turnkey Interiors',
            'location': 'DLF Camellias, Gurugram',
            'estValue': '₹ 85L',
            'referralSource': 'Architect Partner',
            'referralBy': 'Ar. Meera',
            'stage': 'Design Proposal',
            'nextCallDate': '18 Nov 2026',
            'nextCallTime': '03:00 PM',
            'reminderNote': 'Discuss marble samples and veneer finishes',
          },
        ]);

        await tester.pumpWidget(wrapWithApp(const SalesView()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Rohan Malhotra'));
        await tester.pumpAndSettle();

        verifyCentered75PercentBox(tester, size);
        expect(find.text('Estimated Value'), findsOneWidget);
        expect(find.text('CLIENT & ATTRIBUTION'), findsOneWidget);
        expect(find.text('CALL REMINDER NOTE'), findsOneWidget);
        expect(find.textContaining('Discuss marble samples'), findsWidgets);

        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('expanded_detail_box_container')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Mobile viewport (~420x880) expands Sales lead box centered at 75% height',
      (tester) async {
        const size = Size(420, 880);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await StorageService.saveLeads([
          {
            'id': 'lead_mobile_1',
            'client': 'Neha Kapoor',
            'phone': '+91 98222 11009',
            'scope': 'Master Bedroom & Lounge',
            'location': 'Vasant Vihar, Delhi',
            'estValue': '₹ 32L',
            'referralSource': 'Instagram',
            'stage': 'Site Visit',
          },
        ]);

        await tester.pumpWidget(wrapWithApp(const SalesView()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Neha Kapoor'));
        await tester.pumpAndSettle();

        verifyCentered75PercentBox(tester, size);
      },
    );

    testWidgets(
      'Template works consistently across Design, Materials, Amendments, Accounts, Team, Projects, Tasks & Vendors',
      (tester) async {
        const size = Size(800, 900);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. DesignView
        await StorageService.saveDesignItems([
          {
            'id': 'DES-1',
            'title': 'Living Room False Ceiling Plan',
            'project': 'DLF Magnolias 4BHK Sky Villa',
            'type': 'CAD Drawing',
            'format': '.DWG',
            'version': 'v2.1',
            'fileSize': '8.4 MB',
            'status': 'Approved',
            'designer': 'Priya Sharma',
            'notes': 'Includes recessed cove lighting details',
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const DesignView()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Living Room False Ceiling Plan'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 2. MaterialRequestsView
        await StorageService.saveMaterialRequests([
          {
            'id': 'MR-99',
            'itemName': 'Italian Statuario Slabs (1200x2400)',
            'project': 'One Horizon Suite',
            'category': 'Flooring & Stone',
            'quantity': '18 Slabs',
            'urgency': 'Urgent',
            'status': 'Pending Approval',
            'estimatedCost': '₹ 4,20,000',
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const MaterialRequestsView()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Italian Statuario Slabs (1200x2400)'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 3. AmendmentsView
        await StorageService.saveAmendments([
          {
            'id': 'AMD-55',
            'title': 'Motorized Drapery Tracks Upgrade',
            'project': 'One Horizon Suite',
            'costImpact': '+₹ 1,85,000',
            'timelineImpact': '+4 Days',
            'priority': 'Medium',
            'status': 'Under Review',
            'description': 'Somfy automation tracks in all 3 suites',
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const AmendmentsView()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Motorized Drapery Tracks Upgrade'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 4. AccountsDashboard
        await StorageService.saveInvoices([
          {
            'id': 'INV-77',
            'title': 'Milestone 2 Joinery Billing',
            'client': 'Vikram Khanna',
            'project': 'Khanna Residence',
            'amount': '₹ 6,50,000',
            'status': 'Payment Pending',
            'date': '15 Nov 2026',
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const AccountsDashboard()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Milestone 2 Joinery Billing'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 5. TeamView
        final auth = AuthProvider()..switchRole(UserRole.proprietor);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>(
            key: const Key('team_auth_provider'),
            create: (_) => auth,
            child: const MaterialApp(home: Scaffold(body: TeamView())),
          ),
        );
        await tester.pumpAndSettle();
        final firstMemberName = auth.approvedUsers.first.fullName;
        await tester.tap(find.text(firstMemberName).first);
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 6. ProjectsView
        await StorageService.saveProjects([
          {
            'id': 'PROJ-EXP-1',
            'name': 'Camellias Penthouse 802',
            'client': 'Aditya Oberoi',
            'location': 'Golf Course Road',
            'budget': '₹ 1.4 Cr',
            'spent': '₹ 45 L',
            'pm': 'Vikram Sethi',
            'supervisor': 'Manoj Yadav',
            'handover': '20 Dec 2026',
            'stages': [
              {'title': 'Civil & Demolition', 'isDone': true},
              {'title': 'Electrical Conduiting', 'isDone': false},
            ],
          },
        ]);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>(
            key: const Key('projects_auth_provider'),
            create: (_) => AuthProvider()..switchRole(UserRole.proprietor),
            child: const MaterialApp(home: Scaffold(body: ProjectsView())),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Handover: 20 Dec 2026').first);
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 7. TasksView
        await StorageService.saveTasks([
          {
            'id': 'TSK-1',
            'title': 'Verify Electrical Conduit Layout',
            'project': 'DLF Camellias',
            'department': 'Site & Execution',
            'assignee': 'Ramesh Verma',
            'deadline': 'Tomorrow',
            'priority': 'High',
            'completed': false,
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const TasksView()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verify Electrical Conduit Layout'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();

        // 8. VendorsView
        await StorageService.saveVendors([
          {
            'id': 'VND-1',
            'name': 'Jaquar Luxury Sanitaryware',
            'category': 'Plumbing & Fixtures',
            'contactPerson': 'Suresh Nair',
            'phone': '+91 98100 11223',
            'city': 'Gurugram',
            'paymentStatus': 'Pending',
            'amountDue': '₹ 2,40,000',
          },
        ]);
        await tester.pumpWidget(wrapWithApp(const VendorsView()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Jaquar Luxury Sanitaryware'));
        await tester.pumpAndSettle();
        verifyCentered75PercentBox(tester, size);
        await tester.tap(find.byKey(const Key('expanded_detail_close_btn')));
        await tester.pumpAndSettle();
      },
    );
  });
}
