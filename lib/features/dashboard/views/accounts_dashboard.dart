import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cloud_network_image.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/full_screen_media_viewer.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/currency_utils.dart';
import '../../auth/state/auth_provider.dart';
import '../widgets/mobile_action_sheets.dart';
import '../../accounts/dialogs/invoice_qr_payment_dialog.dart';
import '../../accounts/dialogs/upload_invoice_qr_sheet.dart';

class AccountsDashboard extends StatefulWidget {
  const AccountsDashboard({super.key});

  @override
  State<AccountsDashboard> createState() => _AccountsDashboardState();
}

class _AccountsDashboardState extends State<AccountsDashboard> {
  final List<Map<String, dynamic>> _invoices = [];
  final List<Map<String, dynamic>> _expenses = [];
  final List<Map<String, dynamic>> _receipts = [];
  String _selectedIncomingTab = 'Invoices';

  @override
  void initState() {
    super.initState();
    _invoices.addAll(StorageService.getInvoices());
    _expenses.addAll(StorageService.getExpenses());
    _receipts.addAll(StorageService.getReceipts());
    MobileActionSheets.invoiceCreatedNotifier.addListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.addListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.addListener(_onExpenseCreated);
    MobileActionSheets.receiptCreatedNotifier.addListener(_onReceiptCreated);
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    StorageService.cloudSyncNotifier.addListener(_onCloudSync);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onCloudSync);
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.removeListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.removeListener(_onExpenseCreated);
    MobileActionSheets.receiptCreatedNotifier.removeListener(_onReceiptCreated);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    super.dispose();
  }

  void _onCloudSync() {
    if (mounted) {
      setState(() {
        _invoices
          ..clear()
          ..addAll(StorageService.getInvoices());
        _expenses
          ..clear()
          ..addAll(StorageService.getExpenses());
        _receipts
          ..clear()
          ..addAll(StorageService.getReceipts());
      });
    }
  }

  void _onInvoiceCreated() {
    final invoice = MobileActionSheets.invoiceCreatedNotifier.value;
    if (invoice != null && mounted) {
      if (!_invoices.any((i) => i['id'] == invoice['id'])) {
        setState(() {
          _invoices.insert(0, Map<String, dynamic>.from(invoice));
        });
        StorageService.saveInvoices(_invoices);
        BackendManager.instance.createInvoice(InvoiceModel.fromMap(invoice));
      }
    }
  }

  void _onInvoiceUpdated() {
    final updated = MobileActionSheets.invoiceUpdatedNotifier.value;
    if (updated != null && mounted) {
      setState(() {
        final idx = _invoices.indexWhere(
          (i) => i['id'] == updated['id'] || i['invoiceNumber'] == updated['id'],
        );
        if (idx != -1) {
          _invoices[idx] = {
            ..._invoices[idx],
            ...updated,
          };
        } else {
          _invoices.clear();
          _invoices.addAll(StorageService.getInvoices());
        }
      });
    }
  }

  void _onExpenseCreated() {
    final exp = MobileActionSheets.expenseCreatedNotifier.value;
    if (exp != null && mounted) {
      setState(() {
        final existingIdx = _expenses.indexWhere((e) => e['id'] == exp['id']);
        if (existingIdx != -1) {
          _expenses[existingIdx] = Map<String, dynamic>.from(exp);
        } else {
          _expenses.insert(0, Map<String, dynamic>.from(exp));
        }
      });
      StorageService.saveExpenses(_expenses);
    }
  }

  void _onReceiptCreated() {
    final rec = MobileActionSheets.receiptCreatedNotifier.value;
    if (rec != null && mounted) {
      setState(() {
        final existingIdx = _receipts.indexWhere((r) => r['id'] == rec['id']);
        if (existingIdx != -1) {
          _receipts[existingIdx] = Map<String, dynamic>.from(rec);
        } else {
          _receipts.insert(0, Map<String, dynamic>.from(rec));
        }
      });
      StorageService.saveReceipts(_receipts);
    }
  }

  void _onProjectCreated() {
    final newProj = MobileActionSheets.projectCreatedNotifier.value;
    if (newProj != null && mounted) {
      // Auto-generate mobilization advance invoice if originating from sales lead conversion
      final originLeadId = newProj['originLeadId'];
      if (originLeadId == null || originLeadId.toString().isEmpty) {
        return;
      }

      final projName = newProj['name'] as String? ?? 'Turnkey Site';
      final clientName =
          (newProj['client'] ?? newProj['location'] ?? 'Client') as String;
      final budgetStr = (newProj['budget'] ?? '₹ 0') as String;
      final rawBudget = CurrencyUtils.parseAmount(budgetStr);

      // Auto-generate 10% mobilization advance invoice for the newly created turnkey project
      final advanceAmount =
          rawBudget > 0 ? (rawBudget * 0.10).round() : 100000;
      final advanceFormatted = CurrencyUtils.formatInr(advanceAmount);

      final invId =
          'INV-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final autoInvoice = {
        'id': invId,
        'invoiceNumber': invId,
        'title': '$projName - Mobilization Advance (10%)',
        'client': clientName,
        'project': projName,
        'projectId': newProj['id'],
        'leadId': originLeadId.toString(),
        'leadName': clientName,
        'amount': advanceFormatted,
        'status': 'Pending Payment',
        'dueDate': DateFormat('dd MMM yyyy')
            .format(DateTime.now().add(const Duration(days: 7))),
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'color': AppColors.warning,
        'statusColor': AppColors.warning,
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': AppConstants.defaultUpiId,
        'items': [
          {
            'desc': 'Turnkey mobilization & procurement advance (10%)',
            'amount': advanceFormatted,
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (!_invoices.any(
        (inv) =>
            inv['project'] == projName &&
            (inv['title'] ?? '')
                .toString()
                .contains('Mobilization Advance'),
      )) {
        setState(() {
          _invoices.insert(0, autoInvoice);
        });
        StorageService.saveInvoices(_invoices);
        BackendManager.instance.createInvoice(
          InvoiceModel.fromMap(autoInvoice),
        );
        MobileActionSheets.invoiceCreatedNotifier.value = autoInvoice;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canManageAccounts = AppPermissions.canManageAccounts(
      auth.currentRole,
      user: auth.currentUser,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalInvoiced = 0;
    final settledInvoiceIds = <String>{};
    for (final inv in _invoices) {
      totalInvoiced += CurrencyUtils.parseAmount(inv['amount']);
      if (inv['status'] == 'Settled') {
        final invId = inv['id']?.toString();
        if (invId != null && invId.isNotEmpty) {
          settledInvoiceIds.add(invId);
        }
      }
    }

    int totalDisbursed = 0;
    for (final exp in _expenses) {
      totalDisbursed += CurrencyUtils.parseAmount(exp['amount']);
    }
    final outgoingStr =
        totalDisbursed > 0 ? CurrencyUtils.formatInr(totalDisbursed) : '₹ 0';

    int unlinkedReceipts = 0;
    for (final rec in _receipts) {
      final linkedInvId = rec['invoiceId']?.toString();
      if (linkedInvId == null || !settledInvoiceIds.contains(linkedInvId)) {
        unlinkedReceipts += CurrencyUtils.parseAmount(rec['amount']);
      }
    }
    final totalIncoming = totalInvoiced + unlinkedReceipts;
    final incomingStr =
        totalIncoming > 0 ? CurrencyUtils.formatInr(totalIncoming) : '₹ 0';

    final isWide = MediaQuery.of(context).size.width > 900;
    final isIncomingEmpty = _selectedIncomingTab == 'Invoices'
        ? _invoices.isEmpty
        : _receipts.isEmpty;

    final incomingPane = Container(
      key: const Key('accounts_incoming_pane'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: const Icon(
                        Icons.south_west_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Incoming (Receivables & Receipts)',
                          style: AppTypography.titleMedium(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PillBox(
                        label: 'Invoices (${_invoices.length})',
                        isSelected: _selectedIncomingTab == 'Invoices',
                        activeColor: AppColors.brandPeach,
                        icon: Icons.receipt_long_rounded,
                        onSelected: () =>
                            setState(() => _selectedIncomingTab = 'Invoices'),
                      ),
                      const SizedBox(width: 8),
                      PillBox(
                        label: 'Receipts (${_receipts.length})',
                        isSelected: _selectedIncomingTab == 'Receipts',
                        activeColor: AppColors.brandPeach,
                        icon: Icons.receipt_rounded,
                        onSelected: () =>
                            setState(() => _selectedIncomingTab = 'Receipts'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          FilterSwitcher(
            child: Container(
              key: ValueKey(_selectedIncomingTab),
              width: double.infinity,
              padding: isIncomingEmpty
                  ? const EdgeInsets.symmetric(vertical: 40, horizontal: 20)
                  : EdgeInsets.zero,
              child: _selectedIncomingTab == 'Invoices'
                  ? _buildInvoicesSection(context, isDark, canManageAccounts)
                  : _buildReceiptsSection(context, isDark, canManageAccounts),
            ),
          ),
        ],
      ),
    );

    final outgoingPane = Container(
      key: const Key('accounts_outgoing_pane'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Outgoing (Payables & Expenses)',
                      style: AppTypography.titleMedium(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    '${_expenses.length} Vouchers',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: _expenses.isEmpty
                ? const EdgeInsets.symmetric(vertical: 40, horizontal: 20)
                : EdgeInsets.zero,
            child: _buildExpensesSection(context, isDark, canManageAccounts),
          ),
        ],
      ),
    );

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Finance, Invoicing & Expense Control',
          subtitle:
              'Manage incoming client invoices & receipts and outgoing vendor & site expenses',
        ),
        const SizedBox(height: ScreenLayout.headerGap),
        // Financial KPIs (Compact StatStrip: Total Incoming & Total Outgoing)
        StatStrip(
          cards: [
            StatCard(
              title: 'Total Incoming',
              value: incomingStr,
              subtitle: (_invoices.isEmpty && _receipts.isEmpty)
                  ? null
                  : '${_invoices.length} invoices • ${_receipts.length} receipts',
              icon: Icons.south_west_rounded,
              accentColor: AppColors.success,
            ),
            StatCard(
              title: 'Total Outgoing',
              value: outgoingStr,
              subtitle: _expenses.isEmpty
                  ? null
                  : '${_expenses.length} expense vouchers',
              icon: Icons.north_east_rounded,
              accentColor: AppColors.warning,
            ),
          ],
        ),
        if (!canManageAccounts) ...[
          const SizedBox(height: ScreenLayout.noticeGap),
          ReadOnlyNotice(
            'Confidential Financial Ledger: Signed in as ${auth.currentRole.title}. Financial vouchers, ledger mutations, and invoices are restricted to Accounts & Proprietor.',
          ),
        ],
        const SizedBox(height: ScreenLayout.sectionGap),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: incomingPane),
              const SizedBox(width: ScreenLayout.gridGap),
              Expanded(child: outgoingPane),
            ],
          )
        else ...[
          incomingPane,
          const SizedBox(height: ScreenLayout.itemGap),
          outgoingPane,
        ],
      ],
    );
  }

  Widget _buildInvoicesSection(
    BuildContext context,
    bool isDark,
    bool canManageAccounts,
  ) {
    if (_invoices.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'No Invoices Generated',
            style: AppTypography.titleMedium(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            'No invoices yet. Tap below to create your first invoice.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
          if (canManageAccounts) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => MobileActionSheets.showCreateInvoiceSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(AppStrings.tr('New Invoice')),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoices.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final color = (inv['statusColor'] as Color?) ?? AppColors.warning;
        final projName = (inv['project'] ?? inv['projectName'] ?? '') as String;
        final leadName = (inv['leadName'] ?? '') as String;

        return InkWell(
          onTap: () => _showInvoiceExpandedBox(context, inv, isDark),
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv['title'] != null &&
                                (inv['title'] as String).isNotEmpty
                            ? inv['title'] as String
                            : inv['client'] as String,
                        style: AppTypography.titleMedium(isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${inv['client']} • ${inv['id']} • ${inv['date']}',
                        style: AppTypography.bodySmall(isDark),
                      ),
                      if (projName.isNotEmpty || leadName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (projName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.business_rounded,
                                      size: 10,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        projName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (leadName.isNotEmpty &&
                                leadName != projName &&
                                leadName != inv['title'] &&
                                leadName != inv['client'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandOrange
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_pin_circle_rounded,
                                      size: 10,
                                      color: AppColors.brandOrange,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        leadName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brandOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      inv['amount'] as String,
                      style: AppTypography.titleMedium(isDark),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Text(
                            'Incoming',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            inv['status'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesSection(
    BuildContext context,
    bool isDark,
    bool canManageAccounts,
  ) {
    if (_expenses.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 44,
            color: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'No Expense Vouchers Logged',
            style: AppTypography.titleMedium(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            'No expenses logged yet. Tap below to record site or material expenses.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
          if (canManageAccounts) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => MobileActionSheets.showAddExpenseSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(AppStrings.tr('Record Expense')),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _expenses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final exp = _expenses[index];
        final color = (exp['statusColor'] as Color?) ?? AppColors.brandPeach;
        return InkWell(
          onTap: () => _showExpenseExpandedBox(context, exp, isDark),
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (exp['title'] as String?) ?? 'Expense Item',
                        style: AppTypography.titleMedium(isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exp['project']} • ${exp['category']} • ${exp['date']}',
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (exp['amount'] as String?) ?? '₹ 0',
                      style: AppTypography.titleMedium(isDark),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Text(
                            'Outgoing',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            (exp['status'] as String?) ?? 'Approved',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptsSection(
    BuildContext context,
    bool isDark,
    bool canManageAccounts,
  ) {
    if (_receipts.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 44,
            color: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'No Receipts Logged',
            style: AppTypography.titleMedium(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload payment receipts, client remittance slips, or vendor bill scans.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
          if (canManageAccounts) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => MobileActionSheets.showAddReceiptSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.receipt_rounded, size: 18),
              label: const Text('Add Receipt'),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canManageAccounts)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment & Bill Receipts',
                  style: AppTypography.titleMedium(isDark),
                ),
                TextButton.icon(
                  onPressed: () =>
                      MobileActionSheets.showAddReceiptSheet(context),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.brandPeach,
                  ),
                  label: const Text(
                    'Add Receipt',
                    style: TextStyle(
                      color: AppColors.brandPeach,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _receipts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final rec = _receipts[index];
            final color =
                (rec['statusColor'] as Color?) ?? AppColors.success;
            final party = (rec['party'] ?? 'Client / Vendor').toString();
            final project = (rec['project'] ?? 'General Studio').toString();
            final mode = (rec['paymentMode'] ?? 'UPI').toString();
            final date = (rec['date'] ?? '').toString();
            final hasAttachment = (rec['attachmentName'] ?? '').toString().isNotEmpty ||
                (rec['attachmentBase64'] ?? '').toString().isNotEmpty ||
                (rec['downloadUrl'] ?? '').toString().isNotEmpty;

            return InkWell(
              onTap: () => _showReceiptExpandedBox(
                context,
                rec,
                isDark,
                canManageAccounts,
              ),
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Icon(
                        hasAttachment
                            ? Icons.document_scanner_rounded
                            : Icons.receipt_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (rec['title'] as String?) ?? 'Payment Receipt',
                            style: AppTypography.titleMedium(isDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$party • $project • $mode • $date',
                            style: AppTypography.bodySmall(isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (rec['amount'] as String?) ?? '₹ 0',
                          style: AppTypography.titleMedium(isDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Text(
                                'Incoming',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                (rec['status'] as String?) ?? 'Verified',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showInvoiceExpandedBox(
    BuildContext context,
    Map<String, dynamic> inv,
    bool isDark,
  ) {
    final color = (inv['statusColor'] as Color?) ?? AppColors.warning;
    final hasQr = (inv['qrCodePath'] != null &&
            inv['qrCodePath'].toString().isNotEmpty) ||
        (inv['qrCodeBase64'] != null &&
            inv['qrCodeBase64'].toString().isNotEmpty);
    final invTitle = (inv['title'] != null && (inv['title'] as String).isNotEmpty)
        ? inv['title'] as String
        : (inv['client'] as String? ?? 'Tax Invoice');
    final invId = inv['id']?.toString() ?? 'INV';
    final client = inv['client']?.toString() ?? 'Client';
    final amount = inv['amount']?.toString() ?? '₹ 0';
    final status = inv['status']?.toString() ?? 'Payment Pending';
    final date = inv['date']?.toString() ?? '';
    final projName = (inv['project'] ?? inv['projectName'] ?? '').toString();
    final leadName = (inv['leadName'] ?? '').toString();
    final upiId = inv['upiId']?.toString() ?? AppConstants.defaultUpiId;

    showExpandedDetailBox(
      context: context,
      title: invTitle,
      subtitle: '$invId • $client',
      headerIcon: Icons.description_rounded,
      accentColor: color,
      badgeLabel: status,
      badgeColor: color,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Invoice Amount',
                value: amount,
                color: AppColors.brandPeach,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Invoice Date',
                value: date.isNotEmpty ? date : 'Current',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Mapping & Payment Info', isDark: isDark),
          DetailInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Client',
            value: client,
            isDark: isDark,
          ),
          if (projName.isNotEmpty)
            DetailInfoRow(
              icon: Icons.apartment_rounded,
              label: 'Linked Project',
              value: projName,
              isDark: isDark,
              valueColor: AppColors.info,
            ),
          if (leadName.isNotEmpty)
            DetailInfoRow(
              icon: Icons.person_pin_circle_rounded,
              label: 'Linked Lead',
              value: leadName,
              isDark: isDark,
              valueColor: AppColors.brandOrange,
            ),
          DetailInfoRow(
            icon: Icons.qr_code_2_rounded,
            label: 'UPI / QR Code',
            value: hasQr ? 'Attached ($upiId)' : 'Not Uploaded Yet',
            isDark: isDark,
            valueColor: hasQr ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        OutlinedButton.icon(
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Print PDF', maxLines: 1),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            PdfService.showPdfViewer(
              context,
              title: 'Tax Invoice $invId',
              documentBuilder: () => PdfService.generateInvoicePdf(inv),
            );
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          icon: Icon(
            hasQr ? Icons.qr_code_2_rounded : Icons.add_photo_alternate_outlined,
            size: 15,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hasQr ? 'Pay via QR' : 'Upload QR',
              maxLines: 1,
            ),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            if (hasQr) {
              InvoiceQrPaymentDialog.show(
                context,
                invoice: inv,
                onStatusChanged: () {
                  setState(() {
                    _invoices.clear();
                    _invoices.addAll(StorageService.getInvoices());
                  });
                },
              );
            } else {
              UploadInvoiceQrSheet.show(
                context,
                invoiceId: inv['id'] as String?,
                currentUpiId: inv['upiId'] as String?,
                onQrSelected: (path, b64, upi) {
                  setState(() {
                    inv['qrCodePath'] = path;
                    inv['qrCodeBase64'] = b64;
                    inv['upiId'] = upi;
                  });
                },
              );
            }
          },
        ),
      ],
    );
  }

  void _showExpenseExpandedBox(
    BuildContext context,
    Map<String, dynamic> exp,
    bool isDark,
  ) {
    final color = (exp['statusColor'] as Color?) ?? AppColors.brandPeach;
    final title = (exp['title'] as String?) ?? 'Expense Item';
    final project = (exp['project'] as String?) ?? 'General Site';
    final category = (exp['category'] as String?) ?? 'Site Expense';
    final date = (exp['date'] as String?) ?? '';
    final amount = (exp['amount'] as String?) ?? '₹ 0';
    final status = (exp['status'] as String?) ?? 'Approved';
    final vendor = (exp['vendor'] as String?) ?? '';

    showExpandedDetailBox(
      context: context,
      title: title,
      subtitle: project,
      headerIcon: Icons.payments_outlined,
      accentColor: color,
      badgeLabel: status,
      badgeColor: color,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Disbursed Amount',
                value: amount,
                color: color,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Voucher Date',
                value: date.isNotEmpty ? date : 'Recorded',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Voucher Breakdown', isDark: isDark),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project Site',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: category,
            isDark: isDark,
          ),
          if (vendor.isNotEmpty)
            DetailInfoRow(
              icon: Icons.storefront_rounded,
              label: 'Payee / Vendor',
              value: vendor,
              isDark: isDark,
            ),
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget? _buildReceiptAttachmentPreview(
    Map<String, dynamic> rec, {
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final isImg = (rec['isImageAttachment'] as bool?) ?? true;
    final path = rec['attachmentPath']?.toString();
    final b64 = rec['attachmentBase64']?.toString();
    final url = rec['downloadUrl']?.toString();

    if (!isImg) return null;
    if (path != null &&
        path.isNotEmpty &&
        !path.startsWith('http') &&
        !kIsWeb &&
        File(path).existsSync()) {
      return Image.file(File(path), height: height, fit: fit);
    }
    if (b64 != null && b64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(b64), height: height, fit: fit);
      } catch (_) {}
    }
    if (url != null && url.isNotEmpty) {
      return CloudNetworkImage(url: url, height: height, fit: fit);
    }
    return null;
  }

  Future<void> _deleteReceipt(Map<String, dynamic> rec) async {
    final id = rec['id']?.toString() ?? '';
    final storagePath = rec['storagePath']?.toString();
    final downloadUrl = rec['downloadUrl']?.toString();

    setState(() {
      _receipts.removeWhere((r) => r['id'] == id);
    });
    await StorageService.saveReceipts(_receipts);
    if (id.isNotEmpty) {
      BackendManager.instance.deleteDocument('receipts', id);
    }
    if ((storagePath != null && storagePath.isNotEmpty) ||
        (downloadUrl != null && downloadUrl.isNotEmpty)) {
      CloudStorageService.deleteFile(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
      );
    }
  }

  void _showReceiptExpandedBox(
    BuildContext context,
    Map<String, dynamic> rec,
    bool isDark,
    bool canManageAccounts,
  ) {
    final color = (rec['statusColor'] as Color?) ?? AppColors.success;
    final title = (rec['title'] as String?) ?? 'Payment Receipt';
    final recId = (rec['id'] ?? 'RCP').toString();
    final party = (rec['party'] ?? 'Client / Vendor').toString();
    final project = (rec['project'] ?? 'General Studio').toString();
    final type = (rec['type'] ?? 'Payment Received').toString();
    final mode = (rec['paymentMode'] ?? 'UPI').toString();
    final date = (rec['timestamp'] ?? rec['date'] ?? '').toString();
    final amount = (rec['amount'] as String?) ?? '₹ 0';
    final status = (rec['status'] as String?) ?? 'Verified';
    final notes = (rec['notes'] ?? '').toString();
    final invoiceId = (rec['invoiceId'] ?? '').toString();
    final attachmentName = (rec['attachmentName'] ?? '').toString();
    final preview = _buildReceiptAttachmentPreview(rec, height: 180);

    showExpandedDetailBox(
      context: context,
      title: title,
      subtitle: '$recId • $party',
      headerIcon: Icons.receipt_rounded,
      accentColor: color,
      badgeLabel: status,
      badgeColor: color,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Receipt Amount',
                value: amount,
                color: color,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Recorded On',
                value: date.isNotEmpty ? date : 'Recorded',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Receipt Details', isDark: isDark),
          DetailInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Party',
            value: party,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project Site',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.category_outlined,
            label: 'Receipt Type',
            value: type,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment Mode',
            value: mode,
            isDark: isDark,
          ),
          if (invoiceId.isNotEmpty)
            DetailInfoRow(
              icon: Icons.receipt_long_rounded,
              label: 'Linked Invoice',
              value: invoiceId,
              isDark: isDark,
              valueColor: AppColors.info,
            ),
          if (notes.isNotEmpty)
            DetailInfoRow(
              icon: Icons.notes_rounded,
              label: 'Notes / UTR',
              value: notes,
              isDark: isDark,
            ),
          if (preview != null || attachmentName.isNotEmpty) ...[
            const SizedBox(height: 14),
            DetailSectionTitle(label: 'Receipt Scan / Attachment', isDark: isDark),
            InkWell(
              key: const Key('receipt_attachment_fullscreen_tap'),
              borderRadius: BorderRadius.circular(6.0),
              onTap: () {
                FullScreenMediaViewer.show(
                  dialogCtx,
                  title: title,
                  subtitle: '$recId • $party',
                  filePath: rec['attachmentPath']?.toString(),
                  fileUrl: rec['downloadUrl']?.toString(),
                  base64Data: rec['attachmentBase64']?.toString(),
                  fileName: attachmentName.isNotEmpty ? attachmentName : null,
                  fallbackIcon: preview != null
                      ? Icons.image_rounded
                      : Icons.picture_as_pdf_rounded,
                  accentColor: color,
                );
              },
              child: preview != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: preview,
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Full Screen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 18,
                            color: AppColors.brandPeach,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attachmentName,
                              style: AppTypography.bodySmall(isDark),
                            ),
                          ),
                          const Icon(
                            Icons.fullscreen_rounded,
                            size: 18,
                            color: AppColors.brandPeach,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        if (canManageAccounts)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 0.8),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _deleteReceipt(rec);
              if (mounted) {
                AppNotification.show(
                  this.context,
                  message: 'Receipt "$title" removed from ledger.',
                );
              }
            },
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
