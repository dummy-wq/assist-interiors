import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/main.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/permissions/app_permissions.dart';
import 'package:assist_interiors_dashboard/core/models/project_model.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/utils/app_notification.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/projects/sheets/take_site_photo_sheet.dart';

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
    AppNotification.resetCooldown();
  });

  group('Site Photos Permissions & RBAC Matrix', () {
    test('Operations roles are authorized to capture and delete site photos', () {
      expect(AppPermissions.canAddProjectPhotos(UserRole.proprietor), isTrue);
      expect(AppPermissions.canAddProjectPhotos(UserRole.projectManager), isTrue);
      expect(AppPermissions.canAddProjectPhotos(UserRole.designer), isTrue);
      expect(AppPermissions.canAddProjectPhotos(UserRole.supervisor), isTrue);
    });

    test('Commercial and Accounts roles have strictly read-only access to site photos', () {
      expect(AppPermissions.canAddProjectPhotos(UserRole.sales), isFalse);
      expect(AppPermissions.canAddProjectPhotos(UserRole.accounts), isFalse);
    });
  });

  group('ProjectModel and StorageService Photo Serialization', () {
    test('ProjectModel serializes and deserializes photos list correctly', () {
      final samplePhotos = [
        {
          'id': 'photo_test_1',
          'title': 'Kitchen Island Granite Fitting',
          'tag': 'Kitchen Area',
          'timestamp': '14 Oct 2026, 11:30 AM',
          'note': 'Verified edge profile and sink cut-out.',
          'milestone': 'Carpentry & Joinery',
          'isLocal': true,
        },
      ];

      final project = ProjectModel(
        id: 'proj_test_photo',
        name: 'Penthouse 902 Luxury Fitout',
        location: 'Indiranagar',
        createdAt: DateTime.now(),
        photos: samplePhotos,
      );

      final map = project.toMap();
      expect(map['photos'], isA<List>());
      expect((map['photos'] as List).length, equals(1));
      expect((map['photos'] as List).first['title'], equals('Kitchen Island Granite Fitting'));

      final reconstructed = ProjectModel.fromMap(map);
      expect(reconstructed.photos.length, equals(1));
      expect(reconstructed.photos.first['id'], equals('photo_test_1'));
      expect(reconstructed.photos.first['milestone'], equals('Carpentry & Joinery'));
    });

    test('StorageService persists and restores project photos across restarts', () async {
      final projectsWithPhotos = [
        {
          'id': 'proj_persisted_1',
          'name': 'Villa Verde Master Suite',
          'client': 'Ayesha Khan',
          'stage': 'Woodwork & Joinery',
          'progress': 0.75,
          'photos': [
            {
              'id': 'ph_v1',
              'title': 'Wardrobe carcass installation',
              'tag': 'Master Bedroom',
              'timestamp': '12 Oct 2026, 04:15 PM',
              'note': 'Checked alignment and hinge clearances.',
              'milestone': 'Carpentry & Joinery',
            }
          ],
        }
      ];

      await StorageService.saveProjects(projectsWithPhotos);
      final restored = StorageService.getProjects();
      expect(restored, isNotEmpty);
      expect(restored.first['photos'], isNotNull);
      final photos = (restored.first['photos'] as List);
      expect(photos.length, equals(1));
      expect(photos.first['title'], equals('Wardrobe carcass installation'));
    });
  });

  group('ProjectsView Site Photos UI & Interactive Flow', () {
    testWidgets('Operations role sees Take Photo button and photo gallery in ProjectsView', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(role: UserRole.proprietor));
      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Projects Portfolio'), findsOneWidget);

      // Verify SITE INSPECTION PHOTOS header is displayed
      expect(find.text('SITE INSPECTION PHOTOS'), findsWidgets);

      // Verify unified Add Photo button is present for proprietor without redundant buttons
      expect(find.text('Add Photo'), findsWidgets);
      expect(find.text('Upload Photo'), findsNothing);
    });

    testWidgets('Sales role sees gallery without Add Photo or Upload Photo buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(role: UserRole.sales));
      await tester.pumpAndSettle();

      // Navigate to Projects view
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Projects Portfolio'), findsOneWidget);

      // Verify SITE INSPECTION PHOTOS header exists
      expect(find.text('SITE INSPECTION PHOTOS'), findsWidgets);

      // Add Photo button should NOT exist for Sales
      expect(find.text('Add Photo'), findsNothing);
      expect(find.text('Upload Photo'), findsNothing);
    });

    testWidgets('Tapping Add Photo opens TakeSitePhotoSheet and adds photo to project', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(role: UserRole.proprietor));
      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      // Tap Add Photo button on the first card
      final addPhotoButton = find.text('Add Photo').first;
      await tester.ensureVisible(addPhotoButton);
      await tester.tap(addPhotoButton);
      await tester.pumpAndSettle();

      // Verify TakeSitePhotoSheet modal opened
      expect(find.text('OPTICAL VIEWFINDER • LIVE SITE CAMERA'), findsOneWidget);
      expect(find.text('Save & Attach Photo to Project'), findsOneWidget);

      // Select an area tag
      final kitchenChip = find.text('Kitchen');
      if (kitchenChip.evaluate().isNotEmpty) {
        await tester.tap(kitchenChip.first);
        await tester.pumpAndSettle();
      }

      // Enter a custom note
      final noteField = find.byType(TextField);
      if (noteField.evaluate().isNotEmpty) {
        await tester.enterText(noteField.first, 'Verified modular kitchen carcase finish');
        await tester.pumpAndSettle();
      }

      // Tap Save & Attach button
      final attachBtn = find.text('Save & Attach Photo to Project');
      expect(attachBtn, findsOneWidget);
      await tester.tap(attachBtn);
      await tester.pumpAndSettle();

      // Verify sheet is closed and notification appears
      expect(find.text('OPTICAL VIEWFINDER • LIVE SITE CAMERA'), findsNothing);
      expect(find.textContaining('Site inspection photo added to'), findsOneWidget);
    });

    testWidgets('TakeSitePhotoSheet in upload mode displays upload source actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(role: UserRole.proprietor));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      TakeSitePhotoSheet.show(
        context,
        project: {'name': 'The Camellias Penthouse'},
        initialUploadMode: true,
        onPhotoAdded: (_) {},
      );
      await tester.pumpAndSettle();

      // Verify TakeSitePhotoSheet modal opened in Upload Mode
      expect(find.textContaining('Upload Mode: Choose an existing photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Save & Attach Photo to Project'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping an existing photo card opens ProjectPhotoViewerDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(role: UserRole.proprietor));
      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      // Find seeded photo titles (e.g., 'Living Room Framing & False Ceiling')
      final photoCard = find.text('Living Room Framing & False Ceiling');
      expect(photoCard, findsOneWidget);

      await tester.ensureVisible(photoCard);
      await tester.tap(photoCard);
      await tester.pumpAndSettle();

      // Verify viewer dialog opened with technical details
      expect(find.text('ASSIST INTERIORS • VERIFIED SITE PHOTO'), findsOneWidget);
      expect(find.text('Zone: Living Room'), findsOneWidget);
      expect(find.text('Cloud Synced'), findsOneWidget);

      // Close viewer dialog
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.text('ASSIST INTERIORS • VERIFIED SITE PHOTO'), findsNothing);
    });
  });
}
