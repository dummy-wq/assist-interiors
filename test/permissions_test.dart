import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/permissions/app_permissions.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/main_dashboard_screen.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/proprietor_dashboard.dart';
import 'package:assist_interiors_dashboard/core/utils/app_notification.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPermissions RBAC Matrix Verification', () {
    test('Proprietor has comprehensive executive administrative access', () {
      const role = UserRole.proprietor;
      expect(AppPermissions.canCreateProject(role), isTrue);
      expect(AppPermissions.canEditProjectDetails(role), isTrue);
      expect(AppPermissions.canModifyProjectStatus(role), isTrue);
      expect(AppPermissions.canToggleOrReorderStages(role), isTrue);
      expect(AppPermissions.canCreateTask(role), isTrue);
      expect(AppPermissions.canUpdateTaskStatus(role), isTrue);
      expect(AppPermissions.canDeleteTask(role), isTrue);
      expect(AppPermissions.canManageVendors(role), isTrue);
      expect(AppPermissions.canManageAccounts(role), isTrue);
      expect(AppPermissions.canExportFinancials(role), isTrue);
      expect(AppPermissions.canManageSales(role), isTrue);
      expect(AppPermissions.canManageTeam(role), isTrue);
    });

    test('Accounts role cannot touch projects or tasks, but manages finances', () {
      const role = UserRole.accounts;
      // Restricted
      expect(AppPermissions.canCreateProject(role), isFalse);
      expect(AppPermissions.canEditProjectDetails(role), isFalse);
      expect(AppPermissions.canModifyProjectStatus(role), isFalse);
      expect(AppPermissions.canToggleOrReorderStages(role), isFalse);
      expect(AppPermissions.canCreateTask(role), isFalse);
      expect(AppPermissions.canUpdateTaskStatus(role), isFalse);
      expect(AppPermissions.canDeleteTask(role), isFalse);
      expect(AppPermissions.canManageSales(role), isFalse);
      expect(AppPermissions.canManageTeam(role), isFalse);

      // Allowed
      expect(AppPermissions.canManageAccounts(role), isTrue);
      expect(AppPermissions.canExportFinancials(role), isTrue);
      expect(AppPermissions.canManageVendors(role), isTrue);
    });

    test('Sales role cannot touch projects, tasks, or financial ledger', () {
      const role = UserRole.sales;
      // Restricted
      expect(AppPermissions.canCreateProject(role), isFalse);
      expect(AppPermissions.canEditProjectDetails(role), isFalse);
      expect(AppPermissions.canModifyProjectStatus(role), isFalse);
      expect(AppPermissions.canToggleOrReorderStages(role), isFalse);
      expect(AppPermissions.canCreateTask(role), isFalse);
      expect(AppPermissions.canUpdateTaskStatus(role), isFalse);
      expect(AppPermissions.canDeleteTask(role), isFalse);
      expect(AppPermissions.canManageAccounts(role), isFalse);
      expect(AppPermissions.canExportFinancials(role), isFalse);
      expect(AppPermissions.canManageVendors(role), isFalse);
      expect(AppPermissions.canManageTeam(role), isFalse);

      // Allowed
      expect(AppPermissions.canManageSales(role), isTrue);
    });

    test('Project Manager manages sites, stages, tasks, and vendors', () {
      const role = UserRole.projectManager;
      expect(AppPermissions.canCreateProject(role), isTrue);
      expect(AppPermissions.canEditProjectDetails(role), isTrue);
      expect(AppPermissions.canModifyProjectStatus(role), isTrue);
      expect(AppPermissions.canToggleOrReorderStages(role), isTrue);
      expect(AppPermissions.canCreateTask(role), isTrue);
      expect(AppPermissions.canUpdateTaskStatus(role), isTrue);
      expect(AppPermissions.canDeleteTask(role), isTrue);
      expect(AppPermissions.canManageVendors(role), isTrue);
      expect(AppPermissions.canExportFinancials(role), isTrue);
      expect(AppPermissions.canManageAccounts(role), isFalse);
      expect(AppPermissions.canManageSales(role), isFalse);
      expect(AppPermissions.canManageTeam(role), isFalse);
    });

    test('Designer can update milestone stages and deliverables', () {
      const role = UserRole.designer;
      expect(AppPermissions.canCreateProject(role), isFalse);
      expect(AppPermissions.canEditProjectDetails(role), isFalse);
      expect(AppPermissions.canModifyProjectStatus(role), isFalse);
      expect(AppPermissions.canToggleOrReorderStages(role), isTrue);
      expect(AppPermissions.canUpdateTaskStatus(role), isTrue);
      expect(AppPermissions.canCreateTask(role), isFalse);
      expect(AppPermissions.canDeleteTask(role), isFalse);
      expect(AppPermissions.canManageAccounts(role), isFalse);
      expect(AppPermissions.canExportFinancials(role), isFalse);
    });

    test('Site Supervisor can update execution stages and mark tasks complete', () {
      const role = UserRole.supervisor;
      expect(AppPermissions.canCreateProject(role), isFalse);
      expect(AppPermissions.canEditProjectDetails(role), isFalse);
      expect(AppPermissions.canModifyProjectStatus(role), isFalse);
      expect(AppPermissions.canToggleOrReorderStages(role), isTrue);
      expect(AppPermissions.canUpdateTaskStatus(role), isTrue);
      expect(AppPermissions.canCreateTask(role), isFalse);
      expect(AppPermissions.canDeleteTask(role), isFalse);
      expect(AppPermissions.canManageAccounts(role), isFalse);
      expect(AppPermissions.canExportFinancials(role), isFalse);
    });

    test('Role access summaries are populated for all roles', () {
      for (final role in UserRole.values) {
        final summary = AppPermissions.getRoleAccessSummary(role);
        expect(summary, isNotEmpty);
      }
    });
  });

  group('Demo Role Switching in AuthProvider', () {
    test('AuthProvider allows switching roles instantly for demo', () {
      final auth = AuthProvider();
      expect(auth.currentRole, equals(UserRole.proprietor));

      // Switch to Accounts
      auth.switchRole(UserRole.accounts);
      expect(auth.currentRole, equals(UserRole.accounts));
      expect(AppPermissions.canManageAccounts(auth.currentRole), isTrue);
      expect(AppPermissions.canCreateProject(auth.currentRole), isFalse);

      // Switch to Sales
      auth.switchRole(UserRole.sales);
      expect(auth.currentRole, equals(UserRole.sales));
      expect(AppPermissions.canManageSales(auth.currentRole), isTrue);
      expect(AppPermissions.canManageAccounts(auth.currentRole), isFalse);

      // Switch to Site Supervisor
      auth.switchRole(UserRole.supervisor);
      expect(auth.currentRole, equals(UserRole.supervisor));
      expect(AppPermissions.canToggleOrReorderStages(auth.currentRole), isTrue);
      expect(AppPermissions.canCreateProject(auth.currentRole), isFalse);
    });
  });

  group('Studio Hub Persistence Across All Roles', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      await StorageService.clearAll();
    });

    Widget createTestApp(AuthProvider auth) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
          home: const MainDashboardScreen(),
        ),
      );
    }

    testWidgets(
      'Tab 0 always renders Executive Studio Hub regardless of active role',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        for (final role in UserRole.values) {
          final auth = AuthProvider();
          auth.switchRole(role);

          await tester.pumpWidget(createTestApp(auth));
          await tester.pumpAndSettle();

          // Verify Tab 0 is always Executive Studio Hub
          expect(
            find.text('Executive Studio Hub'),
            findsOneWidget,
            reason: 'Studio Hub must be persistent for role $role',
          );
          expect(
            find.byType(ProprietorDashboard),
            findsOneWidget,
            reason:
                'ProprietorDashboard must remain on Tab 0 for role $role',
          );
        }
      },
    );
  });

  group(
    'Strict Project Creation Restrictions for Sales and Unauthorized Roles',
    () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService.init();
        await StorageService.clearAll();
        AppNotification.resetCooldown();
      });

      testWidgets(
        'Sales role sees Pending Handover instead of Launch button on leads',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final lead = {
            'id': 'lead_1',
            'name': 'Aditi Rao Residence',
            'client': 'Aditi Rao',
            'phone': '+91 99887 76655',
            'scope': 'Penthouse Interior',
            'location': 'Mumbai',
            'estValue': '₹ 80L',
            'referralSource': 'Direct Walk-in',
            'stage': 'Token Advance Received',
          };
          await StorageService.saveLeads([lead]);

          final salesAuth = AuthProvider();
          salesAuth.switchRole(UserRole.sales);

          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: salesAuth,
              child: MaterialApp(
                theme:
                    ThemeData(brightness: Brightness.light, useMaterial3: true),
                home: const Scaffold(body: SalesView()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Aditi Rao'), findsOneWidget);
          // Sales must NOT see Launch button
          expect(find.text('Launch'), findsNothing);
          expect(find.text('Pending Handover'), findsOneWidget);

          // Now pump with Proprietor
          final propAuth = AuthProvider();
          propAuth.switchRole(UserRole.proprietor);

          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: propAuth,
              child: MaterialApp(
                theme:
                    ThemeData(brightness: Brightness.light, useMaterial3: true),
                home: const Scaffold(body: SalesView()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Proprietor CAN see Launch button
          expect(find.text('Launch'), findsOneWidget);
        },
      );

      testWidgets(
        'MobileActionSheets gateway strictly blocks project creation for Sales',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final salesAuth = AuthProvider();
          salesAuth.switchRole(UserRole.sales);

          late BuildContext capturedContext;
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: salesAuth,
              child: MaterialApp(
                theme:
                    ThemeData(brightness: Brightness.light, useMaterial3: true),
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) {
                      capturedContext = ctx;
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          AppNotification.resetCooldown();
          // Attempt to invoke showInitiateProjectSheet as Sales
          MobileActionSheets.showInitiateProjectSheet(capturedContext);
          await tester.pumpAndSettle();

          // Modal should NOT be opened
          expect(find.text('Launch New Turnkey Project'), findsNothing);
          // Restriction notification should be displayed
          expect(
            find.text(
              'Action restricted: Only Proprietor and Project Managers can create projects.',
            ),
            findsOneWidget,
          );

          // Dismiss snackbar
          await tester.pump(const Duration(seconds: 4));
          AppNotification.resetCooldown();

          // Attempt to invoke showCreateProjectSheet as Sales
          MobileActionSheets.showCreateProjectSheet(capturedContext);
          await tester.pumpAndSettle();

          expect(find.text('Launch New Turnkey Project'), findsNothing);
          expect(
            find.text(
              'Action restricted: Only Proprietor and Project Managers can create projects.',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}
