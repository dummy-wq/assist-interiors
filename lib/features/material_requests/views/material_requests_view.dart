import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class MaterialRequestsView extends StatefulWidget {
  const MaterialRequestsView({super.key});

  static final ValueNotifier<int> openCreateModalTrigger =
      ValueNotifier<int>(0);

  @override
  State<MaterialRequestsView> createState() => _MaterialRequestsViewState();
}

class _MaterialRequestsViewState extends State<MaterialRequestsView> {
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _requests = [];

  final List<String> _filterChips = [
    'All',
    'Pending Approval',
    'Approved',
    'Dispatched',
    'Delivered',
    'Urgent',
  ];

  final List<String> _tradeCategories = [
    'All',
    'Carpentry & Joinery',
    'Hardware & Fittings',
    'Italian Marble & Tiles',
    'Electrical & Automation',
    'Paint & Polish',
    'Civil & Masonry',
    'Plumbing & Sanitary',
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    MaterialRequestsView.openCreateModalTrigger.addListener(
      _onOpenCreateModalTriggered,
    );
    StorageService.cloudSyncNotifier.addListener(_onProjectCreated);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MaterialRequestsView.openCreateModalTrigger.removeListener(
      _onOpenCreateModalTriggered,
    );
    _searchController.dispose();
    super.dispose();
  }

  void _onOpenCreateModalTriggered() {
    if (mounted) {
      _showCreateRequestModal(context);
    }
  }

  void _onProjectCreated() {
    if (mounted) {
      _loadRequests();
    }
  }

  String? _previousStatus(String status) {
    switch (status) {
      case 'Approved':
        return 'Pending Approval';
      case 'Dispatched':
        return 'Approved';
      case 'Delivered':
        return 'Dispatched';
      default:
        return null;
    }
  }

  void _stepRequestBack(Map<String, dynamic> req) {
    final current = (req['status'] ?? 'Pending Approval').toString();
    final prev = _previousStatus(current);
    if (prev == null) return;
    final id = (req['id'] ?? 'IND').toString();
    setState(() => req['status'] = prev);
    _saveRequests();
    AppNotification.show(
      context,
      message: 'Material request $id moved back to $prev.',
    );
  }

