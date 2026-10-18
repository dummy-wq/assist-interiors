import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assist_interiors_dashboard/main.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/core/theme/app_theme.dart';
import 'package:assist_interiors_dashboard/core/theme/app_typography.dart';
import 'package:assist_interiors_dashboard/core/widgets/pill_box.dart';
import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/services/backend_manager.dart';
import 'package:assist_interiors_dashboard/core/models/project_model.dart';
import 'package:assist_interiors_dashboard/core/models/task_model.dart';
import 'package:assist_interiors_dashboard/core/models/vendor_model.dart';
import 'package:assist_interiors_dashboard/core/models/invoice_model.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/role_bottom_bar.dart';
import 'package:assist_interiors_dashboard/features/tasks/views/tasks_view.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/main_dashboard_screen.dart';

Future<void> _addNewProject(WidgetTester tester, String name) async {
  final actionBtn = find.byKey(const Key('action_bar_add_project'));
  if (actionBtn.evaluate().isNotEmpty) {
    await tester.tap(actionBtn.first);
  } else {
    final textBtn = find.text('Add Project');
    if (textBtn.evaluate().isNotEmpty) {
      await tester.tap(textBtn.first);
    } else {
      final addBtn = find.widgetWithText(ElevatedButton, 'Add New Project');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(addBtn.first);
        await tester.tap(addBtn.first);
      }
    }
  }
  await tester.pumpAndSettle();

  final nameField = find.widgetWithText(
    TextField,
    'Project Name (e.g. DLF Magnolias 4BHK)',
  );
  await tester.enterText(nameField, name);
  await tester.pumpAndSettle();

  final launchBtn = find.widgetWithText(ElevatedButton, 'Launch Project');
  await tester.tap(launchBtn);
  await tester.pumpAndSettle();
}

Future<void> _addNewVendor(
  WidgetTester tester,
  String name,
  String category,
) async {
  final actionBtn = find.byKey(const Key('action_bar_add_vendor'));
  if (actionBtn.evaluate().isNotEmpty) {
    await tester.tap(actionBtn.first);
  } else {
    final textBtn = find.text('Add Vendor');
    if (textBtn.evaluate().isNotEmpty) {
      await tester.tap(textBtn.first);
    } else {
      final addBtn = find.widgetWithText(ElevatedButton, 'Onboard Vendor');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(addBtn.first);
        await tester.tap(addBtn.first);
      }
    }
  }
  await tester.pumpAndSettle();

  final nameField = find.widgetWithText(TextField, 'Company / Firm Name');
  await tester.enterText(nameField, name);
  await tester.pumpAndSettle();

  final categoryField = find.widgetWithText(
    TextField,
    'Trade Category (e.g. Italian Marble, Hardware, Glass)',
  );
  await tester.enterText(categoryField, category);
  await tester.pumpAndSettle();

  final saveBtn = find.widgetWithText(ElevatedButton, 'Save Vendor Profile');
  await tester.tap(saveBtn);
  await tester.pumpAndSettle();
}

