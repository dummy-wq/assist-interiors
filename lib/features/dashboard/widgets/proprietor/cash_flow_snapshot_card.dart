import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/instant_press_feedback.dart';

/// Card displaying executive studio cash flow, billing ratios, and recent ledger activity.
class CashFlowSnapshotCard extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> expenses;
  final VoidCallback? onTap;

  const CashFlowSnapshotCard({
    super.key,
    required this.projects,
    required this.invoices,
    required this.expenses,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalInvoiced = 0;
    int totalCollected = 0;
    int totalReceivables = 0;
    for (final inv in invoices) {
      final amt = CurrencyUtils.parseAmount(inv['amount']);
      totalInvoiced += amt;
      if (inv['status'] == 'Settled') {
        totalCollected += amt;
      } else {
        totalReceivables += amt;
      }
    }

    int totalDisbursed = 0;
    for (final exp in expenses) {
      totalDisbursed += CurrencyUtils.parseAmount(exp['amount']);
    }

    final netCash = totalInvoiced - totalDisbursed;

    final totalFlow = totalInvoiced + totalDisbursed;
    final inflowRatio = totalFlow > 0 ? (totalInvoiced / totalFlow) : 0.5;
    final outflowRatio = totalFlow > 0 ? (totalDisbursed / totalFlow) : 0.5;

    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSizes.borderRadiusMd,
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach.withValues(alpha: 0.15),
                        borderRadius: AppSizes.borderRadiusMd,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.brandPeach,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Cash Flow Snapshot',
                      style: AppTypography.titleMedium(isDark),
                    ),
                  ],
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 32.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                    borderRadius: AppSizes.borderRadiusMd,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 13,
                        color: AppColors.brandPeach,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Accounts Real-Time',
                        style: AppTypography.labelLarge(isDark).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.brandPeach,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Pillars: Inflow, Outflow, Net Position
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    final cards = [
                      _buildMetricTile(
                        isDark: isDark,
                        title: 'Total Inflow (Billings)',
                        amount: totalInvoiced > 0
                            ? CurrencyUtils.formatInr(totalInvoiced)
                            : '₹ 0',
                        subtitle:
                            'Collected: ${totalCollected > 0 ? CurrencyUtils.formatInr(totalCollected) : "₹ 0"} • Unsettled: ${totalReceivables > 0 ? CurrencyUtils.formatInr(totalReceivables) : "₹ 0"}',
                        icon: Icons.south_west_rounded,
                        color: AppColors.success,
                      ),
                      _buildMetricTile(
                        isDark: isDark,
                        title: 'Total Outflow (Disbursed)',
                        amount: totalDisbursed > 0
                            ? CurrencyUtils.formatInr(totalDisbursed)
                            : '₹ 0',
                        subtitle:
                            '${expenses.length} Expense Vouchers Processed',
                        icon: Icons.north_east_rounded,
                        color: AppColors.brandPeach,
                      ),
                      _buildMetricTile(
                        isDark: isDark,
                        title: 'Net Cash Position',
                        amount: netCash != 0
                            ? CurrencyUtils.formatInr(netCash)
                            : '₹ 0',
                        subtitle: netCash >= 0
                            ? 'Surplus Operating Balance'
                            : 'Negative Cash Deficit',
                        icon: Icons.swap_vert_rounded,
                        color: netCash >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ];

                    if (isCompact) {
                      return Column(
                        children: cards
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: c,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[2]),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Visual Proportional Flow Bar
                Text(
                  'Inflow vs. Outflow Balance',
                  style: AppTypography.labelLarge(isDark)
                      .copyWith(fontSize: 11),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppSizes.borderRadiusSm,
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (inflowRatio * 100).toInt().clamp(1, 99),
                          child: Container(color: AppColors.success),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: (outflowRatio * 100).toInt().clamp(1, 99),
                          child: Container(color: AppColors.brandPeach),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: AppSizes.borderRadiusSm,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Inflow (${(inflowRatio * 100).toInt()}%)',
                          style: AppTypography.bodySmall(isDark)
                              .copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach,
                            borderRadius: AppSizes.borderRadiusSm,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Outflow (${(outflowRatio * 100).toInt()}%)',
                          style: AppTypography.bodySmall(isDark)
                              .copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Accounts Activity Strip
                Text(
                  'Recent Accounts Ledger Activity',
                  style: AppTypography.labelLarge(isDark)
                      .copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                if (invoices.isEmpty && expenses.isEmpty)
                  Text(
                    'No invoices or vouchers logged yet.',
                    style: AppTypography.bodySmall(isDark),
                  )
                else ...[
                  ...invoices
                      .take(2)
                      .map(
                        (inv) => _buildRecentActivityRow(
                          isDark: isDark,
                          title:
                              '${inv['invoiceNumber'] ?? 'Invoice'} • ${inv['client'] ?? inv['project'] ?? 'Client Billing'}',
                          subtitle: inv['date'] as String? ?? 'Recent',
                          amount: inv['amount'] as String? ?? '₹ 0',
                          isInflow: true,
                          status: inv['status'] as String? ?? 'Pending',
                        ),
                      ),
                  ...expenses
                      .take(1)
                      .map(
                        (exp) => _buildRecentActivityRow(
                          isDark: isDark,
                          title:
                              '${exp['title'] ?? 'Site Expense'} • ${exp['project'] ?? 'Site Claim'}',
                          subtitle: exp['date'] as String? ?? 'Recent',
                          amount: exp['amount'] as String? ?? '₹ 0',
                          isInflow: false,
                          status: exp['status'] as String? ?? 'Disbursed',
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InstantPressFeedback(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSizes.borderRadiusMd,
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: AppSizes.borderRadiusSm,
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySmall(isDark).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTypography.displayMedium(isDark).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTypography.bodySmall(isDark).copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.textLightMuted
                  : AppColors.textDarkMuted,
              height: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityRow({
    required bool isDark,
    required String title,
    required String subtitle,
    required String amount,
    required bool isInflow,
    required String status,
  }) {
    final color = isInflow ? AppColors.success : AppColors.brandPeach;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppSizes.borderRadiusSm,
            ),
            child: Text(
              isInflow ? 'IN' : 'OUT',
              style: AppTypography.labelSmall(isDark).copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium(isDark)
                      .copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(isDark).copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isInflow ? '+ $amount' : '- $amount',
            style: AppTypography.labelLarge(isDark).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
