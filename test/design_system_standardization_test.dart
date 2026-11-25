import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/cloud_storage_service.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/widgets/screen_layout.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/main.dart';

Widget _buildWideTestApp({UserRole role = UserRole.proprietor}) {
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

  testWidgets(
    'Wide web layout standardizes sub-header bar and ScreenHeader left alignment across Hub and other tabs',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWideTestApp());
      await tester.pumpAndSettle();

      // Hub (Tab 0) renders standardized sub-header bar + ScreenHeader
      expect(find.text('EXECUTIVE STUDIO HUB'), findsOneWidget);
      final hubHeaderFinder = find.text('Executive Studio Hub');
      expect(hubHeaderFinder, findsOneWidget);
      final hubHeaderRect = tester.getRect(hubHeaderFinder);

      // Switch to Projects (Tab 2)
      await tester.tap(find.text('Projects').first);
      await tester.pumpAndSettle();

      expect(find.text('PROJECTS PORTFOLIO'), findsOneWidget);
      final projHeaderFinder = find.text('Projects Portfolio');
      expect(projHeaderFinder, findsOneWidget);
      final projHeaderRect = tester.getRect(projHeaderFinder);

      // Both headers must start at the exact same left X and top Y (zero vertical jump)
      expect(hubHeaderRect.left, closeTo(projHeaderRect.left, 0.5));
      expect(hubHeaderRect.top, closeTo(projHeaderRect.top, 0.5));
    },
  );

  testWidgets(
    'ResponsiveCardGrid renders 2 columns on wide desktop and 1 column on mobile',
    (tester) async {
      // Desktop (1200px) -> 2 side-by-side columns
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCardGrid(
              children: [
                SizedBox(key: Key('c1'), height: 80),
                SizedBox(key: Key('c2'), height: 80),
                SizedBox(key: Key('c3'), height: 80),
              ],
            ),
          ),
        ),
      );

      final c1Wide = tester.getRect(find.byKey(const Key('c1')));
      final c2Wide = tester.getRect(find.byKey(const Key('c2')));
      final c3Wide = tester.getRect(find.byKey(const Key('c3')));

      expect(c1Wide.top, equals(c2Wide.top));
      expect(c2Wide.left, greaterThan(c1Wide.right));
      expect(c1Wide.width, closeTo(c2Wide.width, 0.5));
      expect(c3Wide.width, closeTo(c1Wide.width, 0.5));

      // Mobile (400px) -> stacked 1 column
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      final c1Narrow = tester.getRect(find.byKey(const Key('c1')));
      final c2Narrow = tester.getRect(find.byKey(const Key('c2')));
      expect(c2Narrow.top, greaterThan(c1Narrow.bottom));
      expect(c1Narrow.left, equals(c2Narrow.left));
    },
  );

  test(
    'CloudStorageService preserves extensions and infers MIME types for new and legacy filenames',
    () {
      expect(
        CloudStorageService.safeFileName('Living Room Plan.pdf'),
        equals('Living_Room_Plan.pdf'),
      );
      expect(
        CloudStorageService.safeFileName('Floor Plan', format: '.PDF'),
        equals('Floor_Plan.pdf'),
      );
      expect(
        CloudStorageService.safeFileName(
          '1732482910_Floor_Plan_pdf',
          format: '.PDF',
        ),
        equals('1732482910_Floor_Plan.pdf'),
      );
      expect(
        CloudStorageService.inferContentType('Living Room Plan.pdf'),
        equals('application/pdf'),
      );
      expect(
        CloudStorageService.inferContentType(
          '1732482910_Floor_Plan_pdf',
          format: '.PDF',
        ),
        equals('application/pdf'),
      );
      expect(
        CloudStorageService.inferContentType('Schedule.xlsx'),
        equals(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      expect(
        CloudStorageService.inferContentType('Master_Render.png'),
        equals('image/png'),
      );
    },
  );
}
