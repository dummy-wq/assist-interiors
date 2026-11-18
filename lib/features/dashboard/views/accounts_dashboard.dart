import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
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
  String _selectedSection = 'Invoices';

  @override
  void initState() {
    super.initState();
    _invoices.addAll(StorageService.getInvoices());
    _expenses.addAll(StorageService.getExpenses());
    MobileActionSheets.invoiceCreatedNotifier.addListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.addListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.addListener(_onExpenseCreated);
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    StorageService.cloudSyncNotifier.addListener(_onCloudSync);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onCloudSync);
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.removeListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.removeListener(_onExpenseCreated);
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
        _expenses.insert(0, Map<String, dynamic>.from(exp));
      });
      StorageService.saveExpenses(_expenses);
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

    int totalReceivables = 0;
    for (final inv in _invoices) {
      if (inv['status'] != 'Settled') {
        totalReceivables += CurrencyUtils.parseAmount(inv['amount']);
      }
    }
    final receivablesStr =
        totalReceivables > 0 ? CurrencyUtils.formatInr(totalReceivables) : '₹ 0';

    int totalDisbursed = 0;
    for (final exp in _expenses) {
      totalDisbursed += CurrencyUtils.parseAmount(exp['amount']);
    }
    final disbursedStr =
        totalDisbursed > 0 ? CurrencyUtils.formatInr(totalDisbursed) : '₹ 0';

    return ScreenScrollView(
      children: [
        const ScreenHeader('Finance, Invoicing & Expense Control'),
        const SizedBox(height: ScreenLayout.headerGap),
        // Financial KPIs (Compact StatStrip)
        StatStrip(
          cards: [
            StatCard(
              title: 'Receivables',
              value: receivablesStr,
              subtitle: _invoices.isEmpty
                  ? null
                  : '${_invoices.where((i) => i['status'] != 'Settled').length} active billings',
              icon: Icons.account_balance_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Disbursed',
              value: disbursedStr,
              subtitle: _expenses.isEmpty
                  ? null
                  : '${_expenses.length} expense vouchers',
              icon: Icons.payments_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Site Claims',
              value: '${_expenses.length} Vouchers',
              icon: Icons.receipt_rounded,
              accentColor: AppColors.warning,
            ),
            const StatCard(
              title: 'GST Status',
              value: 'Verified',
              trend: 'Active',
              icon: Icons.fact_check_rounded,
              accentColor: AppColors.success,
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PillBox(
                label: 'Invoices (${_invoices.length})',
                isSelected: _selectedSection == 'Invoices',
                activeColor: AppColors.brandPeach,
                icon: Icons.receipt_long_rounded,
                onSelected: () => setState(() => _selectedSection = 'Invoices'),
              ),
              const SizedBox(width: 8),
              PillBox(
                label: 'Expense Vouchers (${_expenses.length})',
                isSelected: _selectedSection == 'Expenses',
                activeColor: AppColors.brandPeach,
                icon: Icons.payments_rounded,
                onSelected: () => setState(() => _selectedSection = 'Expenses'),
              ),
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),
        FilterSwitcher(
          child: Container(
            key: ValueKey(_selectedSection),
            width: double.infinity,
            padding:
                (_selectedSection == 'Invoices'
                    ? _invoices.isEmpty
                    : _expenses.isEmpty)
                ? const EdgeInsets.symmetric(vertical: 48, horizontal: 20)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
            child: _selectedSection == 'Invoices'
                ? (_invoices.isEmpty
                      ? Column(
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
                              'All invoice records have been cleared. Tap "Add Invoice" to log milestone billings.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall(isDark),
                            ),
                          ],
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _invoices.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final inv = _invoices[index];
                            final color = (inv['statusColor'] as Color?) ?? AppColors.warning;
                            final hasQr = (inv['qrCodePath'] != null &&
                                    inv['qrCodePath'].toString().isNotEmpty) ||
                                (inv['qrCodeBase64'] != null &&
                                    inv['qrCodeBase64'].toString().isNotEmpty);
                            final projName = (inv['project'] ?? inv['projectName'] ?? '') as String;
                            final leadName = (inv['leadName'] ?? '') as String;

                            return InkWell(
                              onTap: () => _showInvoiceExpandedBox(
                                context,
                                inv,
                                isDark,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv['title'] != null &&
                                                    (inv['title'] as String)
                                                        .isNotEmpty
                                                ? inv['title'] as String
                                                : inv['client'] as String,
                                            style: AppTypography.titleMedium(
                                              isDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${inv['client']} • ${inv['id']} • ${inv['date']}',
                                            style: AppTypography.bodySmall(
                                              isDark,
                                            ),
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
                                                      color: AppColors.brandOrange.withValues(alpha: 0.12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          inv['amount'] as String,
                                          style: AppTypography.titleMedium(
                                            isDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
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
                                    const SizedBox(width: 2),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.all(4),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(
                                        hasQr
                                            ? Icons.qr_code_2_rounded
                                            : Icons.add_photo_alternate_outlined,
                                        size: 19,
                                      ),
                                      tooltip: hasQr
                                          ? 'Scan & Pay via QR'
                                          : 'Upload Payment QR Code',
                                      color: hasQr
                                          ? AppColors.brandPeach
                                          : (isDark
                                              ? AppColors.textLightMuted
                                              : AppColors.textDarkMuted),
                                      onPressed: () {
                                        if (hasQr) {
                                          InvoiceQrPaymentDialog.show(
                                            context,
                                            invoice: inv,
                                            onStatusChanged: () {
                                              setState(() {
                                                _invoices.clear();
                                                _invoices.addAll(
                                                  StorageService.getInvoices(),
                                                );
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
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.all(4),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 18,
                                      ),
                                      tooltip: 'View & Print Tax Invoice PDF',
                                      color: AppColors.brandPeach,
                                      onPressed: () {
                                        PdfService.showPdfViewer(
                                          context,
                                          title: 'Tax Invoice ${inv['id']}',
                                          documentBuilder: () =>
                                              PdfService.generateInvoicePdf(
                                                inv,
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ))
                : (_expenses.isEmpty
                      ? Column(
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
                              'All expense records have been cleared. Tap "Record Expense" to record site expenses, material purchases, or labour payouts.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall(isDark),
                            ),
                          ],
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _expenses.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final exp = _expenses[index];
                            final color =
                                (exp['statusColor'] as Color?) ??
                                AppColors.brandPeach;
                            return InkWell(
                              onTap: () => _showExpenseExpandedBox(
                                context,
                                exp,
                                isDark,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
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
                                      Icons.payments_outlined,
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (exp['title'] as String?) ??
                                              'Expense Item',
                                          style: AppTypography.titleMedium(
                                            isDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${exp['project']} • ${exp['category']} • ${exp['date']}',
                                          style: AppTypography.bodySmall(
                                            isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        (exp['amount'] as String?) ?? '₹ 0',
                                        style: AppTypography.titleMedium(
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6.0,
                                          ),
                                        ),
                                        child: Text(
                                          (exp['status'] as String?) ??
                                              'Approved',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            );
                          },
                        )),
          ),
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
}
