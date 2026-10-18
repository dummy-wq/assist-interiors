import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/instant_press_feedback.dart';

/// Hub element representing the Sales & Client Acquisition screen.
/// Displays active lead pipeline, inquiry volume, and due follow-ups.
class SalesSnapshotCard extends StatelessWidget {
  final List<Map<String, dynamic>> leads;
  final VoidCallback? onTap;

  const SalesSnapshotCard({super.key, required this.leads, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalPipelineValue = 0;
    int dueFollowupsCount = 0;
    final now = DateTime.now();

    for (final l in leads) {
      final raw = (l['estValue'] as String? ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      totalPipelineValue += int.tryParse(raw) ?? 0;

      final nextCall = l['nextCallDate'] as String?;
      if (nextCall != null && nextCall.isNotEmpty) {
        try {
          final parsed = DateFormat('dd MMM yyyy').parse(nextCall);
          if (parsed.year == now.year &&
              parsed.month == now.month &&
              parsed.day == now.day) {
            dueFollowupsCount++;
          }
        } catch (_) {}
      }
    }

    final pipelineStr = totalPipelineValue > 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(totalPipelineValue)
        : '₹ 0';

    final previewLeads = leads.take(2).toList();

    return InstantPressFeedback(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusMd,
        child: Container(
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                            color: AppColors.brandOrange.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: AppSizes.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: AppColors.brandOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sales Pipeline',
                          style: AppTypography.titleMedium(isDark),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                              Text(
                                '${leads.length} Leads',
                                style: AppTypography.labelLarge(isDark)
                                    .copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.brandOrange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // KPI Summary Strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Total Pipeline',
                        value: pipelineStr,
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Active Inquiries',
                        value: '${leads.length}',
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color:
                          (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Due Calls',
                        value: '$dueFollowupsCount',
                        isDark: isDark,
                        valueColor: dueFollowupsCount > 0
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Lead Previews or Zero State
              if (previewLeads.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.8),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: previewLeads.map((l) {
                      final client = l['clientName'] as String? ?? 'New Lead';
                      final type =
                          l['projectType'] as String? ?? 'Interior Design';
                      final stage = l['stage'] as String? ?? 'New Inquiry';
                      final est = l['estValue'] as String? ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground.withValues(alpha: 0.5)
                              : AppColors.lightBackground.withValues(
                                  alpha: 0.7,
                                ),
                          borderRadius: AppSizes.borderRadiusSm,
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.brandOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 11,
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
                            if (est.isNotEmpty) ...[
                              Text(
                                est,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPeach,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandOrange.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                stage,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brandOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Center(
                    child: Text(
                      'No active leads in pipeline • Tap to manage Sales',
                      style: AppTypography.bodySmall(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  (isDark
                      ? AppColors.textLightPrimary
                      : AppColors.textDarkPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
