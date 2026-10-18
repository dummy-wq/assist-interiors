import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'pdf/invoice_pdf_builder.dart';
import 'pdf/pdf_file_utils.dart';
import 'pdf/pdf_preview_dialog.dart';
import 'pdf/pnl_pdf_builder.dart';
import 'storage_service.dart';

export 'pdf/invoice_pdf_builder.dart';
export 'pdf/pdf_file_utils.dart';
export 'pdf/pdf_preview_dialog.dart';
export 'pdf/pdf_widgets.dart';
export 'pdf/pnl_pdf_builder.dart';

/// Central Facade for all PDF operations, invoicing, financial statements, and document previewing.
class PdfService {
  PdfService._();

  /// Formats currency safely for standard PDF Helvetica font (avoiding unicode symbol crashes).
  static String formatInr(num amount) => PdfFileUtils.formatInr(amount);

  /// Parses raw strings like "₹ 3,50,000" or "450000" into a safe double.
  static double parseAmount(String? raw) => PdfFileUtils.parseAmount(raw);

  /// Generates a GST-compliant tax invoice PDF.
  static Future<Uint8List> generateInvoicePdf(Map<String, dynamic> invoice) =>
      InvoicePdfBuilder.build(invoice);

  /// Generates an executive Profit & Loss statement PDF.
  static Future<Uint8List> generateProfitLossPdf({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> expenses,
  }) => PnlPdfBuilder.build(
    projects: projects,
    invoices: invoices,
    expenses: expenses,
  );

  /// Exports and saves the generated PDF bytes to the user's Downloads or Documents directory.
  static Future<File?> savePdfToDisk({
    required Uint8List bytes,
    required String fileName,
  }) => PdfFileUtils.savePdfToDisk(bytes: bytes, fileName: fileName);

  /// Launches the PDF file with the system default viewer or xdg-open.
  static Future<bool> openPdfFile(String filePath) =>
      PdfFileUtils.openPdfFile(filePath);

  /// Centrally launches the Executive Financial & P&L Statement PDF preview dialog.
  /// Deduplicates P&L generation calls across role dashboards and bottom navigation bars.
  static void showProfitLoss(
    BuildContext context, {
    List<Map<String, dynamic>>? projects,
    List<Map<String, dynamic>>? invoices,
    List<Map<String, dynamic>>? expenses,
  }) {
    showPdfViewer(
      context,
      title: 'Executive Financial & P&L Statement',
      documentBuilder: () => generateProfitLossPdf(
        projects: projects ?? StorageService.getProjects(),
        invoices: invoices ?? StorageService.getInvoices(),
        expenses: expenses ?? StorageService.getExpenses(),
      ),
    );
  }

  /// Displays a clean floating notification indicating the PDF file was saved,
  /// equipped with Open and Dismiss actions plus a dedicated close button.
  static void showExportSuccessSnackBar(BuildContext context, File file) =>
      PdfFileUtils.showExportSuccessSnackBar(context, file);

  /// Centrally launches an interactive PDF preview dialog.
  static Future<void> showPdfViewer(
    BuildContext context, {
    required String title,
    required Future<Uint8List> Function() documentBuilder,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          PdfPreviewDialog(title: title, documentBuilder: documentBuilder),
    );
  }
}