Future<void> _addNewInvoice(
  WidgetTester tester,
  String stage,
  String amount,
) async {
  final actionBtn = find.byKey(const Key('action_bar_add_invoice'));
  if (actionBtn.evaluate().isNotEmpty) {
    await tester.tap(actionBtn.first);
  } else {
    final textBtn = find.text('Add Invoice');
    if (textBtn.evaluate().isNotEmpty) {
      await tester.tap(textBtn.first);
    } else {
      final genBtn = find.widgetWithText(
        ElevatedButton,
        'Generate Client Invoice',
      );
      if (genBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(genBtn.first);
        await tester.tap(genBtn.first);
      }
    }
  }
  await tester.pumpAndSettle();

  final stageField = find.widgetWithText(
    TextField,
    'Billing Stage (e.g. Milestone 2: False Ceiling)',
  );
  await tester.enterText(stageField, stage);
  await tester.pumpAndSettle();

  final amountField = find.widgetWithText(TextField, 'Invoice Amount (INR ₹)');
  await tester.enterText(amountField, amount);
  await tester.pumpAndSettle();

  final submitBtn = find.widgetWithText(
    ElevatedButton,
    'Generate & Send Invoice (GST Compliant)',
  );
  await tester.tap(submitBtn);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    AppConstants.preExistingProjects.clear();
    MobileActionSheets.projectFilterNotifier.value = 'All';
    MainDashboardScreen.activeTabNotifier.value = 0;
  });
  testWidgets('App smoke test & initial Hub render', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const AssistInteriorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssistInteriorsApp), findsOneWidget);
    // Hub header should be present
    expect(find.text('Executive Studio Hub'), findsOneWidget);
  });

  testWidgets(
    'Navigation across all 6 enterprise screens with contextual bottom buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Check BottomNavigationBar items: Hub, Projects, Vendors, Tasks, Accounts, Team
      expect(find.text('Hub'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Vendors'), findsWidgets);
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Accounts'), findsWidgets);
      expect(find.text('Team'), findsWidgets);

      // Top options: only Language, Colour switch, Role switch, and Sign Out
      expect(find.byTooltip('Toggle Theme'), findsOneWidget);
      expect(find.byTooltip('Switch Demo Role'), findsOneWidget);
      expect(find.byTooltip('Sign Out'), findsOneWidget);
      expect(find.text('EN'), findsWidgets);

      // Verify screen-dependent action icons are NOT present on top
      expect(find.byTooltip('Export P&L'), findsNothing);
      expect(find.byTooltip('New Project'), findsNothing);

      // 2. Switch to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(find.text('Projects Portfolio'), findsOneWidget);
      expect(find.text('Add Project'), findsWidgets);
      expect(find.byTooltip('Filter Projects'), findsNothing);

      // 3. Switch to Vendors tab
      await tester.tap(find.text('Vendors').last);
      await tester.pumpAndSettle();
      expect(find.text('Vendors & Suppliers'), findsOneWidget);
      expect(find.text('Add Vendor'), findsWidgets);
      expect(find.byTooltip('Track POs'), findsNothing);

      // 4. Switch to Tasks tab
      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();
      expect(find.text('Tasks & Milestones'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.byTooltip('Urgent Only'), findsNothing);

      // 5. Switch to Accounts tab
      await tester.tap(find.text('Accounts').last);
      await tester.pumpAndSettle();
      expect(find.text('Finance, Invoicing & Expense Control'), findsOneWidget);
      expect(find.text('Add Invoice'), findsOneWidget);
      expect(find.text('Record Expense'), findsOneWidget);

      // 6. Switch to Team tab (with Team Overview)
      await tester.tap(find.text('Team').last);
      await tester.pumpAndSettle();
      expect(find.text('Team & Workforce'), findsOneWidget);
      expect(find.text('28 Field Staff'), findsOneWidget);
      expect(find.text('7 Designers'), findsOneWidget);
      expect(find.text('Invite Staff'), findsOneWidget);
      expect(find.byTooltip('Labour Roll'), findsNothing);
    },
  );

  testWidgets('Font Theme can be switched and defaults to Plus Jakarta Sans', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final auth = AuthProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: auth)],
        child: const AssistInteriorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Default font theme is Plus Jakarta Sans
    expect(auth.fontTheme.label, 'Plus Jakarta Sans');

    // Switch to Cascadia Code programmatically
    auth.setFontTheme(AppFontTheme.cascadiaCode);
    await tester.pumpAndSettle();
    expect(auth.fontTheme.label, 'Cascadia Code');
  });

  testWidgets(
    'Theme mode switches instantaneously with synchronized brightness and icon',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final auth = AuthProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: auth)],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.light_mode_outlined);
      expect(iconFinder, findsOneWidget);

      final initialMode = auth.isDarkMode;
      await tester.tap(iconFinder);
      await tester.pumpAndSettle();

      // Verify theme mode flipped immediately
      expect(auth.isDarkMode, !initialMode);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'PillBox taps trigger bounce scale animation and state selection',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Verify Status PillBoxes rendered: All, Completed, On Track, Delayed, Design and Planning
      expect(find.text('All'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('On Track'), findsWidgets);
      expect(find.text('Delayed'), findsWidgets);
      expect(find.text('Design and Planning'), findsWidgets);

      // Initially verify empty state because all projects are erased
      expect(find.text('No Projects Listed'), findsOneWidget);

      // Add projects
      await _addNewProject(tester, 'The Camellias Penthouse');
      expect(find.text('The Camellias Penthouse'), findsOneWidget);

      await _addNewProject(tester, 'Innov8 Co-Working Hub');
      expect(find.text('Innov8 Co-Working Hub'), findsOneWidget);

      // Expand the first project card (The Camellias Penthouse)
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      // Tap 'Mark Delayed' on the first project (Camellias)
      final markDelayedButtons = find.text('Mark Delayed');
      expect(markDelayedButtons, findsWidgets);
      await tester.ensureVisible(markDelayedButtons.first);
      await tester.tap(markDelayedButtons.first);
      await tester.pumpAndSettle();

      // Now tap 'Delayed' pill box
      final delayedPill = find.widgetWithText(PillBox, 'Delayed');
      await tester.ensureVisible(delayedPill);
      await tester.tap(delayedPill);
      await tester.pumpAndSettle();

      // Verify filtered projects list shows the delayed project
      expect(find.text('The Camellias Penthouse'), findsOneWidget);
      expect(find.text('Innov8 Co-Working Hub'), findsNothing);

      // Tap 'Design and Planning' pill box
      final designPill = find.widgetWithText(PillBox, 'Design and Planning');
      await tester.ensureVisible(designPill);
      await tester.tap(designPill);
      await tester.pumpAndSettle();

      // Verify projects in Design and Planning are visible
      expect(find.text('Innov8 Co-Working Hub'), findsOneWidget);
      expect(find.text('The Camellias Penthouse'), findsNothing);
    },
  );

  testWidgets(
    'Projects stage checklist toggles and adaptively updates progress',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      // Add project first
      await _addNewProject(tester, 'The Camellias Penthouse');

      // Expand project card
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
      await tester.pumpAndSettle();

      // Stages are hidden by default: tap 'Update Progress' to open stage checklist
      final updateProgressBtn1 = find
          .widgetWithText(OutlinedButton, 'Update Progress')
          .first;
      await tester.ensureVisible(updateProgressBtn1);
      await tester.tap(updateProgressBtn1);
      await tester.pumpAndSettle();

      // Find the textfield to add a stage for the first project
      final addStageField = find
          .widgetWithText(TextField, '+ Add custom milestone stage...')
          .first;
      await tester.ensureVisible(addStageField);
      await tester.enterText(addStageField, 'Civil Demolition');
      await tester.pumpAndSettle();

      // Tap 'Add Stage' button
      final addStageBtn = find
          .widgetWithText(ElevatedButton, 'Add Stage')
          .first;
      await tester.tap(addStageBtn);
      await tester.pumpAndSettle();

      // Verify stage is added and visible
      expect(find.text('Civil Demolition'), findsOneWidget);
      expect(find.text('0% COMPLETE'), findsWidgets);

      // Tap the stage to mark it as done
      final stageText = find.text('Civil Demolition');
      await tester.ensureVisible(stageText);
      await tester.pumpAndSettle();
      await tester.tap(stageText);
      await tester.pumpAndSettle();

      // 1 of 1 done = 100% COMPLETE
      expect(find.text('100% COMPLETE'), findsOneWidget);
    },
  );

  testWidgets('Stages drag handle performs fast magnetic reorder', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const AssistInteriorsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Projects tab
    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();

    // Add project first
    await _addNewProject(tester, 'The Camellias Penthouse');

    // Expand project card
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
    await tester.pumpAndSettle();

    // Stages are hidden by default: tap 'Update Progress' to open stage checklist
    final updateProgressBtn2 = find
        .widgetWithText(OutlinedButton, 'Update Progress')
        .first;
    await tester.ensureVisible(updateProgressBtn2);
    await tester.tap(updateProgressBtn2);
    await tester.pumpAndSettle();

    // Add stage 1
    final addStageField = find
        .widgetWithText(TextField, '+ Add custom milestone stage...')
        .first;
    await tester.ensureVisible(addStageField);
    await tester.enterText(addStageField, 'Stage 1 Demolition');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Stage').first);
    await tester.pumpAndSettle();

    // Add stage 2
    await tester.enterText(addStageField, 'Stage 2 Flooring');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Stage').first);
    await tester.pumpAndSettle();

    // Find the drag handles
    final dragHandles = find.byIcon(Icons.reorder_rounded);
    expect(dragHandles, findsWidgets);

    await tester.ensureVisible(dragHandles.first);
    await tester.pumpAndSettle();

    // Drag the first handle downwards by 50px
    final gesture = await tester.startGesture(
      tester.getCenter(dragHandles.first),
    );
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.up();

    // Settle the fast 90ms magnetic snap animation
    await tester.pumpAndSettle();

    // Verify app remains stable and stages intact
    expect(find.text('PROJECT EXECUTION STAGES'), findsWidgets);
    expect(find.text('Stage 1 Demolition'), findsOneWidget);
    expect(find.text('Stage 2 Flooring'), findsOneWidget);
  });

  testWidgets(
    'Add Task sheet shows dropdown of pre-existing projects and adds task to TasksView',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Projects tab and create project
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      await _addNewProject(tester, 'Villa Riviera');

      // Navigate to Tasks tab
      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();

      // Tap 'Add Task' action button
      final newTaskBtn = find.byTooltip('+ New Task');
      if (newTaskBtn.evaluate().isNotEmpty) {
        await tester.tap(newTaskBtn.first);
      } else {
        final addTaskBtn = find.text('Add Task');
        if (addTaskBtn.evaluate().isNotEmpty) {
          await tester.tap(addTaskBtn.first);
        } else {
          await tester.tap(find.text('+ New Task'));
        }
      }
      await tester.pumpAndSettle();

      // Verify modal sheet is opened
      expect(find.text('Create Project Task'), findsOneWidget);

      // Enter task title
      final titleField = find.widgetWithText(
        TextField,
        'Task Description / Deliverable',
      );
      await tester.enterText(titleField, 'Install Acoustic Wall Cladding');
      await tester.pumpAndSettle();

      // Find and tap the Associated Project dropdown
      final dropdownFinder = find.byType(DropdownButtonFormField<String>).first;
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Verify project appears in the dropdown list
      expect(find.text('Villa Riviera'), findsWidgets);

      // Select 'Villa Riviera'
      await tester.tap(find.text('Villa Riviera').last);
      await tester.pumpAndSettle();

      // Tap Add Task submit button in bottom sheet
      final submitBtn = find.widgetWithText(ElevatedButton, 'Add Task').last;
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify task is added to TasksView list with selected project
      expect(find.text('Install Acoustic Wall Cladding'), findsOneWidget);
      expect(find.text('Villa Riviera'), findsWidgets);
    },
  );

  testWidgets(
    'Cleared entries verification across Projects, Tasks, Vendors, Accounts with preserved Team data',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Reset AppConstants.preExistingProjects for test isolation
      AppConstants.preExistingProjects.clear();
      await StorageService.clearAll();

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Hub Upcoming Handovers shows cleared empty state
      expect(find.text('No Upcoming Handovers Scheduled'), findsOneWidget);

      // 2. Projects tab shows cleared empty state
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(find.text('No Projects Listed'), findsOneWidget);
      expect(find.text('0 Sites'), findsWidgets);

      // 3. Tasks tab shows cleared empty state
      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();
      expect(find.text('No Tasks Logged'), findsOneWidget);
      expect(find.text('0 Tasks'), findsWidgets);

      // 4. Vendors tab shows cleared empty state
      await tester.tap(find.text('Vendors').last);
      await tester.pumpAndSettle();
      expect(find.text('No Vendors Registered'), findsOneWidget);
      expect(find.text('0 Partners'), findsOneWidget);

      // 5. Accounts tab shows cleared empty state
      await tester.tap(find.text('Accounts').last);
      await tester.pumpAndSettle();
      expect(find.text('No Invoices Generated'), findsOneWidget);

      // 6. Team tab is preserved intact ("save for the team section")
      await tester.tap(find.text('Team').last);
      await tester.pumpAndSettle();
      expect(find.text('Team & Workforce'), findsOneWidget);
      expect(find.text('28 Field Staff'), findsOneWidget);
      expect(find.text('7 Designers'), findsOneWidget);
    },
  );

  testWidgets(
    'Vendor onboarding dynamically updates VendorsView and persists locally',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Vendors tab
      await tester.tap(find.text('Vendors').last);
      await tester.pumpAndSettle();
      expect(find.text('No Vendors Registered'), findsOneWidget);

      // Onboard a new vendor
      await _addNewVendor(tester, 'Heritage Stone & Marbles', 'Italian Marble');

      // Verify vendor appears in VendorsView list
      expect(find.text('Heritage Stone & Marbles'), findsOneWidget);
      expect(find.text('1 Partners'), findsWidgets);

      // Verify saved in StorageService
      final storedVendors = StorageService.getVendors();
      expect(storedVendors.length, 1);
      expect(storedVendors.first['name'], 'Heritage Stone & Marbles');
      expect(storedVendors.first['category'], 'Italian Marble');
    },
  );

  testWidgets(
    'Invoice generation dynamically updates AccountsDashboard and computes receivables',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Accounts tab
      await tester.tap(find.text('Accounts').last);
      await tester.pumpAndSettle();
      expect(find.text('No Invoices Generated'), findsOneWidget);

      // Generate client invoice
      await _addNewInvoice(
        tester,
        'Milestone 1: Civil & Demolition',
        '3,50,000',
      );

      // Verify invoice appears in Accounts list
      expect(find.text('Milestone 1: Civil & Demolition'), findsOneWidget);
      expect(find.text('₹ 3,50,000'), findsWidgets);
      expect(find.text('1 active billings'), findsOneWidget);

      // Verify saved in StorageService
      final storedInvoices = StorageService.getInvoices();
      expect(storedInvoices.length, 1);
      expect(storedInvoices.first['client'], 'Milestone 1: Civil & Demolition');
    },
  );

  testWidgets(
    'Offline persistent storage restores projects, tasks, vendors, and invoices upon app restart',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed mock local storage directly (simulating pre-existing data saved on disk)
      await StorageService.saveProjects([
        {
          'name': 'The Camellias Penthouse',
          'location': 'DLF Phase 5',
          'category': 'Residential',
          'status': 'Design and Planning',
          'isDelayed': false,
          'type': '4500 sq ft Turnkey',
          'budget': '₹ 1.8 Cr',
          'spent': '₹ 0',
          'pm': 'Aarav Mehta',
          'supervisor': 'Vikram Rathore',
          'handover': 'Dec 2026',
          'color': const Color(0xFFD4A373),
          'isChecklistOpen': false,
          'stages': [
            {'id': 's1', 'title': 'Design Sign-off', 'isDone': true},
          ],
        },
      ]);

      await StorageService.saveTasks([
        {
          'id': 'task_1',
          'title': 'Acoustic Wall Paneling',
          'project': 'The Camellias Penthouse',
          'assignee': 'Vikram Rathore',
          'deadline': 'Tomorrow',
          'status': 'In Progress',
          'completed': false,
          'priority': 'Urgent',
          'color': const Color(0xFFE63946),
        },
      ]);

      await StorageService.saveVendors([
        {
          'name': 'DecoWood Veneers',
          'category': 'Plywood & Veneer',
          'contactPerson': 'Rajesh Sharma',
          'phone': '+91 98111 22233',
          'rating': '4.9',
          'onTime': '98%',
          'activeOrders': '2 Active Purchase Orders',
          'status': 'Active',
          'openPOs': 2,
          'outstanding': '₹ 0',
          'color': const Color(0xFF2A9D8F),
        },
      ]);

      await StorageService.saveInvoices([
        {
          'id': 'INV-90812',
          'client': 'Camellias Phase 1 Advance',
          'date': '28 Sep 2026',
          'amount': '₹ 5,00,000',
          'status': 'Payment Pending',
          'statusColor': const Color(0xFFE76F51),
        },
      ]);

      // Launch app cleanly from cold restart
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Projects tab restores saved project
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();
      expect(find.text('The Camellias Penthouse'), findsOneWidget);
      expect(find.text('1 Sites'), findsWidgets);

      // 2. Tasks tab restores saved task
      await tester.tap(find.text('Tasks').last);
      await tester.pumpAndSettle();
      expect(find.text('Acoustic Wall Paneling'), findsOneWidget);

      // 3. Vendors tab restores saved vendor
      await tester.tap(find.text('Vendors').last);
      await tester.pumpAndSettle();
      expect(find.text('DecoWood Veneers'), findsOneWidget);
      expect(find.text('1 Partners'), findsWidgets);

      // 4. Accounts tab restores saved invoice
      await tester.tap(find.text('Accounts').last);
      await tester.pumpAndSettle();
      expect(find.text('Camellias Phase 1 Advance'), findsOneWidget);
      expect(find.text('₹ 5,00,000'), findsWidgets);
    },
  );

  test(
    'BackendManager executes local-cloud transparent operations and streams',
    () async {
      final backend = BackendManager.instance;
      await backend.init();

      // Verify initial fallback is offline/local when no Firebase app exists in unit test
      expect(backend.isCloudConnected, isFalse);

      // 1. Projects
      final testProj = ProjectModel(
        id: 'proj_test_01',
        name: 'DLF Magnolias Penthouse',
        location: 'Golf Course Road, Gurugram',
        budget: '₹ 85,00,000',
        status: 'Design and Planning',
        stages: const [
          ProjectStageModel(
            id: 'stg_1',
            title: 'Civil & Masonry',
            isDone: true,
          ),
          ProjectStageModel(
            id: 'stg_2',
            title: 'Plumbing & Electrical',
            isDone: false,
          ),
        ],
        createdAt: DateTime.now(),
      );
      await backend.createProject(testProj);

      final projects = await backend.streamProjects().first;
      expect(projects.any((p) => p.id == 'proj_test_01'), isTrue);

      final updatedProj = testProj.copyWith(
        stages: const [
          ProjectStageModel(
            id: 'stg_1',
            title: 'Civil & Masonry',
            isDone: true,
          ),
          ProjectStageModel(
            id: 'stg_2',
            title: 'Plumbing & Electrical',
            isDone: true,
          ),
        ],
      );
      await backend.updateProject(updatedProj);
      final projectsAfterUpdate = await backend.streamProjects().first;
      expect(
        projectsAfterUpdate.firstWhere((p) => p.id == 'proj_test_01').progress,
        1.0,
      );

      // 2. Tasks
      final testTask = TaskModel(
        id: 'task_test_01',
        title: 'False Ceiling Layout',
        project: 'DLF Magnolias Penthouse',
        assignee: 'Vikram (Designer)',
        priority: 'High',
        status: 'In Progress',
        deadline: 'Tomorrow',
        createdAt: DateTime.now(),
      );
      await backend.createTask(testTask);
      final tasks = await backend.streamTasks().first;
      expect(tasks.any((t) => t.id == 'task_test_01'), isTrue);

      // 3. Vendors
      final testVendor = const VendorModel(
        id: 'vnd_test_01',
        name: 'Greenply Century Board',
        category: 'Wood & Ply',
        contactPerson: 'Suresh Agarwal',
        rating: '4.8',
        status: 'Active',
        phone: '+91 99999 88888',
        openPOs: 3,
        outstanding: '₹ 12,00,000',
      );
      await backend.createVendor(testVendor);
      final vendors = await backend.streamVendors().first;
      expect(vendors.any((v) => v.id == 'vnd_test_01'), isTrue);

      // 4. Invoices
      final testInvoice = const InvoiceModel(
        id: 'inv_test_01',
        client: 'Greenply Century Board',
        date: '28 Sep 2026',
        amount: '₹ 2,50,000',
        status: 'Payment Pending',
      );
      await backend.createInvoice(testInvoice);
      final invoices = await backend.streamInvoices().first;
      expect(invoices.any((i) => i.id == 'inv_test_01'), isTrue);

      // 5. Delete operations
      await backend.deleteProject('proj_test_01');
      final projectsAfterDelete = await backend.streamProjects().first;
      expect(projectsAfterDelete.any((p) => p.id == 'proj_test_01'), isFalse);

      await backend.deleteTask('task_test_01');
      await backend.deleteVendor('vnd_test_01');
      await backend.deleteInvoice('inv_test_01');
    },
  );

  testWidgets(
    'RoleBottomBar and AppSizes adapt to system navigation bar insets and theme overlay',
    (WidgetTester tester) async {
      // 1. Verify AppTheme system overlay styles have transparent nav bar and correct brightness
      expect(AppTheme.darkOverlay.systemNavigationBarColor, Colors.transparent);
      expect(
        AppTheme.darkOverlay.systemNavigationBarDividerColor,
        Colors.transparent,
      );
      expect(
        AppTheme.darkOverlay.systemNavigationBarIconBrightness,
        Brightness.light,
      );
      expect(AppTheme.darkOverlay.systemNavigationBarContrastEnforced, isFalse);

      expect(
        AppTheme.lightOverlay.systemNavigationBarColor,
        Colors.transparent,
      );
      expect(
        AppTheme.lightOverlay.systemNavigationBarDividerColor,
        Colors.transparent,
      );
      expect(
        AppTheme.lightOverlay.systemNavigationBarIconBrightness,
        Brightness.dark,
      );
      expect(
        AppTheme.lightOverlay.systemNavigationBarContrastEnforced,
        isFalse,
      );

      // 2. Test AppSizes.sheetBottomPadding with and without system insets
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = AppSizes.sheetBottomPadding(context);
              return Text('Padding: $padding');
            },
          ),
        ),
      );
      expect(find.text('Padding: 20.0'), findsOneWidget);

      // 3. Test with simulated 48dp 3-button system nav bar insets
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 48.0),
            padding: EdgeInsets.only(bottom: 48.0),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final padding = AppSizes.sheetBottomPadding(context);
                return Text('PaddingWithNavBar: $padding');
              },
            ),
          ),
        ),
      );
      expect(find.text('PaddingWithNavBar: 60.0'), findsOneWidget);

      // 4. Test RoleBottomBar renders properly with simulated system navigation bar
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: 48.0),
            padding: EdgeInsets.only(bottom: 48.0),
          ),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              bottomNavigationBar: RoleBottomBar(
                role: UserRole.proprietor,
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RoleBottomBar), findsOneWidget);
      expect(find.text('Hub'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // Find the SafeArea inside RoleBottomBar
      final safeAreaFinder = find.descendant(
        of: find.byType(RoleBottomBar),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);
      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.top, isFalse);
      expect(safeArea.maintainBottomViewPadding, isTrue);
      expect(safeArea.minimum, const EdgeInsets.only(bottom: 6.0));
    },
  );

  testWidgets(
    'Input fields and chips are vertically elongated by 3px preventing descender clipping',
    (WidgetTester tester) async {
      // 1. Theme level validation
      final darkPadding =
          AppTheme.darkTheme.inputDecorationTheme.contentPadding as EdgeInsets;
      final lightPadding =
          AppTheme.lightTheme.inputDecorationTheme.contentPadding as EdgeInsets;

      expect(darkPadding.top, equals(18.0));
      expect(darkPadding.bottom, equals(18.0));
      expect(lightPadding.top, equals(18.0));
      expect(lightPadding.bottom, equals(18.0));
      expect(AppSizes.chipHeight, equals(35.0));

      // 2. Widget rendering validation with descender words (e.g. lowercase 'g', 'y', 'p')
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: TextEditingController(
                      text: 'Magnolias Living Room Staging & Designing',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Project Tagline',
                    ),
                  ),
                  PillBox(
                    label: 'Design and Planning',
                    isSelected: true,
                    onSelected: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Magnolias Living Room Staging & Designing'),
        findsOneWidget,
      );
      expect(find.text('Design and Planning'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text.contains('g'), isTrue);
    },
  );

  testWidgets(
    'Vendor onboarding with all 9 fields shows cleanly in VendorsView',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const AssistInteriorsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Vendors tab
      await tester.tap(find.text('Vendors').last);
      await tester.pumpAndSettle();

      // Tap Onboard Vendor / Add Vendor button
      final actionBtn = find.byKey(const Key('action_bar_add_vendor'));
      if (actionBtn.evaluate().isNotEmpty) {
        await tester.tap(actionBtn.first);
      } else {
        final addBtn = find.widgetWithText(ElevatedButton, 'Onboard Vendor');
        if (addBtn.evaluate().isNotEmpty) {
          await tester.tap(addBtn.first);
        } else {
          await tester.tap(
            find.widgetWithText(ElevatedButton, 'Add Vendor').first,
          );
        }
      }
      await tester.pumpAndSettle();

      // Fill in all 9 fields
      // 1. Vendor Name
      final nameField = find.widgetWithText(TextField, 'Vendor Name');
      await tester.enterText(nameField, 'Greenply Decors');

      // 2. Category
      final categoryField = find.widgetWithText(
        TextField,
        'Trade Category (e.g. Italian Marble, Hardware, Glass)',
      );
      await tester.enterText(categoryField, 'Plywood & Veneer');

      // 3. Contact Person
      final contactField = find.widgetWithText(TextField, 'Contact Person');
      await tester.enterText(contactField, 'Vikram Joshi');

      // 4. Phone
      final phoneField = find.widgetWithText(TextField, 'Phone Number');
      await tester.enterText(phoneField, '+91 98765 43210');

      // 5. Email
      final emailField = find.widgetWithText(TextField, 'Email Address');
      await tester.enterText(emailField, 'vikram@greenplydecors.com');

      // 6. City
      final cityField = find.widgetWithText(TextField, 'City / Base Location');
      await tester.enterText(cityField, 'Gurugram');

      // 7. Payment Status Dropdown
      final paymentStatusFinder = find.byType(DropdownButtonFormField<String>);
      await tester.tap(paymentStatusFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial').last);
      await tester.pumpAndSettle();

      // 8. Amount Due
      final amountDueField = find.widgetWithText(TextField, 'Amount Due (₹)');
      await tester.enterText(amountDueField, '85000');

      // 9. Notes
      final notesField = find.widgetWithText(
        TextField,
        'Notes / Scope / Terms',
      );
      await tester.enterText(
        notesField,
        '15-day credit terms, delivers to DLF sites',
      );
      await tester.pumpAndSettle();

      // Submit
      final saveBtn = find.widgetWithText(
        ElevatedButton,
        'Save Vendor Profile',
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify all fields are cleanly displayed on the subsequent screen (VendorsView)
      expect(find.text('Greenply Decors'), findsOneWidget);
      expect(find.text('Plywood & Veneer'), findsWidgets);
      expect(find.text('Vikram Joshi'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('vikram@greenplydecors.com'), findsOneWidget);
      expect(find.text('Gurugram'), findsOneWidget);
      expect(find.text('Partial'), findsWidgets);
      expect(find.text('₹ 85,000'), findsWidgets);
      expect(
        find.text('15-day credit terms, delivers to DLF sites'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Task onboarding with title, description, department, urgent priority, project, assignee, and due date',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      await StorageService.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const MaterialApp(home: Scaffold(body: TasksView())),
        ),
      );
      await tester.pumpAndSettle();

      // Open Create Task modal
      final addBtn = find.widgetWithText(ElevatedButton, 'Add Task');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
      } else {
        MobileActionSheets.showCreateTaskSheet(
          tester.element(find.byType(TasksView)),
        );
      }
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.text('Create Project Task'), findsOneWidget);

      // 1. Project dropdown (first DropdownButtonFormField)
      expect(
        find.byType(DropdownButtonFormField<String>).first,
        findsOneWidget,
      );

      // 2. Title
      final titleField = find.widgetWithText(TextField, 'Task Title');
      await tester.enterText(titleField, 'Install False Ceiling LED Coves');

      // 3. Description
      final descField = find.widgetWithText(
        TextField,
        'Description / Scope of Work',
      );
      await tester.enterText(
        descField,
        'Use warm white 3000K strips with profile diffuser',
      );

      // 4. Department dropdown (second dropdown)
      final deptDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.ensureVisible(deptDropdown);
      await tester.tap(deptDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design & Architecture').last);
      await tester.pumpAndSettle();

      // 5. Priority dropdown (third dropdown) -> Select Urgent
      final priorityDropdown = find
          .byType(DropdownButtonFormField<String>)
          .at(2);
      await tester.ensureVisible(priorityDropdown);
      await tester.tap(priorityDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Urgent (Critical / Blocker)').last);
      await tester.pumpAndSettle();

      // Verify urgent red alert banner is displayed
      expect(
        find.textContaining(
          'URGENT: This task will be flagged with high-visibility red alert',
        ),
        findsOneWidget,
      );

      // 6. Assignee dropdown (fourth dropdown)
      final assigneeDropdown = find
          .byType(DropdownButtonFormField<String>)
          .at(3);
      await tester.ensureVisible(assigneeDropdown);
      await tester.tap(assigneeDropdown);
      await tester.pumpAndSettle();
      expect(find.textContaining('Vikram Malhotra'), findsWidgets);
      await tester.tap(find.textContaining('Vikram Malhotra').last);
      await tester.pumpAndSettle();

      // 7. Due Date calendar selector
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);

      // Submit
      final submitBtn = find.widgetWithText(ElevatedButton, 'Add Task').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify task card rendering on TasksView with urgent alert styling
      expect(find.text('Install False Ceiling LED Coves'), findsOneWidget);
      expect(
        find.text('Use warm white 3000K strips with profile diffuser'),
        findsOneWidget,
      );
      expect(find.text('Design & Architecture'), findsOneWidget);
      expect(find.text('Urgent'), findsWidgets);
      expect(find.textContaining('Vikram Malhotra'), findsOneWidget);
    },
  );
}
