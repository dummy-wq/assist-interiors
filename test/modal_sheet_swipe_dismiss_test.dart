import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/widgets/app_modal_sheet.dart';
import 'package:assist_interiors_dashboard/features/accounts/dialogs/invoice_qr_payment_dialog.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/more_modules_sheet.dart';
import 'package:assist_interiors_dashboard/features/projects/sheets/review_snags_sheet.dart';
import 'package:assist_interiors_dashboard/features/sales/sheets/schedule_call_sheet.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('Swipe-down dismissal across all slide-up bottom sheets', () {
    testWidgets('Non-scrollable sheet dismisses cleanly on swipe down', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAppModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: SizedBox(
                        height: 160,
                        child: Center(child: Text('Compact Sheet Body')),
                      ),
                    ),
                  );
                },
                child: const Text('Open Compact'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Compact'));
      await tester.pumpAndSettle();
      expect(find.text('Compact Sheet Body'), findsOneWidget);

      await tester.drag(
        find.text('Compact Sheet Body'),
        const Offset(0, 260),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compact Sheet Body'), findsNothing);
    });

    testWidgets(
      'Scrollable SingleChildScrollView sheet dismisses when swiping down at top (ClampingScrollPhysics)',
      (tester) async {
        tester.view.physicalSize = const Size(420, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SizedBox(
                        height: 500,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: List.generate(
                              20,
                              (i) => SizedBox(
                                height: 60,
                                child: Center(child: Text('Scroll Item $i')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Scrollable'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Scrollable'));
        await tester.pumpAndSettle();
        expect(find.text('Scroll Item 0'), findsOneWidget);

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 240),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scroll Item 0'), findsNothing);
      },
    );

    testWidgets(
      'Scrollable ListView sheet dismisses when swiping down at top (BouncingScrollPhysics)',
      (tester) async {
        tester.view.physicalSize = const Size(420, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SizedBox(
                        height: 500,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: 25,
                          itemBuilder: (_, i) => SizedBox(
                            height: 55,
                            child: Center(child: Text('Bounce Item $i')),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Bouncing'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Bouncing'));
        await tester.pumpAndSettle();
        expect(find.text('Bounce Item 0'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, 240));
        await tester.pumpAndSettle();

        expect(find.text('Bounce Item 0'), findsNothing);
      },
    );

    testWidgets(
      'Scrolled-down ListView scrolls back up instead of closing on swipe down, unless dragged by top header/handle',
      (tester) async {
        tester.view.physicalSize = const Size(420, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SizedBox(
                        height: 500,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sheet Fixed Header'),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: controller,
                                physics: const ClampingScrollPhysics(),
                                itemCount: 30,
                                itemBuilder: (_, i) => SizedBox(
                                  height: 60,
                                  child: Center(child: Text('Long Row $i')),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Long'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Long'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(controller.offset, greaterThan(100));

        await tester.drag(find.byType(ListView), const Offset(0, 120));
        await tester.pumpAndSettle();
        expect(find.text('Sheet Fixed Header'), findsOneWidget);

        await tester.drag(
          find.text('Sheet Fixed Header'),
          const Offset(0, 240),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sheet Fixed Header'), findsNothing);
      },
    );

    testWidgets('MoreModulesSheet dismisses with swipe down on mobile viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MoreModulesSheet.show(
                    context,
                    currentScreenIndex: 0,
                    pendingStaffCount: 2,
                    onSelectTab: (_) {},
                  );
                },
                child: const Text('Open More'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open More'));
      await tester.pumpAndSettle();
      expect(find.text('Assist Interiors Suite'), findsOneWidget);

      await tester.drag(
        find.text('Assist Interiors Suite'),
        const Offset(0, 250),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assist Interiors Suite'), findsNothing);
    });

    testWidgets('ReviewSnagsSheet and ScheduleCallSheet dismiss on swipe down', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => ReviewSnagsSheet.show(context),
                    child: const Text('Open Snags'),
                  ),
                  ElevatedButton(
                    onPressed: () => ScheduleCallSheet.show(context, {
                      'id': 'L1',
                      'client': 'Arjun Mehta',
                      'phone': '9876543210',
                    }),
                    child: const Text('Open Call'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Snags'));
      await tester.pumpAndSettle();
      expect(find.text('Site Snags & Delay Bottlenecks'), findsOneWidget);

      await tester.drag(
        find.text('Site Snags & Delay Bottlenecks'),
        const Offset(0, 280),
      );
      await tester.pumpAndSettle();
      expect(find.text('Site Snags & Delay Bottlenecks'), findsNothing);

      await tester.tap(find.text('Open Call'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule Call & Reminder'), findsOneWidget);

      await tester.drag(
        find.text('Schedule Call & Reminder'),
        const Offset(0, 280),
      );
      await tester.pumpAndSettle();
      expect(find.text('Schedule Call & Reminder'), findsNothing);
    });

    testWidgets(
      'InvoiceQrPaymentDialog (Scan & Pay Invoice) slides down and dismisses on mobile viewports',
      (tester) async {
        final testInvoice = {
          'id': 'INV-QR-1',
          'title': 'Milestone 1 Advance',
          'client': 'Aman Gupta',
          'project': 'Aman Gupta Mansion',
          'amount': '₹ 5,00,000',
          'status': 'Payment Pending',
          'qrCodeBase64': AppConstants.samplePaymentQrBase64,
          'upiId': 'assistinteriors@hdfcbank',
        };

        for (final size in const [Size(412, 860), Size(390, 620)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => InvoiceQrPaymentDialog.show(
                      context,
                      invoice: testInvoice,
                    ),
                    child: const Text('Pay via QR'),
                  ),
                ),
              ),
            ),
          );

          for (final targetText in [
            'Scan & Pay Invoice',
            'TOTAL PAYABLE AMOUNT',
            'SCAN WITH ANY UPI APP',
            if (size.height >= 800) 'assistinteriors@hdfcbank',
          ]) {
            await tester.tap(find.text('Pay via QR'));
            await tester.pumpAndSettle();
            expect(find.text('Scan & Pay Invoice'), findsOneWidget);

            await tester.drag(find.text(targetText), const Offset(0, 220));
            await tester.pumpAndSettle();
            expect(
              find.text('Scan & Pay Invoice'),
              findsNothing,
              reason: 'Failed dragging "$targetText" at viewport $size',
            );
          }

          await tester.tap(find.text('Pay via QR'));
          await tester.pumpAndSettle();
          final sheetSurface = find.ancestor(
            of: find.text('Scan & Pay Invoice'),
            matching: find.byType(Material),
          ).first;
          final beforeTop = tester.getTopLeft(sheetSurface).dy;
          final gesture = await tester.startGesture(
            tester.getCenter(find.text('Scan & Pay Invoice')),
          );
          await gesture.moveBy(const Offset(0, 24));
          await gesture.moveBy(const Offset(0, 105));
          await tester.pump();
          final midDragTop = tester.getTopLeft(sheetSurface).dy;
          expect(midDragTop, greaterThan(beforeTop + 80));
          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.text('Scan & Pay Invoice'), findsNothing);

          await tester.tap(find.text('Pay via QR'));
          await tester.pumpAndSettle();
          await tester.fling(
            find.text('TOTAL PAYABLE AMOUNT'),
            const Offset(0, 120),
            900,
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Scan & Pay Invoice'),
            findsNothing,
            reason: 'Failed flinging from amount card at viewport $size',
          );
        }
        tester.view.resetPhysicalSize();
      },
    );
  });
}
