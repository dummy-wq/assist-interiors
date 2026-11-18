import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/theme/app_colors.dart';
import 'package:assist_interiors_dashboard/core/models/project_model.dart';
import 'package:assist_interiors_dashboard/core/services/spreadsheet_service.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/projects/dialogs/project_timeline_sheet_dialog.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';
import 'package:assist_interiors_dashboard/features/sales/sheets/add_lead_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
  });

  Widget createTestWidget(
    Widget child, {
    UserRole role = UserRole.projectManager,
  }) {
    final authProvider = AuthProvider();
    authProvider.switchRole(role);

    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('SpreadsheetService & SpreadsheetData Unit Tests', () {
    test('generateDefaultTimelineForProject generates 12 turnkey activities', () {
      final sheet = SpreadsheetService.generateDefaultTimelineForProject(
        'DLF Magnolias Penthouse',
      );

      expect(sheet.fileName, contains('DLF_Magnolias_Penthouse_Timeline_Schedule.xlsx'));
      expect(sheet.sheetName, equals('Master Timeline'));
      expect(sheet.headers.length, equals(9));
      expect(sheet.headers, contains('WBS'));
      expect(sheet.headers, contains('Milestone & Site Activity'));
      expect(sheet.headers, contains('Trade / Agency'));
      expect(sheet.headers, contains('Status'));
      expect(sheet.rows.length, equals(12));

      // Verify WBS structure
      expect(sheet.rows[0][0], equals('1.1'));
      expect(sheet.rows[0][1], contains('As-Built 3D Laser Scanning'));
      expect(sheet.rows[0][7], equals('Completed'));

      // Verify task metrics
      expect(sheet.totalTasks, equals(12));
      expect(sheet.completedTasks, greaterThanOrEqualTo(1));
      expect(sheet.inProgressTasks, greaterThanOrEqualTo(1));
      expect(sheet.criticalTasks, greaterThan(0));
      expect(sheet.overallProgress, greaterThan(0.0));
      expect(sheet.overallProgress, lessThanOrEqualTo(1.0));
    });

    test('parseCsvString correctly parses rows and quoted fields', () {
      const csvText =
          'WBS,Task,Trade,Status\n'
          '1.0,"Site Survey & 3D Scanning",Architecture,Completed\n'
          '2.0,"Civil & Masonry",Masonry,In Progress\n';

      final sheet = SpreadsheetService.parseCsvString(
        csvText,
        fileName: 'imported_timeline.csv',
      );

      expect(sheet.fileName, equals('imported_timeline.csv'));
      expect(sheet.headers, equals(['WBS', 'Task', 'Trade', 'Status']));
      expect(sheet.rows.length, equals(2));
      expect(sheet.rows[0][1], equals('Site Survey & 3D Scanning'));
      expect(sheet.rows[1][1], equals('Civil & Masonry'));
      expect(sheet.rows[1][3], equals('In Progress'));
    });

    test('SpreadsheetData serializes toMap and fromMap accurately', () {
      final original = SpreadsheetService.generateDefaultTimelineForProject(
        'Villa Royale',
      );
      final map = original.toMap();

      final restored = SpreadsheetData.fromMap(map);
      expect(restored.fileName, equals(original.fileName));
      expect(restored.sheetName, equals(original.sheetName));
      expect(restored.headers, equals(original.headers));
      expect(restored.rows.length, equals(original.rows.length));
      expect(restored.totalTasks, equals(original.totalTasks));
      expect(restored.overallProgress, equals(original.overallProgress));
    });
  });

  group('ProjectModel & StorageService Spreadsheet Integration', () {
    test('ProjectModel stores and exposes timelineSpreadsheet', () {
      final defaultSheet = SpreadsheetService.generateDefaultTimelineForProject(
        'Apex Tower Suite',
      );
      final project = ProjectModel(
        id: 'proj_101',
        name: 'Apex Tower Suite',
        location: 'Gurugram, Haryana',
        budget: '₹85,00,000',
        stages: const [
          ProjectStageModel(id: 's1', title: 'Design', isDone: true),
        ],
        timelineSpreadsheet: defaultSheet.toMap(),
        createdAt: DateTime(2026, 10, 24),
      );

      final map = project.toMap();
      expect(map['timelineSpreadsheet'], isNotNull);

      final fromMap = ProjectModel.fromMap(map);
      expect(fromMap.timelineSpreadsheet, isNotNull);
      expect(
        fromMap.timelineSpreadsheet!['fileName'],
        contains('Apex_Tower_Suite'),
      );
    });

    test('StorageService auto-heals missing timelineSpreadsheet with defaults', () {
      final projectWithoutSheet = {
        'id': 'legacy_proj',
        'name': 'Legacy Luxury Villa',
        'client': 'Anya Sharma',
        'budget:': '₹50,00,000',
        'stages': <Map<String, dynamic>>[],
      };
      StorageService.saveProjects([projectWithoutSheet]);

      final loaded = StorageService.getProjects();
      expect(loaded.length, equals(1));
      expect(loaded.first['timelineSpreadsheet'], isNotNull);
      final sheet = SpreadsheetData.fromMap(
        loaded.first['timelineSpreadsheet'] as Map<String, dynamic>,
      );
      expect(sheet.rows.length, equals(12));
    });
  });

  group('Sales Lead Creation Auto-Provisions Project with Timeline', () {
    testWidgets('Adding lead immediately provisions project with timeline spreadsheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open AddLeadSheet
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => AddLeadSheet.show(context),
                child: const Text('Open Add Lead'),
              );
            },
          ),
          role: UserRole.sales,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Lead'));
      await tester.pumpAndSettle();

      // Enter client name, project name, value
      final clientField = find.widgetWithText(TextField, 'Client / Company Name');
      await tester.enterText(clientField, 'Rajesh Khanna');

      final scopeField = find.widgetWithText(
        TextField,
        'Project Scope (e.g. 4BHK Villa / 5000 sq ft)',
      );
      await tester.enterText(scopeField, 'Grand Hyatt Penthouse');

      final budgetField = find.widgetWithText(
        TextField,
        'Est. Budget (e.g. ₹60L)',
      );
      await tester.enterText(budgetField, '12000000');
      await tester.pumpAndSettle();

      // Submit lead
      final submitBtn = find.widgetWithText(
        ElevatedButton,
        'Save Lead to Pipeline',
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify lead is saved
      final leads = StorageService.getLeads();
      expect(leads.length, equals(1));
      expect(leads.first['client'], equals('Rajesh Khanna'));

      // Verify project was immediately provisioned
      final projects = StorageService.getProjects();
      expect(projects.length, equals(1));
      final provProj = projects.first;
      expect(provProj['client'], equals('Rajesh Khanna'));
      expect(provProj['stages'], isNotEmpty);

      // Verify timelineSpreadsheet was provisioned automatically
      expect(provProj['timelineSpreadsheet'], isNotNull);
      final sheetData = SpreadsheetData.fromMap(
        provProj['timelineSpreadsheet'] as Map<String, dynamic>,
      );
      expect(sheetData.fileName, contains('Timeline_Schedule.xlsx'));
      expect(sheetData.rows.length, equals(12));
    });
  });

  group('ProjectTimelineSheetDialog UI Widget Tests', () {
    testWidgets('Renders clean Excel external link dialog when no file is linked and when a file is linked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final unlinkedProject = <String, dynamic>{
        'id': 'test_1',
        'name': 'The Camellias Penthouse',
        'client': 'Aarav Singhania',
        'status': 'In Progress',
      };

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => ProjectTimelineSheetDialog.show(
                  context,
                  project: unlinkedProject,
                  projectAccent: AppColors.brandPeach,
                ),
                child: const Text('Open Timeline Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Timeline Dialog'));
      await tester.pumpAndSettle();

      // Verify Excel Green Header & Empty File State (no fake internal spreadsheet table)
      expect(find.text('PROJECT TIMELINE SPREADSHEET'), findsOneWidget);
      expect(find.text('EXCEL .XLSX'), findsOneWidget);
      expect(find.text('The Camellias Penthouse'), findsOneWidget);
      expect(find.text('No Excel Timeline File Linked'), findsOneWidget);
      expect(
        find.text('Upload & Link Excel File (.xlsx)'),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Now test with a linked Excel file
      unlinkedProject['timelineSpreadsheet'] = {
        'fileName': 'Camellias_Master_Schedule.xlsx',
        'fileSize': '142.5 KB',
        'downloadUrl': 'https://example.com/Camellias_Master_Schedule.xlsx',
        'isUserUploaded': true,
      };

      await tester.tap(find.text('Open Timeline Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Camellias_Master_Schedule.xlsx'), findsOneWidget);
      expect(
        find.text('Open Externally in Excel / Viewer'),
        findsOneWidget,
      );
      expect(find.text('Replace File'), findsOneWidget);
      expect(find.text('Remove File'), findsOneWidget);
    });

    testWidgets('ProjectsView displays Excel Timeline button and opens sheet dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Save a project
      final dummyProject = {
        'id': 'test_proj',
        'name': 'One Horizon Center Executive Suite',
        'client': 'Sanjay Singhania',
        'handover': '15 Dec 2026',
        'stages': [
          {'name': 'Demolition', 'isDone': true},
        ],
      };
      await StorageService.saveProjects([dummyProject]);

      await tester.pumpWidget(
        createTestWidget(const ProjectsView(), role: UserRole.proprietor),
      );
      await tester.pumpAndSettle();

      // Verify Compact Card has Excel Timeline button
      final excelBtn = find.text('Excel Timeline Schedule');
      expect(excelBtn, findsOneWidget);

      // Tap the Excel Timeline Schedule button
      await tester.tap(excelBtn);
      await tester.pumpAndSettle();

      // Excel Timeline Sheet Dialog opens with clean external link view
      expect(find.text('PROJECT TIMELINE SPREADSHEET'), findsOneWidget);
      expect(find.text('One Horizon Center Executive Suite'), findsWidgets);
      expect(find.text('No Excel Timeline File Linked'), findsOneWidget);
      expect(
        find.text('Upload & Link Excel File (.xlsx)'),
        findsOneWidget,
      );
    });
  });
}
