import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../auth/state/auth_provider.dart';
import '../../projects/views/projects_view.dart';
import '../../vendors/views/vendors_view.dart';
import '../../tasks/views/tasks_view.dart';
import '../../team/views/team_view.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/pdf_service.dart';
import '../widgets/mobile_action_sheets.dart';
import '../widgets/role_bottom_bar.dart';
import 'accounts_dashboard.dart';
import 'proprietor_dashboard.dart';
import '../../sales/views/sales_view.dart';


// ---------------------------------------------------------------------------
// Animated IndexedStack — all children stay alive, active child fades+slides in
// ---------------------------------------------------------------------------
class _AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedIndexedStack({required this.index, required this.children});

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _currentIndex = widget.index;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: widget.children.asMap().entries.map((entry) {
        final isActive = entry.key == _currentIndex;
        return Offstage(
          offstage: !isActive,
          child: isActive
              ? FadeTransition(
                  opacity: _opacity,
                  child: SlideTransition(
                    position: _slide,
                    child: entry.value,
                  ),
                )
              : entry.value,
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Dashboard Screen
// ---------------------------------------------------------------------------
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  static void navigateToTab(int index) {
    activeTabNotifier.value = index;
  }

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = MainDashboardScreen.activeTabNotifier.value;
    MainDashboardScreen.activeTabNotifier.addListener(_onActiveTabChanged);
  }

  @override
  void dispose() {
    MainDashboardScreen.activeTabNotifier.removeListener(_onActiveTabChanged);
    MainDashboardScreen.activeTabNotifier.value = 0;
    super.dispose();
  }

  void _onActiveTabChanged() {
    if (mounted &&
        _selectedTabIndex != MainDashboardScreen.activeTabNotifier.value) {
      setState(() {
        _selectedTabIndex = MainDashboardScreen.activeTabNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return PopScope(
      canPop: _selectedTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedTabIndex != 0) {
          MainDashboardScreen.navigateToTab(0);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppConstants.logoPath,
                height: 28,
                errorBuilder: (context, error, stackTrace) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.brandPeach,
                        borderRadius: BorderRadius.all(Radius.circular(6.0)),
                      ),
                      child: const Text(
                        'ASSIST',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'INTERIORS',
                        style: TextStyle(fontSize: 14, letterSpacing: 2),
                      ),
                    ],
                  ],
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 24),
                Container(
                  height: 20,
                  width: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(width: 20),
                Text(
                  'ENTERPRISE SUITE',
                  style: AppTypography.bodySmall(isDark).copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPeach,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Language Selector Button
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language (${auth.language.shortCode})',
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
              side: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.8),
                width: 0.8,
              ),
            ),
            position: PopupMenuPosition.under,
            onSelected: (AppLanguage selected) {
              auth.setLanguage(selected);
              AppNotification.show(
                context,
                message: 'Language set to ${selected.nativeName}',
              );
            },
            itemBuilder: (context) {
              return AppLanguage.values.map((lang) {
                final isSelected = auth.language == lang;
                return PopupMenuItem<AppLanguage>(
                  value: lang,
                  height: 38,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPeach.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          lang.shortCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.brandPeach : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? AppColors.brandPeach : null,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.brandPeach,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InstantPressFeedback(
                child: Material(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
                  child: Container(
                    width: AppSizes.topActionButtonSize,
                    height: AppSizes.topActionButtonSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.topActionRadius,
                      ),
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      auth.language.shortCode,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPeach,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Standardized compact Theme Toggle button
          _buildTopIconButton(
            icon: auth.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: 'Toggle Theme',
            isDark: isDark,
            onPressed: () => auth.toggleTheme(),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildRoleSwitcher(context, auth, isDark, isWide),
          ),
          // Standardized compact Sign Out button
          _buildTopIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign Out',
            isDark: isDark,
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 10),
        ],
        bottom: isWide
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    border: Border(
                      top: BorderSide(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                      bottom: BorderSide(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildWideNavTab(
                        0,
                        AppStrings.tabHub,
                        Icons.hub_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        1,
                        AppStrings.tabSales,
                        Icons.campaign_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        2,
                        AppStrings.tabProjects,
                        Icons.apartment_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        3,
                        AppStrings.tabVendors,
                        Icons.storefront_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        4,
                        AppStrings.tabTasks,
                        Icons.task_alt_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        5,
                        AppStrings.tabAccounts,
                        Icons.account_balance_wallet_rounded,
                        isDark,
                      ),
                      _buildWideNavTab(
                        6,
                        AppStrings.tabTeam,
                        Icons.badge_rounded,
                        isDark,
                        badgeCount: auth.currentRole == UserRole.proprietor
                            ? auth.pendingUsers.length
                            : 0,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          if (_selectedTabIndex != 0)
            _buildScreenActionSection(context, auth, isDark, isWide),
          Expanded(
            child: _AnimatedIndexedStack(
              index: _selectedTabIndex,
              children: [
                const ProprietorDashboard(),
                const SalesView(),
                const ProjectsView(),
                const VendorsView(),
                const TasksView(),
                const AccountsDashboard(),
                const TeamView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWide
          ? RoleBottomBar(
              role: auth.currentRole,
              selectedIndex: _selectedTabIndex,
              pendingStaffCount: auth.currentRole == UserRole.proprietor
                  ? auth.pendingUsers.length
                  : 0,
              onTabSelected: (idx) {
                HapticFeedback.selectionClick();
                MainDashboardScreen.navigateToTab(idx);
              },
            )
          : null,
      ),
    );
  }

  Widget _buildWideNavTab(
    int index,
    String label,
    IconData icon,
    bool isDark, {
    int badgeCount = 0,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        MainDashboardScreen.navigateToTab(index);
      },
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPeach.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: isSelected
              ? Border.all(
                  color: AppColors.brandPeach.withValues(alpha: 0.5),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.brandPeach
                  : (isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.brandPeach
                    : (isDark
                          ? AppColors.textLightSecondary
                          : AppColors.textDarkSecondary),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.brandPeachDark,
                  borderRadius: BorderRadius.all(Radius.circular(6.0)),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  DateTime _lastActionTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  Widget _buildTopIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
    Color? iconColor,
    Duration cooldown = const Duration(milliseconds: 500),
  }) {
    final effectiveIconColor =
        iconColor ??
        (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
          child: InkWell(
            onTap: () {
              final now = DateTime.now();
              if (now.difference(_lastActionTapTime) < cooldown) {
                return; // Throttled: prevents spam taps from stacking actions
              }
              _lastActionTapTime = now;
              onPressed();
            },
            borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
            child: Container(
              width: AppSizes.topActionButtonSize,
              height: AppSizes.topActionButtonSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
                border: Border.all(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.82,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  icon,
                  key: ValueKey<IconData>(icon),
                  size: AppSizes.topActionIconSize,
                  color: effectiveIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    bool isWide,
  ) {
    return PopupMenuButton<UserRole>(
      tooltip: 'Switch Demo Role',
      initialValue: auth.currentRole,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
      onSelected: (newRole) {
        auth.switchRole(newRole);
        AppNotification.show(
          context,
          message: 'Active demo role switched to ${newRole.title}',
        );
      },
      itemBuilder: (context) => UserRole.values.map((role) {
        final isSelected = role == auth.currentRole;
        return PopupMenuItem<UserRole>(
          value: role,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Icon(role.icon, color: role.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? role.color : null,
                      ),
                    ),
                    Text(
                      AppPermissions.getRoleAccessSummary(role),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: role.color, size: 16),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCardElevated : AppColors.lightCard)
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: auth.currentRole.color.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: auth.currentRole.color.withValues(alpha: 0.2),
              child: Icon(
                auth.currentRole.icon,
                color: auth.currentRole.color,
                size: 14,
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auth.userName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    auth.currentRole.shortCode,
                    style: TextStyle(
                      fontSize: 9,
                      color: auth.currentRole.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: auth.currentRole.color,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Section Below Top Bar (Dedicated per screen, excluded on Hub)
  // ---------------------------------------------------------------------------
  Widget _buildScreenActionSection(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    bool isWide,
  ) {
    final buttons = _getScreenActionButtons(context, auth, isDark);
    if (buttons.isEmpty) return const SizedBox.shrink();

    final screenTitle = _getScreenTitle(_selectedTabIndex);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                .withValues(alpha: 0.7),
            width: 0.8,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: 8,
      ),
      child: isWide
          ? Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3.5,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      screenTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark
                            ? AppColors.textLightSecondary
                            : AppColors.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < buttons.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            buttons[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    buttons[i],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return InstantPressFeedback(
      child: ElevatedButton.icon(
        key: key,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPeach,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.black),
        label: Text(label),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
    Color? accentColor,
    Key? key,
  }) {
    final effectiveColor =
        accentColor ?? (isDark ? AppColors.brandPeach : AppColors.brandPeachDark);
    return InstantPressFeedback(
      child: OutlinedButton.icon(
        key: key,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          elevation: 0,
          side: BorderSide(
            color: effectiveColor.withValues(alpha: 0.8),
            width: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: effectiveColor),
        label: Text(label),
      ),
    );
  }

  List<Widget> _getScreenActionButtons(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
  ) {
    final role = auth.currentRole;
    switch (_selectedTabIndex) {
      case 1:
        // SALES & PIPELINE
        final canManageSales = AppPermissions.canManageSales(role);
        return [
          if (canManageSales)
            _buildPrimaryActionButton(
              key: const Key('action_bar_add_lead'),
              icon: Icons.person_add_alt_1_rounded,
              label: 'Add Lead',
              onPressed: () => MobileActionSheets.showAddLeadSheet(context),
            ),
          _buildSecondaryActionButton(
            key: const Key('action_bar_schedule_call'),
            icon: Icons.phone_callback_rounded,
            label: 'Schedule Call',
            isDark: isDark,
            onPressed: () {
              final leads = StorageService.getLeads();
              if (leads.isNotEmpty) {
                MobileActionSheets.showScheduleCallSheet(context, leads.first);
              } else {
                AppNotification.show(
                  context,
                  message: 'No active leads found to schedule calls.',
                );
              }
            },
          ),
        ];

      case 2:
        // PROJECTS PORTFOLIO
        final canCreateProject = AppPermissions.canCreateProject(role);
        return [
          if (canCreateProject)
            _buildPrimaryActionButton(
              key: const Key('action_bar_add_project'),
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Project',
              onPressed: () =>
                  MobileActionSheets.showCreateProjectSheet(context),
            ),
          _buildSecondaryActionButton(
            key: const Key('action_bar_filter_projects'),
            icon: Icons.filter_list_rounded,
            label: 'Filter Projects',
            isDark: isDark,
            onPressed: () =>
                MobileActionSheets.showProjectFilterSheet(context),
          ),
        ];

      case 3:
        // VENDORS & TRADES
        final canManageVendors = AppPermissions.canManageVendors(role);
        return [
          if (canManageVendors)
            _buildPrimaryActionButton(
              key: const Key('action_bar_add_vendor'),
              icon: Icons.add_business_rounded,
              label: 'Add Vendor',
              onPressed: () => MobileActionSheets.showAddVendorSheet(context),
            ),
          _buildSecondaryActionButton(
            key: const Key('action_bar_track_pos'),
            icon: Icons.local_shipping_outlined,
            label: 'Track POs',
            isDark: isDark,
            onPressed: () {
              AppNotification.show(
                context,
                message:
                    '10 Active Purchase Orders currently in transit across 5 vendors.',
              );
            },
          ),
        ];

      case 4:
        // TASKS & EXECUTION
        final canCreateTask = AppPermissions.canCreateTask(role);
        return [
          if (canCreateTask)
            _buildPrimaryActionButton(
              key: const Key('action_bar_add_task'),
              icon: Icons.add_task_rounded,
              label: 'Add Task',
              onPressed: () =>
                  MobileActionSheets.showCreateTaskSheet(context),
            ),
          _buildSecondaryActionButton(
            key: const Key('action_bar_urgent_only'),
            icon: Icons.flag_rounded,
            label: 'Urgent Only',
            isDark: isDark,
            onPressed: () {
              AppNotification.show(
                context,
                message:
                    'Showing Urgent & High priority milestones due within 48 hours.',
              );
            },
          ),
        ];

      case 5:
        // ACCOUNTS & BILLING
        final canManageAccounts = AppPermissions.canManageAccounts(role);
        final canExportFinancials = AppPermissions.canExportFinancials(role);

        if (!canManageAccounts && !canExportFinancials) {
          return [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.brandPeach,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Financial ledger read-only for ${role.title}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ];
        }

        return [
          if (canManageAccounts)
            _buildPrimaryActionButton(
              key: const Key('action_bar_add_invoice'),
              icon: Icons.receipt_long_rounded,
              label: 'Add Invoice',
              onPressed: () =>
                  MobileActionSheets.showCreateInvoiceSheet(context),
            ),
          if (canManageAccounts || canExportFinancials)
            _buildSecondaryActionButton(
              key: const Key('action_bar_print_invoice'),
              icon: Icons.print_rounded,
              label: 'Print Invoice',
              isDark: isDark,
              onPressed: () => _onPrintInvoicePressed(context),
            ),
          if (canExportFinancials)
            _buildSecondaryActionButton(
              key: const Key('action_bar_pnl_report'),
              icon: Icons.picture_as_pdf_outlined,
              label: 'P&L Report',
              isDark: isDark,
              onPressed: () => PdfService.showProfitLoss(context),
            ),
          if (canManageAccounts)
            _buildSecondaryActionButton(
              key: const Key('action_bar_record_expense'),
              icon: Icons.receipt_outlined,
              label: 'Record Expense',
              isDark: isDark,
              onPressed: () =>
                  MobileActionSheets.showAddExpenseSheet(context),
            ),
        ];

      case 6:
        // TEAM & WORKFORCE
        final canManageTeam = AppPermissions.canManageTeam(role);
        return [
          if (canManageTeam)
            _buildPrimaryActionButton(
              key: const Key('action_bar_invite_staff'),
              icon: Icons.person_add_rounded,
              label: 'Invite Staff',
              onPressed: () =>
                  MobileActionSheets.showInviteStaffSheet(context),
            ),
          _buildSecondaryActionButton(
            key: const Key('action_bar_labour_roll'),
            icon: Icons.groups_rounded,
            label: 'Labour Roll',
            isDark: isDark,
            onPressed: () =>
                MobileActionSheets.showLabourAttendanceSheet(context),
          ),
        ];

      default:
        return [];
    }
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 1:
        return 'Sales & Client Acquisition';
      case 2:
        return 'Projects Portfolio';
      case 3:
        return 'Vendors & Procurement';
      case 4:
        return 'Tasks & Site Milestones';
      case 5:
        return 'Accounts, Billing & Financials';
      case 6:
        return 'Team & Personnel Governance';
      default:
        return '';
    }
  }

  void _onPrintInvoicePressed(BuildContext context) {
    final invoices = StorageService.getInvoices();
    if (invoices.isEmpty) {
      AppNotification.show(
        context,
        message: 'No invoice records available to print.',
      );
      return;
    }
    if (invoices.length == 1) {
      final inv = invoices.first;
      PdfService.showPdfViewer(
        context,
        title: 'Tax Invoice ${inv['id'] ?? inv['invoiceNumber'] ?? ''}',
        documentBuilder: () => PdfService.generateInvoicePdf(inv),
      );
      return;
    }
    _showInvoicePrintPickerSheet(context, invoices);
  }

  void _showInvoicePrintPickerSheet(
    BuildContext context,
    List<Map<String, dynamic>> invoices,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.8),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.65,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.print_rounded,
                    color: AppColors.brandPeach,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Invoice to Print',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                        .withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final invId =
                        inv['id'] ?? inv['invoiceNumber'] ?? 'INV-$index';
                    final client = inv['client'] ?? 'Client';
                    final amount = inv['amount'] ?? '₹ 0';
                    final date = inv['date'] ?? '';
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.brandPeach,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '$invId • $client',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$date • $amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPeach,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            PdfService.showPdfViewer(
                              context,
                              title: 'Tax Invoice $invId',
                              documentBuilder: () =>
                                  PdfService.generateInvoicePdf(inv),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text(
                            'Print',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          PdfService.showPdfViewer(
                            context,
                            title: 'Tax Invoice $invId',
                            documentBuilder: () =>
                                PdfService.generateInvoicePdf(inv),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