  Widget _buildStepBackButton(
    Map<String, dynamic> req,
    bool isDark, {
    VoidCallback? onBeforeStepBack,
  }) {
    final prev = _previousStatus((req['status'] ?? '').toString());
    if (prev == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      style: AppSizes.compactOutlinedStyle(
        foregroundColor: isDark
            ? AppColors.textLightSecondary
            : AppColors.textDarkSecondary,
        borderColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
            .withValues(alpha: 0.8),
      ),
      onPressed: () {
        onBeforeStepBack?.call();
        _stepRequestBack(req);
      },
      icon: const Icon(Icons.undo_rounded, size: 14),
      label: const Text(
        'Step Back',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppSizes.compactButtonFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _loadRequests() {
    final list = StorageService.getMaterialRequests();
    setState(() {
      _requests.clear();
      _requests.addAll(list);
    });
  }

  void _saveRequests() {
    StorageService.saveMaterialRequests(_requests);
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('delivered')) return AppColors.success;
    if (lower.contains('dispatched')) return const Color(0xFF9B51E0);
    if (lower.contains('approved')) return AppColors.info;
    if (lower.contains('pending')) return AppColors.warning;
    return AppColors.textDarkMuted;
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('carpentry') || lower.contains('ply')) {
      return Icons.carpenter_rounded;
    }
    if (lower.contains('hardware') || lower.contains('fittings')) {
      return Icons.build_rounded;
    }
    if (lower.contains('marble') || lower.contains('tile') || lower.contains('stone')) {
      return Icons.dashboard_customize_rounded;
    }
    if (lower.contains('electric') || lower.contains('lighting')) {
      return Icons.electric_bolt_rounded;
    }
    if (lower.contains('paint') || lower.contains('polish')) {
      return Icons.format_paint_rounded;
    }
    if (lower.contains('plumb') || lower.contains('sanitary')) {
      return Icons.water_drop_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalPending = 0;
    int totalDispatched = 0;
    int totalCostInt = 0;

    for (final r in _requests) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      if (status.contains('pending')) totalPending++;
      if (status.contains('dispatched')) totalDispatched++;

      totalCostInt += CurrencyUtils.parseAmount(r['estimatedCost'] ?? r['cost']);
    }

    final totalCostStr =
        totalCostInt > 0 ? CurrencyUtils.formatInr(totalCostInt) : '₹ 0';

    final filteredRequests = _requests.where((r) {
      final status = (r['status'] ?? '').toString();
      final urgency = (r['urgency'] ?? '').toString();
      final category = (r['category'] ?? '').toString();

      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Urgent') {
          if (!urgency.toLowerCase().contains('urgent')) return false;
        } else if (!status.toLowerCase().contains(_selectedFilter.toLowerCase())) {
          return false;
        }
      }

      if (_selectedCategory != 'All' && category != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final item = (r['itemName'] ?? r['title'] ?? '').toString().toLowerCase();
        final proj = (r['project'] ?? '').toString().toLowerCase();
        final supplier = (r['assignedSupplier'] ?? r['supplier'] ?? '')
            .toString()
            .toLowerCase();
        final supervisor = (r['requestedBy'] ?? '').toString().toLowerCase();
        final id = (r['id'] ?? '').toString().toLowerCase();
        final notes = (r['notes'] ?? '').toString().toLowerCase();

        if (!item.contains(_searchQuery) &&
            !proj.contains(_searchQuery) &&
            !supplier.contains(_searchQuery) &&
            !supervisor.contains(_searchQuery) &&
            !id.contains(_searchQuery) &&
            !notes.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    return ScreenScrollView(
      children: [
        const ScreenHeader(
          'Material Requests & Indents',
          subtitle:
              'Trade procurement, site supervisor requests, dispatch tracking & delivery sign-offs',
        ),
        const SizedBox(height: ScreenLayout.headerGap),

        // Stat Strip
        StatStrip(
          cards: [
            StatCard(
              title: 'Total Indents',
              value: '${_requests.length} Requests',
              icon: Icons.inventory_2_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: 'Pending Sign-Off',
              value: '$totalPending Pending',
              icon: Icons.pending_actions_rounded,
              accentColor: AppColors.warning,
            ),
            StatCard(
              title: 'Dispatched / In Transit',
              value: '$totalDispatched En Route',
              icon: Icons.local_shipping_rounded,
              accentColor: const Color(0xFF9B51E0),
            ),
            StatCard(
              title: 'Total Indent Value',
              value: totalCostStr,
              icon: Icons.currency_rupee_rounded,
              accentColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: ScreenLayout.sectionGap),

        // Search Bar
        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search material item, project, supplier or ID...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final filter in _filterChips)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PillBox(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    activeColor: filter == 'Urgent'
                        ? AppColors.error
                        : AppColors.brandPeach,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter =
                            _selectedFilter == filter && filter != 'All'
                                ? 'All'
                                : filter;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Trade Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final cat in _tradeCategories)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PillBox(
                    label: cat == 'All' ? 'All Trades' : cat,
                    icon: _getCategoryIcon(cat),
                    isSelected: _selectedCategory == cat,
                    activeColor: AppColors.brandPeach,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Material Requests List — smooth cross-fade on filter change
        FilterSwitcher(
          child: filteredRequests.isEmpty
              ? EmptyStateCard(
                  key: ValueKey(
                    'empty_mat_${_selectedFilter}_$_selectedCategory',
                  ),
                  icon: Icons.inventory_2_outlined,
                  title: 'No Material Requests Found',
                  message: _searchQuery.isNotEmpty || _selectedFilter != 'All'
                      ? 'No material indents match your filter criteria.'
                      : 'Create a new material indent for site supervisors or trade contractors.',
                  action: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _selectedCategory = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Clear Filters & View All',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  key: ValueKey(
                    'mat_${_selectedFilter}_${_selectedCategory}_${filteredRequests.length}',
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRequests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
                    return _buildRequestCard(context, req, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> req,
    bool isDark,
  ) {
    final id = (req['id'] ?? 'MR-001').toString();
    final itemName = (req['itemName'] ?? req['title'] ?? 'Material Item').toString();
    final project = (req['project'] ?? 'General Site').toString();
    final category = (req['category'] ?? 'Carpentry & Joinery').toString();
    final quantity = (req['quantity'] ?? '1 Unit').toString();
    final urgency = (req['urgency'] ?? 'Standard').toString();
    final status = (req['status'] ?? 'Pending Approval').toString();
    final supplier = (req['assignedSupplier'] ?? req['supplier'] ?? 'Trade Depot').toString();
    final cost = (req['estimatedCost'] ?? req['cost'] ?? '₹ 0').toString();
    final requestedBy = (req['requestedBy'] ?? 'Site Supervisor').toString();
    final requiredDate = (req['requiredDate'] ?? 'In 3 Days').toString();
    final notes = (req['notes'] ?? '').toString();

    final isUrgent = urgency.toLowerCase().contains('urgent');
    final statusColor = _getStatusColor(status);
    final catIcon = _getCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _showRequestExpandedBox(context, req, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isUrgent
                  ? AppColors.error.withValues(alpha: 0.6)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      .withValues(alpha: 0.7),
              width: isUrgent ? 1.2 : 0.8,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: ID + Urgency Banner + Status Badge
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkCardElevated
                                : AppColors.lightBackground)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        id,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 0.7,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 10,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'URGENT SITE STOPPAGE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Item Title & Quantity Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Icon(catIcon, color: AppColors.brandPeach, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 13,
                          color: AppColors.brandPeach,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            project,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLightSecondary
                                  : AppColors.textDarkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Quantity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: AppColors.brandPeach.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      quantity,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPeach,
                      ),
                    ),
                    Text(
                      cost,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata Chips (Trade, Supplier, Supervisor, Due Date)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusTagPill(label: category),
              StatusTagPill(
                label: 'Supplier: $supplier',
                accentColor: AppColors.brandPeach,
              ),
              StatusTagPill(label: 'By: $requestedBy'),
              StatusTagPill(
                label: 'Due: $requiredDate',
                accentColor: isUrgent ? AppColors.error : null,
              ),
            ],
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground)
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textLightMuted
                      : AppColors.textDarkMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // State Progressor Row
          Row(
            children: [
              if (status == 'Pending Approval') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: AppSizes.compactOutlinedStyle(
                      foregroundColor: AppColors.error,
                      borderColor: AppColors.error.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() => _requests.remove(req));
                      _saveRequests();
                      BackendManager.instance.deleteDocument(
                        'material_requests',
                        id,
                      );
                      AppNotification.show(
                        context,
                        message: 'Request $id cancelled.',
                      );
                    },
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Reject',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: AppSizes.compactButtonFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppSizes.compactElevatedStyle(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      setState(() => req['status'] = 'Approved');
                      _saveRequests();
                      AppNotification.show(
                        context,
                        message: 'Indent $id approved for procurement.',
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                    ),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Approve Indent',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: AppSizes.compactButtonFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'Approved') ...[
                _buildStepBackButton(req, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppSizes.compactElevatedStyle(
                      backgroundColor: const Color(0xFF9B51E0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => req['status'] = 'Dispatched');
                      _saveRequests();
                      AppNotification.show(
                        context,
                        message: 'Materials for $id marked as Dispatched & In Transit.',
                      );
                    },
                    icon: const Icon(Icons.local_shipping_rounded, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mark Dispatched & In Transit',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: AppSizes.compactButtonFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'Dispatched') ...[
                _buildStepBackButton(req, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: AppSizes.compactElevatedStyle(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => req['status'] = 'Delivered');
                      _saveRequests();
                      AppNotification.show(
                        context,
                        message: 'Delivery confirmed for $id on site.',
                      );
                    },
                    icon: const Icon(Icons.inventory_rounded, size: 16),
                    label: const Text(
                      'Confirm Site Delivery',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else ...[
                _buildStepBackButton(req, isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Delivered & Received on Site',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
    ),
    );
  }

  void _showRequestExpandedBox(
    BuildContext context,
    Map<String, dynamic> req,
    bool isDark,
  ) {
    final id = (req['id'] ?? 'MR-001').toString();
    final itemName = (req['itemName'] ?? req['title'] ?? 'Material Item').toString();
    final project = (req['project'] ?? 'General Site').toString();
    final category = (req['category'] ?? 'Carpentry & Joinery').toString();
    final quantity = (req['quantity'] ?? '1 Unit').toString();
    final urgency = (req['urgency'] ?? 'Standard').toString();
    final status = (req['status'] ?? 'Pending Approval').toString();
    final supplier = (req['assignedSupplier'] ?? req['supplier'] ?? 'Trade Depot').toString();
    final cost = (req['estimatedCost'] ?? req['cost'] ?? '₹ 0').toString();
    final requestedBy = (req['requestedBy'] ?? 'Site Supervisor').toString();
    final requiredDate = (req['requiredDate'] ?? 'In 3 Days').toString();
    final notes = (req['notes'] ?? '').toString();
    final statusColor = _getStatusColor(status);

    showExpandedDetailBox(
      context: context,
      title: itemName,
      subtitle: '$id • $project',
      headerIcon: _getCategoryIcon(category),
      accentColor: statusColor,
      badgeLabel: status,
      badgeColor: statusColor,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Quantity Requested',
                value: quantity,
                color: AppColors.brandPeach,
                icon: Icons.inventory_2_rounded,
              ),
              DetailMetric(
                label: 'Estimated Cost',
                value: cost,
                icon: Icons.currency_rupee_rounded,
              ),
              DetailMetric(
                label: 'Urgency',
                value: urgency,
                color: urgency.toLowerCase().contains('urgent')
                    ? AppColors.error
                    : null,
                icon: Icons.flag_rounded,
              ),
              DetailMetric(
                label: 'Required By',
                value: requiredDate,
                icon: Icons.event_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailSectionTitle(label: 'Procurement Details', isDark: isDark),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project Site',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.category_outlined,
            label: 'Trade Category',
            value: category,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.storefront_rounded,
            label: 'Supplier',
            value: supplier,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Requested By',
            value: requestedBy,
            isDark: isDark,
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            DetailNoteBox(label: 'SITE NOTES', text: notes, isDark: isDark),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        if (status == 'Pending Approval') ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => _requests.remove(req));
              _saveRequests();
              BackendManager.instance.deleteDocument(
                'material_requests',
                id,
              );
              AppNotification.show(
                context,
                message: 'Request $id cancelled.',
              );
            },
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Reject', maxLines: 1),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPeach,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Approve Indent', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => req['status'] = 'Approved');
              _saveRequests();
              AppNotification.show(
                context,
                message: 'Indent $id approved for procurement.',
              );
            },
          ),
        ] else if (status == 'Approved') ...[
          _buildStepBackButton(
            req,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.local_shipping_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Mark Dispatched', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => req['status'] = 'Dispatched');
              _saveRequests();
              AppNotification.show(
                context,
                message: 'Materials for $id marked as Dispatched & In Transit.',
              );
            },
          ),
        ] else if (status == 'Dispatched') ...[
          _buildStepBackButton(
            req,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.inventory_rounded, size: 15),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Confirm Delivery', maxLines: 1),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              setState(() => req['status'] = 'Delivered');
              _saveRequests();
              AppNotification.show(
                context,
                message: 'Delivery confirmed for $id on site.',
              );
            },
          ),
        ] else ...[
          _buildStepBackButton(
            req,
            isDark,
            onBeforeStepBack: () => Navigator.of(dialogCtx).pop(),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Close', maxLines: 1),
            ),
          ),
        ],
      ],
    );
  }

