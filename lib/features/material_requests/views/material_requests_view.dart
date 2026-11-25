import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/cloud_network_image.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/full_screen_media_viewer.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class MaterialRequestsView extends StatefulWidget {
  const MaterialRequestsView({super.key});

  /// Notifier triggered from top action bar to open the "Upload Material List" modal.
  static final ValueNotifier<int> openCreateModalTrigger = ValueNotifier<int>(0);

  @override
  State<MaterialRequestsView> createState() => _MaterialRequestsViewState();
}

class _MaterialRequestsViewState extends State<MaterialRequestsView> {
  String _selectedProject = 'All';
  String _selectedPane = 'active'; // 'active' | 'rejected'
  final List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    StorageService.cloudSyncNotifier.addListener(_onCloudSync);
    MaterialRequestsView.openCreateModalTrigger.addListener(
      _onOpenCreateModalTriggered,
    );
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onCloudSync);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MaterialRequestsView.openCreateModalTrigger.removeListener(
      _onOpenCreateModalTriggered,
    );
    super.dispose();
  }

  void _onOpenCreateModalTriggered() {
    if (mounted) {
      _showCreateRequestModal(context);
    }
  }

  void _onProjectCreated() {
    if (mounted) {
      _loadRequests();
    }
  }

  void _onCloudSync() {
    if (mounted) {
      _loadRequests();
    }
  }

  void _loadRequests() {
    final list = StorageService.getMaterialRequests();
    setState(() {
      _requests
        ..clear()
        ..addAll(list);
    });
  }

  void _saveRequests() {
    StorageService.saveMaterialRequests(_requests);
  }

  List<String> _availableProjectNames() {
    final names = <String>[];
    for (final p in StorageService.getProjects()) {
      final n = (p['name'] ?? '').toString().trim();
      if (n.isNotEmpty && !names.contains(n)) {
        names.add(n);
      }
    }
    for (final n in AppConstants.preExistingProjects) {
      final clean = n.trim();
      if (clean.isNotEmpty && !names.contains(clean)) {
        names.add(clean);
      }
    }
    for (final r in _requests) {
      final n = (r['project'] ?? '').toString().trim();
      if (n.isNotEmpty && !names.contains(n)) {
        names.add(n);
      }
    }
    return names;
  }

  bool _isRequestPaid(Map<String, dynamic> req) {
    if (req['isPaid'] == true) return true;
    final st = (req['status'] ?? '').toString().toLowerCase();
    return st == 'paid' || st == 'settled';
  }

  String _getApprovalStatus(Map<String, dynamic> req) {
    if (_isRequestPaid(req)) return 'approved';
    final explicit = (req['approvalStatus'] ?? '').toString().toLowerCase();
    if (explicit == 'approved' || explicit == 'rejected' || explicit == 'pending') {
      return explicit;
    }
    final st = (req['status'] ?? '').toString().toLowerCase();
    if (st == 'rejected') return 'rejected';
    if (st == 'approved' || st == 'payment pending') return 'approved';
    return 'pending';
  }

  Future<void> _setApprovalStatus(
    Map<String, dynamic> req,
    String newApproval,
  ) async {
    setState(() {
      req['approvalStatus'] = newApproval;
      if (newApproval == 'approved') {
        req['status'] = 'Payment Pending';
        req['color'] = AppColors.warning;
      } else if (newApproval == 'rejected') {
        req['isPaid'] = false;
        req['status'] = 'Rejected';
        req['color'] = AppColors.error;
      } else {
        req['isPaid'] = false;
        req['status'] = 'Pending Approval';
        req['color'] = AppColors.warning;
      }
    });
    _saveRequests();
    if (newApproval == 'rejected') {
      await _syncPaymentToAccounts(req, isPaid: false);
    }
    if (!mounted) return;
    final vendor =
        (req['assignedSupplier'] ?? req['vendor'] ?? 'Vendor').toString();
    AppNotification.show(
      context,
      message: newApproval == 'approved'
          ? 'Approved material request for $vendor. Ready to mark as paid.'
          : (newApproval == 'rejected'
                ? 'Rejected material request for $vendor. Moved to Rejected pane.'
                : 'Restored material request for $vendor to Active.'),
      backgroundColor: newApproval == 'approved'
          ? AppColors.success
          : (newApproval == 'rejected' ? AppColors.error : AppColors.brandPeach),
    );
  }

  /// Synchronizes a material payment directly into Accounts (`StorageService.getExpenses()`)
  /// when marked as Paid, or removes the linked expense voucher if reverted to unpaid.
  Future<void> _syncPaymentToAccounts(
    Map<String, dynamic> req, {
    required bool isPaid,
  }) async {
    final reqId = (req['id'] ?? 'MR').toString();
    final expenseId = 'EXP-$reqId';
    final allExpenses = StorageService.getExpenses();

    if (!isPaid) {
      allExpenses.removeWhere(
        (e) => e['id'] == expenseId || e['materialRequestId'] == reqId,
      );
      await StorageService.saveExpenses(allExpenses);
      StorageService.cloudSyncNotifier.value =
          StorageService.cloudSyncNotifier.value + 1;
      return;
    }

    final itemSummary = (req['itemName'] ?? req['title'] ?? 'Material List')
        .toString()
        .split('\n')
        .first
        .trim();
    final vendor =
        (req['assignedSupplier'] ?? req['vendor'] ?? req['supplier'] ?? 'Vendor')
            .toString();
    final project = (req['project'] ?? 'Project Site').toString();
    final amount =
        (req['estimatedCost'] ?? req['cost'] ?? req['amount'] ?? '₹ 0')
            .toString();
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    final expenseRecord = <String, dynamic>{
      'id': expenseId,
      'materialRequestId': reqId,
      'title': 'Materials: $itemSummary ($vendor)',
      'project': project,
      'category': 'Material Purchase',
      'vendor': vendor,
      'amount': amount,
      'direction': 'outgoing',
      'source': 'materials',
      'date': today,
      'status': 'Paid',
      'color': AppColors.success,
      'statusColor': AppColors.success,
      if (req['listPhotoPath'] != null) 'listPhotoPath': req['listPhotoPath'],
      if (req['listPhotoBase64'] != null)
        'listPhotoBase64': req['listPhotoBase64'],
      if (req['listPhotoUrl'] != null) 'listPhotoUrl': req['listPhotoUrl'],
      if (req['scannerPhotoPath'] != null)
        'scannerPhotoPath': req['scannerPhotoPath'],
      if (req['scannerPhotoBase64'] != null)
        'scannerPhotoBase64': req['scannerPhotoBase64'],
      if (req['scannerPhotoUrl'] != null)
        'scannerPhotoUrl': req['scannerPhotoUrl'],
    };

    final existingIdx = allExpenses.indexWhere(
      (e) => e['id'] == expenseId || e['materialRequestId'] == reqId,
    );
    if (existingIdx != -1) {
      allExpenses[existingIdx] = expenseRecord;
      await StorageService.saveExpenses(allExpenses);
    } else {
      allExpenses.insert(0, expenseRecord);
      await StorageService.saveExpenses(allExpenses);
      MobileActionSheets.expenseCreatedNotifier.value = expenseRecord;
    }
    StorageService.cloudSyncNotifier.value =
        StorageService.cloudSyncNotifier.value + 1;
  }

  Future<void> _togglePaidStatus(Map<String, dynamic> req) async {
    final currentlyPaid = _isRequestPaid(req);
    final nextPaid = !currentlyPaid;
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    setState(() {
      req['isPaid'] = nextPaid;
      req['status'] = nextPaid ? 'Paid' : 'Payment Pending';
      req['paidDate'] = nextPaid ? today : null;
      req['color'] = nextPaid ? AppColors.success : AppColors.warning;
    });
    _saveRequests();
    await _syncPaymentToAccounts(req, isPaid: nextPaid);

    if (!mounted) return;
    final vendor =
        (req['assignedSupplier'] ?? req['vendor'] ?? 'Vendor').toString();
    final amount =
        (req['estimatedCost'] ?? req['cost'] ?? '₹ 0').toString();

    AppNotification.show(
      context,
      message: nextPaid
          ? 'Marked as Paid ($amount to $vendor) and recorded in Accounts.'
          : 'Reverted to Payment Pending and removed from Accounts.',
      backgroundColor: nextPaid ? AppColors.success : AppColors.warning,
    );
  }

  Widget? _buildAttachedImageWidget({
    required String? localPath,
    required String? base64Data,
    required String? networkUrl,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http') &&
        !kIsWeb &&
        File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        height: height,
        width: width,
        fit: fit,
      );
    }
    if (base64Data != null && base64Data.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Data),
          height: height,
          width: width,
          fit: fit,
        );
      } catch (_) {}
    }
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return CloudNetworkImage(
        url: networkUrl,
        height: height,
        width: width,
        fit: fit,
      );
    }
    return null;
  }

  bool _hasImageSource({
    required String? localPath,
    required String? base64Data,
    required String? networkUrl,
  }) {
    if (localPath != null &&
        localPath.isNotEmpty &&
        !localPath.startsWith('http') &&
        !kIsWeb &&
        File(localPath).existsSync()) {
      return true;
    }
    if (base64Data != null && base64Data.isNotEmpty) return true;
    if (networkUrl != null && networkUrl.isNotEmpty) return true;
    return false;
  }

  void _showFullImageDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String? localPath,
    required String? base64Data,
    required String? networkUrl,
  }) {
    if (!_hasImageSource(
      localPath: localPath,
      base64Data: base64Data,
      networkUrl: networkUrl,
    )) {
      return;
    }
    FullScreenMediaViewer.show(
      context,
      title: title,
      subtitle: subtitle,
      filePath: localPath,
      fileUrl: networkUrl,
      base64Data: base64Data,
      fallbackIcon: Icons.image_rounded,
      accentColor: AppColors.brandPeach,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectNames = _availableProjectNames();
    final filterProjects = ['All', ...projectNames];
    final effectiveSelectedProject = filterProjects.contains(_selectedProject)
        ? _selectedProject
        : 'All';

    final filteredRequests = _requests.where((r) {
      if (effectiveSelectedProject != 'All') {
        final proj = (r['project'] ?? '').toString();
        if (proj != effectiveSelectedProject) return false;
      }
      return true;
    }).toList();

    final activeRequests = filteredRequests
        .where((r) => _getApprovalStatus(r) != 'rejected')
        .toList();
    final rejectedRequests = filteredRequests
        .where((r) => _getApprovalStatus(r) == 'rejected')
        .toList();
    final displayedRequests =
        _selectedPane == 'rejected' ? rejectedRequests : activeRequests;

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Material Requests & Indents',
          subtitle:
              'Upload project material lists, vendor payment scanner QR & sync paid bills to Accounts',
        ),
        const SizedBox(height: ScreenLayout.headerGap),

        if (filterProjects.length > 1) ...[
          SizedBox(
            width: double.infinity,
            height: AppSizes.chipHeight,
            child: QuickFadeDropdown<String>(
              value: effectiveSelectedProject,
              isExpanded: true,
              dropdownColor: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCard,
              icon: const Icon(
                Icons.filter_alt_rounded,
                size: 14,
                color: AppColors.brandPeach,
              ),
              style: AppTypography.labelSmall(isDark).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textLightPrimary
                    : AppColors.textDarkPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCard,
                prefixIcon: const Icon(
                  Icons.apartment_rounded,
                  size: 15,
                  color: AppColors.brandPeach,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                  borderSide: BorderSide(
                    color: (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder)
                        .withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedProject = val);
                }
              },
              items: filterProjects.map((p) {
                return DropdownMenuItem<String>(
                  value: p,
                  child: Text(
                    p == 'All' ? 'All Projects' : p,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: ScreenLayout.listGap),
        ],

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PillBox(
                key: const Key('materials_active_pane_tab'),
                label: 'Active (${activeRequests.length})',
                isSelected: _selectedPane == 'active',
                activeColor: AppColors.brandPeach,
                icon: Icons.inventory_2_outlined,
                onSelected: () => setState(() => _selectedPane = 'active'),
              ),
              const SizedBox(width: 8),
              PillBox(
                key: const Key('materials_rejected_pane_tab'),
                label: 'Rejected (${rejectedRequests.length})',
                isSelected: _selectedPane == 'rejected',
                activeColor: AppColors.error,
                icon: Icons.cancel_outlined,
                onSelected: () => setState(() => _selectedPane = 'rejected'),
              ),
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        FilterSwitcher(
          child: displayedRequests.isEmpty
              ? EmptyStateCard(
                  key: ValueKey(
                    'empty_mat_${effectiveSelectedProject}_$_selectedPane',
                  ),
                  icon: _selectedPane == 'rejected'
                      ? Icons.cancel_outlined
                      : Icons.inventory_2_outlined,
                  title: _selectedPane == 'rejected'
                      ? 'No Rejected Material Requests'
                      : 'No Material Requests Found',
                  message: _selectedPane == 'rejected'
                      ? 'Rejected material lists will appear here.'
                      : 'Upload a material list (by typing items or taking a photo), vendor name, total amount, and payment scanner QR.',
                  action: _selectedPane == 'rejected'
                      ? null
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPeach,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => _showCreateRequestModal(context),
                          icon: const Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Upload Material List',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                )
              : ResponsiveCardGrid(
                  key: ValueKey(
                    'mat_${effectiveSelectedProject}_${_selectedPane}_${displayedRequests.length}',
                  ),
                  children: [
                    for (final req in displayedRequests)
                      _buildRequestCard(context, req, isDark),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> req,
    bool isDark,
  ) {
    final itemName =
        (req['itemName'] ?? req['title'] ?? 'Material List').toString();
    final project = (req['project'] ?? 'Project Site').toString();
    final vendor =
        (req['assignedSupplier'] ?? req['vendor'] ?? req['supplier'] ?? 'Vendor')
            .toString();
    final cost =
        (req['estimatedCost'] ?? req['cost'] ?? req['amount'] ?? '₹ 0')
            .toString();
    final isPaid = _isRequestPaid(req);
    final approvalStatus = _getApprovalStatus(req);
    final isRejected = approvalStatus == 'rejected';
    final isApproved = approvalStatus == 'approved';
    final statusLabel = isPaid
        ? 'PAID'
        : (isRejected
              ? 'REJECTED'
              : (isApproved ? 'PAYMENT PENDING' : 'PENDING APPROVAL'));
    final statusColor = isPaid
        ? AppColors.success
        : (isRejected ? AppColors.error : AppColors.warning);

    final listPhotoPath = req['listPhotoPath']?.toString();
    final listPhotoBase64 = req['listPhotoBase64']?.toString();
    final listPhotoUrl = req['listPhotoUrl']?.toString();
    final hasListPhoto = _hasImageSource(
      localPath: listPhotoPath,
      base64Data: listPhotoBase64,
      networkUrl: listPhotoUrl,
    );

    final scannerPhotoPath = req['scannerPhotoPath']?.toString();
    final scannerPhotoBase64 = req['scannerPhotoBase64']?.toString();
    final scannerPhotoUrl = req['scannerPhotoUrl']?.toString();
    final hasScannerPhoto = _hasImageSource(
      localPath: scannerPhotoPath,
      base64Data: scannerPhotoBase64,
      networkUrl: scannerPhotoUrl,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _showRequestExpandedBox(context, req, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.45)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                        .withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Project Name + Payment Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: AppColors.brandPeach,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vendor & Total Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            vendor,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLightSecondary
                                  : AppColors.textDarkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cost,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPeach,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Material List Text & Attached Photo / Scanner Thumbnails
              Text(
                itemName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textLightPrimary
                      : AppColors.textDarkPrimary,
                ),
              ),

              if (hasListPhoto || hasScannerPhoto) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasListPhoto)
                      InkWell(
                        onTap: () => _showFullImageDialog(
                          context,
                          title: 'Material List Photo',
                          subtitle: '$project • $vendor',
                          localPath: listPhotoPath,
                          base64Data: listPhotoBase64,
                          networkUrl: listPhotoUrl,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 13,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'View Material List Photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (hasScannerPhoto)
                      InkWell(
                        onTap: () => _showFullImageDialog(
                          context,
                          title: 'Vendor Payment Scanner (QR)',
                          subtitle: '$vendor • $cost',
                          localPath: scannerPhotoPath,
                          base64Data: scannerPhotoBase64,
                          networkUrl: scannerPhotoUrl,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: AppColors.brandPeach.withValues(alpha: 0.45),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 13,
                                color: AppColors.brandPeach,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'View Payment Scanner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPeach,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Payment / Approval Action Row
              if (isRejected)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: Key('material_restore_${req['id']}'),
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: AppColors.brandPeach,
                          borderColor: AppColors.brandPeach.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        onPressed: () => _setApprovalStatus(req, 'pending'),
                        icon: const Icon(Icons.restore_rounded, size: 15),
                        label: const Text(
                          'Restore to Active',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizes.compactButtonFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (!isApproved && !isPaid)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: Key('material_approve_${req['id']}'),
                        style: AppSizes.compactElevatedStyle(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _setApprovalStatus(req, 'approved'),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text(
                          'Approve',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizes.compactButtonFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: Key('material_reject_${req['id']}'),
                        style: AppSizes.compactOutlinedStyle(
                          foregroundColor: AppColors.error,
                          borderColor: AppColors.error.withValues(alpha: 0.7),
                        ),
                        onPressed: () => _setApprovalStatus(req, 'rejected'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text(
                          'Reject',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizes.compactButtonFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: isPaid
                          ? OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: AppColors.success,
                                borderColor: AppColors.success.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              onPressed: () => _togglePaidStatus(req),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Paid · In Accounts (Tap to Undo)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppSizes.compactButtonFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              style: AppSizes.compactElevatedStyle(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _togglePaidStatus(req),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Mark as Paid (Send to Accounts)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppSizes.compactButtonFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestExpandedBox(
    BuildContext context,
    Map<String, dynamic> req,
    bool isDark,
  ) {
    final itemName =
        (req['itemName'] ?? req['title'] ?? 'Material List').toString();
    final project = (req['project'] ?? 'Project Site').toString();
    final vendor =
        (req['assignedSupplier'] ?? req['vendor'] ?? req['supplier'] ?? 'Vendor')
            .toString();
    final cost =
        (req['estimatedCost'] ?? req['cost'] ?? req['amount'] ?? '₹ 0')
            .toString();
    final isPaid = _isRequestPaid(req);
    final statusLabel = isPaid ? 'Paid' : 'Payment Pending';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    final listPhotoPath = req['listPhotoPath']?.toString();
    final listPhotoBase64 = req['listPhotoBase64']?.toString();
    final listPhotoUrl = req['listPhotoUrl']?.toString();
    final listImg = _buildAttachedImageWidget(
      localPath: listPhotoPath,
      base64Data: listPhotoBase64,
      networkUrl: listPhotoUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.contain,
    );

    final scannerPhotoPath = req['scannerPhotoPath']?.toString();
    final scannerPhotoBase64 = req['scannerPhotoBase64']?.toString();
    final scannerPhotoUrl = req['scannerPhotoUrl']?.toString();
    final scannerImg = _buildAttachedImageWidget(
      localPath: scannerPhotoPath,
      base64Data: scannerPhotoBase64,
      networkUrl: scannerPhotoUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.contain,
    );

    showExpandedDetailBox(
      context: context,
      title: itemName,
      subtitle: project,
      headerIcon: Icons.inventory_2_rounded,
      accentColor: statusColor,
      badgeLabel: statusLabel,
      badgeColor: statusColor,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Total Amount',
                value: cost,
                color: AppColors.brandPeach,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Payment Status',
                value: isPaid ? 'Paid · In Accounts' : 'Payment Pending',
                color: statusColor,
                icon: isPaid
                    ? Icons.verified_rounded
                    : Icons.pending_actions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.storefront_rounded,
            label: 'Vendor Name',
            value: vendor,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          DetailNoteBox(
            label: 'MATERIAL LIST',
            text: itemName,
            isDark: isDark,
          ),
          if (listImg != null) ...[
            const SizedBox(height: 12),
            DetailSectionTitle(label: 'Material List Photo', isDark: isDark),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.7),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: listImg,
            ),
          ],
          if (scannerImg != null) ...[
            const SizedBox(height: 12),
            DetailSectionTitle(
              label: 'Vendor Payment Scanner (QR)',
              isDark: isDark,
            ),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: AppColors.brandPeach.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: scannerImg,
            ),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Close', maxLines: 1),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPaid ? AppColors.warning : AppColors.success,
            foregroundColor: isPaid ? Colors.black : Colors.white,
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            _togglePaidStatus(req);
          },
          icon: Icon(
            isPaid ? Icons.undo_rounded : Icons.check_circle_rounded,
            size: 16,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isPaid ? 'Mark Unpaid' : 'Mark as Paid',
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateRequestModal(BuildContext context) {
    final projectNames = _availableProjectNames();
    String selectedProj = projectNames.isNotEmpty ? projectNames.first : '';
    final customProjCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();

    String? listPhotoPath;
    Uint8List? listPhotoBytes;
    String? listPhotoBase64;
    String? listPhotoUrl;
    bool isUploadingListPhoto = false;

    String? scannerPhotoPath;
    Uint8List? scannerPhotoBytes;
    String? scannerPhotoBase64;
    String? scannerPhotoUrl;
    bool isUploadingScannerPhoto = false;

    bool markPaidNow = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> pickAndUploadImage({
      required BuildContext modalCtx,
      required StateSetter setModalState,
      required bool isScanner,
      required ImageSource? cameraOrGallery,
    }) async {
      try {
        final allowed = cameraOrGallery == ImageSource.camera
            ? await PermissionService.requestCamera(modalCtx)
            : await PermissionService.requestMediaOrStorage(modalCtx);
        if (!allowed) return;

        Uint8List? pickedBytes;
        String? pickedPath;

        if (cameraOrGallery != null) {
          final picker = ImagePicker();
          final XFile? file = await picker.pickImage(
            source: cameraOrGallery,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 85,
          );
          if (file == null) return;
          pickedPath = file.path;
          pickedBytes = await file.readAsBytes();
        } else {
          final result = await FilePicker.pickFile(type: FileType.image);
          if (result == null) return;
          pickedPath = result.path ?? result.name;
          pickedBytes = await result.readAsBytes();
        }

        final encodedBase64 = base64Encode(pickedBytes);
        final activeProj = projectNames.isNotEmpty
            ? selectedProj
            : (customProjCtrl.text.trim().isNotEmpty
                  ? customProjCtrl.text.trim()
                  : 'Project Site');

        setModalState(() {
          if (isScanner) {
            scannerPhotoPath = pickedPath;
            scannerPhotoBytes = pickedBytes;
            scannerPhotoBase64 = encodedBase64;
            isUploadingScannerPhoto = CloudStorageService.isAvailable;
          } else {
            listPhotoPath = pickedPath;
            listPhotoBytes = pickedBytes;
            listPhotoBase64 = encodedBase64;
            isUploadingListPhoto = CloudStorageService.isAvailable;
          }
        });

        // Immediately upload the captured/selected photo to Cloud Storage
        if (CloudStorageService.isAvailable) {
          final uploadRes = await CloudStorageService.uploadSitePhoto(
            projectId: activeProj,
            projectName: activeProj,
            filePath: pickedPath,
            bytes: pickedBytes,
            title: isScanner
                ? 'Vendor Payment Scanner QR'
                : 'Material List Photo',
            tag: isScanner ? 'Payment Scanner' : 'Materials',
            capturedBy: 'Studio Staff',
            retentionMonths: StorageService.getPhotoRetentionMonths(),
          );
          if (modalCtx.mounted) {
            setModalState(() {
              if (isScanner) {
                scannerPhotoUrl = uploadRes?.downloadUrl;
                isUploadingScannerPhoto = false;
              } else {
                listPhotoUrl = uploadRes?.downloadUrl;
                isUploadingListPhoto = false;
              }
            });
          }
        }
      } catch (e) {
        if (modalCtx.mounted) {
          setModalState(() {
            isUploadingListPhoto = false;
            isUploadingScannerPhoto = false;
          });
          AppNotification.show(
            modalCtx,
            message: 'Could not attach image: $e',
            backgroundColor: AppColors.error,
          );
        }
      }
    }

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: AppSizes.sheetBottomPadding(ctx),
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
                      child: Text(
                        'Upload Material List',
                        style: AppTypography.titleLarge(isDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. Project Dropdown (or text field if no projects exist yet)
                if (projectNames.isNotEmpty)
                  QuickFadeDropdown<String>(
                    value: selectedProj,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Project *',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: projectNames
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedProj = val);
                      }
                    },
                  )
                else
                  TextField(
                    controller: customProjCtrl,
                    decoration: const InputDecoration(
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('Project Name *'),
                      ),
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                  ),
                const SizedBox(height: 12),

                // 2. Vendor Name & 3. Total Amount
                TextField(
                  controller: vendorCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Vendor Name *'),
                    ),
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
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
                      child: Text('Total Amount (₹) *'),
                    ),
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Material List (Type in OR Upload Photo of List)
                TextField(
                  controller: itemsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Material List (Type items or attach photo below)',
                      ),
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.list_alt_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: listPhotoBytes != null
                          ? AppColors.success.withValues(alpha: 0.6)
                          : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 15,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Photo of Material List',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (isUploadingListPhoto)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (listPhotoBytes != null)
                            InkWell(
                              onTap: () => setModalState(() {
                                listPhotoPath = null;
                                listPhotoBytes = null;
                                listPhotoBase64 = null;
                                listPhotoUrl = null;
                              }),
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (listPhotoBytes != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.memory(
                            listPhotoBytes!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: AppColors.brandPeach,
                                borderColor: AppColors.brandPeach,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: false,
                                cameraOrGallery: ImageSource.camera,
                              ),
                              icon: const Icon(
                                Icons.photo_camera_rounded,
                                size: 14,
                              ),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                                borderColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: false,
                                cameraOrGallery: ImageSource.gallery,
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 14,
                              ),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                                borderColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: false,
                                cameraOrGallery: null,
                              ),
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 14,
                              ),
                              label: const Text('Files'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5. Payment Scanner (QR) Upload
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: scannerPhotoBytes != null
                          ? AppColors.success.withValues(alpha: 0.6)
                          : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 15,
                                  color: AppColors.brandPeach,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Vendor Payment Scanner (QR)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUploadingScannerPhoto)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (scannerPhotoBytes != null)
                            InkWell(
                              onTap: () => setModalState(() {
                                scannerPhotoPath = null;
                                scannerPhotoBytes = null;
                                scannerPhotoBase64 = null;
                                scannerPhotoUrl = null;
                              }),
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (scannerPhotoBytes != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.memory(
                            scannerPhotoBytes!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: AppColors.brandPeach,
                                borderColor: AppColors.brandPeach,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: true,
                                cameraOrGallery: ImageSource.camera,
                              ),
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 14,
                              ),
                              label: const Text('Scan QR'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                                borderColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: true,
                                cameraOrGallery: ImageSource.gallery,
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 14,
                              ),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: AppSizes.compactOutlinedStyle(
                                foregroundColor: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                                borderColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              onPressed: () => pickAndUploadImage(
                                modalCtx: ctx,
                                setModalState: setModalState,
                                isScanner: true,
                                cameraOrGallery: null,
                              ),
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 14,
                              ),
                              label: const Text('Files'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 6. Mark as Paid Switch
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeThumbColor: AppColors.success,
                  value: markPaidNow,
                  onChanged: (v) => setModalState(() => markPaidNow = v),
                  title: const Text(
                    'Mark as Paid (Reflect in Accounts)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // Submit Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPeach,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final resolvedProj = projectNames.isNotEmpty
                        ? selectedProj.trim()
                        : customProjCtrl.text.trim();
                    final vendor = vendorCtrl.text.trim();
                    final typedItems = itemsCtrl.text.trim();

                    if (resolvedProj.isEmpty) {
                      AppNotification.show(
                        context,
                        message: 'Please select or enter a project.',
                      );
                      return;
                    }
                    if (typedItems.isEmpty && listPhotoBase64 == null) {
                      AppNotification.show(
                        context,
                        message:
                            'Please type the list of items or attach a photo of the material list.',
                      );
                      return;
                    }

                    final parsedCost = CurrencyUtils.parseAmount(costCtrl.text);
                    final costFormatted = parsedCost > 0
                        ? CurrencyUtils.formatInr(parsedCost)
                        : '₹ 0';
                    final displayItem = typedItems.isNotEmpty
                        ? typedItems
                        : 'Material List Photo (${vendor.isEmpty ? resolvedProj : vendor})';
                    final today = DateFormat('dd MMM yyyy').format(
                      DateTime.now(),
                    );
                    final reqId =
                        'MR-${DateTime.now().millisecondsSinceEpoch % 100000}';

                    final newReq = <String, dynamic>{
                      'id': reqId,
                      'itemName': displayItem,
                      'project': resolvedProj,
                      'assignedSupplier': vendor.isEmpty ? 'Vendor' : vendor,
                      'vendor': vendor.isEmpty ? 'Vendor' : vendor,
                      'estimatedCost': costFormatted,
                      'requestDate': today,
                      'isPaid': markPaidNow,
                      'approvalStatus': markPaidNow ? 'approved' : 'pending',
                      'status': markPaidNow ? 'Paid' : 'Pending Approval',
                      'paidDate': markPaidNow ? today : null,
                      'color': markPaidNow
                          ? AppColors.success
                          : AppColors.warning,
                      'listPhotoPath': listPhotoPath,
                      'listPhotoBase64': listPhotoBase64,
                      'listPhotoUrl': listPhotoUrl,
                      'scannerPhotoPath': scannerPhotoPath,
                      'scannerPhotoBase64': scannerPhotoBase64,
                      'scannerPhotoUrl': scannerPhotoUrl,
                      'createdAt': DateTime.now().toIso8601String(),
                    };

                    if (!AppConstants.preExistingProjects.contains(
                      resolvedProj,
                    )) {
                      AppConstants.preExistingProjects.add(resolvedProj);
                    }

                    setState(() {
                      _requests.insert(0, newReq);
                    });
                    _saveRequests();

                    if (markPaidNow) {
                      await _syncPaymentToAccounts(newReq, isPaid: true);
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (context.mounted) {
                      AppNotification.show(
                        context,
                        message: markPaidNow
                            ? 'Material list uploaded and recorded as Paid in Accounts.'
                            : 'Material list uploaded for $resolvedProj.',
                        backgroundColor: AppColors.success,
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text(
                    'Save Material Upload',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
