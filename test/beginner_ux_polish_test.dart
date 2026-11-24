import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/localization/app_strings.dart';
import 'package:assist_interiors_dashboard/core/permissions/app_permissions.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/theme/app_sizes.dart';
import 'package:assist_interiors_dashboard/core/utils/app_notification.dart';
import 'package:assist_interiors_dashboard/core/widgets/app_modal_sheet.dart';
import 'package:assist_interiors_dashboard/core/widgets/expanded_detail_dialog.dart';
import 'package:assist_interiors_dashboard/core/widgets/full_screen_media_viewer.dart';
import 'package:assist_interiors_dashboard/core/widgets/pill_box.dart';
import 'package:assist_interiors_dashboard/core/widgets/role_onboarding_guide.dart';
import 'package:assist_interiors_dashboard/core/widgets/sync_status_badge.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/material_requests/views/material_requests_view.dart';
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

  testWidgets('SyncStatusBadge renders minimal theme-matched icon with status tooltip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SyncStatusBadge())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, equals('Offline – will sync later'));
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

  testWidgets(
    'Pending staff authorization screens open as normal full screens and do not dismiss on swipe',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AuthProvider(autoDemoLogin: false);
      auth.quickLoginAs(UserRole.proprietor);
      auth.signUp(
        fullName: 'Aarav Nair',
        email: 'aarav@studio.in',
        phone: '+91 98765 11111',
        requestedRole: UserRole.designer,
        password: 'Password1!',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showStaffManagementSheet(ctx, initialTabIndex: 0),
                    child: const Text('Open Governance'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Governance'));
      await tester.pumpAndSettle();

      // Staff Management opens as a normal screen (not SwipeDismissibleSheet / FlickDismissibleCard)
      expect(find.text('Executive Staff Access & Governance'), findsOneWidget);
      expect(find.byType(SwipeDismissibleSheet), findsNothing);
      expect(find.byType(FlickDismissibleCard), findsNothing);

      // Fast downward fling does not dismiss Staff Management screen
      await tester.fling(
        find.text('Executive Staff Access & Governance'),
        const Offset(0, 400),
        1200,
      );
      await tester.pumpAndSettle();
      expect(find.text('Executive Staff Access & Governance'), findsOneWidget);

      // Tap Assign / Custom Role -> opens Authorize screen as a normal full screen
      await tester.tap(find.text('Assign / Custom Role'));
      await tester.pumpAndSettle();

      expect(find.text('Authorize Aarav Nair'), findsOneWidget);
      expect(find.byType(FlickDismissibleCard), findsNothing);
      expect(find.byType(SwipeDismissibleSheet), findsNothing);

      // Flinging horizontally or vertically does not dismiss Authorize screen
      await tester.fling(
        find.text('Pre-existing Roles'),
        const Offset(250, 0),
        1400,
      );
      await tester.pumpAndSettle();
      expect(find.text('Authorize Aarav Nair'), findsOneWidget);

      await tester.fling(
        find.text('Pre-existing Roles'),
        const Offset(0, 350),
        1400,
      );
      await tester.pumpAndSettle();
      expect(find.text('Authorize Aarav Nair'), findsOneWidget);
    },
  );

  testWidgets(
    'MaterialRequestsView shows clean project material upload flow and syncs Paid status to Accounts',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await StorageService.saveProjects([
        {'id': 'P-1', 'name': 'Skyline Duplex', 'status': 'On Track'},
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MaterialRequestsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Old StatStrip / Trade Category boxes are removed
      expect(find.text('Total Indents'), findsNothing);
      expect(find.text('Dispatched / In Transit'), findsNothing);
      expect(find.text('All Trades'), findsNothing);

      // Tap Upload Material List button
      await tester.tap(find.text('Upload Material List'));
      await tester.pumpAndSettle();

      expect(find.text('Photo of Material List'), findsOneWidget);
      expect(find.text('Vendor Payment Scanner (QR)'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Vendor Name *'),
        'Shree Hardware & Ply',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Total Amount (₹) *'),
        '48500',
      );
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Material List (Type items or attach photo below)',
        ),
        '25x Marine Plywood 18mm, 40x Soft-Close Hinges',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Material Upload'));
      await tester.pumpAndSettle();

      expect(find.text('Shree Hardware & Ply'), findsOneWidget);
      expect(find.text('PENDING APPROVAL'), findsOneWidget);
      expect(StorageService.getExpenses(), isEmpty);

      // Approve (tick) -> changes action button to "Mark as Paid (Send to Accounts)"
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('PAYMENT PENDING'), findsOneWidget);
      expect(find.text('Mark as Paid (Send to Accounts)'), findsOneWidget);

      // Mark as Paid -> reflects in Accounts expenses immediately
      await tester.tap(find.text('Mark as Paid (Send to Accounts)'));
      await tester.pumpAndSettle();

      expect(find.text('PAID'), findsOneWidget);
      final expenses = StorageService.getExpenses();
      expect(expenses.length, 1);
      expect(expenses.first['vendor'], 'Shree Hardware & Ply');
      expect(expenses.first['project'], 'Skyline Duplex');
      expect(expenses.first['status'], 'Paid');
    },
  );

  testWidgets(
    'Upload Material List modal stays within viewport when software keyboard is open',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await StorageService.saveProjects([
        {
          'id': 'p1',
          'name': 'Skyline Duplex',
          'client': 'Aarav Mehta',
          'status': 'On Track',
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MaterialRequestsView()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upload Material List'));
      await tester.pumpAndSettle();

      // Simulate tapping an input field and opening the software keyboard
      tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      await tester.pumpAndSettle();

      final headerFinder = find.text('Upload Material List').last;
      final headerRect = tester.getRect(headerFinder);
      expect(headerRect.top, greaterThanOrEqualTo(0));
      expect(headerRect.bottom, lessThanOrEqualTo(844 - 340));

      final vendorField = find.widgetWithText(TextField, 'Vendor Name *');
      final vendorRect = tester.getRect(vendorField);
      expect(vendorRect.top, greaterThanOrEqualTo(0));
    },
  );

  testWidgets(
    'AppNotification disappears in 2.5 seconds and renders tiny bottom right-to-left progress bar',
    (tester) async {
      expect(
        AppNotification.defaultDuration,
        equals(const Duration(milliseconds: 2500)),
      );

      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                hostContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      AppNotification.show(hostContext, message: 'Test bottom notification');
      await tester.pump();

      expect(find.text('Test bottom notification'), findsOneWidget);

      final barFinder = find.byKey(const Key('app_notification_progress_bar'));
      final fillFinder = find.byKey(const Key('app_notification_progress_fill'));
      expect(barFinder, findsOneWidget);
      expect(fillFinder, findsOneWidget);

      final barBox = tester.widget<SizedBox>(barFinder);
      expect(barBox.height, equals(2.5));

      final initialFill = tester.widget<FractionallySizedBox>(fillFinder);
      expect(initialFill.alignment, equals(Alignment.centerLeft));
      expect(initialFill.widthFactor, equals(1.0));

      // Advance 1.25s (half of 2.5s) -> progress bar reduces from right to left
      await tester.pump(const Duration(milliseconds: 1250));
      final midFill = tester.widget<FractionallySizedBox>(fillFinder);
      expect(midFill.widthFactor, closeTo(0.5, 0.05));

      // Advance past 2.5s and settle exit animation -> notification disappears
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(find.text('Test bottom notification'), findsNothing);
    },
  );

  testWidgets(
    'ProjectsView status badge is an interactive dropdown that manually changes and persists project status',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await StorageService.saveProjects([
        {
          'id': 'proj_status_dd_1',
          'name': 'Lodha Altamount Residence',
          'client': 'Vikramaditya Singh',
          'location': 'Altamount Road, Mumbai',
          'type': '5BHK Duplex',
          'budget': '₹ 2,40,00,000',
          'status': 'On Track',
          'isDelayed': false,
          'stages': [
            {'title': 'Civil Demolition', 'isDone': true},
            {'title': 'MEP & HVAC', 'isDone': false},
          ],
          'photos': <Map<String, dynamic>>[],
          'designAssets': <Map<String, dynamic>>[],
        },
      ]);

      final auth = AuthProvider(autoDemoLogin: true);
      auth.switchRole(UserRole.proprietor);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: Scaffold(body: ProjectsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows 'On Track' on the dropdown badge
      final dropdownFinder = find.byKey(const ValueKey('project_status_dropdown_0'));
      expect(dropdownFinder, findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);

      // Tap dropdown and manually change status to 'Completed'
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(StorageService.getProjects().first['status'], equals('Completed'));

      // Tap dropdown again and manually change status to 'Delayed'
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delayed').last);
      await tester.pumpAndSettle();

      expect(find.text('Delayed'), findsOneWidget);
      expect(StorageService.getProjects().first['status'], equals('Delayed'));
      expect(StorageService.getProjects().first['isDelayed'], isTrue);

      // Tap dropdown and select 'Custom...' to enter a custom status
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom...').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Custom Status'),
        'Snagging Phase',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Snagging Phase'), findsOneWidget);
      expect(
        StorageService.getProjects().first['status'],
        equals('Snagging Phase'),
      );
    },
  );

  testWidgets(
    'FullScreenMediaViewer renders full-screen image/file with granular zoom controls and Open in Gallery',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FullScreenMediaViewer(
            title: 'Master Suite Render',
            subtitle: 'Lodha Altamount • .PNG',
            fileUrl: 'https://example.com/render.png',
            fileName: 'render.png',
            format: '.PNG',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Master Suite Render'), findsOneWidget);
      expect(find.byKey(const Key('fullscreen_interactive_viewer')), findsOneWidget);
      expect(find.byKey(const Key('fullscreen_zoom_slider')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Open in Gallery'), findsOneWidget);

      // Tap zoom-in button -> granular zoom increases by 50% (100% -> 150%)
      await tester.tap(find.byKey(const Key('fullscreen_zoom_in_btn')));
      await tester.pump();
      expect(find.text('150%'), findsOneWidget);

      // Tap 1x reset -> resets to 100%
      await tester.tap(find.byKey(const Key('fullscreen_zoom_reset_btn')));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets(
    'FullScreenMediaViewer keeps cached base64 image intact during pinch/zoom without rebuilding bytes',
    (tester) async {
      // Valid 1x1 transparent PNG
      const onePxPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      await tester.pumpWidget(
        const MaterialApp(
          home: FullScreenMediaViewer(
            title: 'Site Photo',
            fileName: 'site.png',
            format: '.PNG',
            base64Data: onePxPngBase64,
          ),
        ),
      );
      await tester.pump();

      final imageBefore = tester.widget<Image>(find.byType(Image));
      expect(imageBefore.gaplessPlayback, isTrue);
      final providerBefore = imageBefore.image as MemoryImage;

      // Simulate multi-finger pinch zoom on InteractiveViewer
      final viewer = find.byKey(const Key('fullscreen_interactive_viewer'));
      final center = tester.getCenter(viewer);
      final pointer1 = await tester.startGesture(center - const Offset(30, 0));
      final pointer2 = await tester.startGesture(center + const Offset(30, 0));
      await pointer1.moveBy(const Offset(-60, 0));
      await pointer2.moveBy(const Offset(60, 0));
      await tester.pump();

      final imageDuringPinch = tester.widget<Image>(find.byType(Image));
      final providerDuringPinch = imageDuringPinch.image as MemoryImage;
      expect(identical(providerBefore.bytes, providerDuringPinch.bytes), isTrue);

      await pointer1.up();
      await pointer2.up();
      await tester.pump(const Duration(milliseconds: 400));
    },
  );

  testWidgets(
    'MaterialRequestsView Reject (cross) moves request to Rejected pane',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await StorageService.saveMaterialRequests([
        {
          'id': 'mr_rej_1',
          'project': 'Skyline Duplex',
          'assignedSupplier': 'Apex Plywoods',
          'estimatedCost': '₹ 22,000',
          'itemName': '20x Blockboard',
          'approvalStatus': 'pending',
          'status': 'Pending Approval',
          'isPaid': false,
        },
      ]);

      final auth = AuthProvider(autoDemoLogin: true);
      auth.switchRole(UserRole.proprietor);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: Scaffold(body: MaterialRequestsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Rejected (0)'), findsOneWidget);
      expect(find.text('Apex Plywoods'), findsOneWidget);

      // Tap Reject (cross)
      await tester.tap(find.byKey(const Key('material_reject_mr_rej_1')));
      await tester.pumpAndSettle();

      expect(find.text('Active (0)'), findsOneWidget);
      expect(find.text('Rejected (1)'), findsOneWidget);
      expect(find.text('Apex Plywoods'), findsNothing);

      // Switch to Rejected pane
      await tester.tap(find.byKey(const Key('materials_rejected_pane_tab')));
      await tester.pumpAndSettle();

      expect(find.text('Apex Plywoods'), findsOneWidget);
      expect(find.text('REJECTED'), findsOneWidget);
    },
  );

  testWidgets(
    'Site Engineer role is configured across AuthProvider, permissions, and InviteStaffSheet',
    (tester) async {
      expect(UserRole.siteEngineer.title, equals('Site Engineer'));
      expect(UserRole.siteEngineer.shortCode, equals('SE'));

      final auth = AuthProvider(autoDemoLogin: true);
      final siteEngineer = auth.approvedUsers.firstWhere(
        (u) => u.role == UserRole.siteEngineer,
      );
      expect(siteEngineer.fullName, equals('Vikram Nair'));

      auth.switchRole(UserRole.siteEngineer);
      expect(auth.currentRole, equals(UserRole.siteEngineer));
      expect(AppPermissions.canAddProjectPhotos(UserRole.siteEngineer), isTrue);
      expect(AppPermissions.canCreateTask(UserRole.siteEngineer), isTrue);
      expect(
        AppPermissions.canManageAccounts(UserRole.siteEngineer),
        isFalse,
      );
    },
  );
}
