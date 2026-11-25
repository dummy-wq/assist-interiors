import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class UploadInvoiceQrSheet {
  UploadInvoiceQrSheet._();

  static void show(
    BuildContext context, {
    String? invoiceId,
    String? currentQrPath,
    String? currentQrBase64,
    String? currentUpiId,
    void Function(String? path, String? base64, String upiId)? onQrSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? selectedPath = currentQrPath;
    String? selectedBase64 = currentQrBase64;
    final upiController = TextEditingController(
      text: currentUpiId?.isNotEmpty == true
          ? currentUpiId
          : AppConstants.defaultUpiId,
    );
    bool isProcessing = false;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final hasImage =
                (selectedPath != null &&
                    !kIsWeb &&
                    File(selectedPath!).existsSync()) ||
                (selectedBase64 != null && selectedBase64!.isNotEmpty);

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: AppSizes.sheetBottomPadding(modalContext),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet Header
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
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload Invoice QR Code',
                                      style: AppTypography.titleLarge(isDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      invoiceId != null
                                          ? 'Attach payment QR photo to $invoiceId'
                                          : 'Attach payment QR photo for quick UPI settlements',
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
                    const SizedBox(height: 16),

                    // QR Code Preview Area
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: hasImage
                              ? AppColors.success.withValues(alpha: 0.6)
                              : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)
                                  .withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (hasImage) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Container(
                                height: 160,
                                width: 160,
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: selectedPath != null &&
                                        !kIsWeb &&
                                        File(selectedPath!).existsSync()
                                    ? Image.file(
                                        File(selectedPath!),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.memory(
                                        base64Decode(selectedBase64!),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Payment QR Ready to Attach',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textLightPrimary
                                        : AppColors.textDarkPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      selectedPath = null;
                                      selectedBase64 = null;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: AppColors.brandPeach,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Upload Actions (Camera, Gallery, Files, Sample Preset)
                    Row(
                      children: [
                        Expanded(
                          child: InstantPressFeedback(
                            child: OutlinedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      try {
                                        final allowed =
                                            await PermissionService
                                                .requestCamera(modalContext);
                                        if (!allowed) return;
                                        setModalState(() => isProcessing = true);
                                        final picker = ImagePicker();
                                        final XFile? file =
                                            await picker.pickImage(
                                          source: ImageSource.camera,
                                          maxWidth: 1200,
                                          maxHeight: 1200,
                                          imageQuality: 90,
                                        );
                                        if (file != null) {
                                          final bytes =
                                              await file.readAsBytes();
                                          setModalState(() {
                                            selectedPath = file.path;
                                            selectedBase64 =
                                                base64Encode(bytes);
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('Camera error: $e');
                                      } finally {
                                        setModalState(
                                          () => isProcessing = false,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.photo_camera_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InstantPressFeedback(
                            child: OutlinedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      try {
                                        final allowed =
                                            await PermissionService
                                                .requestMediaOrStorage(
                                                  modalContext,
                                                );
                                        if (!allowed) return;
                                        setModalState(() => isProcessing = true);
                                        final picker = ImagePicker();
                                        final XFile? file =
                                            await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 1200,
                                          maxHeight: 1200,
                                          imageQuality: 90,
                                        );
                                        if (file != null) {
                                          final bytes =
                                              await file.readAsBytes();
                                          setModalState(() {
                                            selectedPath = file.path;
                                            selectedBase64 =
                                                base64Encode(bytes);
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('Gallery error: $e');
                                      } finally {
                                        setModalState(
                                          () => isProcessing = false,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.photo_library_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InstantPressFeedback(
                            child: OutlinedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      try {
                                        final allowed =
                                            await PermissionService
                                                .requestMediaOrStorage(
                                                  modalContext,
                                                );
                                        if (!allowed) return;
                                        setModalState(() => isProcessing = true);
                                        final result =
                                            await FilePicker.pickFile(
                                          type: FileType.image,
                                        );
                                        if (result != null &&
                                            result.path != null) {
                                          final bytes = await File(result.path!)
                                              .readAsBytes();
                                          setModalState(() {
                                            selectedPath = result.path;
                                            selectedBase64 =
                                                base64Encode(bytes);
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('File picker error: $e');
                                      } finally {
                                        setModalState(
                                          () => isProcessing = false,
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Files',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Preset Studio QR Option
                    InstantPressFeedback(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandPeach,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text(
                          'Use Sample Studio HDFC UPI QR Code',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedBase64 = AppConstants.samplePaymentQrBase64;
                            selectedPath = null;
                            upiController.text = AppConstants.defaultUpiId;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // UPI ID Field
                    TextField(
                      controller: upiController,
                      decoration: const InputDecoration(
                        labelText: 'Beneficiary UPI ID',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                        hintText: 'assistinteriors@hdfcbank',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      onPressed: (!hasImage)
                          ? null
                          : () async {
                              final upiId = upiController.text.trim().isEmpty
                                  ? AppConstants.defaultUpiId
                                  : upiController.text.trim();

                              if (invoiceId != null) {
                                await StorageService.updateInvoiceQrCode(
                                  invoiceId,
                                  qrCodePath: selectedPath,
                                  qrCodeBase64: selectedBase64,
                                  upiId: upiId,
                                );
                                final updatedInv = {
                                  'id': invoiceId,
                                  'qrCodePath': selectedPath,
                                  'qrCodeBase64': selectedBase64,
                                  'upiId': upiId,
                                };
                                MobileActionSheets
                                    .invoiceUpdatedNotifier.value = updatedInv;
                              }

                              if (onQrSelected != null) {
                                onQrSelected(
                                  selectedPath,
                                  selectedBase64,
                                  upiId,
                                );
                              }

                              if (modalContext.mounted) {
                                Navigator.pop(modalContext);
                                AppNotification.show(context, message: 'Payment QR Code attached successfully!', backgroundColor: AppColors.success);
                              }
                            },
                      child: Text(
                        invoiceId != null
                            ? 'Save QR Code to $invoiceId'
                            : 'Attach Payment QR Code',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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
