import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';
import '../dialogs/upload_invoice_qr_sheet.dart';
import '../dialogs/invoice_qr_payment_dialog.dart';

import '../../../core/utils/app_notification.dart';
class CreateInvoiceSheet {
  CreateInvoiceSheet._();

  static void show(
    BuildContext context, {
    String? initialProjectId,
    String? initialProjectName,
    String? initialLeadId,
    String? initialClient,
    String? initialAmount,
    String? initialMilestone,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(text: initialAmount ?? '');
    final milestoneController = TextEditingController(
      text: initialMilestone ?? '',
    );

    final projects = StorageService.getProjects();
    final leads = StorageService.getLeads();

    String? selectedProjectId = initialProjectId;
    String? selectedProjectName = initialProjectName;
    if (selectedProjectId != null && selectedProjectName == null) {
      final p = projects.firstWhere(
        (proj) => proj['id'] == selectedProjectId,
        orElse: () => <String, dynamic>{},
      );
      if (p.isNotEmpty) {
        selectedProjectName = p['name'] as String?;
      }
    }

    String? selectedLeadId = initialLeadId;
    String? selectedLeadName = initialClient;
    if (selectedLeadId != null && selectedLeadName == null) {
      final l = leads.firstWhere(
        (lead) => lead['id'] == selectedLeadId,
        orElse: () => <String, dynamic>{},
      );
      if (l.isNotEmpty) {
        selectedLeadName = (l['client'] ?? l['name']) as String?;
      }
    }

    String? capturedQrPath;
    String? capturedQrBase64 = AppConstants.samplePaymentQrBase64;
    String attachedUpiId = AppConstants.defaultUpiId;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final hasQr = (capturedQrPath != null &&
                    !kIsWeb &&
                    File(capturedQrPath!).existsSync()) ||
                (capturedQrBase64 != null && capturedQrBase64!.isNotEmpty);

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom +
                    AppSizes.sheetBottomPadding(modalContext),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.15,
                                  ),
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
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mapped Project Selector
                    QuickFadeDropdown<String?>(
                      initialValue: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Project (Optional)',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...projects.map((proj) {
                          final id = proj['id']?.toString() ?? '';
                          final name = proj['name']?.toString() ?? 'Project';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedProjectId = val;
                          if (val != null) {
                            final match = projects.firstWhere(
                              (p) => p['id'] == val,
                              orElse: () => <String, dynamic>{},
                            );
                            selectedProjectName = match['name'] as String?;
                            if (match['client'] != null &&
                                selectedLeadName == null) {
                              selectedLeadName = match['client'] as String?;
                            }
                            if (match['originLeadId'] != null) {
                              selectedLeadId =
                                  match['originLeadId'] as String?;
                            }
                          } else {
                            selectedProjectName = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mapped Lead Selector
                    QuickFadeDropdown<String?>(
                      initialValue: selectedLeadId,
                      decoration: const InputDecoration(
                        labelText: 'Sales Lead / Client (Optional)',
                        prefixIcon: Icon(Icons.person_pin_circle_rounded),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...leads.map((l) {
                          final id = l['id']?.toString() ?? '';
                          final clientName =
                              (l['client'] ?? l['name'])?.toString() ?? 'Lead';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(
                              clientName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedLeadId = val;
                          if (val != null) {
                            final match = leads.firstWhere(
                              (l) => l['id'] == val,
                              orElse: () => <String, dynamic>{},
                            );
                            selectedLeadName =
                                (match['client'] ?? match['name']) as String?;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Billing Stage TextField
                    TextField(
                      controller: milestoneController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Billing Stage (e.g. Milestone 2: False Ceiling)',
                          ),
                        ),
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Invoice Amount TextField
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Invoice Amount (INR ₹)'),
                        ),
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment QR Code Card / Action
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: hasQr
                              ? AppColors.success.withValues(alpha: 0.5)
                              : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)
                                  .withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: AppColors.brandPeach,
                                width: 0.8,
                              ),
                            ),
                            child: hasQr
                                ? (capturedQrPath != null &&
                                        !kIsWeb &&
                                        File(capturedQrPath!).existsSync()
                                    ? Image.file(
                                        File(capturedQrPath!),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.memory(
                                        base64Decode(capturedQrBase64!),
                                        fit: BoxFit.contain,
                                      ))
                                : const Icon(
                                    Icons.qr_code_2_rounded,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        hasQr
                                            ? 'Payment QR Attached'
                                            : 'Payment QR Code',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: hasQr
                                              ? AppColors.success
                                              : (isDark
                                                  ? AppColors.textLightPrimary
                                                  : AppColors.textDarkPrimary),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasQr) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: AppColors.success,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  attachedUpiId,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandPeach,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            icon: Icon(
                              hasQr
                                  ? Icons.change_circle_outlined
                                  : Icons.add_a_photo_outlined,
                              size: 14,
                            ),
                            label: Text(
                              hasQr ? 'Change' : 'Upload QR',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              UploadInvoiceQrSheet.show(
                                modalContext,
                                currentQrPath: capturedQrPath,
                                currentQrBase64: capturedQrBase64,
                                currentUpiId: attachedUpiId,
                                onQrSelected: (newPath, newB64, newUpi) {
                                  setModalState(() {
                                    capturedQrPath = newPath;
                                    capturedQrBase64 = newB64;
                                    attachedUpiId = newUpi;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                      ),
                      child:
                          const Text('Generate & Send Invoice (GST Compliant)'),
                      onPressed: () {
                        final milestone = milestoneController.text.trim().isEmpty
                            ? 'Turnkey Milestone Billing'
                            : milestoneController.text.trim();
                        final rawAmount = amountController.text
                            .trim()
                            .replaceAll(',', '');
                        final amount =
                            rawAmount.isEmpty ? '₹ 2,50,000' : '₹ $rawAmount';

                        final clientDisplayName = selectedLeadName ??
                            selectedProjectName ??
                            milestone;

                        final newInvoice = <String, dynamic>{
                          'id':
                              'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          'client': clientDisplayName,
                          'title': milestone,
                          'project': selectedProjectName,
                          'projectId': selectedProjectId,
                          'leadId': selectedLeadId,
                          'leadName': selectedLeadName ?? clientDisplayName,
                          'date':
                              DateFormat('dd MMM yyyy').format(DateTime.now()),
                          'dueDate': DateFormat('dd MMM yyyy').format(
                            DateTime.now().add(const Duration(days: 15)),
                          ),
                          'amount': amount,
                          'direction': 'incoming',
                          'status': 'Payment Pending',
                          'statusColor': AppColors.warning,
                          'qrCodePath': ?capturedQrPath,
                          'qrCodeBase64': ?capturedQrBase64,
                          'upiId': attachedUpiId,
                          'createdAt': DateTime.now().toIso8601String(),
                        };

                        MobileActionSheets.invoiceCreatedNotifier.value =
                            newInvoice;
                        Navigator.pop(modalContext);

                        AppNotification.show(context, message: 'GST Tax Invoice generated successfully with Payment QR!', backgroundColor: AppColors.success, action: SnackBarAction(
                              label: 'Pay via QR',
                              textColor: Colors.white,
                              onPressed: () {
                                InvoiceQrPaymentDialog.show(
                                  context,
                                  invoice: newInvoice,
                                );
                              },
                            ));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
