import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/team/views/team_view.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
    await StorageService.clearUsers();
  });

  Widget createTestWidget(Widget child, AuthProvider authProvider) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'Proprietor alone sees staff authorization alert banner on team screen',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authProvider = AuthProvider();
      authProvider.switchRole(UserRole.proprietor);

      await tester.pumpWidget(createTestWidget(const TeamView(), authProvider));
      await tester.pumpAndSettle();

      // Verify alert banner is visible on Proprietor team screen
      expect(find.text('STAFF ACTION REQUIRED'), findsOneWidget);
      expect(find.textContaining('Staff Registration'), findsOneWidget);
      expect(find.textContaining('Review & Authorize'), findsOneWidget);

      // Switch to Sales and verify banner is NOT present
      authProvider.switchRole(UserRole.sales);
      await tester.pumpWidget(createTestWidget(const TeamView(), authProvider));
      await tester.pumpAndSettle();

      expect(find.text('STAFF ACTION REQUIRED'), findsNothing);
      expect(find.textContaining('Review & Authorize'), findsNothing);
    },
  );

  testWidgets(
    'Proprietor can open staff governance sheet, approve pending user, and view active directory',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authProvider = AuthProvider();
      authProvider.switchRole(UserRole.proprietor);

      await tester.pumpWidget(createTestWidget(const TeamView(), authProvider));
      await tester.pumpAndSettle();

      final initialPendingCount = authProvider.pendingUsers.length;
      final initialApprovedCount = authProvider.approvedUsers.length;
      expect(initialPendingCount, greaterThan(0));

      // Tap Review & Authorize button
      final reviewBtn = find.textContaining('Review & Authorize');
      await tester.tap(reviewBtn.first);
      await tester.pumpAndSettle();

      // Verify Sheet is open
      expect(find.text('Executive Staff Access & Governance'), findsOneWidget);
      expect(find.textContaining('Pending Requests'), findsOneWidget);

      // Tap Approve Access on first pending applicant
      final approveBtn = find.widgetWithText(ElevatedButton, 'Approve Access');
      expect(approveBtn, findsWidgets);
      await tester.tap(approveBtn.first);
      await tester.pumpAndSettle();

      // Verify pending user count decreased and approved user count increased
      expect(authProvider.pendingUsers.length, initialPendingCount - 1);
      expect(authProvider.approvedUsers.length, initialApprovedCount + 1);

      // Switch to Active Directory tab
      final activeTab = find.textContaining('Active Directory');
      await tester.tap(activeTab);
      await tester.pumpAndSettle();

      // Verify Master Owner is protected and has Master Owner badge
      expect(find.text('Master Owner'), findsOneWidget);
    },
  );

  testWidgets(
    'Proprietor can dismiss active staff member and login access is revoked',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authProvider = AuthProvider();
      authProvider.switchRole(UserRole.proprietor);

      await tester.pumpWidget(createTestWidget(const TeamView(), authProvider));
      await tester.pumpAndSettle();

      // Open staff governance sheet on Active Directory tab
      final viewRosterBtn = find.textContaining('View Active Roster');
      await tester.tap(viewRosterBtn.first);
      await tester.pumpAndSettle();

      // Verify active directory is displayed
      expect(find.text('Executive Staff Access & Governance'), findsOneWidget);
      final dismissButtons = find.widgetWithText(
        OutlinedButton,
        'Dismiss Staff',
      );
      expect(dismissButtons, findsWidgets);

      // Dismiss first non-proprietor staff member (e.g. Kavita Reddy)
      final staffToDismiss = authProvider.approvedUsers.firstWhere(
        (u) => u.role != UserRole.proprietor,
      );
      final dismissedEmail = staffToDismiss.email;

      await tester.tap(dismissButtons.first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Revoke Staff Access?'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to dismiss'),
        findsOneWidget,
      );

      // Tap Confirm Dismissal
      final confirmBtn = find.widgetWithText(
        ElevatedButton,
        'Confirm Dismissal',
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify staff member is removed from approved list
      expect(
        authProvider.approvedUsers.any((u) => u.id == staffToDismiss.id),
        isFalse,
      );

      // Verify that dismissed employee cannot log in
      final loginResult = authProvider.login(dismissedEmail, 'password123');
      expect(loginResult, isFalse);
    },
  );
}
