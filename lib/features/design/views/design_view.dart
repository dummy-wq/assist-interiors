import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/expanded_detail_dialog.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class DesignView extends StatefulWidget {
  const DesignView({super.key});

  @override
  State<DesignView> createState() => _DesignViewState();
}

class _DesignViewState extends State<DesignView> {
  String _selectedCategory = 'All';
  String _selectedProject = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _designItems = [];

  final List<String> _categories = [
    'All',
    '3D Render',
    'CAD Plan',
    'GFC Set',
    'Mood Board',
    'Material BOQ',
  ];

  @override
  void initState() {
    super.initState();
    _loadDesignItems();
    MobileActionSheets.renderCreatedNotifier.addListener(_onAssetCreated);
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    StorageService.cloudSyncNotifier.addListener(_loadDesignItems);
  }

  @override
  void dispose() {
    StorageService.cloudSyncNotifier.removeListener(_loadDesignItems);
    MobileActionSheets.renderCreatedNotifier.removeListener(_onAssetCreated);
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    _searchController.dispose();
    super.dispose();
  }

  void _loadDesignItems() {
    final items = StorageService.getDesignItems();
    setState(() {
      _designItems.clear();
      _designItems.addAll(items);
    });
  }

  void _onAssetCreated() {
    final newAsset = MobileActionSheets.renderCreatedNotifier.value;
    if (newAsset != null && mounted) {
      setState(() {
        _designItems.insert(0, Map<String, dynamic>.from(newAsset));
      });
      StorageService.saveDesignItems(_designItems);
    }
  }

