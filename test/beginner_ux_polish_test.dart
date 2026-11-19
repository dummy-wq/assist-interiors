import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/localization/app_strings.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/theme/app_sizes.dart';
import 'package:assist_interiors_dashboard/core/widgets/pill_box.dart';
import 'package:assist_interiors_dashboard/core/widgets/role_onboarding_guide.dart';
import 'package:assist_interiors_dashboard/core/widgets/sync_status_badge.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';
import 'package:assist_interiors_dashboard/features/team/widgets/reset_password_dialog.dart';
import 'package:assist_interiors_dashboard/features/team/widgets/staff_management_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
    await StorageService.clearUsers();
  });

  test('Production AuthProvider starts with empty studio (only Master Proprietor)', () {
    final prodAuth = AuthProvider(autoDemoLogin: false);
    expect(prodAuth.shouldShowOnboardingTips, isTrue);
    expect(prodAuth.approvedUsers.length, equals(1));
    expect(prodAuth.approvedUsers.first.id, equals('USR-001'));
    expect(prodAuth.approvedUsers.first.role, equals(UserRole.proprietor));
    expect(prodAuth.pendingUsers, isEmpty);
    expect(StorageService.getProjects(), isEmpty);
    expect(StorageService.getLeads(), isEmpty);
  });

  test('Proprietor resetStaffPassword updates staff credentials & login works with new password', () {
    final auth = AuthProvider(autoDemoLogin: true);
    auth.switchRole(UserRole.proprietor);

    final supervisor =
        auth.approvedUsers.firstWhere((u) => u.role == UserRole.supervisor);

    final ok = auth.resetStaffPassword(
      userId: supervisor.id,
      newPassword: 'NewSitePass99',
    );
    expect(ok, isTrue);

    auth.logout();
    final wrongLogin = auth.login(supervisor.email, 'WrongOldPass');
    expect(wrongLogin, isFalse);

    final newLogin = auth.login(supervisor.email, 'NewSitePass99');
    expect(newLogin, isTrue);
    expect(auth.currentUser?.id, equals(supervisor.id));
  });

  test('Text scale factor updates and persists via StorageService', () {
    final auth = AuthProvider(autoDemoLogin: true);
    expect(auth.textScaleFactor, equals(1.0));

    auth.setTextScaleFactor(1.15);
    expect(auth.textScaleFactor, equals(1.15));
    expect(StorageService.getTextScaleFactor(), equals(1.15));
  });

  test('Plain English labels map confusing jargon consistently', () {
    expect(AppStrings.tr('Upload BOQ'), equals('Upload Material List'));
    expect(AppStrings.tr('Add Amendment'), equals('New Change Request'));
    expect(AppStrings.tr('Take Site Photo'), equals('Take Site Photo'));
  });

  testWidgets('SyncStatusBadge renders readable status cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusBadge())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('⚠ Offline – will sync later'), findsOneWidget);
  });

  testWidgets('RoleOnboardingGuide displays tailored quick tips and navigates steps', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => RoleOnboardingGuide.show(
                  context,
                  role: UserRole.supervisor,
                  force: true,
                ),
                child: const Text('Open Guide'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Guide'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/4'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2/4'), findsOneWidget);
    expect(find.text('Simple Bottom Tabs'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3/4'), findsOneWidget);
    expect(find.textContaining('Take Site Photo'), findsWidgets);
  });

  testWidgets('ResetStaffPasswordDialog validates & resets password', (tester) async {
    final auth = AuthProvider(autoDemoLogin: true);
    auth.switchRole(UserRole.proprietor);
    final staff = auth.approvedUsers.firstWhere((u) => u.role == UserRole.designer);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ResetStaffPasswordDialog.show(context, targetUser: staff),
                child: const Text('Open Reset'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsWidgets);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Design@2027');
    await tester.enterText(fields.at(1), 'Design@2027');
    await tester.tap(find.text('Reset Password').last);
    await tester.pumpAndSettle();

    auth.logout();
    expect(auth.login(staff.email, 'Design@2027'), isTrue);
  });

  testWidgets('Expanded project card filters tabs by role and supports Undo photo delete', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await StorageService.saveProjects([
      {
        'id': 'proj_ux_1',
        'name': 'Maple Residency',
        'client': 'Kiran Rao',
        'budget': '₹ 40,00,000',
        'spent': '₹ 12,00,000',
        'pm': 'Vikram',
        'supervisor': 'Suresh',
        'handover': 'Dec 2026',
        'status': 'Active',
        'progress': 0.5,
        'stages': <Map<String, dynamic>>[],
        'photos': [
          {
            'id': 'ph_ux_1',
            'title': 'False ceiling grid check',
            'tag': 'Living Room',
            'timestamp': '10 Nov 2026, 02:30 PM',
            'capturedBy': 'Suresh',
            'note': 'Framing complete',
            'milestone': 'Ceiling',
          },
        ],
        'designAssets': <Map<String, dynamic>>[],
      },
    ]);

    // 1. Supervisor sees Progress, Photos, Files and NOT Billing
    final supAuth = AuthProvider(autoDemoLogin: true);
    supAuth.switchRole(UserRole.supervisor);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: supAuth,
        child: const MaterialApp(
          home: Scaffold(body: ProjectsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expandFinder = find.text('Tap to view Progress, Photos & Files');
    await tester.ensureVisible(expandFinder);
    await tester.tap(expandFinder);
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.textContaining('Photos (1)'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Billing'), findsNothing);

    // 2. Open Photos tab, open photo viewer, remove photo, and tap Undo
    await tester.tap(find.textContaining('Photos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('False ceiling grid check'), findsOneWidget);

    await tester.tap(find.text('False ceiling grid check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Photo removed'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(StorageService.getProjects().first['photos'], isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((StorageService.getProjects().first['photos'] as List).length, equals(1));
  });

  testWidgets('StaffManagementSheet buttons and PillBox chips share uniform sizes', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final auth = AuthProvider(autoDemoLogin: true);
    auth.switchRole(UserRole.proprietor);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PillBox(
                  label: 'Short',
                  isSelected: true,
                  onSelected: () {},
                ),
                PillBox(
                  label: 'Icon Filter Chip',
                  icon: Icons.filter_list_rounded,
                  isSelected: false,
                  onSelected: () {},
                ),
                const Expanded(child: StaffManagementSheet(initialTabIndex: 1)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all PillBoxes share exact 35.0 height
    final chip1 = tester.getRect(find.byType(PillBox).at(0));
    final chip2 = tester.getRect(find.byType(PillBox).at(1));
    expect(chip1.height, equals(AppSizes.chipHeight));
    expect(chip2.height, equals(AppSizes.chipHeight));

    // Verify Active Directory buttons share uniform equal width, top, and 38.0 height matching Pending Requests
    final editRect = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Edit Role & Access').first,
    );
    final resetRect = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Reset Password').first,
    );
    final dismissRect = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Dismiss Staff').first,
    );
    expect(editRect.top, closeTo(resetRect.top, 0.5));
    expect(resetRect.top, closeTo(dismissRect.top, 0.5));
    expect(editRect.height, closeTo(AppSizes.compactButtonHeight, 0.5));
    expect(resetRect.height, closeTo(AppSizes.compactButtonHeight, 0.5));
    expect(dismissRect.height, closeTo(AppSizes.compactButtonHeight, 0.5));
    expect(editRect.width, closeTo(resetRect.width, 1.0));
    expect(resetRect.width, closeTo(dismissRect.width, 1.0));
  });
}
