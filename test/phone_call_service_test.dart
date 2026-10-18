import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/phone_call_service.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/sales/sheets/schedule_call_sheet.dart';
import 'package:assist_interiors_dashboard/features/team/views/team_view.dart';
import 'package:assist_interiors_dashboard/features/vendors/views/vendors_view.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
  });

  group('PhoneCallService Unit Tests', () {
    test('cleanPhoneNumber formats standard and international phone numbers', () {
      expect(PhoneCallService.cleanPhoneNumber('+91 98765-43210'), '+919876543210');
      expect(PhoneCallService.cleanPhoneNumber('(555) 123-4567'), '5551234567');
      expect(PhoneCallService.cleanPhoneNumber('+1 (800) 555-0199'), '+18005550199');
      expect(PhoneCallService.cleanPhoneNumber('  98450 11223  '), '9845011223');
      expect(PhoneCallService.cleanPhoneNumber('invalid-chars-only!#@'), '');
      expect(PhoneCallService.cleanPhoneNumber(''), '');
    });

    testWidgets('dialNumber returns false without error on empty or invalid phone number',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    final result = await PhoneCallService.dialNumber(
                      context,
                      phoneNumber: '   ',
                      contactName: 'Unknown',
                    );
                    expect(result, isFalse);
                  },
                  child: const Text('Dial Empty'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dial Empty'));
      await tester.pumpAndSettle();
      expect(find.text('No valid phone number found to dial.'), findsOneWidget);
    });
  });

  group('Dialer Redirection UI Triggers', () {
    Widget buildTestHarness(Widget child, {UserRole role = UserRole.proprietor}) {
      final auth = AuthProvider();
      auth.switchRole(role);

      return ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('TeamView has interactive phone dial icon for staff members',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestHarness(const TeamView()));
      await tester.pumpAndSettle();

      final phoneButtons = find.byIcon(Icons.phone_outlined);
      expect(phoneButtons, findsAtLeastNWidgets(1));

      // Tap first member's dial button
      await tester.tap(phoneButtons.first);
      await tester.pumpAndSettle();
    });

    testWidgets('VendorsView displays clickable vendor phone chip',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.saveVendors([
        {
          'id': 'v-1',
          'name': 'Greenply Plywoods',
          'contactPerson': 'Mr. Rajesh',
          'phone': '+91 98450 11223',
          'email': 'rajesh@greenply.com',
          'category': 'Plywood',
          'rating': 4.8,
          'status': 'Active',
          'openPOs': 2,
          'amountDue': '₹ 1,45,000',
        }
      ]);

      await tester.pumpWidget(buildTestHarness(const VendorsView()));
      await tester.pumpAndSettle();

      final vendorPhoneIcons = find.byIcon(Icons.phone_outlined);
      expect(vendorPhoneIcons, findsAtLeastNWidgets(1));

      // Tap first vendor phone chip
      await tester.tap(vendorPhoneIcons.first);
      await tester.pumpAndSettle();
    });

    testWidgets('ScheduleCallSheet provides Direct Dial button for lead',
        (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScheduleCallSheet.show(
                      context,
                      {
                        'id': 'lead-999',
                        'client': 'Sanjay Verma',
                        'phone': '+91 98450 12345',
                        'notes': [],
                      },
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Direct Dial (+91 98450 12345)'), findsOneWidget);

      await tester.tap(find.textContaining('Direct Dial'));
      await tester.pumpAndSettle();
    });
  });
}
