import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/pdf_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class CreateInvoiceSheet {
  CreateInvoiceSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();
    final milestoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: AppSizes.sheetBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.brandPeach,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Generate Client Invoice',
                            style: AppTypography.titleLarge(isDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: milestoneController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Billing Stage (e.g. Milestone 2: False Ceiling)',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Invoice Amount (INR ₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPeach,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Generate & Send Invoice (GST Compliant)'),
                onPressed: () {
                  final milestone = milestoneController.text.trim().isEmpty
                      ? 'Turnkey Milestone Billing'
                      : milestoneController.text.trim();
                  final rawAmount = amountController.text.trim().replaceAll(
                    ',',
                    '',
                  );
                  final amount = rawAmount.isEmpty
                      ? '₹ 2,50,000'
                      : '₹ $rawAmount';
                  final newInvoice = {
                    'id':
                        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    'client': milestone,
                    'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
                    'amount': amount,
                    'status': 'Payment Pending',
                    'statusColor': AppColors.warning,
                  };
                  MobileActionSheets.invoiceCreatedNotifier.value = newInvoice;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'GST Tax Invoice generated successfully!',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'View PDF',
                        textColor: Colors.white,
                        onPressed: () {
                          PdfService.showPdfViewer(
                            context,
                            title: 'Tax Invoice ${newInvoice['id']}',
                            documentBuilder: () =>
                                PdfService.generateInvoicePdf(newInvoice),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
