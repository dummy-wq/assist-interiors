import 'package:flutter_test/flutter_test.dart';
import 'package:assist_interiors_dashboard/core/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfService Tests', () {
    test('generateInvoicePdf produces non-empty valid PDF byte data', () async {
      final sampleInvoice = {
        'id': 'INV-2024-884',
        'client': 'Prestige Golfshire Villa 14',
        'date': '12 Oct 2026',
        'amount': '₹ 4,75,000',
        'status': 'Payment Pending',
      };

      final bytes = await PdfService.generateInvoicePdf(sampleInvoice);

      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(500));
      // Standard PDF files start with %PDF-
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test(
      'generateProfitLossPdf produces non-empty valid PDF document',
      () async {
        final projects = [
          {
            'id': 'PRJ-1',
            'name': 'Sobha City Penthouse',
            'client': 'Siddharth V.',
            'budget': '₹ 75,00,000',
            'progress': 0.65,
          },
        ];

        final invoices = [
          {
            'id': 'INV-101',
            'client': 'Siddharth V.',
            'date': '01 Oct 2026',
            'amount': '₹ 25,00,000',
            'status': 'Settled',
          },
          {
            'id': 'INV-102',
            'client': 'Siddharth V.',
            'date': '10 Oct 2026',
            'amount': '₹ 15,00,000',
            'status': 'Payment Pending',
          },
        ];

        final expenses = [
          {
            'id': 'EXP-1',
            'title': 'Teak Veneer Sheets Batch #4',
            'project': 'Sobha City Penthouse',
            'category': 'Modular Woodwork & Veneers',
            'amount': '₹ 4,80,000',
            'date': '05 Oct 2026',
          },
        ];

        final bytes = await PdfService.generateProfitLossPdf(
          projects: projects,
          invoices: invoices,
          expenses: expenses,
        );

        expect(bytes, isNotNull);
        expect(bytes.length, greaterThan(500));
        final header = String.fromCharCodes(bytes.take(5));
        expect(header, equals('%PDF-'));
      },
    );

    test('parseAmount parses both formatted and raw values cleanly', () {
      expect(PdfService.parseAmount('₹ 3,50,000'), equals(350000.0));
      expect(PdfService.parseAmount('45000'), equals(45000.0));
      expect(PdfService.parseAmount('₹ 1,25,00,000'), equals(12500000.0));
      expect(PdfService.parseAmount(null), equals(0.0));
    });

    test('formatInr produces formatted INR strings safely', () {
      final str = PdfService.formatInr(350000);
      expect(str, contains('3,50,000'));
      expect(str, contains('INR'));
    });
  });
}
