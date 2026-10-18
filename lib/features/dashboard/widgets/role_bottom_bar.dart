import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';

class RoleBottomBar extends StatelessWidget {
  final UserRole role;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int pendingStaffCount;

  const RoleBottomBar({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onTabSelected,
    this.pendingStaffCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        minimum: const EdgeInsets.only(bottom: 6.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTabSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.brandPeach,
            unselectedItemColor: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.hub_outlined, size: 20),
                activeIcon: const Icon(Icons.hub_rounded, size: 20),
                label: AppStrings.tabHub,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.campaign_outlined, size: 20),
                activeIcon: const Icon(Icons.campaign_rounded, size: 20),
                label: AppStrings.tabSales,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.apartment_outlined, size: 20),
                activeIcon: const Icon(Icons.apartment_rounded, size: 20),
                label: AppStrings.tabProjects,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.storefront_outlined, size: 20),
                activeIcon: const Icon(Icons.storefront_rounded, size: 20),
                label: AppStrings.tabVendors,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.task_alt_outlined, size: 20),
                activeIcon: const Icon(Icons.task_alt_rounded, size: 20),
                label: AppStrings.tabTasks,
              ),
              BottomNavigationBarItem(
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                ),
                activeIcon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                ),
                label: AppStrings.tabAccounts,
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingStaffCount > 0,
                  label: Text('$pendingStaffCount'),
                  backgroundColor: AppColors.brandPeachDark,
                  child: const Icon(Icons.badge_outlined, size: 20),
                ),
                activeIcon: Badge(
                  isLabelVisible: pendingStaffCount > 0,
                  label: Text('$pendingStaffCount'),
                  backgroundColor: AppColors.brandPeachDark,
                  child: const Icon(Icons.badge_rounded, size: 20),
                ),
                label: AppStrings.tabTeam,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