  void _showCreateRequestModal(BuildContext context) {
    final itemCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final supervisorCtrl = TextEditingController(text: 'Suresh Kumar (Supervisor)');
    final reqDateCtrl = TextEditingController(text: 'In 3 Days');
    final notesCtrl = TextEditingController();

    String selectedProj = AppConstants.preExistingProjects.isNotEmpty
        ? AppConstants.preExistingProjects.first
        : 'Aurelia Sea-Facing Penthouse 42';
    String selectedTrade = 'Carpentry & Joinery';
    bool isUrgent = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Create Site Material Indent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Material Item & Specification *',
                    hintText: 'e.g. Greenply 19mm Marine Ply Club First',
                  ),
                ),
                const SizedBox(height: 12),
                QuickFadeDropdown<String>(
                  initialValue: selectedProj,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Associated Project Site *',
                  ),
                  items: AppConstants.preExistingProjects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedProj = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: QuickFadeDropdown<String>(
                        initialValue: selectedTrade,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trade Category *',
                        ),
                        items: [
                          'Carpentry & Joinery',
                          'Hardware & Fittings',
                          'Italian Marble & Tiles',
                          'Electrical & Automation',
                          'Paint & Polish',
                          'Civil & Masonry',
                          'Plumbing & Sanitary',
                        ]
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedTrade = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantity & Unit *',
                          hintText: 'e.g. 50 Sheets',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Cost (₹)',
                          hintText: 'e.g. 150000',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: supplierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vendor / Supplier',
                          hintText: 'e.g. Bhagwati Plywoods',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reqDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Required on Site By',
                          hintText: 'e.g. 24 Oct 2026',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: supervisorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Requested By',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Location on Site',
                    hintText: 'Specify room, trade details or special instructions...',
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isUrgent,
                  activeColor: AppColors.error,
                  onChanged: (val) {
                    setModalState(() => isUrgent = val ?? false);
                  },
                  title: const Text(
                    'Mark as Urgent (Site Stoppage Risk)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Flags indent for immediate proprietor & accounts dispatch priority.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: () {
                      final item = itemCtrl.text.trim();
                      final qty = qtyCtrl.text.trim();
                      if (item.isEmpty || qty.isEmpty) {
                        AppNotification.show(
                          context,
                          message: 'Please provide material item name and quantity.',
                        );
                        return;
                      }

                      final parsedCost = CurrencyUtils.parseAmount(costCtrl.text);
                      final costFormatted = parsedCost > 0
                          ? CurrencyUtils.formatInr(parsedCost)
                          : '₹ 0';

                      final newReq = {
                        'id': 'MR-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        'itemName': item,
                        'category': selectedTrade,
                        'project': selectedProj,
                        'quantity': qty,
                        'urgency': isUrgent ? 'Urgent' : 'Standard',
                        'status': 'Pending Approval',
                        'requestedBy': supervisorCtrl.text.trim().isEmpty
                            ? 'Site Supervisor'
                            : supervisorCtrl.text.trim(),
                        'assignedSupplier': supplierCtrl.text.trim().isEmpty
                            ? 'Trade Depot'
                            : supplierCtrl.text.trim(),
                        'estimatedCost': costFormatted,
                        'requestDate': 'Today',
                        'requiredDate': reqDateCtrl.text.trim().isEmpty
                            ? 'In 3 Days'
                            : reqDateCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      };

                      setState(() {
                        _requests.insert(0, newReq);
                      });
                      _saveRequests();

                      Navigator.pop(ctx);
                      AppNotification.show(
                        context,
                        message: 'Material indent for "$item" submitted successfully.',
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Submit Material Request',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
