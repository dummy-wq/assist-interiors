import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/projects/sheets/upload_render_sheet.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('CAD & Deliverables Upload Sheet Tests', () {
    testWidgets('UploadRenderSheet renders CAD file picker dropzone and formats', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadRenderSheet(
              preselectedProject: 'Magnolia Sanctuary',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and header
      expect(find.text('Upload Drawing or Render'), findsOneWidget);
      expect(find.text('2D Drawings, 3D Renders, Mood Boards & PDFs'), findsOneWidget);

      // Verify CAD file picker dropzone is present
      expect(find.text('SELECT CAD / 3D / BOQ FILE'), findsOneWidget);
      expect(find.text('Upload .DWG, .DXF, .MAX, .PDF, .XLSX, or Renders'), findsOneWidget);
      expect(find.text('Browse Device Storage'), findsOneWidget);

      // Verify deliverable format and type sections
      expect(find.text('DELIVERABLE TYPE'), findsOneWidget);
      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.text('Save Deliverable for Client Review'), findsOneWidget);
    });

    testWidgets('UploadRenderSheet submit emits deliverable payload to onUploaded callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? uploadedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadRenderSheet(
              preselectedProject: 'The Camellias Penthouse',
              onUploaded: (data) {
                uploadedResult = data;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify simplified sheet removes Deliverable Title & extra metadata fields
      expect(find.text('DELIVERABLE TITLE'), findsNothing);
      expect(find.text('VERSION TAG'), findsNothing);
      expect(find.text('CLIENT APPROVAL STATUS'), findsNothing);
      expect(find.text('TECHNICAL SPECIFICATION & REVISION NOTES'), findsNothing);

      // Tap Save Deliverable for Client Review button
      final submitButton = find.text('Save Deliverable for Client Review');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify onUploaded was called with simplified metadata
      expect(uploadedResult, isNotNull);
      expect(uploadedResult!['title'], 'CAD Drawing Deliverable');
      expect(uploadedResult!['version'], 'v1.0');
      expect(uploadedResult!['type'], 'CAD Drawing');
      expect(uploadedResult!['format'], '.DWG');
      expect(uploadedResult!['isUploaded'], isFalse); // False because no local file was selected in mock
    });

    testWidgets('ProjectsView Files tab displays non-image PDF and DWG files from design_items database', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await StorageService.saveProjects([
        {
          'id': 'proj_files_test',
          'name': 'Skyline Residence',
          'location': 'South Mumbai',
          'client': 'Arjun Mehta',
          'status': 'Ongoing',
          'budget': '₹ 80,00,000',
          'color': Colors.amber,
          'stages': [
            {'title': 'Design Sign-Off', 'isDone': false},
          ],
          'designAssets': <Map<String, dynamic>>[],
        },
      ]);

      await StorageService.saveDesignItems([
        {
          'id': 'asset_pdf_1',
          'title': 'Electrical Conduit Layout',
          'type': 'CAD Drawing',
          'project': 'Skyline Residence',
          'projectId': 'proj_files_test',
          'format': '.PDF',
          'version': 'v2.0',
          'fileSize': '4.2 MB',
          'status': 'Under Client Review',
          'fileName': 'electrical_conduit_layout.pdf',
          'isUploaded': true,
        },
        {
          'id': 'asset_dwg_2',
          'title': 'Master Bedroom Millwork',
          'type': 'CAD Drawing',
          'project': 'Skyline Residence',
          'projectId': 'proj_files_test',
          'format': '.DWG',
          'version': 'v1.0',
          'fileSize': '9.8 MB',
          'status': 'Approved by Client',
          'fileName': 'master_bedroom_millwork.dwg',
          'isUploaded': true,
        },
      ]);

      final auth = AuthProvider()..switchRole(UserRole.proprietor);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: Scaffold(body: ProjectsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      // Files tab should show count (2)
      expect(find.textContaining('Files (2)'), findsOneWidget);
      await tester.tap(find.textContaining('Files (2)'));
      await tester.pumpAndSettle();

      // Both non-image PDF and DWG files should be visible on the project card
      expect(find.text('Electrical Conduit Layout'), findsOneWidget);
      expect(find.text('Master Bedroom Millwork'), findsOneWidget);
      expect(find.text('.PDF'), findsOneWidget);
      expect(find.text('.DWG'), findsOneWidget);
    });
  });
}
