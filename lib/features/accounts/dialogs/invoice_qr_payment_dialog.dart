import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';
import 'upload_invoice_qr_sheet.dart';

import '../../../core/utils/app_notification.dart';
class InvoiceQrPaymentDialog {
  InvoiceQrPaymentDialog._();

  static void show(
    BuildContext context, {
    required Map<String, dynamic> invoice,
    VoidCallback? onStatusChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Map<String, dynamic> currentInvoice = Map<String, dynamic>.from(invoice);

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final invId = currentInvoice['id']?.toString() ??
                currentInvoice['invoiceNumber']?.toString() ??
                'INV';
            final title = (currentInvoice['title'] ??
                currentInvoice['client'] ??
                'Tax Invoice') as String;
            final amount = (currentInvoice['amount'] ?? '₹ 0') as String;
            final status = (currentInvoice['status'] ?? 'Payment Pending') as String;
            final isSettled =
                status.toLowerCase() == 'settled' || status.toLowerCase() == 'paid';
            final statusColor = isSettled ? AppColors.success : AppColors.warning;

            final projectName = (currentInvoice['project'] ??
                currentInvoice['projectName'] ??
                '') as String;
            final clientOrLead = (currentInvoice['leadName'] ??
                currentInvoice['client'] ??
                '') as String;

            final qrPath = currentInvoice['qrCodePath']?.toString();
            final qrBase64 = currentInvoice['qrCodeBase64']?.toString() ??
                (qrPath == null ? AppConstants.samplePaymentQrBase64 : null);
            final upiId = currentInvoice['upiId']?.toString() ??
                AppConstants.defaultUpiId;

            final hasImage =
                (qrPath != null && !kIsWeb && File(qrPath).existsSync()) ||
                (qrBase64 != null && qrBase64.isNotEmpty);

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: AppSizes.sheetBottomPadding(modalContext),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fixed Header outside scroll so swiping header always slides sheet down
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
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color: AppColors.brandPeach,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan & Pay Invoice',
                                    style: AppTypography.titleLarge(isDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$invId • $title',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                    // Mapped Project & Lead Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (projectName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.business_rounded,
                                  size: 13,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Project: $projectName',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (clientOrLead.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: AppColors.brandOrange.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_pin_circle_rounded,
                                  size: 13,
                                  color: AppColors.brandOrange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Lead: $clientOrLead',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.south_west_rounded,
                                size: 12,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Incoming Payment',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Amount Due Callout
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAYABLE AMOUNT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                amount,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (isSettled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Settled',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Frame
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.brandPeach.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (hasImage) ...[
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: qrPath != null &&
                                        !kIsWeb &&
                                        File(qrPath).existsSync()
                                    ? Image.file(
                                        File(qrPath),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.memory(
                                        base64Decode(qrBase64!),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ] else ...[
                              Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade100,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 54,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brandPeach,
                                        foregroundColor: Colors.black,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () {
                                        UploadInvoiceQrSheet.show(
                                          modalContext,
                                          invoiceId: invId,
                                          currentUpiId: upiId,
                                          onQrSelected: (path, b64, id) {
                                            setModalState(() {
                                              currentInvoice['qrCodePath'] = path;
                                              currentInvoice['qrCodeBase64'] = b64;
                                              currentInvoice['upiId'] = id;
                                            });
                                          },
                                        );
                                      },
                                      child: const Text('Upload QR Photo'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'SCAN WITH ANY UPI APP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GPay • PhonePe • Paytm • BHIM • Mobile Banking',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payee & UPI ID Details
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BENEFICIARY UPI ID',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  upiId,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textLightPrimary
                                        : AppColors.textDarkPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InstantPressFeedback(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 13),
                              label: const Text(
                                'Copy',
                                style: TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: upiId));
                                AppNotification.show(modalContext, message: 'Copied "$upiId" to clipboard!');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Primary Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPeach,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: const Text(
                              'Pay via UPI App',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            onPressed: () async {
                              final parsedAmt = CurrencyUtils.parseAmount(amount);
                              final cleanAmt = parsedAmt > 0
                                  ? '$parsedAmt'
                                  : '1000';
                              final uri = Uri.parse(
                                'upi://pay?pa=$upiId&pn=${Uri.encodeComponent('Assist Interiors')}&am=$cleanAmt&cu=INR&tn=${Uri.encodeComponent('Invoice $invId')}',
                              );
                              try {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (modalContext.mounted) {
                                    AppNotification.show(modalContext, message: 'UPI App not detected. Copied $upiId to clipboard.');
                                  }
                                }
                              } catch (_) {
                                // Safe fallback
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isSettled
                              ? OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    side: const BorderSide(
                                      color: AppColors.success,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.undo_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Settled • Tap to Undo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await StorageService.updateInvoiceStatus(
                                      invId,
                                      'Payment Pending',
                                      statusColor: AppColors.warning,
                                    );
                                    final receipts = StorageService.getReceipts();
                                    final removedCount = receipts.length;
                                    receipts.removeWhere(
                                      (r) => r['invoiceId'] == invId,
                                    );
                                    if (receipts.length != removedCount) {
                                      await StorageService.saveReceipts(
                                        receipts,
                                      );
                                      StorageService.cloudSyncNotifier.value =
                                          StorageService
                                              .cloudSyncNotifier.value +
                                          1;
                                    }
                                    setModalState(() {
                                      currentInvoice['status'] =
                                          'Payment Pending';
                                      currentInvoice['statusColor'] =
                                          AppColors.warning;
                                    });
                                    final updatedInv = {
                                      ...currentInvoice,
                                      'status': 'Payment Pending',
                                      'statusColor': AppColors.warning,
                                    };
                                    MobileActionSheets
                                        .invoiceUpdatedNotifier.value =
                                        updatedInv;
                                    if (onStatusChanged != null) {
                                      onStatusChanged();
                                    }
                                    if (modalContext.mounted) {
                                      AppNotification.show(modalContext, message: 'Invoice $invId reverted to Payment Pending.');
                                    }
                                  },
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.done_all_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Mark Paid',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await StorageService.updateInvoiceStatus(
                                      invId,
                                      'Settled',
                                      statusColor: AppColors.success,
                                    );
                                    final receipts = StorageService.getReceipts();
                                    if (!receipts.any(
                                      (r) => r['invoiceId'] == invId,
                                    )) {
                                      final now = DateTime.now();
                                      final receiptRecord = <String, dynamic>{
                                        'id': 'RCP-$invId',
                                        'receiptNumber': 'RCP-$invId',
                                        'invoiceId': invId,
                                        'title': 'Payment Receipt: $title',
                                        'type': 'Payment Received',
                                        'party': clientOrLead.isNotEmpty
                                            ? clientOrLead
                                            : 'Client',
                                        'project': projectName.isNotEmpty
                                            ? projectName
                                            : 'General Studio',
                                        'amount': amount,
                                        'direction': 'incoming',
                                        'paymentMode': 'UPI / QR',
                                        'date': DateFormat(
                                          'dd MMM yyyy',
                                        ).format(now),
                                        'timestamp': DateFormat(
                                          'dd MMM yyyy, hh:mm a',
                                        ).format(now),
                                        'status': 'Verified',
                                        'color': AppColors.success,
                                        'statusColor': AppColors.success,
                                        'createdAt': now.toIso8601String(),
                                      };
                                      receipts.insert(0, receiptRecord);
                                      await StorageService.saveReceipts(
                                        receipts,
                                      );
                                      MobileActionSheets
                                              .receiptCreatedNotifier
                                              .value =
                                          receiptRecord;
                                    }
                                    setModalState(() {
                                      currentInvoice['status'] = 'Settled';
                                      currentInvoice['statusColor'] =
                                          AppColors.success;
                                    });
                                    final updatedInv = {
                                      ...currentInvoice,
                                      'status': 'Settled',
                                      'statusColor': AppColors.success,
                                    };
                                    MobileActionSheets
                                        .invoiceUpdatedNotifier.value =
                                        updatedInv;
                                    if (onStatusChanged != null) {
                                      onStatusChanged();
                                    }
                                    if (modalContext.mounted) {
                                      AppNotification.show(modalContext, message: 'Invoice $invId marked as Settled!', backgroundColor: AppColors.success);
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Secondary Action: Upload / Change QR Photo
                    InstantPressFeedback(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 14,
                        ),
                        label: Text(
                          hasImage ? 'Change QR Photo' : 'Upload QR Code Photo',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          UploadInvoiceQrSheet.show(
                            modalContext,
                            invoiceId: invId,
                            currentQrPath: qrPath,
                            currentQrBase64: qrBase64,
                            currentUpiId: upiId,
                            onQrSelected: (newPath, newB64, newUpi) {
                              setModalState(() {
                                currentInvoice['qrCodePath'] = newPath;
                                currentInvoice['qrCodeBase64'] = newB64;
                                currentInvoice['upiId'] = newUpi;
                              });
                            },
                          );
                        },
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