  void _onProjectCreated() {
    final newProj = MobileActionSheets.projectCreatedNotifier.value;
    if (newProj != null && mounted) {
      final projName = newProj['name'] as String? ?? 'New Site';
      if (!AppConstants.preExistingProjects.contains(projName)) {
        AppConstants.preExistingProjects.add(projName);
      }
      final originLeadId = newProj['originLeadId'];
      if (originLeadId == null || originLeadId.toString().isEmpty) {
        setState(() {});
        return;
      }
      final deliverableId =
          'DSG-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final initialDeliverable = {
        'id': deliverableId,
        'title': '$projName - Concept Layout & Mood Board',
        'project': projName,
        'type': 'CAD Plan',
        'category': 'CAD Plan',
        'version': 'v1.0',
        'status': 'Approved',
        'designer': 'Lead Architect',
        'format': 'DWG / PDF / 3D Render',
        'fileSize': '24.5 MB',
        'notes':
            'Initial layout & moodboard generated from sales handover brief.',
        'date': 'Today',
        'color': AppColors.info,
        'statusColor': AppColors.success,
        'createdAt': DateTime.now().toIso8601String(),
      };

      setState(() {
        if (!_designItems.any(
          (item) =>
              item['project'] == projName &&
              item['title'] == initialDeliverable['title'],
        )) {
          _designItems.insert(0, initialDeliverable);
        }
        if (!AppConstants.preExistingProjects.contains(projName)) {
          AppConstants.preExistingProjects.add(projName);
        }
      });
      StorageService.saveDesignItems(_designItems);
    }
  }

  void _saveItems() {
    StorageService.saveDesignItems(_designItems);
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('3d') || lower.contains('render')) {
      return Icons.view_in_ar_rounded;
    }
    if (lower.contains('cad') || lower.contains('plan')) {
      return Icons.architecture_rounded;
    }
    if (lower.contains('gfc')) {
      return Icons.draw_rounded;
    }
    if (lower.contains('mood') || lower.contains('board')) {
      return Icons.palette_rounded;
    }
    if (lower.contains('boq')) {
      return Icons.table_chart_rounded;
    }
    return Icons.design_services_rounded;
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approved')) return AppColors.success;
    if (lower.contains('review')) return AppColors.warning;
    if (lower.contains('revision') || lower.contains('reject')) {
      return AppColors.error;
    }
    if (lower.contains('gfc')) return AppColors.info;
    return AppColors.brandPeach;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canManageDesign = AppPermissions.canManageDesignAssets(
      auth.currentRole,
      user: auth.currentUser,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalRenders = 0;
    int totalCad = 0;
    int totalApproved = 0;
    for (final item in _designItems) {
      final cat = (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
      final stat = (item['status'] ?? '').toString().toLowerCase();
      if (cat.contains('3d') || cat.contains('render')) totalRenders++;
      if (cat.contains('cad') || cat.contains('plan') || cat.contains('gfc')) {
        totalCad++;
      }
      if (stat.contains('approved')) totalApproved++;
    }

    final filteredItems = _designItems.where((item) {
      if (_selectedCategory != 'All') {
        final cat = (item['type'] ?? item['category'] ?? '').toString();
        if (!cat.toLowerCase().contains(_selectedCategory.toLowerCase())) {
          return false;
        }
      }
      if (_selectedProject != 'All') {
        final proj = (item['project'] ?? '').toString();
        if (proj != _selectedProject) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final proj = (item['project'] ?? '').toString().toLowerCase();
        final format = (item['format'] ?? '').toString().toLowerCase();
        final designer = (item['designer'] ?? '').toString().toLowerCase();
        final notes = (item['notes'] ?? '').toString().toLowerCase();
        if (!title.contains(_searchQuery) &&
            !proj.contains(_searchQuery) &&
            !format.contains(_searchQuery) &&
            !designer.contains(_searchQuery) &&
            !notes.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    final projectsList = [
      'All',
      ...AppConstants.preExistingProjects,
    ];

    return ScreenScrollView(
      children: [
        ScreenHeader(
          AppStrings.tr('Drawings & Renders'),
          subtitle: AppStrings.tr('Drawings, 3D views & material lists'),
        ),
        const SizedBox(height: ScreenLayout.headerGap),

        // Stat Strip
        StatStrip(
          cards: [
            StatCard(
              title: 'Total Drawings',
              value: '${_designItems.length}',
              icon: Icons.folder_special_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: '3D Visualizations',
              value: '$totalRenders Renders',
              icon: Icons.view_in_ar_rounded,
              accentColor: AppColors.info,
            ),
            StatCard(
              title: 'Site Drawings (CAD)',
              value: '$totalCad Drawings',
              icon: Icons.architecture_rounded,
              accentColor: AppColors.warning,
            ),
            StatCard(
              title: 'Client Approved',
              value: '$totalApproved Approved',
              icon: Icons.verified_rounded,
              accentColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: ScreenLayout.sectionGap),

        // Search Bar & Filter Controls
        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search drawings, 3D renders, CAD sets or architect...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final cat in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PillBox(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    activeColor: AppColors.brandPeach,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory =
                            _selectedCategory == cat && cat != 'All'
                                ? 'All'
                                : cat;
                      });
                    },
                  ),
                ),
              if (projectsList.length > 2) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 190,
                  height: AppSizes.chipHeight,
                  child: QuickFadeDropdown<String>(
                    value: _selectedProject,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightCard,
                    icon: const Icon(
                      Icons.filter_alt_rounded,
                      size: 14,
                      color: AppColors.brandPeach,
                    ),
                    style: AppTypography.labelSmall(isDark).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                        borderSide: BorderSide(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProject = val);
                      }
                    },
                    items: projectsList.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(
                          p == 'All' ? 'All Projects' : p,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Deliverables Grid / List
        if (filteredItems.isEmpty)
          EmptyStateCard(
            icon: Icons.draw_outlined,
            title: AppStrings.tr('Drawings & Renders'),
            message: (_searchQuery.isNotEmpty ||
                    _selectedCategory != 'All' ||
                    _selectedProject != 'All')
                ? 'No drawings match your current filter.'
                : 'No drawings uploaded yet. Tap below to add your first drawing or render.',
            action: (_searchQuery.isNotEmpty ||
                    _selectedCategory != 'All' ||
                    _selectedProject != 'All')
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedProject = 'All';
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
                  )
                : (canManageDesign
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPeach,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () =>
                              MobileActionSheets.showUploadRenderSheet(context),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: Text(
                            AppStrings.tr('Upload Drawing'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildDesignCard(context, item, isDark, canManageDesign);
            },
          ),
      ],
    );
  }

  Widget _buildDesignCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
    bool canManageDesign,
  ) {
    final title = (item['title'] ?? 'Architectural Drawing').toString();
    final project = (item['project'] ?? 'General Deliverable').toString();
    final category = (item['type'] ?? item['category'] ?? '3D Render').toString();
    final format = (item['format'] ?? '.PDF').toString();
    final version = (item['version'] ?? 'v1.0').toString();
    final fileSize = (item['fileSize'] ?? '12.0 MB').toString();
    final status = (item['status'] ?? 'Under Client Review').toString();
    final designer = (item['designer'] ?? 'Priya Sharma').toString();
    final notes = (item['notes'] ?? '').toString();

    final statusColor = _getStatusColor(status);
    final catIcon = _getCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () => _viewDesignDetails(context, item, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.7),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Block
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: AppColors.brandPeach.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Icon(catIcon, color: AppColors.brandPeach, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
              // Status Badge
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
          const SizedBox(height: 10),

          // Metadata Chips (Format, Version, Size, Designer)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              StatusTagPill(label: category),
              StatusTagPill(label: format),
              StatusTagPill(label: version),
              StatusTagPill(label: fileSize),
              StatusTagPill(
                label: 'Ar. $designer',
                accentColor: AppColors.brandPeach,
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
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: AppSizes.compactOutlinedStyle(
                    foregroundColor: isDark
                        ? AppColors.textLightPrimary
                        : AppColors.textDarkPrimary,
                    borderColor: (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder)
                        .withValues(alpha: 0.7),
                  ),
                  onPressed: () => _viewDesignDetails(context, item, isDark),
                  icon: const Icon(Icons.fullscreen_rounded, size: 15),
                  label: Text(
                    'Inspect & Preview',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall(isDark).copyWith(
                      fontSize: AppSizes.compactButtonFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: AppSizes.compactOutlinedStyle(
                    foregroundColor: AppColors.brandPeach,
                    borderColor: AppColors.brandPeach.withValues(alpha: 0.6),
                  ),
                  onPressed: () async {
                    final cloudUrl =
                        (item['fileUrl'] ?? item['downloadUrl'])?.toString();
                    if (cloudUrl != null && cloudUrl.startsWith('http')) {
                      await launchUrl(
                        Uri.parse(cloudUrl),
                        mode: LaunchMode.externalApplication,
                      );
                      return;
                    }
                    AppNotification.show(
                      context,
                      message: 'Exporting $title ($format) - $fileSize',
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: Text(
                    'Export',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall(isDark).copyWith(
                      fontSize: AppSizes.compactButtonFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPeach,
                    ),
                  ),
                ),
              ),
              if (canManageDesign) ...[
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                  ),
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCard,
                  onSelected: (val) {
                    if (val == 'approve') {
                      setState(() => item['status'] = 'Approved');
                      _saveItems();
                      AppNotification.show(
                        context,
                        message: '$title marked as Approved',
                      );
                    } else if (val == 'revision') {
                      setState(() => item['status'] = 'Revision Requested');
                      _saveItems();
                      AppNotification.show(
                        context,
                        message: '$title marked for Revision',
                      );
                    } else if (val == 'gfc') {
                      setState(() => item['status'] = 'GFC Issued');
                      _saveItems();
                      AppNotification.show(
                        context,
                        message: '$title issued as Good For Construction (GFC)',
                      );
                    } else if (val == 'review') {
                      setState(() => item['status'] = 'Under Client Review');
                      _saveItems();
                      AppNotification.show(
                        context,
                        message: '$title moved back to Under Client Review',
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'approve',
                      child: Text('Mark Approved'),
                    ),
                    const PopupMenuItem(
                      value: 'gfc',
                      child: Text('Issue as Site Drawing (GFC)'),
                    ),
                    const PopupMenuItem(
                      value: 'revision',
                      child: Text('Request Revision'),
                    ),
                    const PopupMenuItem(
                      value: 'review',
                      child: Text('Step Back to Client Review'),
                    ),
                  ],
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

  void _viewDesignDetails(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
  ) {
    final title = (item['title'] ?? 'Architectural Drawing').toString();
    final project = (item['project'] ?? 'General Deliverable').toString();
    final category = (item['type'] ?? item['category'] ?? '3D Render').toString();
    final format = (item['format'] ?? '.PDF').toString();
    final version = (item['version'] ?? 'v1.0').toString();
    final fileSize = (item['fileSize'] ?? '12.0 MB').toString();
    final designer = (item['designer'] ?? 'Priya Sharma').toString();
    final notes = (item['notes'] ?? '').toString();
    final status = (item['status'] ?? 'Under Client Review').toString();
    final statusColor = _getStatusColor(status);

    showExpandedDetailBox(
      context: context,
      title: title,
      subtitle: project,
      headerIcon: _getCategoryIcon(category),
      accentColor: statusColor,
      badgeLabel: status,
      badgeColor: statusColor,
      bodyBuilder: (dialogCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 132,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.7),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 44,
                  color: AppColors.brandPeach.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 6),
                Text(
                  'High-Resolution Preview Simulation',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textLightMuted
                        : AppColors.textDarkMuted,
                  ),
                ),
                Text(
                  '$format • $fileSize • $version',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPeach,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DetailMetricGrid(
            isDark: isDark,
            metrics: [
              DetailMetric(
                label: 'Format & Size',
                value: '$format ($fileSize)',
                color: AppColors.brandPeach,
                icon: Icons.insert_drive_file_rounded,
              ),
              DetailMetric(
                label: 'Active Version',
                value: version,
                icon: Icons.history_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailSectionTitle(label: 'Deliverable Specifications', isDark: isDark),
          DetailInfoRow(
            icon: Icons.apartment_rounded,
            label: 'Project Site',
            value: project,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.category_rounded,
            label: 'Category',
            value: category,
            isDark: isDark,
          ),
          DetailInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Architect / Lead',
            value: designer,
            isDark: isDark,
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            DetailNoteBox(
              label: 'SPECIFICATIONS & NOTES',
              text: notes,
              isDark: isDark,
            ),
          ],
        ],
      ),
      actionsBuilder: (dialogCtx) => [
        OutlinedButton.icon(
          icon: const Icon(Icons.close_rounded, size: 15),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Close', maxLines: 1),
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPeach,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.download_rounded, size: 15),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Download CAD / Render', maxLines: 1),
          ),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            AppNotification.show(
              context,
              message: 'Technical drawing file $title downloaded successfully.',
            );
          },
        ),
      ],
    );
  }
}
