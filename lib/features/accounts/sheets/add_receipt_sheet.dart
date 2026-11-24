import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/custom_entry_dropdown.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class AddReceiptSheet {
  AddReceiptSheet._();

  static const List<String> _receiptTypes = [
    'Payment Received',
    'Vendor / Bill Receipt',
    'Site Advance Receipt',
  ];

  static const List<String> _paymentModes = [
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Cash',
  ];

  static void show(
    BuildContext context, {
    String? initialProject,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (_) => _AddReceiptSheetContent(
        initialProject: initialProject,
      ),
    );
  }
}

class _AddReceiptSheetContent extends StatefulWidget {
  final String? initialProject;

  const _AddReceiptSheetContent({this.initialProject});

  @override
  State<_AddReceiptSheetContent> createState() =>
      _AddReceiptSheetContentState();
}

class _AddReceiptSheetContentState extends State<_AddReceiptSheetContent> {
  final _titleController = TextEditingController();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedProject = 'General Studio';
  String _selectedType = AddReceiptSheet._receiptTypes.first;
  String _selectedMode = AddReceiptSheet._paymentModes.first;

  String? _attachmentPath;
  String? _attachmentBase64;
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  bool _isImageAttachment = true;
  bool _isPickingAttachment = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final projects = StorageService.getProjects();
    if (widget.initialProject != null &&
        widget.initialProject!.trim().isNotEmpty) {
      _selectedProject = widget.initialProject!.trim();
    } else if (projects.isNotEmpty) {
      _selectedProject =
          (projects.first['name'] as String?) ?? 'General Studio';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    if (_isPickingAttachment) return;
    setState(() => _isPickingAttachment = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      final b64 = bytes.length <= 450 * 1024 ? base64Encode(bytes) : null;
      if (!mounted) return;
      setState(() {
        _attachmentPath = xFile.path;
        _attachmentBase64 = b64;
        _attachmentBytes = bytes;
        _attachmentName = xFile.name;
        _isImageAttachment = true;
      });
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Could not select receipt photo: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  Future<void> _pickReceiptFile() async {
    if (_isPickingAttachment) return;
    setState(() => _isPickingAttachment = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final ext = (file.extension ?? '').toLowerCase();
      final isImg = ['png', 'jpg', 'jpeg', 'webp'].contains(ext);
      final rawBytes = await file.readAsBytes();
      String? b64;
      if (isImg && rawBytes.length <= 450 * 1024) {
        b64 = base64Encode(rawBytes);
      }
      if (!mounted) return;
      setState(() {
        _attachmentPath = file.path;
        _attachmentBase64 = b64;
        _attachmentBytes = rawBytes;
        _attachmentName = file.name;
        _isImageAttachment = isImg;
      });
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Could not pick receipt file: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  Future<void> _uploadReceiptAttachment(
    String receiptId,
    String projectName,
  ) async {
    final path = _attachmentPath;
    final name = _attachmentName;
    if ((path == null || path.isEmpty) && _attachmentBase64 == null) return;

    try {
      Uint8List? bytes = _attachmentBytes;
      if (bytes == null && _attachmentBase64 != null) {
        bytes = base64Decode(_attachmentBase64!);
      }
      final result = await CloudStorageService.uploadDesignAsset(
        projectName: projectName,
        filePath: path,
        bytes: bytes,
        originalFileName: name ?? 'receipt_$receiptId.jpg',
        title: _titleController.text.trim(),
        assetType: 'Receipt',
      );
      if (result != null && result.downloadUrl.isNotEmpty) {
        final receipts = StorageService.getReceipts();
        final idx = receipts.indexWhere((r) => r['id'] == receiptId);
        if (idx != -1) {
          receipts[idx]['storagePath'] = result.storagePath;
          receipts[idx]['downloadUrl'] = result.downloadUrl;
          await StorageService.saveReceipts(receipts);
          StorageService.cloudSyncNotifier.value =
              StorageService.cloudSyncNotifier.value + 1;
        }
      }
    } catch (e) {
      debugPrint('Receipt cloud upload notice: $e');
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final rawTitle = _titleController.text.trim();
    final party = _partyController.text.trim();
    final amountRaw = _amountController.text.trim();

    if (rawTitle.isEmpty && party.isEmpty) {
      AppNotification.show(
        context,
        message: 'Please enter a receipt title or party name.',
        backgroundColor: AppColors.warning,
      );
      return;
    }
    if (amountRaw.isEmpty) {
      AppNotification.show(
        context,
        message: 'Please enter the receipt amount.',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    final parsedAmt = CurrencyUtils.parseAmount(amountRaw);
    final formattedAmount =
        parsedAmt > 0 ? CurrencyUtils.formatInr(parsedAmt) : '₹ $amountRaw';
    final now = DateTime.now();
    final receiptId = 'RCP-${now.millisecondsSinceEpoch % 1000000}';
    final dateStr = DateFormat('dd MMM yyyy').format(now);
    final dateTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : '$_selectedType (${party.isNotEmpty ? party : _selectedProject})';

    final newReceipt = <String, dynamic>{
      'id': receiptId,
      'receiptNumber': receiptId,
      'title': title,
      'type': _selectedType,
      'party': party.isNotEmpty ? party : 'Client / Vendor',
      'project': _selectedProject,
      'amount': formattedAmount,
      'direction': 'incoming',
      'paymentMode': _selectedMode,
      'date': dateStr,
      'timestamp': dateTimeStr,
      'status': 'Verified',
      'color': AppColors.success,
      'statusColor': AppColors.success,
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_attachmentPath != null) 'attachmentPath': _attachmentPath,
      if (_attachmentBase64 != null) 'attachmentBase64': _attachmentBase64,
      if (_attachmentName != null) 'attachmentName': _attachmentName,
      'isImageAttachment': _isImageAttachment,
      'createdAt': now.toIso8601String(),
    };

    final allReceipts = StorageService.getReceipts();
    allReceipts.insert(0, newReceipt);
    await StorageService.saveReceipts(allReceipts);
    MobileActionSheets.receiptCreatedNotifier.value = newReceipt;

    _uploadReceiptAttachment(receiptId, _selectedProject);

    if (!mounted) return;
    Navigator.pop(context);
    AppNotification.show(
      context,
      message: 'Receipt "$title" ($formattedAmount) recorded in Accounts.',
      backgroundColor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = StorageService.getProjects();
    final projectOptions = <String>{
      'General Studio',
      for (final p in projects)
        if ((p['name'] as String?)?.trim().isNotEmpty == true)
          (p['name'] as String).trim(),
    }.toList();
    if (!projectOptions.contains(_selectedProject)) {
      projectOptions.insert(0, _selectedProject);
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: AppSizes.sheetBottomPadding(context),
      ),
      child: SingleChildScrollView(
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
                          Icons.receipt_rounded,
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
                              'Add Payment Receipt',
                              style: AppTypography.titleLarge(isDark),
                            ),
                            Text(
                              'Upload bill scan, remittance slip, or payment proof',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : AppColors.textDarkMuted,
                              ),
                            ),
                          ],
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
            QuickFadeDropdown<String>(
              value: _selectedProject,
              decoration: const InputDecoration(
                labelText: 'Project',
                prefixIcon: Icon(Icons.business_rounded),
              ),
              items: projectOptions
                  .map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedProject = val);
              },
            ),
            const SizedBox(height: 12),
            CustomEntryDropdown(
              value: _selectedType,
              options: AddReceiptSheet._receiptTypes,
              customFieldLabel: 'Custom Receipt Type',
              customFieldHint: 'Enter receipt type...',
              decoration: const InputDecoration(
                labelText: 'Receipt Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              onChanged: (val) {
                setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 12),
            CustomEntryDropdown(
              value: _selectedMode,
              options: AddReceiptSheet._paymentModes,
              customFieldLabel: 'Custom Payment Mode',
              customFieldHint: 'Enter payment mode...',
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              onChanged: (val) {
                setState(() => _selectedMode = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Receipt Title / Description *'),
                ),
                hintText: 'e.g. Booking Advance Receipt, Hardware Bill',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Received From / Party'),
                ),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
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
                  child: Text('Amount (₹) *'),
                ),
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Reference / UTR / Notes (Optional)'),
                ),
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: (_attachmentName != null
                          ? AppColors.success
                          : AppColors.brandPeach)
                      .withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.document_scanner_rounded,
                        size: 16,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _attachmentName ?? 'Receipt Photo / Scan (Optional)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _attachmentName != null
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary),
                          ),
                        ),
                      ),
                      if (_attachmentName != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            setState(() {
                              _attachmentPath = null;
                              _attachmentBase64 = null;
                              _attachmentBytes = null;
                              _attachmentName = null;
                            });
                          },
                        ),
                    ],
                  ),
                  if (_attachmentBase64 != null && _isImageAttachment) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.memory(
                        base64Decode(_attachmentBase64!),
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPickingAttachment
                              ? null
                              : () => _pickReceiptImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined, size: 15),
                          label: const Text('Camera', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPickingAttachment
                              ? null
                              : () => _pickReceiptImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 15),
                          label: const Text('Gallery', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isPickingAttachment ? null : _pickReceiptFile,
                          icon: const Icon(Icons.attach_file_rounded, size: 15),
                          label: const Text('PDF / File', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
              ),
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'Save Receipt',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
