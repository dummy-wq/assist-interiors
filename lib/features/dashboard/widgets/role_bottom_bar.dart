import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import 'more_modules_sheet.dart';

class _NavTabSpec {
  final int tabIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavTabSpec({
    required this.tabIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Ergonomic, role-aware mobile bottom navigation bar.
/// Displays 4 high-frequency primary tabs tailored to the logged-in [UserRole]
/// plus a 5th "More / Suite" launcher for remaining modules.
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

  static _NavTabSpec _tabSpec(int tabIndex, {bool isFieldStaff = false}) {
    switch (tabIndex) {
      case 0:
        return _NavTabSpec(
          tabIndex: 0,
          label: isFieldStaff ? AppStrings.tr('Home') : AppStrings.tabHub,
          icon: isFieldStaff ? Icons.home_outlined : Icons.hub_outlined,
          activeIcon: isFieldStaff ? Icons.home_rounded : Icons.hub_rounded,
        );
      case 1:
        return _NavTabSpec(
          tabIndex: 1,
          label: AppStrings.tabSales,
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
        );
      case 2:
        return _NavTabSpec(
          tabIndex: 2,
          label: isFieldStaff ? AppStrings.tr('Sites') : AppStrings.tabProjects,
          icon: Icons.apartment_outlined,
          activeIcon: Icons.apartment_rounded,
        );
      case 3:
        return _NavTabSpec(
          tabIndex: 3,
          label: AppStrings.tabDesign,
          icon: Icons.draw_outlined,
          activeIcon: Icons.draw_rounded,
        );
      case 4:
        return _NavTabSpec(
          tabIndex: 4,
          label: AppStrings.tabMaterials,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        );
      case 5:
        return _NavTabSpec(
          tabIndex: 5,
          label: isFieldStaff
              ? AppStrings.tr('Issues')
              : AppStrings.tabAmendments,
          icon: Icons.published_with_changes_outlined,
          activeIcon: Icons.published_with_changes_rounded,
        );
      case 6:
        return _NavTabSpec(
          tabIndex: 6,
          label: AppStrings.tabAccounts,
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
        );
      default:
        return _NavTabSpec(
          tabIndex: 7,
          label: AppStrings.tabTeam,
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge_rounded,
        );
    }
  }

  List<_NavTabSpec> get _primaryTabs {
    final isFieldStaff = role == UserRole.supervisor;
    final List<int> indices;
    switch (role) {
      case UserRole.proprietor:
        indices = const [0, 1, 2, 6];
        break;
      case UserRole.sales:
        indices = const [0, 1, 2, 5];
        break;
      case UserRole.projectManager:
        indices = const [0, 2, 4, 5];
        break;
      case UserRole.designer:
        indices = const [0, 3, 2, 5];
        break;
      case UserRole.accounts:
        indices = const [0, 6, 2, 4];
        break;
      case UserRole.supervisor:
        indices = const [0, 2, 4, 5];
        break;
    }
    return [
      for (final idx in indices) _tabSpec(idx, isFieldStaff: isFieldStaff),
    ];
  }

  int _bottomNavIndex(List<_NavTabSpec> primaryTabs) {
    final match = primaryTabs.indexWhere((t) => t.tabIndex == selectedIndex);
    return match >= 0 ? match : 4;
  }

  void _onItemTapped(
    BuildContext context,
    int bottomIndex,
    List<_NavTabSpec> primaryTabs,
  ) {
    if (bottomIndex >= 0 && bottomIndex < primaryTabs.length) {
      onTabSelected(primaryTabs[bottomIndex].tabIndex);
      return;
    }
    MoreModulesSheet.show(
      context,
      currentScreenIndex: selectedIndex,
      pendingStaffCount: pendingStaffCount,
      onSelectTab: onTabSelected,
    );
  }

  BottomNavigationBarItem _buildMoreItem(
    List<_NavTabSpec> primaryTabs,
  ) {
    final isPrimaryActive = primaryTabs.any((t) => t.tabIndex == selectedIndex);
    if (!isPrimaryActive && selectedIndex >= 0 && selectedIndex <= 7) {
      final spec = _tabSpec(selectedIndex);
      final showBadge = selectedIndex == 7 && pendingStaffCount > 0;
      return BottomNavigationBarItem(
        icon: showBadge
            ? Badge(
                isLabelVisible: true,
                label: Text('$pendingStaffCount'),
                backgroundColor: AppColors.brandPeachDark,
                child: Icon(spec.icon, size: 21),
              )
            : Icon(spec.icon, size: 21),
        activeIcon: showBadge
            ? Badge(
                isLabelVisible: true,
                label: Text('$pendingStaffCount'),
                backgroundColor: AppColors.brandPeachDark,
                child: Icon(spec.activeIcon, size: 21),
              )
            : Icon(spec.activeIcon, size: 21),
        label: spec.label,
        tooltip: 'More Modules & Tools',
      );
    }

    return BottomNavigationBarItem(
      icon: Badge(
        isLabelVisible: pendingStaffCount > 0,
        label: Text('$pendingStaffCount'),
        backgroundColor: AppColors.brandPeachDark,
        child: const Icon(Icons.grid_view_outlined, size: 21),
      ),
      activeIcon: Badge(
        isLabelVisible: pendingStaffCount > 0,
        label: Text('$pendingStaffCount'),
        backgroundColor: AppColors.brandPeachDark,
        child: const Icon(Icons.grid_view_rounded, size: 21),
      ),
      label: AppStrings.tabMore,
      tooltip: 'More Modules & Tools',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, _, _) {
        final primaryTabs = _primaryTabs;
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
            currentIndex: _bottomNavIndex(primaryTabs),
            onTap: (idx) => _onItemTapped(context, idx, primaryTabs),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.brandPeach,
            unselectedItemColor: isDark
                ? AppColors.textLightMuted
                : AppColors.textDarkMuted,
            selectedFontSize: 11.5,
            unselectedFontSize: 11.0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              for (final spec in primaryTabs)
                BottomNavigationBarItem(
                  icon: Icon(spec.icon, size: 21),
                  activeIcon: Icon(spec.activeIcon, size: 21),
                  label: spec.label,
                ),
              _buildMoreItem(primaryTabs),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
