import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/services/backend_manager.dart';
import 'package:assist_interiors_dashboard/core/widgets/project_status_chart.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/projects/sheets/review_snags_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await StorageService.clearAll();
    await BackendManager.instance.init();
  });

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('ReviewSnagsSheet Functional & Interactive Flow', () {
    testWidgets('Displays delayed projects and snag checklist items', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.seedFillerProjectsIfEmpty();

      await tester.pumpWidget(createTestWidget(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => ReviewSnagsSheet.show(context),
              child: const Text('Open Snags Sheet'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Open Snags Sheet'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Site Snags & Delay Bottlenecks'), findsOneWidget);
      expect(find.text('Oberoi Sky City Suite'), findsOneWidget);
      expect(find.text('DELAYED SITE'), findsOneWidget);
      expect(find.text('Snag Rectification & Deep Clean Handover'), findsOneWidget);
      expect(find.text('Clear Delay Flag'), findsOneWidget);
    });

    testWidgets('Toggling a snag stage toggles isDone and persists', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.seedFillerProjectsIfEmpty();

      await tester.pumpWidget(createTestWidget(
        const ReviewSnagsSheet(),
      ));
      await tester.pumpAndSettle();

      final stageFinder = find.text('Snag Rectification & Deep Clean Handover');
      expect(stageFinder, findsOneWidget);

      // Tap on the stage to mark it as done
      await tester.tap(stageFinder);
      await tester.pumpAndSettle();

      final projects = StorageService.getProjects();
      final delayedProject = projects.firstWhere((p) => p['name'] == 'Oberoi Sky City Suite');
      final stages = delayedProject['stages'] as List<dynamic>;
      final targetStage = stages.firstWhere((s) => s['title'] == 'Snag Rectification & Deep Clean Handover');
      expect(targetStage['isDone'], true);
    });

    testWidgets('Adding a new snag adds item to project checklist', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.seedFillerProjectsIfEmpty();

      await tester.pumpWidget(createTestWidget(
        const ReviewSnagsSheet(),
      ));
      await tester.pumpAndSettle();

      // Tap on '+ Add Snag'
      await tester.tap(find.text('+ Add Snag'));
      await tester.pumpAndSettle();

      // Enter snag title
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Touchup PU polish on hallway credenza');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Touchup PU polish on hallway credenza'), findsOneWidget);

      final projects = StorageService.getProjects();
      final delayedProject = projects.firstWhere((p) => p['name'] == 'Oberoi Sky City Suite');
      final stages = delayedProject['stages'] as List<dynamic>;
      expect(stages.any((s) => s['title'] == 'Touchup PU polish on hallway credenza'), true);
    });

    testWidgets('Clearing delay unflags project and marks it On Track', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.seedFillerProjectsIfEmpty();

      await tester.pumpWidget(createTestWidget(
        const ReviewSnagsSheet(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clear Delay Flag'), findsOneWidget);
      await tester.tap(find.text('Clear Delay Flag'));
      await tester.pumpAndSettle();

      final projects = StorageService.getProjects();
      final project = projects.firstWhere((p) => p['name'] == 'Oberoi Sky City Suite');
      expect(project['isDelayed'], false);
      expect(project['status'], 'On Track');
    });

    testWidgets('Tapping Review Snags in ProjectStatusDistributionChart opens ReviewSnagsSheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await StorageService.seedFillerProjectsIfEmpty();
      final projects = StorageService.getProjects();

      await tester.pumpWidget(createTestWidget(
        SingleChildScrollView(
          child: ProjectStatusDistributionChart(
            projects: projects,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll to review snags strip
      final reviewSnagsFinder = find.byKey(const Key('review_snags_strip'));
      final verticalScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        reviewSnagsFinder,
        100,
        scrollable: verticalScrollable,
      );
      await tester.pumpAndSettle();

      // Tap 'Review Snags'
      await tester.tap(reviewSnagsFinder);
      await tester.pumpAndSettle();

      // Verify sheet opens
      expect(find.text('Site Snags & Delay Bottlenecks'), findsOneWidget);
      expect(find.text('Oberoi Sky City Suite'), findsOneWidget);
    });
  });
}
