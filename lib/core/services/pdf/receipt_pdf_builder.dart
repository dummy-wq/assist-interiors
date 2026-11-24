import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../constants/app_constants.dart';
import 'pdf_file_utils.dart';

/// Generates a clean Payment Receipt PDF.
class ReceiptPdfBuilder {
  ReceiptPdfBuilder._();

  static Future<Uint8List> build(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();

    final receiptId =
        receipt['id']?.toString() ??
        'RCP-${DateTime.now().millisecondsSinceEpoch}';
    final title = receipt['title']?.toString() ?? 'Payment Receipt';
    final party = receipt['party']?.toString() ?? 'Client / Vendor';
    final project = receipt['project']?.toString() ?? 'General Studio';
    final type = receipt['type']?.toString() ?? 'Payment Received';
    final mode = receipt['paymentMode']?.toString() ?? 'UPI';
    final date =
        receipt['timestamp']?.toString() ??
        receipt['date']?.toString() ??
        DateFormat('dd MMM yyyy').format(DateTime.now());
    final status = receipt['status']?.toString() ?? 'Verified';
    final notes = receipt['notes']?.toString() ?? '';
    final amount = PdfFileUtils.parseAmount(receipt['amount']?.toString());

    final peachAccent = PdfColor.fromInt(0xFFF3B9A8);
    final slateDark = PdfColor.fromInt(0xFF1F2937);
    final slateMuted = PdfColor.fromInt(0xFF6B7280);
    final borderGray = PdfColor.fromInt(0xFFE5E7EB);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppConstants.appName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: slateDark,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppConstants.appTagline,
                      style: pw.TextStyle(fontSize: 10, color: slateMuted),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: peachAccent,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: slateDark,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(color: borderGray),
            pw.SizedBox(height: 16),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: slateDark,
              ),
            ),
            pw.SizedBox(height: 16),
            _infoRow('Receipt ID', receiptId, slateMuted, slateDark),
            _infoRow('Date', date, slateMuted, slateDark),
            _infoRow('Party', party, slateMuted, slateDark),
            _infoRow('Project Site', project, slateMuted, slateDark),
            _infoRow('Receipt Type', type, slateMuted, slateDark),
            _infoRow('Payment Mode', mode, slateMuted, slateDark),
            _infoRow('Status', status, slateMuted, slateDark),
            if (notes.isNotEmpty) _infoRow('Notes', notes, slateMuted, slateDark),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9FAFB),
                border: pw.Border.all(color: borderGray),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Receipt Amount',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: slateDark,
                    ),
                  ),
                  pw.Text(
                    PdfFileUtils.formatInr(amount),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: slateDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    PdfColor labelColor,
    PdfColor valueColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: labelColor),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
