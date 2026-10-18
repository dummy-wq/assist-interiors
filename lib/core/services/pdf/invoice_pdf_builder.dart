import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_file_utils.dart';
import 'pdf_widgets.dart';

/// Generates a GST-compliant tax invoice PDF.
class InvoicePdfBuilder {
  InvoicePdfBuilder._();

  static Future<Uint8List> build(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();

    final invoiceId =
        invoice['id']?.toString() ??
        'INV-${DateTime.now().millisecondsSinceEpoch}';
    final clientName =
        invoice['client']?.toString() ?? 'Corporate Turnkey Client';
    final invoiceDate =
        invoice['date']?.toString() ??
        DateFormat('dd MMM yyyy').format(DateTime.now());
    final status = invoice['status']?.toString() ?? 'Payment Pending';
    final totalAmount = PdfFileUtils.parseAmount(invoice['amount']?.toString());

    // Compute realistic architectural milestone line items
    // Base amount is subtotal before 18% GST (9% CGST + 9% SGST)
    final double subtotal = totalAmount > 0 ? (totalAmount / 1.18) : 250000.0;
    final double cgst = subtotal * 0.09;
    final double sgst = subtotal * 0.09;
    final double grandTotal = totalAmount > 0
        ? totalAmount
        : (subtotal + cgst + sgst);

    // Realistic milestone item breakdown
    final items = [
      {
        'desc': 'Modular Millwork & Veneer Panelling - Living & Master Suites',
        'sac': '9954',
        'qty': '1 Lot',
        'rate': subtotal * 0.40,
        'amount': subtotal * 0.40,
      },
      {
        'desc': 'False Ceiling Architectural POP Grid & Profile Channels',
        'sac': '9954',
        'qty': '1 Lot',
        'rate': subtotal * 0.25,
        'amount': subtotal * 0.25,
      },
      {
        'desc':
            'Electrical Conduit, Phase Distribution & Smart Automation Cabling',
        'sac': '9954',
        'qty': '1 Lot',
        'rate': subtotal * 0.20,
        'amount': subtotal * 0.20,
      },
      {
        'desc': 'Designer Hardware, Blum Fittings & Architectural Finishes',
        'sac': '9983',
        'qty': '1 Set',
        'rate': subtotal * 0.15,
        'amount': subtotal * 0.15,
      },
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ASSIST INTERIORS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Architecture | Interior Fitouts | Turnkey Execution',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Studio: Indiranagar 100ft Road, Bengaluru, KA 560038\nGSTIN: 29AABCA1234D1Z5 | PAN: AABCA1234D\nEmail: billing@assistinteriors.com | Ph: +91 98450 12345',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.blueGrey800,
                        width: 1.5,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'STATUS: ${status.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: status.toLowerCase().contains('settled')
                                ? PdfColors.green800
                                : status.toLowerCase().contains('overdue')
                                ? PdfColors.red800
                                : PdfColors.orange800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Invoice & Client Meta Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILLED TO / CLIENT:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            clientName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Site: Turnkey Architectural Interior Work\nState: Karnataka (Code: 29)\nSupply Type: Intra-State Works Contract',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                              lineSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          PdfWidgets.metaRow('Invoice Number:', invoiceId),
                          PdfWidgets.metaRow('Invoice Date:', invoiceDate),
                          PdfWidgets.metaRow('Payment Terms:', 'Net 15 Days'),
                          PdfWidgets.metaRow(
                            'Place of Supply:',
                            'Bengaluru (29)',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Line Items Table
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6),
                  1: const pw.FlexColumnWidth(3.8),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(0.8),
                  4: const pw.FlexColumnWidth(1.4),
                  5: const pw.FlexColumnWidth(1.6),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                    ),
                    children: [
                      PdfWidgets.tableHeaderCell(
                        '#',
                        align: pw.TextAlign.center,
                      ),
                      PdfWidgets.tableHeaderCell(
                        'Description of Work / Deliverable',
                      ),
                      PdfWidgets.tableHeaderCell(
                        'SAC/HSN',
                        align: pw.TextAlign.center,
                      ),
                      PdfWidgets.tableHeaderCell(
                        'Qty',
                        align: pw.TextAlign.center,
                      ),
                      PdfWidgets.tableHeaderCell(
                        'Rate',
                        align: pw.TextAlign.right,
                      ),
                      PdfWidgets.tableHeaderCell(
                        'Amount',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  // Items
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final itm = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0
                            ? PdfColors.grey50
                            : PdfColors.white,
                      ),
                      children: [
                        PdfWidgets.tableCell(
                          '$idx',
                          align: pw.TextAlign.center,
                        ),
                        PdfWidgets.tableCell(itm['desc'] as String),
                        PdfWidgets.tableCell(
                          itm['sac'] as String,
                          align: pw.TextAlign.center,
                        ),
                        PdfWidgets.tableCell(
                          itm['qty'] as String,
                          align: pw.TextAlign.center,
                        ),
                        PdfWidgets.tableCell(
                          PdfFileUtils.formatInr(itm['rate'] as num),
                          align: pw.TextAlign.right,
                        ),
                        PdfWidgets.tableCell(
                          PdfFileUtils.formatInr(itm['amount'] as num),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // Tax Summary & Calculations
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left side: Bank Details & Notes
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BANK TRANSFER DETAILS (NEFT / RTGS):',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey800,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Account Name: Assist Interiors Private Limited',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'Account No: 50200084729103',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'Bank & Branch: HDFC Bank, Indiranagar Branch',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'IFSC Code: HDFC0000128',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Notes: Please quote invoice number during wire transfer. Turnkey fitouts are carried out under standard architectural warranty terms.',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),

                  // Right side: Totals & Tax
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          PdfWidgets.calculationRow(
                            'Taxable Subtotal:',
                            PdfFileUtils.formatInr(subtotal),
                          ),
                          pw.SizedBox(height: 3),
                          PdfWidgets.calculationRow(
                            'CGST (9.0%):',
                            PdfFileUtils.formatInr(cgst),
                          ),
                          pw.SizedBox(height: 3),
                          PdfWidgets.calculationRow(
                            'SGST (9.0%):',
                            PdfFileUtils.formatInr(sgst),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 1, color: PdfColors.grey400),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TOTAL DUE:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blueGrey900,
                                ),
                              ),
                              pw.Text(
                                PdfFileUtils.formatInr(grandTotal),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blueGrey900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Footer Sign-Off
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'This is a computer-generated invoice issued by Assist Interiors PMS.\nRegistered Office: Bengaluru, Karnataka, India.',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 130,
                        height: 1,
                        color: PdfColors.blueGrey800,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'For ASSIST INTERIORS PVT LTD',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        'Authorized Signatory',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
