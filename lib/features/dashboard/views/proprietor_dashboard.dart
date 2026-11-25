import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/project_status_chart.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/state/auth_provider.dart';
import '../../projects/sheets/take_site_photo_sheet.dart';
import '../widgets/mobile_action_sheets.dart';
import '../widgets/proprietor/compact_stat_tile.dart';
import '../widgets/proprietor/upcoming_handovers_card.dart';
import '../widgets/proprietor/cash_flow_snapshot_card.dart';
import '../widgets/proprietor/sales_snapshot_card.dart';
import '../widgets/proprietor/tasks_snapshot_card.dart';
import '../widgets/proprietor/vendors_snapshot_card.dart';
import '../widgets/proprietor/team_snapshot_card.dart';
import 'main_dashboard_screen.dart';

class ProprietorDashboard extends StatefulWidget {
  const ProprietorDashboard({super.key});

  @override
  State<ProprietorDashboard> createState() => _ProprietorDashboardState();
}

class _ProprietorDashboardState extends State<ProprietorDashboard> {
  final List<Map<String, dynamic>> _projects = [];
  final List<Map<String, dynamic>> _invoices = [];
  final List<Map<String, dynamic>> _expenses = [];
  final List<Map<String, dynamic>> _leads = [];
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _vendors = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();

    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    MobileActionSheets.projectUpdatedNotifier.addListener(_onProjectUpdated);
    MobileActionSheets.invoiceCreatedNotifier.addListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.addListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.addListener(_onExpenseCreated);
    MobileActionSheets.leadCreatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.taskCreatedNotifier.addListener(_onTaskCreated);
    MobileActionSheets.vendorCreatedNotifier.addListener(_onVendorCreated);
    MainDashboardScreen.activeTabNotifier.addListener(_onTabSwitched);
    StorageService.cloudSyncNotifier.addListener(_onCloudSync);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onCloudSync);
    MainDashboardScreen.activeTabNotifier.removeListener(_onTabSwitched);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.projectUpdatedNotifier.removeListener(_onProjectUpdated);
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceCreated);
    MobileActionSheets.invoiceUpdatedNotifier.removeListener(_onInvoiceUpdated);
    MobileActionSheets.expenseCreatedNotifier.removeListener(_onExpenseCreated);
    MobileActionSheets.leadCreatedNotifier.removeListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.removeListener(_onLeadChanged);
    MobileActionSheets.taskCreatedNotifier.removeListener(_onTaskCreated);
    MobileActionSheets.vendorCreatedNotifier.removeListener(_onVendorCreated);
    super.dispose();
  }

  void _loadAllData() {
    _projects.clear();
    _projects.addAll(StorageService.getProjects());
    _invoices.clear();
    _invoices.addAll(StorageService.getInvoices());
    _expenses.clear();
    _expenses.addAll(StorageService.getExpenses());
    _leads.clear();
    _leads.addAll(StorageService.getLeads());
    _tasks.clear();
    _tasks.addAll(StorageService.getTasks());
    _vendors.clear();
    _vendors.addAll(StorageService.getVendors());
  }

  void _onCloudSync() {
    if (mounted) {
      setState(_loadAllData);
    }
  }

  void _onTabSwitched() {
    if (mounted && MainDashboardScreen.activeTabNotifier.value == 0) {
      setState(_loadAllData);
    }
  }

  void _onInvoiceUpdated() {
    if (mounted) {
      setState(() {
        _invoices.clear();
        _invoices.addAll(StorageService.getInvoices());
      });
    }
  }

  void _onProjectCreated() {
    final p = MobileActionSheets.projectCreatedNotifier.value;
    if (p != null && mounted) {
      setState(() {
        if (!_projects.any((existing) => existing['name'] == p['name'])) {
          _projects.add(Map<String, dynamic>.from(p));
        }
      });
      StorageService.saveProjects(_projects);
    }
  }

  void _onProjectUpdated() {
    if (mounted) {
      setState(() {
        _projects.clear();
        _projects.addAll(StorageService.getProjects());
      });
    }
  }

  void _onInvoiceCreated() {
    final inv = MobileActionSheets.invoiceCreatedNotifier.value;
    if (inv != null && mounted) {
      setState(() {
        _invoices.insert(0, Map<String, dynamic>.from(inv));
      });
    }
  }

  void _onExpenseCreated() {
    final exp = MobileActionSheets.expenseCreatedNotifier.value;
    if (exp != null && mounted) {
      setState(() {
        _expenses.insert(0, Map<String, dynamic>.from(exp));
      });
    }
  }

  void _onLeadChanged() {
    if (mounted) {
      setState(() {
        _leads.clear();
        _leads.addAll(StorageService.getLeads());
      });
    }
  }

  void _onTaskCreated() {
    final t = MobileActionSheets.taskCreatedNotifier.value;
    if (t != null && mounted) {
      setState(() {
        _tasks.insert(0, Map<String, dynamic>.from(t));
      });
    }
  }

  void _onVendorCreated() {
    final v = MobileActionSheets.vendorCreatedNotifier.value;
    if (v != null && mounted) {
      setState(() {
        _vendors.insert(0, Map<String, dynamic>.from(v));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    final isFieldStaff =
        auth.currentRole == UserRole.supervisor ||
        auth.currentRole == UserRole.siteEngineer;

    int totalInvoiced = 0;
    int totalReceivables = 0;
    for (final inv in _invoices) {
      final amt = CurrencyUtils.parseAmount(inv['amount']);
      totalInvoiced += amt;
      if (inv['status'] != 'Settled') {
        totalReceivables += amt;
      }
    }
    final receivablesStr =
        totalReceivables > 0 ? CurrencyUtils.formatInr(totalReceivables) : '₹ 0';

    int totalDisbursed = 0;
    for (final exp in _expenses) {
      totalDisbursed += CurrencyUtils.parseAmount(exp['amount']);
    }

    final netCash = totalInvoiced - totalDisbursed;
    final netCashStr =
        netCash != 0 ? CurrencyUtils.formatInr(netCash) : '₹ 0';

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Executive Studio Hub',
          subtitle:
              'Live portfolio health, upcoming handovers, cash flow & studio operations',
        ),
        const SizedBox(height: ScreenLayout.headerGap),

          if (_buildPrimaryRoleHeroButton(context, auth, isDark) case final heroBtn?) ...[
            heroBtn,
            const SizedBox(height: 14),
          ],
          if (isFieldStaff) ...[
            _buildFieldQuickActions(isDark, isWide),
            const SizedBox(height: 14),
          ],

          // Upper Area: Project Status Distribution Chart (50%) + 2x2 Compact Stat Tiles Grid (50%)
          if (isWide) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: ProjectStatusDistributionChart(
                      projects: _projects,
                      onTap: () => MainDashboardScreen.navigateToTab(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CompactStatTile(
                                  title: 'Ongoing Projects',
                                  value: '${_projects.length} Active Sites',
                                  icon: Icons.apartment_rounded,
                                  accentColor: AppColors.brandPeach,
                                  onTap: () =>
                                      MainDashboardScreen.navigateToTab(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CompactStatTile(
                                  title: 'Upcoming Handovers',
                                  value: '${_projects.length} Scheduled',
                                  icon: Icons.key_rounded,
                                  accentColor: AppColors.brandPeach,
                                  onTap: () =>
                                      MainDashboardScreen.navigateToTab(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isFieldStaff) ...[
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: CompactStatTile(
                                    title: 'Pending Receivables',
                                    value: receivablesStr,
                                    icon: Icons.account_balance_wallet_rounded,
                                    accentColor: AppColors.brandPeach,
                                    onTap: () =>
                                        MainDashboardScreen.navigateToTab(6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CompactStatTile(
                                    title: 'Net Cash Flow',
                                    value: netCashStr,
                                    trend:
                                        netCash >= 0 ? '+Surplus' : '-Deficit',
                                    icon: Icons.swap_vert_rounded,
                                    accentColor: netCash >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    onTap: () =>
                                        MainDashboardScreen.navigateToTab(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Row 2: Upcoming Handovers (Projects) & Cash Flow Snapshot (Accounts)
            if (isFieldStaff) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: UpcomingHandoversCard(
                        projects: _projects,
                        onTap: () => MainDashboardScreen.navigateToTab(2),
                      ),
                    ),
                    const SizedBox(width: ScreenLayout.gridGap),
                    Expanded(
                      flex: 6,
                      child: TasksSnapshotCard(
                        tasks: _tasks,
                        onTap: () => MainDashboardScreen.navigateToTab(5),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: UpcomingHandoversCard(
                        projects: _projects,
                        onTap: () => MainDashboardScreen.navigateToTab(2),
                      ),
                    ),
                    const SizedBox(width: ScreenLayout.gridGap),
                    Expanded(
                      flex: 6,
                      child: CashFlowSnapshotCard(
                        projects: _projects,
                        invoices: _invoices,
                        expenses: _expenses,
                        onTap: () => MainDashboardScreen.navigateToTab(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ScreenLayout.gridGap),

              // Row 3: Sales Pipeline (Sales - Tab 1) & Site Variations (Amendments - Tab 5)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SalesSnapshotCard(
                        leads: _leads,
                        onTap: () => MainDashboardScreen.navigateToTab(1),
                      ),
                    ),
                    const SizedBox(width: ScreenLayout.gridGap),
                    Expanded(
                      flex: 6,
                      child: TasksSnapshotCard(
                        tasks: _tasks,
                        onTap: () => MainDashboardScreen.navigateToTab(5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ScreenLayout.gridGap),

              // Row 4: Materials & Indents (Tab 4) & Staff Governance (Team - Tab 7)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: VendorsSnapshotCard(
                        vendors: _vendors,
                        onTap: () => MainDashboardScreen.navigateToTab(4),
                      ),
                    ),
                    const SizedBox(width: ScreenLayout.gridGap),
                    Expanded(
                      flex: 6,
                      child: TeamSnapshotCard(
                        approvedUsers: auth.approvedUsers,
                        pendingUsers: auth.pendingUsers,
                        onTap: () => MainDashboardScreen.navigateToTab(7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Compact / Mobile Layout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppSizes.statCardHeightMobile,
                        child: CompactStatTile(
                          title: 'Ongoing Projects',
                          value: '${_projects.length} Active Sites',
                          icon: Icons.apartment_rounded,
                          accentColor: AppColors.brandPeach,
                          onTap: () => MainDashboardScreen.navigateToTab(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: AppSizes.statCardHeightMobile,
                        child: CompactStatTile(
                          title: 'Upcoming Handovers',
                          value: '${_projects.length} Scheduled',
                          icon: Icons.key_rounded,
                          accentColor: AppColors.brandPeach,
                          onTap: () => MainDashboardScreen.navigateToTab(2),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isFieldStaff) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.statCardHeightMobile,
                          child: CompactStatTile(
                            title: 'Pending Receivables',
                            value: receivablesStr,
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: AppColors.brandPeach,
                            onTap: () => MainDashboardScreen.navigateToTab(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.statCardHeightMobile,
                          child: CompactStatTile(
                            title: 'Net Cash Flow',
                            value: netCashStr,
                            trend: netCash >= 0 ? '+Surplus' : '-Deficit',
                            icon: Icons.swap_vert_rounded,
                            accentColor: netCash >= 0
                                ? AppColors.success
                                : AppColors.error,
                            onTap: () => MainDashboardScreen.navigateToTab(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Projects Screen Element 1: Status Distribution
            ProjectStatusDistributionChart(
              projects: _projects,
              onTap: () => MainDashboardScreen.navigateToTab(2),
            ),
            const SizedBox(height: 14),

            // Projects Screen Element 2: Upcoming Handovers
            UpcomingHandoversCard(
              projects: _projects,
              onTap: () => MainDashboardScreen.navigateToTab(2),
            ),
            const SizedBox(height: 14),

            if (!isFieldStaff) ...[
              // Accounts Screen Element: Cash Flow Snapshot
              CashFlowSnapshotCard(
                projects: _projects,
                invoices: _invoices,
                expenses: _expenses,
                onTap: () => MainDashboardScreen.navigateToTab(6),
              ),
              const SizedBox(height: 14),

              // Sales Screen Element: Sales & Pipeline Snapshot
              SalesSnapshotCard(
                leads: _leads,
                onTap: () => MainDashboardScreen.navigateToTab(1),
              ),
              const SizedBox(height: 14),
            ],

            // Amendments Screen Element
            TasksSnapshotCard(
              tasks: _tasks,
              onTap: () => MainDashboardScreen.navigateToTab(5),
            ),
            if (!isFieldStaff) ...[
              const SizedBox(height: 14),

              // Materials Screen Element
              VendorsSnapshotCard(
                vendors: _vendors,
                onTap: () => MainDashboardScreen.navigateToTab(4),
              ),
              const SizedBox(height: 14),

              // Team Screen Element: Studio Team & Governance
              TeamSnapshotCard(
                approvedUsers: auth.approvedUsers,
                pendingUsers: auth.pendingUsers,
                onTap: () => MainDashboardScreen.navigateToTab(7),
              ),
            ],
          ],
        ],
      );
  }

  Widget? _buildPrimaryRoleHeroButton(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
  ) {
    final role = auth.currentRole;
    final IconData icon;
    final String title;
    final String subtitle;
    final VoidCallback onPressed;

    switch (role) {
      case UserRole.supervisor:
      case UserRole.siteEngineer:
        icon = Icons.add_a_photo_rounded;
        title = AppStrings.tr('Take Site Photo');
        subtitle = 'Capture & upload today\'s site progress photo';
        onPressed = () => TakeSitePhotoSheet.openQuickCapture(context);
        break;
      case UserRole.designer:
        icon = Icons.cloud_upload_rounded;
        title = AppStrings.tr('Upload Drawing');
        subtitle = 'Share 2D plans, 3D renders & PDFs';
        onPressed = () => MobileActionSheets.showUploadRenderSheet(context);
        break;
      case UserRole.accounts:
        icon = Icons.receipt_long_rounded;
        title = AppStrings.tr('New Invoice');
        subtitle = 'Create & send a client milestone bill';
        onPressed = () => MobileActionSheets.showCreateInvoiceSheet(context);
        break;
      case UserRole.sales:
        icon = Icons.person_add_alt_1_rounded;
        title = AppStrings.tr('Add New Lead');
        subtitle = 'Record a new client inquiry & call reminder';
        onPressed = () => MobileActionSheets.showAddLeadSheet(context);
        break;
      case UserRole.projectManager:
        icon = Icons.add_circle_outline_rounded;
        title = AppStrings.tr('Add Project');
        subtitle = 'Start a new interior site & milestone checklist';
        onPressed = () => MobileActionSheets.showCreateProjectSheet(context);
        break;
      case UserRole.proprietor:
        return null;
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.brandPeach,
        borderRadius: BorderRadius.circular(10.0),
        elevation: 0,
        child: InkWell(
          key: const Key('role_primary_hero_action_btn'),
          borderRadius: BorderRadius.circular(10.0),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, size: 26, color: Colors.black),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldQuickActions(bool isDark, bool isWide) {
    final actions = [
      (
        icon: Icons.add_a_photo_rounded,
        title: 'Sites & Photos',
        subtitle: 'Open active sites & take photos',
        tab: 2,
      ),
      (
        icon: Icons.inventory_2_rounded,
        title: 'Request Materials',
        subtitle: 'Order supplies for your site',
        tab: 4,
      ),
      (
        icon: Icons.published_with_changes_rounded,
        title: 'Report Site Issue',
        subtitle: 'Log changes or client requests',
        tab: 5,
      ),
      (
        icon: Icons.draw_rounded,
        title: 'Design Drawings',
        subtitle: 'View 2D/3D plans & layouts',
        tab: 3,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.brandPeach.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: AppColors.brandPeach,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr('Quick Actions — Tap What You Need'),
                  style: AppTypography.titleMedium(isDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isWide)
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldActionTile(
                      isDark: isDark,
                      icon: actions[i].icon,
                      title: actions[i].title,
                      subtitle: actions[i].subtitle,
                      onTap: () =>
                          MainDashboardScreen.navigateToTab(actions[i].tab),
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFieldActionTile(
                        isDark: isDark,
                        icon: actions[0].icon,
                        title: actions[0].title,
                        subtitle: actions[0].subtitle,
                        onTap: () =>
                            MainDashboardScreen.navigateToTab(actions[0].tab),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldActionTile(
                        isDark: isDark,
                        icon: actions[1].icon,
                        title: actions[1].title,
                        subtitle: actions[1].subtitle,
                        onTap: () =>
                            MainDashboardScreen.navigateToTab(actions[1].tab),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFieldActionTile(
                        isDark: isDark,
                        icon: actions[2].icon,
                        title: actions[2].title,
                        subtitle: actions[2].subtitle,
                        onTap: () =>
                            MainDashboardScreen.navigateToTab(actions[2].tab),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldActionTile(
                        isDark: isDark,
                        icon: actions[3].icon,
                        title: actions[3].title,
                        subtitle: actions[3].subtitle,
                        onTap: () =>
                            MainDashboardScreen.navigateToTab(actions[3].tab),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFieldActionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkCardElevated : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: AppColors.brandPeach),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.tr(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium(isDark).copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
