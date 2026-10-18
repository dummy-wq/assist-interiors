import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/instant_press_feedback.dart';

/// Hub element representing the Vendors & Suppliers screen.
/// Displays trade supplier counts, category coverage, and verified partner previews.
class VendorsSnapshotCard extends StatelessWidget {
  final List<Map<String, dynamic>> vendors;
  final VoidCallback? onTap;

  const VendorsSnapshotCard({super.key, required this.vendors, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = <String>{};
    int totalProjectsCovered = 0;

    for (final v in vendors) {
      final cat = v['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
      final rawCount = v['projectsCount'];
      final count = rawCount is num
          ? rawCount.toInt()
          : (int.tryParse(rawCount?.toString() ?? '') ?? 1);
      totalProjectsCovered += count;
    }

    final previewVendors = vendors.take(2).toList();

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
                            color: const Color(0xFFD4AF87)
                                .withValues(alpha: 0.15),
                            borderRadius: AppSizes.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFD4AF87),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Trade Partners',
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
                                '${vendors.length} Suppliers',
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
                                color: Color(0xFFD4AF87),
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
                        label: 'Active Partners',
                        value: '${vendors.length}',
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
                        label: 'Trade Categories',
                        value: '${categories.length}',
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
                        label: 'Sites Supplied',
                        value: '$totalProjectsCovered',
                        isDark: isDark,
                        valueColor: totalProjectsCovered > 0
                            ? AppColors.brandPeach
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Vendor Previews or Zero State
              if (previewVendors.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.8),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: previewVendors.map((v) {
                      final name = v['name'] as String? ?? 'Trade Partner';
                      final category =
                          v['category'] as String? ?? 'General Supplier';
                      final phone = v['phone'] as String? ?? '';
                      final rawRating = v['rating'];
                      final rating = rawRating is num
                          ? rawRating.toDouble()
                          : (double.tryParse(rawRating?.toString() ?? '') ??
                                4.8);

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
                                color: Color(0xFFD4AF87),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
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
                                    phone.isNotEmpty
                                        ? '$category • $phone'
                                        : category,
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFE5A93C),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                      'No trade suppliers registered • Tap to manage Vendors',
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
