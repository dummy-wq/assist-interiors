import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assist_interiors_dashboard/core/constants/app_constants.dart';
import 'package:assist_interiors_dashboard/core/models/invoice_model.dart';
import 'package:assist_interiors_dashboard/core/services/storage_service.dart';
import 'package:assist_interiors_dashboard/core/services/backend_manager.dart';
import 'package:assist_interiors_dashboard/core/theme/app_colors.dart';
import 'package:assist_interiors_dashboard/features/auth/state/auth_provider.dart';
import 'package:assist_interiors_dashboard/features/accounts/dialogs/invoice_qr_payment_dialog.dart';
import 'package:assist_interiors_dashboard/features/accounts/dialogs/upload_invoice_qr_sheet.dart';
import 'package:assist_interiors_dashboard/features/dashboard/views/accounts_dashboard.dart';
import 'package:assist_interiors_dashboard/features/dashboard/widgets/mobile_action_sheets.dart';
import 'package:assist_interiors_dashboard/features/sales/services/sales_pipeline_service.dart';
import 'package:assist_interiors_dashboard/features/sales/views/sales_view.dart';
import 'package:assist_interiors_dashboard/features/projects/views/projects_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await BackendManager.instance.clearAll();
  });

  Widget createTestWidget(
    Widget child, {
    UserRole role = UserRole.proprietor,
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

  group('InvoiceModel Unit Tests', () {
    test('InvoiceModel maps and serializes projectId, leadId, QR code, and UPI ID', () {
      final model = InvoiceModel(
        id: 'INV-TEST-999',
        client: 'Vikramaditya Birla',
        project: 'Birla Heritage Villa',
        projectId: 'proj_birla_01',
        leadId: 'lead_birla_01',
        leadName: 'Vikramaditya Birla',
        title: 'Milestone 1: Civil & Drywall Fitout',
        date: '15 Nov 2026',
        amount: '₹ 15,00,000',
        status: 'Payment Pending',
        statusColor: AppColors.warning,
        qrCodeBase64: AppConstants.samplePaymentQrBase64,
        upiId: 'assistinteriors@hdfcbank',
      );

      final map = model.toMap();
      expect(map['id'], 'INV-TEST-999');
      expect(map['projectId'], 'proj_birla_01');
      expect(map['leadId'], 'lead_birla_01');
      expect(map['leadName'], 'Vikramaditya Birla');
      expect(map['project'], 'Birla Heritage Villa');
      expect(map['qrCodeBase64'], AppConstants.samplePaymentQrBase64);
      expect(map['upiId'], 'assistinteriors@hdfcbank');

      final reconstructed = InvoiceModel.fromMap(map);
      expect(reconstructed.id, 'INV-TEST-999');
      expect(reconstructed.projectId, 'proj_birla_01');
      expect(reconstructed.leadId, 'lead_birla_01');
      expect(reconstructed.leadName, 'Vikramaditya Birla');
      expect(reconstructed.qrCodeBase64, AppConstants.samplePaymentQrBase64);
      expect(reconstructed.upiId, 'assistinteriors@hdfcbank');

      final copied = model.copyWith(status: 'Settled', statusColor: AppColors.success);
      expect(copied.status, 'Settled');
      expect(copied.statusColor, AppColors.success);
      expect(copied.projectId, 'proj_birla_01');
    });
  });

  group('UploadInvoiceQrSheet & InvoiceQrPaymentDialog UI Widget Tests', () {
    testWidgets('UploadInvoiceQrSheet allows attaching studio QR code and saves to invoice', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      // Seed an invoice with no QR
      final testInv = {
        'id': 'INV-QR-TEST-01',
        'invoiceNumber': 'INV-QR-TEST-01',
        'title': 'False Ceiling Advance',
        'client': 'Aarav Singhania',
        'project': 'Singhania Sky Penthouse',
        'amount': '₹ 5,00,000',
        'status': 'Payment Pending',
        'date': '15 Nov 2026',
        'statusColor': AppColors.warning,
      };
      await StorageService.saveInvoices([testInv]);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                UploadInvoiceQrSheet.show(ctx, invoiceId: 'INV-QR-TEST-01');
              },
              child: const Text('Open QR Upload'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open QR Upload'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Invoice QR Code'), findsOneWidget);
      expect(find.text('Attach payment QR photo to INV-QR-TEST-01'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Use Sample Studio HDFC UPI QR Code'), findsOneWidget);

      // Tap preset studio QR code
      await tester.tap(find.text('Use Sample Studio HDFC UPI QR Code'));
      await tester.pumpAndSettle();

      expect(find.text('Payment QR Ready to Attach'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save QR Code to INV-QR-TEST-01'));
      await tester.pumpAndSettle();

      // Verify invoice in storage has QR code base64
      final storedInvoices = StorageService.getInvoices();
      final updated = storedInvoices.firstWhere((i) => i['id'] == 'INV-QR-TEST-01');
      expect(updated['qrCodeBase64'], AppConstants.samplePaymentQrBase64);
      expect(updated['upiId'], AppConstants.defaultUpiId);
    });

    testWidgets('InvoiceQrPaymentDialog renders payment details and marks as Settled', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      final testInv = {
        'id': 'INV-PAY-01',
        'invoiceNumber': 'INV-PAY-01',
        'title': 'Italian Marble Advance',
        'client': 'Rhea Kapoor',
        'project': 'Kapoor Palm Villa',
        'leadName': 'Rhea Kapoor',
        'amount': '₹ 12,00,000',
        'status': 'Payment Pending',
        'statusColor': AppColors.warning,
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': 'assistinteriors@hdfcbank',
      };
      await StorageService.saveInvoices([testInv]);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                InvoiceQrPaymentDialog.show(ctx, invoice: testInv);
              },
              child: const Text('Open Payment Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Payment Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Scan & Pay Invoice'), findsOneWidget);
      expect(find.text('Project: Kapoor Palm Villa'), findsOneWidget);
      expect(find.text('Lead: Rhea Kapoor'), findsOneWidget);
      expect(find.text('₹ 12,00,000'), findsOneWidget);
      expect(find.text('SCAN WITH ANY UPI APP'), findsOneWidget);
      expect(find.text('assistinteriors@hdfcbank'), findsOneWidget);
      expect(find.text('Pay via UPI App'), findsOneWidget);
      expect(find.text('Mark Paid'), findsOneWidget);

      // Tap Mark Paid
      await tester.tap(find.text('Mark Paid'));
      await tester.pumpAndSettle();

      // Check stored invoice status is Settled
      final storedInvoices = StorageService.getInvoices();
      final settledInv = storedInvoices.firstWhere((i) => i['id'] == 'INV-PAY-01');
      expect(settledInv['status'], 'Settled');
    });
  });

  group('AccountsDashboard QR & Mapping Integration', () {
    testWidgets('AccountsDashboard lists mapped project/lead and renders QR action button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      final mappedInvoice = {
        'id': 'INV-ACC-01',
        'title': 'Turnkey Fitout Phase 1',
        'client': 'Kavita Verma',
        'project': 'Kavita Verma Residence',
        'leadName': 'Kavita Verma',
        'amount': '₹ 8,50,000',
        'status': 'Payment Pending',
        'date': '15 Nov 2026',
        'statusColor': AppColors.warning,
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': 'assistinteriors@hdfcbank',
      };
      await StorageService.saveInvoices([mappedInvoice]);

      await tester.pumpWidget(createTestWidget(const AccountsDashboard()));
      await tester.pumpAndSettle();

      // Verify mapped Project badge
      expect(find.text('Kavita Verma Residence'), findsWidgets);
      expect(find.textContaining('INV-ACC-01', skipOffstage: false), findsWidgets);
      expect(find.text('₹ 8,50,000', skipOffstage: false), findsWidgets);

      // Find the QR code payment icon button
      final qrIconFinder = find.byIcon(Icons.qr_code_2_rounded);
      expect(qrIconFinder, findsWidgets);

      // Tap the QR action button
      await tester.tap(qrIconFinder.first);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Scan & Pay Invoice'), findsOneWidget);
      expect(find.text('Project: Kavita Verma Residence'), findsOneWidget);
      expect(find.text('₹ 8,50,000'), findsWidgets);
    });
  });

  group('CreateInvoiceSheet Mapping to Project & Lead', () {
    testWidgets('CreateInvoiceSheet maps selected project and lead and attaches QR code', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      // Seed project and lead
      final testProject = {
        'id': 'proj_custom_101',
        'name': 'Bespoke Oberoi Penthouse',
        'client': 'Sameer Kulkarni',
        'location': 'Borivali West',
        'budget': '₹ 1,50,00,000',
        'status': 'In Progress',
        'stages': [],
      };
      final testLead = {
        'id': 'lead_custom_101',
        'name': 'Sameer Kulkarni',
        'client': 'Sameer Kulkarni',
        'phone': '+91 98200 11223',
        'stage': 'Approved',
        'status': 'Approved',
      };
      await StorageService.saveProjects([testProject]);
      await StorageService.saveLeads([testLead]);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                CreateInvoiceSheet.show(
                  ctx,
                  initialProjectId: 'proj_custom_101',
                  initialLeadId: 'lead_custom_101',
                  initialAmount: '450000',
                  initialMilestone: 'Milestone 3: Millwork & Polishing',
                );
              },
              child: const Text('Open Create Invoice'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Create Invoice'));
      await tester.pumpAndSettle();

      expect(find.text('Generate Client Invoice'), findsOneWidget);
      expect(find.text('Payment QR Attached'), findsOneWidget);

      // Submit invoice
      await tester.tap(find.text('Generate & Send Invoice (GST Compliant)'));
      await tester.pumpAndSettle();

      // Check invoice created in MobileActionSheets notifier
      final created = MobileActionSheets.invoiceCreatedNotifier.value;
      expect(created, isNotNull);
      expect(created!['projectId'], 'proj_custom_101');
      expect(created['leadId'], 'lead_custom_101');
      expect(created['title'], 'Milestone 3: Millwork & Polishing');
      expect(created['amount'], '₹ 450000');
      expect(created['qrCodeBase64'], AppConstants.samplePaymentQrBase64);
    });
  });

  group('Sales Pipeline & Project Cross-Tab Propagation with QR', () {
    test('SalesPipelineService.approveLeadAndMoveToProjects provisions 10% mobilization invoice with mapped data and QR code', () async {
      final lead = {
        'id': 'lead_turnkey_auto',
        'client': 'Pooja Hegde',
        'name': 'Pooja Hegde',
        'phone': '+91 98888 77777',
        'scope': 'Turnkey Duplex Penthouse',
        'location': 'Koregaon Park, Pune',
        'estValue': '₹ 30,00,000',
        'stage': 'BOQ',
        'status': 'BOQ',
      };
      await StorageService.saveLeads([lead]);

      final result = await SalesPipelineService.approveLeadAndMoveToProjects(lead);
      final updatedLead = result['lead'] as Map<String, dynamic>;
      expect(updatedLead['stage'], 'Approved');
      expect(updatedLead['isConverted'], true);
      expect(updatedLead['projectId'], isNotNull);

      // Verify auto-generated mobilization advance invoice in StorageService
      final invoices = StorageService.getInvoices();
      final advanceInv = invoices.firstWhere(
        (i) => (i['title'] ?? '').toString().contains('Mobilization Advance (10%)'),
      );
      expect(advanceInv['client'], 'Pooja Hegde');
      expect(advanceInv['leadId'], 'lead_turnkey_auto');
      expect(advanceInv['projectId'], isNotNull);
      expect(advanceInv['qrCodeBase64'], AppConstants.samplePaymentQrBase64);
      expect(advanceInv['upiId'], AppConstants.defaultUpiId);
      expect(advanceInv['amount'], '₹ 3,00,000');
    });

    testWidgets('SalesView lead card displays mapped invoice with Pay via QR button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      final lead = {
        'id': 'lead_vis_01',
        'client': 'Aditya Roy',
        'name': 'Aditya Roy',
        'phone': '+91 97777 66666',
        'scope': '3BHK Fitout',
        'location': 'Bandra West',
        'estValue': '₹ 50,00,000',
        'stage': 'Approved',
        'status': 'Approved',
        'convertedToProject': 'Aditya Roy Residence',
      };
      final invoice = {
        'id': 'INV-VIS-01',
        'title': 'Aditya Roy Residence - Mobilization Advance (10%)',
        'client': 'Aditya Roy',
        'leadId': 'lead_vis_01',
        'project': 'Aditya Roy Residence',
        'amount': '₹ 5,00,000',
        'status': 'Sent',
        'statusColor': AppColors.warning,
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': 'assistinteriors@hdfcbank',
      };
      await StorageService.saveLeads([lead]);
      await StorageService.saveInvoices([invoice]);

      await tester.pumpWidget(createTestWidget(const SalesView(), role: UserRole.sales));
      await tester.pumpAndSettle();

      // Lead card should display mapped invoice
      expect(find.text('Aditya Roy Residence - Mobilization Advance (10%)'), findsOneWidget);
      expect(find.text('Pay via QR'), findsWidgets);

      // Tap Pay via QR
      await tester.tap(find.text('Pay via QR').first);
      await tester.pumpAndSettle();

      // QR payment dialog should appear
      expect(find.text('Scan & Pay Invoice'), findsOneWidget);
      expect(find.text('₹ 5,00,000'), findsOneWidget);
    });

    testWidgets('ProjectsView project card displays mapped invoice without Pay via QR button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      final project = {
        'id': 'proj_vis_02',
        'name': 'Oberoi Crest Villa',
        'client': 'Devansh Mittal',
        'location': 'Juhu, Mumbai',
        'type': 'Villa Interiors',
        'budget': '₹ 80,00,000',
        'spent': '₹ 20,00,000',
        'pm': 'Rahul Mehta',
        'supervisor': 'Vikram Rao',
        'status': 'In Progress',
        'stages': [],
      };
      final invoice = {
        'id': 'INV-PROJ-02',
        'title': 'Oberoi Crest Villa - Milestone 1',
        'client': 'Devansh Mittal',
        'projectId': 'proj_vis_02',
        'project': 'Oberoi Crest Villa',
        'amount': '₹ 8,00,000',
        'status': 'Pending Payment',
        'statusColor': AppColors.warning,
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': 'assistinteriors@hdfcbank',
      };
      await StorageService.saveProjects([project]);
      await StorageService.saveInvoices([invoice]);

      await tester.pumpWidget(createTestWidget(const ProjectsView(), role: UserRole.proprietor));
      await tester.pumpAndSettle();

      // Expand project card inline details
      await tester.tap(find.text('Tap to view stages, photos & design assets'));
      await tester.pumpAndSettle();

      // Project card displays billing info without Pay via QR option
      expect(find.text('Oberoi Crest Villa - Milestone 1'), findsOneWidget);
      expect(find.text('₹ 8,00,000 • Status: Pending Payment'), findsOneWidget);
      expect(find.text('Pay via QR'), findsNothing);
    });
  });
}
