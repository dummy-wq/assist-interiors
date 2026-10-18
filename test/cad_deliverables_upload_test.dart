import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/projects/sheets/upload_render_sheet.dart';

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
      expect(find.text('Upload Design Deliverable'), findsOneWidget);
      expect(find.text('CAD Drawings, 3D Renders, Mood Boards & BOQ'), findsOneWidget);

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

      // Fill in deliverable title and notes
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Update notes field
      await tester.enterText(textFields.at(2), 'Approved layout revisions for MEP & False ceiling');
      await tester.pumpAndSettle();

      // Tap Save Deliverable for Client Review button
      final submitButton = find.text('Save Deliverable for Client Review');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify onUploaded was called with expected metadata
      expect(uploadedResult, isNotNull);
      expect(uploadedResult!['title'], '3D Photorealistic Render & BOQ');
      expect(uploadedResult!['version'], 'v1.0');
      expect(uploadedResult!['type'], 'CAD Drawing');
      expect(uploadedResult!['format'], '.DWG');
      expect(uploadedResult!['notes'], 'Approved layout revisions for MEP & False ceiling');
      expect(uploadedResult!['isUploaded'], isFalse); // False because no local file was selected in mock
    });
  });
}
