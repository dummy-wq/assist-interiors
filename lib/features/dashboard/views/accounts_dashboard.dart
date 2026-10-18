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
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../auth/state/auth_provider.dart';
import '../widgets/mobile_action_sheets.dart';

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
    MobileActionSheets.expenseCreatedNotifier.addListener(_onExpenseCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceCreated);
    MobileActionSheets.expenseCreatedNotifier.removeListener(_onExpenseCreated);
    super.dispose();
  }

  void _onInvoiceCreated() {
    final invoice = MobileActionSheets.invoiceCreatedNotifier.value;
    if (invoice != null && mounted) {
      setState(() {
        _invoices.insert(0, Map<String, dynamic>.from(invoice));
      });
      StorageService.saveInvoices(_invoices);
      BackendManager.instance.createInvoice(InvoiceModel.fromMap(invoice));
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canManageAccounts = AppPermissions.canManageAccounts(
      auth.currentRole,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalReceivables = 0;
    for (final inv in _invoices) {
      if (inv['status'] != 'Settled') {
        final raw = (inv['amount'] as String).replaceAll(RegExp(r'[^0-9]'), '');
        totalReceivables += int.tryParse(raw) ?? 0;
      }
    }
    final receivablesStr = totalReceivables > 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(totalReceivables)
        : '₹ 0';

    int totalDisbursed = 0;
    for (final exp in _expenses) {
      final raw = (exp['amount'] as String).replaceAll(RegExp(r'[^0-9]'), '');
      totalDisbursed += int.tryParse(raw) ?? 0;
    }
    final disbursedStr = totalDisbursed > 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(totalDisbursed)
        : '₹ 0';

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
                            final color = inv['statusColor'] as Color;
                            return InkWell(
                              onTap: () {
                                PdfService.showPdfViewer(
                                  context,
                                  title: 'Tax Invoice ${inv['id']}',
                                  documentBuilder: () =>
                                      PdfService.generateInvoicePdf(inv),
                                );
                              },
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
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
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
                                            inv['client'] as String,
                                            style: AppTypography.titleMedium(
                                              isDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${inv['id']} • ${inv['date']}',
                                            style: AppTypography.bodySmall(
                                              isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.0,
                                            ),
                                          ),
                                          child: Text(
                                            inv['status'] as String,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 20,
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
                            return Padding(
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
                            );
                          },
                        )),
          ),
        ),
      ],
    );
  }
}
