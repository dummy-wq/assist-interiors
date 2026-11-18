import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/main.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';

Widget _buildTestApp({UserRole role = UserRole.proprietor}) {
  final authProvider = AuthProvider()..switchRole(role);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: const AssistInteriorsApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.seedFillerProjectsIfEmpty();
  });

  group('Screen Action Bar Below Top Bar', () {
    testWidgets('Action section does not cross over into Hub (Tab 0)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // On Hub (tab 0), screen action buttons MUST NOT exist
      expect(find.byKey(const Key('action_bar_add_project')), findsNothing);
      expect(find.byKey(const Key('action_bar_upload_design')), findsNothing);
      expect(find.byKey(const Key('action_bar_add_material_request')), findsNothing);
      expect(find.byKey(const Key('action_bar_add_amendment')), findsNothing);
      expect(find.byKey(const Key('action_bar_add_invoice')), findsNothing);
      expect(find.byKey(const Key('action_bar_print_invoice')), findsNothing);
      expect(find.byKey(const Key('action_bar_add_lead')), findsNothing);
      expect(find.byKey(const Key('action_bar_invite_staff')), findsNothing);
    });

    testWidgets('Projects tab renders Add Project and Filter Projects in action section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Projects
      await tester.tap(find.text('Projects').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_add_project')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_filter_projects')), findsOneWidget);

      // Tap Add Project opens creation modal
      await tester.tap(find.byKey(const Key('action_bar_add_project')));
      await tester.pumpAndSettle();
      expect(find.text('Initiate Turnkey Project'), findsOneWidget);
    });

    testWidgets('Amendments tab renders Add Amendment and Pending Sign-Off in action section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Amendments
      await tester.tap(find.text('Amendments').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_add_amendment')), findsOneWidget);
      expect(find.text('Add Amendment'), findsOneWidget);
      expect(find.byKey(const Key('action_bar_urgent_only')), findsOneWidget);
    });

    testWidgets('Design tab renders Upload Drawing and Filter Drawings in action section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Design
      await tester.tap(find.text('Design').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_upload_design')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_filter_designs')), findsOneWidget);
    });

    testWidgets('Accounts tab renders Add Invoice and Print Invoice in action section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Accounts
      await tester.tap(find.text('Accounts').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_add_invoice')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_print_invoice')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_pnl_report')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_record_expense')), findsOneWidget);

      // Tap Print Invoice opens invoice selection sheet
      await tester.tap(find.byKey(const Key('action_bar_print_invoice')));
      await tester.pumpAndSettle();
      expect(find.text('Select Invoice to Print'), findsOneWidget);
    });

    testWidgets('Sales tab renders Add Lead and Schedule Call in action section', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Sales
      await tester.tap(find.text('Sales').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_add_lead')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_schedule_call')), findsOneWidget);

      // Tap Add Lead opens lead modal
      await tester.tap(find.byKey(const Key('action_bar_add_lead')));
      await tester.pumpAndSettle();
      expect(find.text('Add Prospective Lead'), findsOneWidget);
    });

    testWidgets('Materials and Team tabs render their respective action buttons', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Materials
      await tester.tap(find.text('Materials').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_material_request')), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);
      expect(find.byKey(const Key('action_bar_track_pos')), findsOneWidget);

      // Switch to Team
      await tester.ensureVisible(find.text('Team').first);
      await tester.tap(find.text('Team').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_invite_staff')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_labour_roll')), findsOneWidget);
    });

    testWidgets('RBAC guards: Unauthorized roles do not see restricted action buttons', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Accounts role cannot create projects
      await tester.pumpWidget(_buildTestApp(role: UserRole.accounts));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Projects').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_bar_add_project')), findsNothing);
      expect(find.byKey(const Key('action_bar_filter_projects')), findsOneWidget);
    });

    testWidgets('Mobile viewport renders action section without overflow across all tabs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tab 0: Hub -> no action bar
      expect(find.byKey(const Key('action_bar_add_project')), findsNothing);

      // Tab 1: Sales
      await tester.tap(find.text('Sales').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_lead')), findsOneWidget);

      // Tab 2: Projects
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_project')), findsOneWidget);

      // Tab 3: Design (via More suite sheet)
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('more_sheet_module_design')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_upload_design')), findsOneWidget);

      // Tab 4: Materials (via More suite sheet)
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('more_sheet_module_materials')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_material_request')), findsOneWidget);

      // Tab 5: Amendments (via More suite sheet)
      await tester.tap(find.text('Materials').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('more_sheet_module_amendments')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_amendment')), findsOneWidget);

      // Tab 6: Accounts
      await tester.tap(find.text('Accounts').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('action_bar_add_invoice')), findsOneWidget);
      expect(find.byKey(const Key('action_bar_print_invoice')), findsOneWidget);
    });
  });
}
