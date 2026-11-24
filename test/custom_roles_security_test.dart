import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/permissions/app_permissions.dart';
import 'package:assist_interiors_dashboard/core/services/photo_archive_service.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/utils/app_notification.dart';
import 'package:assist_interiors_dashboard/core/utils/security_hash.dart';
import 'package:assist_interiors_dashboard/features/auth/models/user_model.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/main_dashboard_screen.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    StorageService.clearUsers();
  });

  group('Credential Hashing & Sign-Up Security', () {
    test('salted SHA-256 verifies matching password and rejects wrong password', () {
      final salt1 = SecurityHash.generateSalt();
      final salt2 = SecurityHash.generateSalt();
      expect(salt1, isNot(equals(salt2)));

      final hash1 = SecurityHash.hashPassword('Secret#123', salt1);
      final hash2 = SecurityHash.hashPassword('Secret#123', salt2);
      expect(hash1.length, 64);
      expect(hash1, isNot(equals(hash2)));

      expect(SecurityHash.verifyPassword('Secret#123', salt1, hash1), isTrue);
      expect(SecurityHash.verifyPassword('WrongPass', salt1, hash1), isFalse);
    });

    test('signUp blocks duplicate emails, prevents self-Proprietor escalation, and enforces password on login', () {
      final auth = AuthProvider();
      auth.logout();

      // Cannot self-register as Master Proprietor — downgraded to supervisor pending review
      final applicant = auth.signUp(
        fullName: 'Meera Nair',
        email: 'meera@studio.in',
        phone: '+91 98111 22334',
        requestedRole: UserRole.proprietor,
        password: 'MyStrongPassword!9',
      );
      expect(applicant.role, isNot(UserRole.proprietor));
      expect(applicant.status, UserAccountStatus.pendingApproval);
      expect(applicant.seenByProprietor, isFalse);
      expect(applicant.passwordHash, isNotNull);
      expect(applicant.passwordSalt, isNotNull);

      // Duplicate email sign-up throws StateError
      expect(
        () => auth.signUp(
          fullName: 'Duplicate Meera',
          email: 'MEERA@studio.in',
          phone: '+91 90000 00000',
          requestedRole: UserRole.sales,
          password: 'Password123',
        ),
        throwsStateError,
      );

      // Pending user cannot log in even with right password
      expect(
        auth.login('meera@studio.in', 'MyStrongPassword!9'),
        isFalse,
      );
      expect(auth.lastAuthError, contains('pending approval'));

      // Proprietor signs in & approves applicant with wrong-password check afterwards
      auth.quickLoginAs(UserRole.proprietor);
      expect(auth.approveUser(applicant.id), isTrue);

      auth.logout();
      expect(auth.login('meera@studio.in', 'WrongPassword'), isFalse);
      expect(auth.lastAuthError, contains('Incorrect password'));

      expect(
        auth.login('meera@studio.in', 'MyStrongPassword!9'),
        isTrue,
      );
      expect(auth.currentUser?.email, 'meera@studio.in');
    });
  });

  group('Custom Roles & Granular Checked Permissions Security', () {
    test('non-Proprietor and custom-role users cannot manage team, approve staff, or create roles', () {
      final auth = AuthProvider();

      // Applicant registers
      final pending = auth.signUp(
        fullName: 'Rohan Joshi',
        email: 'rohan@studio.in',
        phone: '+91 99887 76655',
        requestedRole: UserRole.designer,
        password: 'RohanPass!22',
      );

      // Switch to Sales user -> all governance mutations must return false
      auth.quickLoginAs(UserRole.sales);
      expect(auth.canManageTeam, isFalse);
      expect(auth.approveUser(pending.id), isFalse);
      expect(
        auth.createCustomRole(
          name: 'Shadow Admin',
          permissions: AppPermissionKey.values.toSet(),
        ),
        isNull,
      );

      // Switch to Master Proprietor -> approve Rohan with custom role & checked permissions
      auth.quickLoginAs(UserRole.proprietor);
      expect(auth.canManageTeam, isTrue);

      // Reserved name blocked
      expect(
        auth.createCustomRole(
          name: 'Master Proprietor',
          permissions: {AppPermissionKey.manageSales},
        ),
        isNull,
      );

      final ok = auth.approveUser(
        pending.id,
        UserRole.supervisor,
        null,
        'Senior Client Coordinator',
        {
          AppPermissionKey.manageSales,
          AppPermissionKey.manageDesignAssets,
        },
        true,
      );
      expect(ok, isTrue);
      expect(
        auth.customRoles.any((r) => r.name == 'Senior Client Coordinator'),
        isTrue,
      );

      // Log in as the newly authorized custom-role user
      auth.logout();
      expect(auth.login('rohan@studio.in', 'RohanPass!22'), isTrue);
      final rohan = auth.currentUser!;
      expect(rohan.hasCustomAccess, isTrue);
      expect(rohan.effectiveRoleTitle, 'Senior Client Coordinator');

      // Allowed checked permissions work
      expect(
        AppPermissions.canManageSales(rohan.role, user: rohan),
        isTrue,
      );
      expect(
        AppPermissions.canManageDesignAssets(rohan.role, user: rohan),
        isTrue,
      );

      // Unchecked permissions & admin governance remain strictly blocked
      expect(
        AppPermissions.canCreateProject(rohan.role, user: rohan),
        isFalse,
      );
      expect(
        AppPermissions.canManageAccounts(rohan.role, user: rohan),
        isFalse,
      );
      expect(
        AppPermissions.canManageTeam(rohan.role, user: rohan),
        isFalse,
      );
      expect(auth.canManageTeam, isFalse);
      expect(
        auth.createCustomRole(
          name: 'Unauthorized Role',
          permissions: {AppPermissionKey.manageSales},
        ),
        isNull,
      );
    });

    test('updating a reusable CustomRoleDefinition syncs permissions to assigned staff and persists', () {
      final auth = AuthProvider();
      auth.quickLoginAs(UserRole.proprietor);

      final roleDef = auth.createCustomRole(
        name: 'Site Auditor',
        permissions: {AppPermissionKey.addProjectPhotos},
      );
      expect(roleDef, isNotNull);

      final applicant = auth.signUp(
        fullName: 'Kiran Verma',
        email: 'kiran@studio.in',
        phone: '+91 91234 56789',
        requestedRole: UserRole.supervisor,
      );

      expect(
        auth.approveUser(
          applicant.id,
          UserRole.supervisor,
          roleDef!.id,
          roleDef.name,
          roleDef.permissions,
          false,
        ),
        isTrue,
      );

      // Update role to also allow updating task statuses
      expect(
        auth.updateCustomRole(
          roleId: roleDef.id,
          name: 'Lead Site Auditor',
          permissions: {
            AppPermissionKey.addProjectPhotos,
            AppPermissionKey.updateTaskStatus,
          },
        ),
        isTrue,
      );

      // Reload AuthProvider from StorageService to prove persistence
      final reloaded = AuthProvider();
      expect(
        reloaded.customRoles.any((r) => r.name == 'Lead Site Auditor'),
        isTrue,
      );
      final kiran = reloaded.approvedUsers.firstWhere(
        (u) => u.email == 'kiran@studio.in',
      );
      expect(kiran.effectiveRoleTitle, 'Lead Site Auditor');
      expect(
        AppPermissions.canUpdateTaskStatus(kiran.role, user: kiran),
        isTrue,
      );
      expect(
        AppPermissions.canCreateProject(kiran.role, user: kiran),
        isFalse,
      );
    });
  });

  group('Proprietor Live Notifications & Custom Role UI Flow', () {
    testWidgets(
      'Proprietor sees notification bell badge & alert on new sign-up, assigns custom checked role via dialog, and custom user actions are enforced',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = AuthProvider();
        auth.quickLoginAs(UserRole.proprietor);
        final initialPendingCount = auth.pendingUsers.length;

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const MaterialApp(
              home: MainDashboardScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Left side pane button is present on top bar; shows existing pending badge count
        expect(find.byKey(const Key('left_side_pane_btn')), findsOneWidget);
        if (initialPendingCount > 0) {
          expect(find.byKey(const Key('proprietor_notifications_badge')), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const Key('proprietor_notifications_badge')),
              matching: find.text('$initialPendingCount'),
            ),
            findsOneWidget,
          );
        } else {
          expect(find.byKey(const Key('proprietor_notifications_badge')), findsNothing);
        }

        // New person tries to create an account -> Proprietor immediately receives notification + incremented badge
        final newApplicant = auth.signUp(
          fullName: 'Devika Kapoor',
          email: 'devika@studio.in',
          phone: '+91 98765 00001',
          requestedRole: UserRole.sales,
          password: 'DevikaPassword1!',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byKey(const Key('proprietor_notifications_badge')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('proprietor_notifications_badge')),
            matching: find.text('${initialPendingCount + 1}'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Devika Kapoor requested access'), findsOneWidget);

        // Open Left Side Pane and tap notifications entry -> opens Staff Management & marks unseen notifications read
        await tester.tap(find.byKey(const Key('left_side_pane_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('proprietor_notifications_btn')), findsOneWidget);
        await tester.tap(find.byKey(const Key('proprietor_notifications_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Executive Staff Access & Governance'), findsOneWidget);
        expect(find.text('Custom Roles (0)'), findsOneWidget);
        expect(find.text('Assign / Custom Role'), findsWidgets);
        expect(auth.unseenPendingCount, 0);

        // Verify Dismiss Request, Assign / Custom Role, and Approve Access are aligned in one uniform equal-width row
        final dismissRect = tester.getRect(
          find.widgetWithText(OutlinedButton, 'Dismiss Request').first,
        );
        final assignRect = tester.getRect(
          find.widgetWithText(OutlinedButton, 'Assign / Custom Role').first,
        );
        final approveRect = tester.getRect(
          find.widgetWithText(ElevatedButton, 'Approve Access').first,
        );
        expect(dismissRect.top, closeTo(assignRect.top, 0.5));
        expect(assignRect.top, closeTo(approveRect.top, 0.5));
        expect(dismissRect.height, closeTo(38.0, 0.5));
        expect(assignRect.height, closeTo(38.0, 0.5));
        expect(approveRect.height, closeTo(38.0, 0.5));
        expect(dismissRect.width, closeTo(assignRect.width, 1.0));
        expect(assignRect.width, closeTo(approveRect.width, 1.0));

        // Open Role & Permission Configuration dialog for Devika (newest pending user -> first card)
        await tester.tap(find.text('Assign / Custom Role').first);
        await tester.pumpAndSettle();

        // Switch to Create Custom Role tab
        await tester.tap(find.byKey(const Key('role_mode_custom_tab')));
        await tester.pumpAndSettle();

        // Enter custom role name
        await tester.enterText(
          find.byKey(const Key('custom_role_name_field')),
          'Client Liaison',
        );
        await tester.pumpAndSettle();

        // Clear all preset permissions and check only Manage Sales Leads & Pipeline
        await tester.tap(find.text('Clear All'));
        await tester.pumpAndSettle();

        final salesCheckbox = find.text('Manage Sales Leads & Pipeline');
        await tester.ensureVisible(salesCheckbox);
        await tester.tap(salesCheckbox);
        await tester.pumpAndSettle();

        // Approve & Grant Access
        await tester.tap(find.text('Approve & Grant Access'));
        await tester.pumpAndSettle();

        // Close Staff Management sheet
        Navigator.of(
          tester.element(find.text('Executive Staff Access & Governance')),
        ).pop();
        await tester.pumpAndSettle();

        // Verify saved custom role & Devika's assigned access
        expect(auth.customRoles.any((r) => r.name == 'Client Liaison'), isTrue);
        final devika = auth.approvedUsers.firstWhere((u) => u.id == newApplicant.id);
        expect(devika.effectiveRoleTitle, 'Client Liaison');
        expect(AppPermissions.canManageSales(devika.role, user: devika), isTrue);
        expect(AppPermissions.canCreateProject(devika.role, user: devika), isFalse);

        // Switch active session to Devika (custom role)
        auth.quickLoginAsUser(devika);
        await tester.pumpAndSettle();

        // Notification badge is hidden from custom-role user
        expect(find.byKey(const Key('proprietor_notifications_badge')), findsNothing);

        // Gateway action check: Initiate Project is blocked for Devika
        AppNotification.resetCooldown();
        final ctx = tester.element(find.byType(Scaffold).first);
        MobileActionSheets.showInitiateProjectSheet(ctx);
        await tester.pumpAndSettle();
        expect(find.textContaining('Action restricted'), findsWidgets);
      },
    );

    testWidgets(
      'InviteStaffSheet displays Staff Email, Department Role dropdown matching button width, and adds invited staff member to Team directory',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = AuthProvider();
        auth.quickLoginAs(UserRole.proprietor);
        final initialCount = auth.approvedUsers.length;

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const MaterialApp(
              home: MainDashboardScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Navigate to Team tab (tab 7)
        MainDashboardScreen.navigateToTab(7);
        await tester.pumpAndSettle();

        // Open Invite Staff Member sheet from top action bar
        await tester.tap(find.text('Invite Staff').first);
        await tester.pumpAndSettle();

        expect(find.text('Invite Staff Member'), findsOneWidget);
        expect(find.text('Staff Email'), findsOneWidget);
        expect(find.text('Company Email'), findsNothing);
        expect(find.text('Department Role'), findsOneWidget);

        // Open Department Role dropdown and verify deployed popup width matches button width
        final roleDropdown = find.byType(DropdownButtonFormField<String>);
        expect(roleDropdown, findsOneWidget);
        final buttonRect = tester.getRect(roleDropdown);

        await tester.tap(roleDropdown);
        await tester.pumpAndSettle();

        final menuMaterial = find.ancestor(
          of: find.text('Project Manager').last,
          matching: find.byType(Material),
        ).first;
        final menuRect = tester.getRect(menuMaterial);
        expect(menuRect.width, closeTo(buttonRect.width, 1.0));
        expect(menuRect.left, closeTo(buttonRect.left, 1.0));

        // Select Project Manager
        await tester.tap(find.text('Project Manager').last);
        await tester.pumpAndSettle();

        // Fill in Full Name and Staff Email
        await tester.enterText(
          find.widgetWithText(TextField, 'Full Name'),
          'Aarav Mehta',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Staff Email'),
          'aarav@assistinteriors.com',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Authorization Invite'));
        await tester.pumpAndSettle();

        expect(auth.approvedUsers.length, initialCount + 1);
        final invited = auth.approvedUsers.firstWhere(
          (u) => u.email == 'aarav@assistinteriors.com',
        );
        expect(invited.fullName, 'Aarav Mehta');
        expect(invited.role, UserRole.projectManager);
        expect(find.text('Aarav Mehta'), findsWidgets);

        // Tap on Aarav Mehta card to open the Expanded Detail Card
        final aaravCard = find.text('Aarav Mehta').first;
        await tester.ensureVisible(aaravCard);
        await tester.tap(aaravCard);
        await tester.pumpAndSettle();

        final expandedCard = find.byKey(
          const Key('expanded_detail_box_container'),
        );
        expect(expandedCard, findsOneWidget);

        // Small swipe does NOT dismiss the fullscreen detail box
        await tester.fling(expandedCard, const Offset(0, 75), 350);
        await tester.pumpAndSettle();
        expect(expandedCard, findsOneWidget);

        // Larger deliberate swipe dismisses the fullscreen detail box
        await tester.fling(expandedCard, const Offset(0, 240), 680);
        await tester.pumpAndSettle();

        expect(expandedCard, findsNothing);
      },
    );

    testWidgets(
      'Left Side Pane & StudioSettingsArchiveScreen configure 6M/12M photo retention, CAD retention, and export project-segmented photo hierarchy ZIP',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await StorageService.seedFillerProjectsIfEmpty();

        final auth = AuthProvider();
        auth.quickLoginAs(UserRole.proprietor);

        // Default photo retention is 6 months; default CAD retention is 12 months
        expect(auth.photoRetentionMonths, 6);
        expect(StorageService.getPhotoRetentionMonths(), 6);
        expect(auth.cadRetentionMonths, 12);

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const MaterialApp(
              home: MainDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Left Side Pane
        await tester.tap(find.byKey(const Key('left_side_pane_btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('studio_left_side_pane')), findsOneWidget);
        expect(find.byKey(const Key('side_pane_photo_retention_6m')), findsOneWidget);
        expect(find.byKey(const Key('side_pane_photo_retention_12m')), findsOneWidget);

        // Switch photo retention to 12 Months from Left Side Pane
        await tester.tap(find.byKey(const Key('side_pane_photo_retention_12m')));
        await tester.pumpAndSettle();
        expect(auth.photoRetentionMonths, 12);
        expect(StorageService.getPhotoRetentionMonths(), 12);

        // Verify 24M CAD retention option is removed and switch CAD retention to 6 Months
        expect(find.byKey(const Key('side_pane_cad_retention_24m')), findsNothing);
        await tester.tap(find.byKey(const Key('side_pane_cad_retention_6m')));
        await tester.pumpAndSettle();
        expect(auth.cadRetentionMonths, 6);
        expect(StorageService.getCadRetentionMonths(), 6);

        // Open full Studio Settings & Photo Archive screen from Left Side Pane
        final openSettingsBtn = find.byKey(const Key('side_pane_open_settings_btn'));
        await tester.ensureVisible(openSettingsBtn);
        await tester.tap(openSettingsBtn);
        await tester.pumpAndSettle();

        expect(find.text('Studio Settings & Media Archive'), findsOneWidget);
        expect(find.text('Project-Segmented Photo Hierarchy Archive'), findsOneWidget);
        expect(find.byKey(const Key('download_all_project_photos_btn')), findsOneWidget);

        // Verify PhotoArchiveService segments uploaded photos into per-project folders inside ZIP
        final exportResult =
            await PhotoArchiveService.downloadSegmentedProjectPhotosArchive(
          photoRetentionMonths: auth.photoRetentionMonths,
          cadRetentionMonths: auth.cadRetentionMonths,
        );
        expect(exportResult.manifest.totalProjects, greaterThanOrEqualTo(2));
        expect(exportResult.manifest.totalPhotos, greaterThanOrEqualTo(2));
        expect(exportResult.zipBytes, isNotEmpty);

        final decodedZip = ZipDecoder().decodeBytes(exportResult.zipBytes);
        final fileNames = decodedZip.files.map((f) => f.name).toList();
        expect(
          fileNames.any((n) => n.endsWith('backend_retention_manifest.json')),
          isTrue,
        );
        for (final folder in exportResult.manifest.projectFolders) {
          expect(
            fileNames.any((n) => n.contains('/${folder.folderName}/')),
            isTrue,
          );
        }
      },
    );
  });
}
