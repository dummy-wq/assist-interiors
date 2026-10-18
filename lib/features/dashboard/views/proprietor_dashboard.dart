import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/project_status_chart.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../auth/state/auth_provider.dart';
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
    MobileActionSheets.expenseCreatedNotifier.addListener(_onExpenseCreated);
    MobileActionSheets.leadCreatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.leadUpdatedNotifier.addListener(_onLeadChanged);
    MobileActionSheets.taskCreatedNotifier.addListener(_onTaskCreated);
    MobileActionSheets.vendorCreatedNotifier.addListener(_onVendorCreated);
  }

  @override
  void dispose() {
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.projectUpdatedNotifier.removeListener(_onProjectUpdated);
    MobileActionSheets.invoiceCreatedNotifier.removeListener(_onInvoiceCreated);
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

    int totalInvoiced = 0;
    int totalReceivables = 0;
    for (final inv in _invoices) {
      final raw = (inv['amount'] as String? ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final amt = int.tryParse(raw) ?? 0;
      totalInvoiced += amt;
      if (inv['status'] != 'Settled') {
        totalReceivables += amt;
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
      final raw = (exp['amount'] as String? ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      totalDisbursed += int.tryParse(raw) ?? 0;
    }

    final netCash = totalInvoiced - totalDisbursed;
    final netCashStr = netCash != 0
        ? NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹ ',
            decimalDigits: 0,
          ).format(netCash)
        : '₹ 0';

    return ScreenScrollView(
      children: [
        // Header Banner
        Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Executive Studio Hub',
                style: AppTypography.displayMedium(isDark),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (AppPermissions.canExportFinancials(auth.currentRole))
                    OutlinedButton.icon(
                      onPressed: () {
                        PdfService.showProfitLoss(
                          context,
                          projects: _projects,
                          invoices: _invoices,
                          expenses: _expenses,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Export P&L Statement'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  if (isWide &&
                      AppPermissions.canCreateProject(auth.currentRole))
                    ElevatedButton.icon(
                      onPressed: () =>
                          MobileActionSheets.showInitiateProjectSheet(context),
                      icon: const Icon(Icons.apartment_rounded, size: 18),
                      label: const Text('Initiate Project'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Upper Area: Project Status Distribution Chart (Projects - Tab 2) + Compact Stat Tiles sitting to the side
          if (isWide) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ProjectStatusDistributionChart(
                    projects: _projects,
                    onTap: () => MainDashboardScreen.navigateToTab(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      CompactStatTile(
                        title: 'Ongoing Projects',
                        value: '${_projects.length} Active Sites',
                        icon: Icons.apartment_rounded,
                        accentColor: AppColors.brandPeach,
                        onTap: () => MainDashboardScreen.navigateToTab(2),
                      ),
                      const SizedBox(height: 8),
                      CompactStatTile(
                        title: 'Upcoming Handovers',
                        value: '${_projects.length} Scheduled',
                        icon: Icons.key_rounded,
                        accentColor: AppColors.brandPeach,
                        onTap: () => MainDashboardScreen.navigateToTab(2),
                      ),
                      const SizedBox(height: 8),
                      CompactStatTile(
                        title: 'Pending Receivables',
                        value: receivablesStr,
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: AppColors.brandPeach,
                        onTap: () => MainDashboardScreen.navigateToTab(5),
                      ),
                      const SizedBox(height: 8),
                      CompactStatTile(
                        title: 'Net Cash Flow',
                        value: netCashStr,
                        trend: netCash >= 0 ? '+Surplus' : '-Deficit',
                        icon: Icons.swap_vert_rounded,
                        accentColor: netCash >= 0
                            ? AppColors.success
                            : AppColors.error,
                        onTap: () => MainDashboardScreen.navigateToTab(5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2: Upcoming Handovers (Projects) & Cash Flow Snapshot (Accounts)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: UpcomingHandoversCard(
                    projects: _projects,
                    onTap: () => MainDashboardScreen.navigateToTab(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: CashFlowSnapshotCard(
                    projects: _projects,
                    invoices: _invoices,
                    expenses: _expenses,
                    onTap: () => MainDashboardScreen.navigateToTab(5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 3: Sales Pipeline (Sales - Tab 1) & Site Tasks (Tasks - Tab 4)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SalesSnapshotCard(
                    leads: _leads,
                    onTap: () => MainDashboardScreen.navigateToTab(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: TasksSnapshotCard(
                    tasks: _tasks,
                    onTap: () => MainDashboardScreen.navigateToTab(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row 4: Trade Partners (Vendors - Tab 3) & Staff Governance (Team - Tab 6)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: VendorsSnapshotCard(
                    vendors: _vendors,
                    onTap: () => MainDashboardScreen.navigateToTab(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 6,
                  child: TeamSnapshotCard(
                    approvedUsers: auth.approvedUsers,
                    pendingUsers: auth.pendingUsers,
                    onTap: () => MainDashboardScreen.navigateToTab(6),
                  ),
                ),
              ],
            ),
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
                          onTap: () => MainDashboardScreen.navigateToTab(5),
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
                          onTap: () => MainDashboardScreen.navigateToTab(5),
                        ),
                      ),
                    ),
                  ],
                ),
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

            // Accounts Screen Element: Cash Flow Snapshot
            CashFlowSnapshotCard(
              projects: _projects,
              invoices: _invoices,
              expenses: _expenses,
              onTap: () => MainDashboardScreen.navigateToTab(5),
            ),
            const SizedBox(height: 14),

            // Sales Screen Element: Sales & Pipeline Snapshot
            SalesSnapshotCard(
              leads: _leads,
              onTap: () => MainDashboardScreen.navigateToTab(1),
            ),
            const SizedBox(height: 14),

            // Tasks Screen Element: Site Tasks & Execution
            TasksSnapshotCard(
              tasks: _tasks,
              onTap: () => MainDashboardScreen.navigateToTab(4),
            ),
            const SizedBox(height: 14),

            // Vendors Screen Element: Trade Partners & Vendors
            VendorsSnapshotCard(
              vendors: _vendors,
              onTap: () => MainDashboardScreen.navigateToTab(3),
            ),
            const SizedBox(height: 14),

            // Team Screen Element: Studio Team & Governance
            TeamSnapshotCard(
              approvedUsers: auth.approvedUsers,
              pendingUsers: auth.pendingUsers,
              onTap: () => MainDashboardScreen.navigateToTab(6),
            ),
          ],
        ],
      );
  }
}
