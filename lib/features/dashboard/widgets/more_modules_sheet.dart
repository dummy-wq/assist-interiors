import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_modal_sheet.dart';

/// Modal sheet for secondary and specialized enterprise modules
/// ("Assist Interiors Suite"), freeing up the bottom navigation bar.
class MoreModulesSheet extends StatelessWidget {
  final int currentScreenIndex;
  final int pendingStaffCount;
  final ValueChanged<int> onSelectTab;

  const MoreModulesSheet({
    super.key,
    required this.currentScreenIndex,
    required this.pendingStaffCount,
    required this.onSelectTab,
  });

  static void show(
    BuildContext context, {
    required int currentScreenIndex,
    required int pendingStaffCount,
    required ValueChanged<int> onSelectTab,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandleBar: false,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) => MoreModulesSheet(
        currentScreenIndex: currentScreenIndex,
        pendingStaffCount: pendingStaffCount,
        onSelectTab: onSelectTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: AppSizes.sheetBottomPadding(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle (kept outside scroll area so it always drags)
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPeach.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
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
                        'Assist Interiors Suite',
                        style: AppTypography.titleMedium(isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Specialized studio, procurement & operations',
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('more_sheet_close_btn'),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close Sheet',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable 2x2 Module Grid + Footer Note
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        _buildModuleCard(
                          context: context,
                          key: const Key('more_sheet_module_design'),
                          screenIndex: 3,
                          title: 'Design Studio',
                          subtitle: 'CAD Drawings & 3D Renders',
                          icon: Icons.draw_rounded,
                          accentColor: const Color(0xFF6366F1),
                          isDark: isDark,
                          isActive: currentScreenIndex == 3,
                        ),
                        _buildModuleCard(
                          context: context,
                          key: const Key('more_sheet_module_materials'),
                          screenIndex: 4,
                          title: 'Materials',
                          subtitle: 'Site Indents & Stock',
                          icon: Icons.inventory_2_rounded,
                          accentColor: const Color(0xFFF59E0B),
                          isDark: isDark,
                          isActive: currentScreenIndex == 4,
                        ),
                        _buildModuleCard(
                          context: context,
                          key: const Key('more_sheet_module_amendments'),
                          screenIndex: 5,
                          title: 'Amendments',
                          subtitle: 'Variations & Approvals',
                          icon: Icons.published_with_changes_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          isActive: currentScreenIndex == 5,
                        ),
                        _buildModuleCard(
                          context: context,
                          key: const Key('more_sheet_module_team'),
                          screenIndex: 7,
                          title: 'Team & Staff',
                          subtitle: 'Directory, Roles & Crew',
                          icon: Icons.badge_rounded,
                          accentColor: const Color(0xFF10B981),
                          isDark: isDark,
                          isActive: currentScreenIndex == 7,
                          badgeText: pendingStaffCount > 0
                              ? '$pendingStaffCount Pending'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Footer Note
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
                      child: Center(
                        child: Text(
                          'Primary tabs (Hub, Sales, Projects, Accounts) are accessible on the main bar.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required Key key,
    required int screenIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required bool isActive,
    String? badgeText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () {
          Navigator.pop(context);
          onSelectTab(screenIndex);
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.brandPeach.withValues(alpha: isDark ? 0.16 : 0.12)
                : (isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isActive
                  ? AppColors.brandPeach
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.7),
              width: isActive ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeachDark,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (isActive)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.brandPeach,
                      size: 16,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.brandPeach
                          : (isDark
                              ? AppColors.textLightPrimary
                              : AppColors.textDarkPrimary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
