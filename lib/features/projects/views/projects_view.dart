import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/models/project_model.dart';
import '../widgets/snappy_reorderable_stages_list.dart';
import '../sheets/edit_project_sheet.dart';
import '../sheets/take_site_photo_sheet.dart';
import '../dialogs/project_photo_viewer_dialog.dart';
import '../dialogs/design_asset_viewer_dialog.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _newStageControllers = {};

  final List<Map<String, dynamic>> _projects = <Map<String, dynamic>>[];
  final Set<String> _expandedProjects = <String>{};

  @override
  void initState() {
    super.initState();
    _projects.addAll(StorageService.getProjects());
    _selectedStatus = 'All';
    MobileActionSheets.projectFilterNotifier.value = 'All';
    MobileActionSheets.projectCreatedNotifier.addListener(_onProjectCreated);
    MobileActionSheets.projectUpdatedNotifier.addListener(_onProjectUpdated);
    MobileActionSheets.projectFilterNotifier.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    MobileActionSheets.projectCreatedNotifier.removeListener(_onProjectCreated);
    MobileActionSheets.projectUpdatedNotifier.removeListener(_onProjectUpdated);
    MobileActionSheets.projectFilterNotifier.removeListener(_onFilterChanged);
    _searchController.dispose();
    for (final controller in _newStageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {
        _selectedStatus = MobileActionSheets.projectFilterNotifier.value;
      });
    }
  }

  void _onProjectCreated() {
    final proj = MobileActionSheets.projectCreatedNotifier.value;
    if (proj != null && mounted) {
      if (!_projects.contains(proj)) {
        setState(() {
          _projects.add(proj);
        });
        StorageService.saveProjects(_projects);
        BackendManager.instance.createProject(ProjectModel.fromMap(proj));
      }
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

  TextEditingController _getController(int projectIndex) {
    return _newStageControllers.putIfAbsent(
      projectIndex,
      () => TextEditingController(),
    );
  }

  void _toggleStage(int projectIndex, int stageIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canToggleOrReorderStages(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Stage updates restricted: Only Site Supervisors, Designers, and Project Managers can update stages.',
      );
      return;
    }
    setState(() {
      final stages =
          _projects[projectIndex]['stages'] as List<Map<String, dynamic>>;
      stages[stageIndex]['isDone'] = !(stages[stageIndex]['isDone'] as bool);
    });
    StorageService.saveProjects(_projects);
    BackendManager.instance.updateProject(
      ProjectModel.fromMap(_projects[projectIndex]),
    );
  }

  void _reorderStage(int projectIndex, int oldIndex, int newIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canToggleOrReorderStages(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Stage reordering restricted: Only operations leads can change stage sequence.',
      );
      return;
    }
    setState(() {
      final stages =
          _projects[projectIndex]['stages'] as List<Map<String, dynamic>>;
      final item = stages.removeAt(oldIndex);
      stages.insert(newIndex, item);
    });
    StorageService.saveProjects(_projects);
    BackendManager.instance.updateProject(
      ProjectModel.fromMap(_projects[projectIndex]),
    );
  }

  void _addNewStage(int projectIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canToggleOrReorderStages(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Stage creation restricted: Only operations leads can define new stages.',
      );
      return;
    }
    final controller = _getController(projectIndex);
    final title = controller.text.trim();
    if (title.isEmpty) return;

    setState(() {
      final stages =
          _projects[projectIndex]['stages'] as List<Map<String, dynamic>>;
      stages.add({
        'id': 'stage_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'isDone': false,
      });
      controller.clear();
    });
    StorageService.saveProjects(_projects);
    BackendManager.instance.updateProject(
      ProjectModel.fromMap(_projects[projectIndex]),
    );
  }

  void _removeStage(int projectIndex, int stageIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canToggleOrReorderStages(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Stage removal restricted to project management leads.',
      );
      return;
    }
    setState(() {
      final stages =
          _projects[projectIndex]['stages'] as List<Map<String, dynamic>>;
      if (stageIndex >= 0 && stageIndex < stages.length) {
        stages.removeAt(stageIndex);
      }
    });
    StorageService.saveProjects(_projects);
    BackendManager.instance.updateProject(
      ProjectModel.fromMap(_projects[projectIndex]),
    );
  }

  void _takeSitePhoto(int projectIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canAddProjectPhotos(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Photo upload restricted: Only Site Supervisors, Designers, and Project Managers can capture site photos.',
      );
      return;
    }
    TakeSitePhotoSheet.show(
      context,
      project: _projects[projectIndex],
      onPhotoAdded: (photo) {
        setState(() {
          final photosRaw = (_projects[projectIndex]['photos'] as List?) ?? [];
          final list = photosRaw
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          list.insert(0, photo);
          _projects[projectIndex]['photos'] = list;
        });
        StorageService.saveProjects(_projects);
        BackendManager.instance.updateProject(
          ProjectModel.fromMap(_projects[projectIndex]),
        );
        AppNotification.show(
          context,
          message:
              'Site inspection photo added to ${_projects[projectIndex]['name']}',
        );
      },
    );
  }

  void _uploadSitePhoto(int projectIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canAddProjectPhotos(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Photo upload restricted: Only Site Supervisors, Designers, and Project Managers can capture site photos.',
      );
      return;
    }
    TakeSitePhotoSheet.show(
      context,
      project: _projects[projectIndex],
      initialUploadMode: true,
      onPhotoAdded: (photo) {
        setState(() {
          final photosRaw = (_projects[projectIndex]['photos'] as List?) ?? [];
          final list = photosRaw
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          list.insert(0, photo);
          _projects[projectIndex]['photos'] = list;
        });
        StorageService.saveProjects(_projects);
        BackendManager.instance.updateProject(
          ProjectModel.fromMap(_projects[projectIndex]),
        );
        AppNotification.show(
          context,
          message:
              'Site inspection photo uploaded to ${_projects[projectIndex]['name']}',
        );
      },
    );
  }

  void _deleteSitePhoto(int projectIndex, int photoIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canAddProjectPhotos(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Photo deletion restricted: Only operations leads can remove site photos.',
      );
      return;
    }
    setState(() {
      final photosRaw = (_projects[projectIndex]['photos'] as List?) ?? [];
      final list = photosRaw
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      if (photoIndex >= 0 && photoIndex < list.length) {
        list.removeAt(photoIndex);
      }
      _projects[projectIndex]['photos'] = list;
    });
    StorageService.saveProjects(_projects);
    BackendManager.instance.updateProject(
      ProjectModel.fromMap(_projects[projectIndex]),
    );
    AppNotification.show(context, message: 'Site inspection photo removed');
  }

  void _openUploadDesignAsset(int projectIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageDesignAssets(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Upload restricted: Only Designers, Project Managers, and Proprietors can upload CAD drawings or 3D renders.',
      );
      return;
    }
    final projectName =
        _projects[projectIndex]['name'] as String? ?? 'Active Site';
    UploadRenderSheet.show(
      context,
      preselectedProject: projectName,
      onUploaded: (newAsset) {
        setState(() {
          final assetsRaw =
              (_projects[projectIndex]['designAssets'] as List?) ?? [];
          final list = assetsRaw
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList();
          list.insert(0, newAsset);
          _projects[projectIndex]['designAssets'] = list;
        });
        StorageService.saveProjects(_projects);
        AppNotification.show(
          context,
          message:
              'Design deliverable published to ${_projects[projectIndex]['name']}',
        );
      },
    );
  }

  void _deleteDesignAsset(int projectIndex, int assetIndex) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canManageDesignAssets(auth.currentRole)) {
      AppNotification.show(
        context,
        message: 'Deletion restricted: Only authorized design leads can remove design assets.',
      );
      return;
    }
    setState(() {
      final assetsRaw =
          (_projects[projectIndex]['designAssets'] as List?) ?? [];
      final list = assetsRaw
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
      if (assetIndex >= 0 && assetIndex < list.length) {
        list.removeAt(assetIndex);
      }
      _projects[projectIndex]['designAssets'] = list;
    });
    StorageService.saveProjects(_projects);
    AppNotification.show(context, message: 'Design deliverable removed');
  }

  void _updateDesignAssetStatus(
    int projectIndex,
    int assetIndex,
    String newStatus,
  ) {
    setState(() {
      final assetsRaw =
          (_projects[projectIndex]['designAssets'] as List?) ?? [];
      final list = assetsRaw
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
      if (assetIndex >= 0 && assetIndex < list.length) {
        list[assetIndex]['status'] = newStatus;
      }
      _projects[projectIndex]['designAssets'] = list;
    });
    StorageService.saveProjects(_projects);
  }

  double _calculateProgress(List<Map<String, dynamic>> stages) {
    if (stages.isEmpty) return 0.0;
    final done = stages.where((s) => s['isDone'] == true).length;
    return done / stages.length;
  }

  String _getActiveStageTitle(List<Map<String, dynamic>> stages) {
    if (stages.isEmpty) return 'No execution stages listed';
    final current = stages.firstWhere(
      (s) => s['isDone'] == false,
      orElse: () => {'title': 'All Stages Completed'},
    );
    return current['title'] as String;
  }

  String _getProjectStatus(Map<String, dynamic> project) {
    if (project['isDelayed'] == true) {
      return 'Delayed';
    }
    final stages = project['stages'] as List<Map<String, dynamic>>? ?? [];
    if (stages.isEmpty) {
      return 'Design and Planning';
    }
    final doneCount = stages.where((s) => s['isDone'] == true).length;
    if (doneCount == stages.length) {
      return 'Completed';
    }
    return 'On Track';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFFC7BBAF); // Alabaster White / Warm Neutral
      case 'On Track':
        return const Color(0xFFD4AF87); // Warm Champagne
      case 'Delayed':
        return const Color(0xFFC48B7D); // Clay Rose / Subdued Terrene
      case 'Design and Planning':
      case 'Design & Planning':
        return const Color(0xFF94979E); // Charcoal Flute / Slate
      default:
        return const Color(0xFFD4AF87);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'Completed':
        return Icons.check_circle_outline_rounded;
      case 'On Track':
        return Icons.trending_up_rounded;
      case 'Delayed':
        return Icons.warning_amber_rounded;
      case 'Design and Planning':
      case 'Design & Planning':
        return Icons.architecture_rounded;
      default:
        return Icons.lens_rounded;
    }
  }

  int _getCountForStatus(String status) {
    if (status == 'All') return _projects.length;
    return _projects.where((p) {
      final s = _getProjectStatus(p);
      return s.toLowerCase().replaceAll('&', 'and') ==
          status.toLowerCase().replaceAll('&', 'and');
    }).length;
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'All':
        return AppStrings.all;
      case 'Completed':
        return AppStrings.statusCompleted;
      case 'On Track':
        return AppStrings.statusOnTrack;
      case 'Delayed':
        return AppStrings.statusDelayed;
      case 'Design and Planning':
      case 'Design & Planning':
        return AppStrings.statusDesignPlanning;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final auth = Provider.of<AuthProvider>(context);
    final currentRole = auth.currentRole;
    final canCreateProject = AppPermissions.canCreateProject(currentRole);
    final canEditProject = AppPermissions.canEditProjectDetails(currentRole);
    final canModifyStatus = AppPermissions.canModifyProjectStatus(currentRole);
    final canModifyStages = AppPermissions.canToggleOrReorderStages(
      currentRole,
    );
    final canAddPhotos = AppPermissions.canAddProjectPhotos(currentRole);
    final canManageDesignAssets = AppPermissions.canManageDesignAssets(
      currentRole,
    );

    final filteredProjects = _projects.where((p) {
      if (_selectedStatus != 'All') {
        final status = _getProjectStatus(p);
        if (status.toLowerCase().replaceAll('&', 'and') !=
            _selectedStatus.toLowerCase().replaceAll('&', 'and')) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final client = (p['clientName'] ?? p['client'] ?? '')
            .toString()
            .toLowerCase();
        final location = (p['location'] ?? '').toString().toLowerCase();
        final type = (p['type'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery) &&
            !client.contains(_searchQuery) &&
            !location.contains(_searchQuery) &&
            !type.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    return ScreenScrollView(
      children: [
        ScreenHeader(AppStrings.projectsPortfolio),
        const SizedBox(height: ScreenLayout.headerGap),

        // High-level Metrics (Compact StatStrip)
        StatStrip(
          cards: [
            StatCard(
              title: AppStrings.activeSites,
              value: '${_projects.length} Sites',
              icon: Icons.apartment_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: AppStrings.contractValue,
              value: _projects.isEmpty ? '₹ 0' : '₹ 4.62 Cr',
              trend: _projects.isEmpty ? null : '+12%',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: AppColors.success,
            ),
            StatCard(
              title: AppStrings.averageProgress,
              value: _projects.isEmpty ? '0%' : '68%',
              icon: Icons.donut_large_rounded,
              accentColor: AppColors.brandPeach,
            ),
            StatCard(
              title: AppStrings.handovers,
              value: _projects.isEmpty ? '0 Projects' : '2 Projects',
              icon: Icons.key_rounded,
              accentColor: AppColors.brandOrange,
            ),
          ],
        ),
        if (!canEditProject && !canModifyStages) ...[
          const SizedBox(height: ScreenLayout.noticeGap),
          ReadOnlyNotice(
            'Read-Only Access: Signed in as ${currentRole.title}. Modifying projects and site execution stages requires Project Manager or Proprietor authorization.',
          ),
        ],
        const SizedBox(height: ScreenLayout.sectionGap),

        ScreenSearchField(
          controller: _searchController,
          hintText: 'Search projects by name, client, or site location...',
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: ScreenLayout.controlGap),

        // Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  'All',
                  'Completed',
                  'On Track',
                  'Delayed',
                  'Design and Planning',
                ].map((status) {
                  final isSelected = _selectedStatus == status;
                  final count = _getCountForStatus(status);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PillBox(
                      label: _getStatusLabel(status),
                      isSelected: isSelected,
                      activeColor: AppColors.brandPeach,
                      icon: _getStatusIcon(status),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPeach.withValues(
                                  alpha: isDark ? 0.35 : 0.22,
                                )
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.brandPeach
                                : (isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted),
                          ),
                        ),
                      ),
                      onSelected: () {
                        setState(() => _selectedStatus = status);
                        MobileActionSheets.projectFilterNotifier.value = status;
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: ScreenLayout.listGap),

        // Projects List or Empty State — animated on filter change
        FilterSwitcher(
          child: filteredProjects.isEmpty
              ? EmptyStateCard(
                  key: ValueKey('empty_projects_$_selectedStatus'),
                  icon: Icons.apartment_outlined,
                  title: AppStrings.noProjectsListed,
                  message: _selectedStatus == 'All'
                      ? (canCreateProject
                            ? 'All project entries have been cleared. Tap "Add Project" to initialize a project site.'
                            : 'All project entries have been cleared.')
                      : 'No projects found with status "$_selectedStatus".',
                  action: (_selectedStatus != 'All' || _searchQuery.isNotEmpty)
                      ? OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedStatus = 'All';
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            MobileActionSheets.projectFilterNotifier.value =
                                'All';
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Show All Projects'),
                        )
                      : null,
                )
              : ListView.separated(
                  key: ValueKey('projects_$_selectedStatus'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: ScreenLayout.itemGap),
                  itemBuilder: (context, index) {
                    final p = filteredProjects[index];
                    final rawIndex = _projects.indexOf(p);
                    final currentStatus = _getProjectStatus(p);
                    final Color statusColor = _getStatusColor(currentStatus);

                    // Project architectural material swatch
                    final projectName = p['name'] as String? ?? '';
                    final swatchInfo = AppColors.getProjectSwatch(projectName);
                    final Color projectAccent =
                        (p['color'] is Color &&
                            p['color'] != AppColors.brandPeach &&
                            p['color'] != AppColors.info &&
                            p['color'] != AppColors.error)
                        ? p['color'] as Color
                        : (p['color'] is int &&
                                  p['color'] !=
                                      AppColors.brandPeach.toARGB32() &&
                                  p['color'] != AppColors.info.toARGB32() &&
                                  p['color'] != AppColors.error.toARGB32()
                              ? Color(p['color'] as int)
                              : swatchInfo['color'] as Color);
                    final String swatchName =
                        (p['swatchName'] as String?) ??
                        swatchInfo['name'] as String;

                    final stages = p['stages'] as List<Map<String, dynamic>>;
                    final bool isChecklistOpen =
                        (p['isChecklistOpen'] as bool?) ?? false;
                    final bool isDelayed = p['isDelayed'] == true;
                    final String projectKey =
                        p['id']?.toString() ??
                        p['name'] as String? ??
                        '$rawIndex';
                    final bool isExpanded = _expandedProjects.contains(
                      projectKey,
                    );

                    final double progress = _calculateProgress(stages);
                    final int progressPercent = (progress * 100).round();
                    final int doneCount = stages
                        .where((s) => s['isDone'] == true)
                        .length;
                    final int totalCount = stages.length;
                    final String activeStage = _getActiveStageTitle(stages);

                    return AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder.withValues(alpha: 0.7)
                                : AppColors.lightBorder.withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.04,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Main Card Body
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                25,
                                isExpanded ? 22 : 14,
                                20,
                                isExpanded ? 22 : 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Project Title with Material Swatch, Location & Status Badge
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Material Swatch Indicator
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  margin: const EdgeInsets.only(
                                                    right: 9,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: projectAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: projectAccent
                                                            .withValues(
                                                              alpha: 0.45,
                                                            ),
                                                        blurRadius: 5,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    onTap: () {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      setState(() {
                                                        if (isExpanded) {
                                                          _expandedProjects
                                                              .remove(
                                                                projectKey,
                                                              );
                                                        } else {
                                                          _expandedProjects
                                                              .add(projectKey);
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      p['name'] as String,
                                                      style:
                                                          AppTypography.titleLarge(
                                                            isDark,
                                                          ).copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                // 3-dots Menu for Edit / Manage Project or Read-Only Pill
                                                if (canEditProject ||
                                                    canAddPhotos ||
                                                    canManageDesignAssets)
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: Theme(
                                                      data: Theme.of(context).copyWith(
                                                        popupMenuTheme: PopupMenuThemeData(
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkCard
                                                              : AppColors
                                                                    .lightCard,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6.0,
                                                                ),
                                                            side: BorderSide(
                                                              color: isDark
                                                                  ? AppColors
                                                                        .darkBorder
                                                                  : AppColors
                                                                        .lightBorder,
                                                              width: 0.8,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: PopupMenuButton<String>(
                                                        tooltip: AppStrings.tr(
                                                          'Project Options',
                                                        ),
                                                        icon: Icon(
                                                          Icons
                                                              .more_vert_rounded,
                                                          size: 18,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        iconSize: 18,
                                                        elevation: 4,
                                                        onSelected: (val) {
                                                          if (val == 'photo') {
                                                            _takeSitePhoto(
                                                              rawIndex,
                                                            );
                                                          } else if (val ==
                                                              'upload_photo') {
                                                            _uploadSitePhoto(
                                                              rawIndex,
                                                            );
                                                          } else if (val ==
                                                              'edit') {
                                                            EditProjectSheet.show(
                                                              context,
                                                              project: p,
                                                              onProjectUpdated: (updated) {
                                                                setState(() {
                                                                  if (rawIndex >=
                                                                          0 &&
                                                                      rawIndex <
                                                                          _projects
                                                                              .length) {
                                                                    _projects[rawIndex] =
                                                                        updated;
                                                                  }
                                                                });
                                                                StorageService.saveProjects(
                                                                  _projects,
                                                                );
                                                                BackendManager
                                                                    .instance
                                                                    .updateProject(
                                                                      ProjectModel.fromMap(
                                                                        updated,
                                                                      ),
                                                                    );
                                                              },
                                                            );
                                                          } else if (val ==
                                                              'delay') {
                                                            setState(() {
                                                              p['isDelayed'] =
                                                                  !isDelayed;
                                                            });
                                                            StorageService.saveProjects(
                                                              _projects,
                                                            );
                                                            BackendManager
                                                                .instance
                                                                .updateProject(
                                                                  ProjectModel.fromMap(
                                                                    p,
                                                                  ),
                                                                );
                                                          } else if (val ==
                                                              'upload_asset') {
                                                            _openUploadDesignAsset(
                                                              rawIndex,
                                                            );
                                                          }
                                                        },
                                                        itemBuilder: (context) => [
                                                          if (canAddPhotos) ...[
                                                            PopupMenuItem<
                                                              String
                                                            >(
                                                              value: 'photo',
                                                              height: 40,
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .add_a_photo_outlined,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .brandPeach,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    'Add Site Photo',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          isDark
                                                                          ? AppColors.textLightPrimary
                                                                          : AppColors.textDarkPrimary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                          if (canManageDesignAssets)
                                                            PopupMenuItem<
                                                              String
                                                            >(
                                                              value: 'upload_asset',
                                                              height: 40,
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .architecture_rounded,
                                                                    size: 16,
                                                                    color:
                                                                        projectAccent,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    'Add Deliverable (CAD/3D)',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          isDark
                                                                          ? AppColors.textLightPrimary
                                                                          : AppColors.textDarkPrimary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          if ((canAddPhotos ||
                                                                  canManageDesignAssets) &&
                                                              canEditProject)
                                                            const PopupMenuDivider(
                                                              height: 1,
                                                            ),
                                                          if (canEditProject) ...[
                                                            PopupMenuItem<
                                                              String
                                                            >(
                                                              value: 'edit',
                                                              height: 40,
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .edit_outlined,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .brandPeach,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    AppStrings.tr(
                                                                      'Edit Project Details',
                                                                    ),
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          isDark
                                                                          ? AppColors.textLightPrimary
                                                                          : AppColors.textDarkPrimary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const PopupMenuDivider(
                                                              height: 1,
                                                            ),
                                                            PopupMenuItem<
                                                              String
                                                            >(
                                                              value: 'delay',
                                                              height: 40,
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    isDelayed
                                                                        ? Icons
                                                                              .check_circle_outline_rounded
                                                                        : Icons
                                                                              .warning_amber_rounded,
                                                                    size: 16,
                                                                    color:
                                                                        isDelayed
                                                                        ? AppColors
                                                                              .success
                                                                        : AppColors
                                                                              .error,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    isDelayed
                                                                        ? AppStrings
                                                                              .revertToOnTrack
                                                                        : AppStrings
                                                                              .markAsDelayed,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          isDelayed
                                                                          ? AppColors.success
                                                                          : AppColors.error,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 3.5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black)
                                                              .withValues(
                                                                alpha: 0.05,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4.0,
                                                          ),
                                                      border: Border.all(
                                                        color: (isDark
                                                            ? Colors.white24
                                                            : Colors.black12),
                                                        width: 0.6,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .lock_outline_rounded,
                                                          size: 11,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Read-Only',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? AppColors
                                                                      .textLightMuted
                                                                : AppColors
                                                                      .textDarkMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  '${p['location']} • ${p['type']}',
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ).copyWith(
                                                        color: isDark
                                                            ? AppColors
                                                                  .textLightMuted
                                                            : AppColors
                                                                  .textDarkMuted,
                                                      ),
                                                ),
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 32,
                                                        maxWidth: 160,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 2.5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: projectAccent
                                                          .withValues(
                                                            alpha: isDark
                                                                ? 0.22
                                                                : 0.14,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4.0,
                                                          ),
                                                      border: Border.all(
                                                        color: projectAccent
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.45
                                                                  : 0.35,
                                                            ),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                right: 4.5,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    projectAccent,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            swatchName,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  projectAccent,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 125,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6.0,
                                            ),
                                            border: Border.all(
                                              color: statusColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusLabel(currentStatus),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        key: ValueKey('expand_arrow_$rawIndex'),
                                        tooltip: isExpanded
                                            ? 'Collapse Project'
                                            : 'Expand Project',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          color: isDark
                                              ? AppColors.textLightSecondary
                                              : AppColors.textDarkSecondary,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedProjects.remove(
                                                projectKey,
                                              );
                                            } else {
                                              _expandedProjects.add(projectKey);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (!isExpanded) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 13,
                                                color: isDark
                                                    ? AppColors.textLightMuted
                                                    : AppColors.textDarkMuted,
                                              ),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: Text(
                                                  'Handover: ${p['handover']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? AppColors
                                                              .textLightMuted
                                                        : AppColors
                                                              .textDarkMuted,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$progressPercent% Complete',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: projectAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2.0),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 3.5,
                                        backgroundColor: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              projectAccent,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(4.0),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _expandedProjects.add(projectKey);
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withValues(alpha: 0.03),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          border: Border.all(
                                            color: (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)
                                                .withValues(alpha: 0.4),
                                            width: 0.6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Tap to view stages, photos & design assets',
                                                style: TextStyle(
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppColors.textLightSecondary
                                                      : AppColors.textDarkSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_drop_down_rounded,
                                              size: 18,
                                              color: projectAccent,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isExpanded) ...[
                                    // Quick Action: Mark as Delayed toggle button
                                    if (canModifyStatus) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: InstantPressFeedback(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                p['isDelayed'] = !isDelayed;
                                              });
                                              StorageService.saveProjects(
                                                _projects,
                                              );
                                              BackendManager.instance
                                                  .updateProject(
                                                    ProjectModel.fromMap(p),
                                                  );
                                            },
                                            icon: Icon(
                                              isDelayed
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.schedule_rounded,
                                              size: 13,
                                              color: isDelayed
                                                  ? AppColors.error
                                                  : (isDark
                                                        ? AppColors
                                                              .textLightMuted
                                                        : AppColors
                                                              .textDarkMuted),
                                            ),
                                            label: Text(
                                              isDelayed
                                                  ? AppStrings.revertToOnTrack
                                                  : AppStrings.markAsDelayed,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDelayed
                                                    ? AppColors.error
                                                    : (isDark
                                                          ? AppColors
                                                                .textLightPrimary
                                                          : AppColors
                                                                .textDarkPrimary),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: isDelayed
                                                    ? AppColors.error
                                                          .withValues(
                                                            alpha: 0.8,
                                                          )
                                                    : (isDark
                                                          ? AppColors.darkBorder
                                                          : AppColors
                                                                .lightBorder),
                                                width: 0.8,
                                              ),
                                              backgroundColor: isDelayed
                                                  ? AppColors.error.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),

                                    // Financial & Team Leads Strip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCardElevated
                                            : AppColors.lightBackground,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color:
                                              (isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.lightBorder)
                                                  .withValues(alpha: 0.6),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppStrings
                                                      .financialCommitment,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    letterSpacing: 0.8,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? AppColors
                                                              .textLightMuted
                                                        : AppColors
                                                              .textDarkMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${p['spent']} / ${p['budget']}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? AppColors
                                                              .textLightPrimary
                                                        : AppColors
                                                              .textDarkPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 28,
                                            width: 0.8,
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'PROJECT LEAD & SITE',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    letterSpacing: 0.8,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? AppColors
                                                              .textLightMuted
                                                        : AppColors
                                                              .textDarkMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${p['pm']} • ${p['supervisor']}',
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ).copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Site Photos & Inspection Gallery
                                    Builder(
                                      builder: (context) {
                                        final photosRaw =
                                            (p['photos'] as List?) ?? [];
                                        final photos = photosRaw
                                            .map(
                                              (ph) => Map<String, dynamic>.from(
                                                ph as Map,
                                              ),
                                            )
                                            .toList();

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: Wrap(
                                                alignment:
                                                    WrapAlignment.spaceBetween,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .photo_camera_rounded,
                                                        size: 14,
                                                        color: AppColors
                                                            .brandPeach,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'SITE INSPECTION PHOTOS',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          letterSpacing: 0.8,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 1.5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .brandPeach
                                                              .withValues(
                                                                alpha: isDark
                                                                    ? 0.22
                                                                    : 0.14,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4.0,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '${photos.length}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .brandPeach,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (canAddPhotos)
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: [
                                                        InstantPressFeedback(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () =>
                                                                _takeSitePhoto(
                                                              rawIndex,
                                                            ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .add_a_photo_outlined,
                                                              size: 13,
                                                              color: AppColors
                                                                  .brandPeach,
                                                            ),
                                                            label: const Text(
                                                              'Add Photo',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight.w700,
                                                                color: AppColors
                                                                    .brandPeach,
                                                              ),
                                                            ),
                                                            style: OutlinedButton.styleFrom(
                                                              side: BorderSide(
                                                                color: AppColors
                                                                    .brandPeach
                                                                    .withValues(
                                                                      alpha: 0.6,
                                                                    ),
                                                                width: 0.8,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal: 8,
                                                                    vertical: 4,
                                                                  ),
                                                              minimumSize:
                                                                  Size.zero,
                                                              tapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4.0,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (photos.isNotEmpty)
                                              SizedBox(
                                                height: 76,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: photos.length,
                                                  separatorBuilder: (
                                                    context,
                                                    idx,
                                                  ) => const SizedBox(width: 8),
                                                  itemBuilder: (context, photoIdx) {
                                                    final photo =
                                                        photos[photoIdx];
                                                    final title =
                                                        (photo['title']
                                                            as String?) ??
                                                        'Site Photo';
                                                    final tag =
                                                        (photo['tag']
                                                            as String?) ??
                                                        'Site';
                                                    final time =
                                                        (photo['timestamp']
                                                            as String?) ??
                                                        '';

                                                    return InstantPressFeedback(
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4.0,
                                                            ),
                                                        onTap: () {
                                                          ProjectPhotoViewerDialog.show(
                                                            context,
                                                            photo: photo,
                                                            projectName:
                                                                projectName,
                                                            projectAccent:
                                                                projectAccent,
                                                            canDelete:
                                                                canAddPhotos,
                                                            onDelete: () =>
                                                                _deleteSitePhoto(
                                                                  rawIndex,
                                                                  photoIdx,
                                                                ),
                                                          );
                                                        },
                                                        child: Container(
                                                          width: 175,
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? AppColors
                                                                      .darkCardElevated
                                                                : AppColors
                                                                      .lightBackground,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  (isDark
                                                                          ? AppColors.darkBorder
                                                                          : AppColors.lightBorder)
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                              width: 0.8,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 36,
                                                                height: double
                                                                    .infinity,
                                                                decoration: BoxDecoration(
                                                                  color: projectAccent
                                                                      .withValues(
                                                                        alpha:
                                                                            isDark
                                                                            ? 0.2
                                                                            : 0.12,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        3.0,
                                                                      ),
                                                                  border: Border.all(
                                                                    color: projectAccent
                                                                        .withValues(
                                                                          alpha:
                                                                              0.4,
                                                                        ),
                                                                    width: 0.6,
                                                                  ),
                                                                ),
                                                                child:
                                                                    (photo['imagePath'] !=
                                                                            null &&
                                                                        !kIsWeb &&
                                                                        File(
                                                                          photo['imagePath']
                                                                              as String,
                                                                        ).existsSync())
                                                                    ? ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              3.0,
                                                                            ),
                                                                        child: Image.file(
                                                                          File(
                                                                            photo['imagePath']
                                                                                as String,
                                                                          ),
                                                                          width:
                                                                              36,
                                                                          height:
                                                                              double.infinity,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      )
                                                                    : Icon(
                                                                        Icons
                                                                            .camera_alt_rounded,
                                                                        size:
                                                                            16,
                                                                        color:
                                                                            projectAccent,
                                                                      ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      tag.toUpperCase(),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            9,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color:
                                                                            projectAccent,
                                                                        letterSpacing:
                                                                            0.4,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    Text(
                                                                      title,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color:
                                                                            isDark
                                                                            ? AppColors.textLightPrimary
                                                                            : AppColors.textDarkPrimary,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                    if (time
                                                                        .isNotEmpty) ...[
                                                                      const SizedBox(
                                                                        height:
                                                                            2,
                                                                      ),
                                                                      Text(
                                                                        time,
                                                                        style: TextStyle(
                                                                          fontSize: 9.5,
                                                                          fontWeight: FontWeight.w500,
                                                                          color:
                                                                              isDark
                                                                              ? AppColors.textLightMuted
                                                                              : AppColors.textDarkMuted,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            else
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors
                                                            .darkCardElevated
                                                            .withValues(
                                                              alpha: 0.5,
                                                            )
                                                      : AppColors
                                                            .lightBackground
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.0,
                                                      ),
                                                  border: Border.all(
                                                    color:
                                                        (isDark
                                                                ? AppColors
                                                                      .darkBorder
                                                                : AppColors
                                                                      .lightBorder)
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: canAddPhotos
                                                    ? InkWell(
                                                        onTap: () =>
                                                            _takeSitePhoto(
                                                              rawIndex,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .add_a_photo_outlined,
                                                              size: 14,
                                                              color: AppColors
                                                                  .brandPeach,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                'No site photos yet. Tap to add a photo.',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: AppColors
                                                                      .brandPeach,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .photo_camera_outlined,
                                                            size: 13,
                                                            color: isDark
                                                                ? AppColors
                                                                      .textLightMuted
                                                                : AppColors
                                                                      .textDarkMuted,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              'No site inspection photos recorded yet.',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: isDark
                                                                    ? AppColors
                                                                          .textLightMuted
                                                                    : AppColors
                                                                          .textDarkMuted,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Architectural Design Deliverables (CAD, 3D Renders, BOQ, Mood Boards)
                                    Builder(
                                      builder: (context) {
                                        final assetsRaw =
                                            (p['designAssets'] as List?) ?? [];
                                        final assets = assetsRaw
                                            .map(
                                              (a) => Map<String, dynamic>.from(
                                                a as Map,
                                              ),
                                            )
                                            .toList();

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: Wrap(
                                                alignment:
                                                    WrapAlignment.spaceBetween,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .architecture_rounded,
                                                        size: 14,
                                                        color: projectAccent,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          'DESIGN DELIVERABLES',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            letterSpacing: 0.6,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isDark
                                                                ? AppColors
                                                                      .textLightMuted
                                                                : AppColors
                                                                      .textDarkMuted,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 1.5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: projectAccent
                                                              .withValues(
                                                                alpha: isDark
                                                                    ? 0.22
                                                                    : 0.14,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4.0,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '${assets.length}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                projectAccent,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (canManageDesignAssets)
                                                    InstantPressFeedback(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _openUploadDesignAsset(
                                                              rawIndex,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .cloud_upload_outlined,
                                                          size: 13,
                                                          color: AppColors
                                                              .brandPeach,
                                                        ),
                                                        label: const Text(
                                                          'Add Deliverable',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .brandPeach,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(
                                                            color: AppColors
                                                                .brandPeach
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                            width: 0.8,
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          minimumSize:
                                                              Size.zero,
                                                          tapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (assets.isNotEmpty)
                                              SizedBox(
                                                height: 82,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: assets.length,
                                                  separatorBuilder:
                                                      (context, idx) =>
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                  itemBuilder: (context, assetIdx) {
                                                    final asset =
                                                        assets[assetIdx];
                                                    final assetTitle =
                                                        (asset['title']
                                                            as String?) ??
                                                        'Design Asset';
                                                    final assetType =
                                                        (asset['type']
                                                            as String?) ??
                                                        'CAD Drawing';
                                                    final assetFormat =
                                                        (asset['format']
                                                            as String?) ??
                                                        '.DWG';
                                                    final assetVersion =
                                                        (asset['version']
                                                            as String?) ??
                                                        'v1.0';
                                                    final assetStatus =
                                                        (asset['status']
                                                            as String?) ??
                                                        'Under Client Review';

                                                    IconData typeIcon = Icons
                                                        .architecture_rounded;
                                                    final lowerType = assetType
                                                        .toLowerCase();
                                                    if (lowerType.contains(
                                                          'render',
                                                        ) ||
                                                        lowerType.contains(
                                                          '3d',
                                                        ) ||
                                                        lowerType.contains(
                                                          'max',
                                                        )) {
                                                      typeIcon = Icons
                                                          .view_in_ar_rounded;
                                                    } else if (lowerType
                                                            .contains('boq') ||
                                                        lowerType.contains(
                                                          'material',
                                                        ) ||
                                                        lowerType.contains(
                                                          'spec',
                                                        )) {
                                                      typeIcon = Icons
                                                          .table_chart_rounded;
                                                    } else if (lowerType
                                                            .contains('mood') ||
                                                        lowerType.contains(
                                                          'board',
                                                        )) {
                                                      typeIcon =
                                                          Icons.palette_rounded;
                                                    }

                                                    Color statusColor =
                                                        AppColors.brandPeach;
                                                    if (assetStatus
                                                        .toLowerCase()
                                                        .contains('approv')) {
                                                      statusColor =
                                                          AppColors.success;
                                                    } else if (assetStatus
                                                        .toLowerCase()
                                                        .contains('revis')) {
                                                      statusColor =
                                                          AppColors.error;
                                                    }

                                                    return InstantPressFeedback(
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4.0,
                                                            ),
                                                        onTap: () {
                                                          DesignAssetViewerDialog.show(
                                                            context,
                                                            asset: asset,
                                                            projectName:
                                                                projectName,
                                                            projectAccent:
                                                                projectAccent,
                                                            canManage:
                                                                canManageDesignAssets,
                                                            canDelete:
                                                                canManageDesignAssets,
                                                            onDelete: () =>
                                                                _deleteDesignAsset(
                                                                  rawIndex,
                                                                  assetIdx,
                                                                ),
                                                            onStatusChanged:
                                                                (newSt) =>
                                                                    _updateDesignAssetStatus(
                                                                      rawIndex,
                                                                      assetIdx,
                                                                      newSt,
                                                                    ),
                                                          );
                                                        },
                                                        child: Container(
                                                          width: 205,
                                                          padding:
                                                              const EdgeInsets.all(
                                                                9,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? AppColors
                                                                      .darkCardElevated
                                                                : AppColors
                                                                      .lightBackground,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4.0,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  (isDark
                                                                          ? AppColors.darkBorder
                                                                          : AppColors.lightBorder)
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                              width: 0.8,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 38,
                                                                height: double
                                                                    .infinity,
                                                                decoration: BoxDecoration(
                                                                  color: projectAccent
                                                                      .withValues(
                                                                        alpha:
                                                                            isDark
                                                                            ? 0.2
                                                                            : 0.12,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        3.0,
                                                                      ),
                                                                  border: Border.all(
                                                                    color: projectAccent
                                                                        .withValues(
                                                                          alpha:
                                                                              0.4,
                                                                        ),
                                                                    width: 0.6,
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    typeIcon,
                                                                    size: 18,
                                                                    color:
                                                                        projectAccent,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Flexible(
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 4,
                                                                              vertical: 1,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: projectAccent.withValues(
                                                                                alpha: isDark ? 0.25 : 0.15,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                2,
                                                                              ),
                                                                            ),
                                                                            child: Text(
                                                                              assetFormat,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(
                                                                                fontSize: 8.5,
                                                                                fontWeight: FontWeight.w800,
                                                                                color: projectAccent,
                                                                                letterSpacing: 0.4,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              4,
                                                                        ),
                                                                        Text(
                                                                          assetVersion,
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                8.5,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                isDark
                                                                                ? AppColors.textLightMuted
                                                                                : AppColors.textDarkMuted,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    Text(
                                                                      assetTitle,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color:
                                                                            isDark
                                                                            ? AppColors.textLightPrimary
                                                                            : AppColors.textDarkPrimary,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              5,
                                                                          height:
                                                                              5,
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                statusColor,
                                                                            shape:
                                                                                BoxShape.circle,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              4,
                                                                        ),
                                                                        Expanded(
                                                                          child: Text(
                                                                            assetStatus,
                                                                            style: TextStyle(
                                                                              fontSize: 9.5,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: statusColor,
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            else
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors
                                                            .darkCardElevated
                                                      : AppColors
                                                            .lightBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.0,
                                                      ),
                                                  border: Border.all(
                                                    color:
                                                        (isDark
                                                                ? AppColors
                                                                      .darkBorder
                                                                : AppColors
                                                                      .lightBorder)
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: canManageDesignAssets
                                                    ? InkWell(
                                                        onTap: () =>
                                                            _openUploadDesignAsset(
                                                              rawIndex,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .cloud_upload_outlined,
                                                              size: 14,
                                                              color: AppColors
                                                                  .brandPeach,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Flexible(
                                                              child: Text(
                                                                'No design deliverables published yet. Tap to attach CAD or 3D renders.',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: AppColors
                                                                      .brandPeach,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .architecture_rounded,
                                                            size: 13,
                                                            color: isDark
                                                                ? AppColors
                                                                      .textLightMuted
                                                                : AppColors
                                                                      .textDarkMuted,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              'No CAD drawings or 3D renders attached yet.',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: isDark
                                                                    ? AppColors
                                                                          .textLightMuted
                                                                    : AppColors
                                                                          .textDarkMuted,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Adaptive Progress Bar & Counter
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 2,
                                                children: [
                                                  Text(
                                                    '$progressPercent% ${AppStrings.complete}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: projectAccent,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    '($doneCount of $totalCount Stages Done)',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isDark
                                                          ? AppColors
                                                                .textLightMuted
                                                          : AppColors
                                                                .textDarkMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                totalCount == 0
                                                    ? 'Design & Planning phase — 0 stages added'
                                                    : doneCount == totalCount
                                                    ? 'All milestone stages completed'
                                                    : 'Current Stage: $activeStage',
                                                style:
                                                    AppTypography.bodySmall(
                                                      isDark,
                                                    ).copyWith(
                                                      color:
                                                          doneCount ==
                                                                  totalCount &&
                                                              totalCount > 0
                                                          ? AppColors.success
                                                          : null,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Update Progress Button (Toggles stage checklist)
                                        InstantPressFeedback(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _projects[rawIndex]['isChecklistOpen'] =
                                                    !isChecklistOpen;
                                              });
                                            },
                                            icon: Icon(
                                              isChecklistOpen
                                                  ? Icons
                                                        .keyboard_arrow_up_rounded
                                                  : Icons.checklist_rtl_rounded,
                                              size: 16,
                                              color: isChecklistOpen
                                                  ? AppColors.brandPeach
                                                  : (isDark
                                                        ? AppColors
                                                              .textLightPrimary
                                                        : AppColors
                                                              .textDarkPrimary),
                                            ),
                                            label: Text(
                                              isChecklistOpen
                                                  ? AppStrings.hideStages
                                                  : AppStrings.updateProgress,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isChecklistOpen
                                                    ? AppColors.brandPeach
                                                    : (isDark
                                                          ? AppColors
                                                                .textLightPrimary
                                                          : AppColors
                                                                .textDarkPrimary),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: isChecklistOpen
                                                    ? AppColors.brandPeach
                                                    : (isDark
                                                          ? AppColors.darkBorder
                                                          : AppColors
                                                                .lightBorder),
                                                width: 0.8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Adaptive Linear Progress Indicator
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.0),
                                      child: TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: progress,
                                        ),
                                        builder: (context, val, _) {
                                          return LinearProgressIndicator(
                                            value: val,
                                            minHeight: 6,
                                            backgroundColor: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  projectAccent,
                                                ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Expandable Stage Checklist with 3-Line Reorder Handles
                                    if (isChecklistOpen) ...[
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkCardElevated
                                              : AppColors.lightBackground,
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                          border: Border.all(
                                            color:
                                                (isDark
                                                        ? AppColors.darkBorder
                                                        : AppColors.lightBorder)
                                                    .withValues(alpha: 0.8),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              alignment:
                                                  WrapAlignment.spaceBetween,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  'PROJECT EXECUTION STAGES',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.0,
                                                    color: AppColors.brandPeach,
                                                  ),
                                                ),
                                                if (stages.isNotEmpty)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.reorder_rounded,
                                                        size: 13,
                                                        color: isDark
                                                            ? AppColors
                                                                  .textLightMuted
                                                            : AppColors
                                                                  .textDarkMuted,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Drag 3-lines to reorder',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Reorderable List of Stages or Empty State
                                            if (stages.isEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Center(
                                                  child: Text(
                                                    'No execution stages listed yet.\nAdd custom stages below to begin tracking execution progress.',
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        AppTypography.bodySmall(
                                                          isDark,
                                                        ).copyWith(
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                          height: 1.4,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            else
                                              SnappyReorderableStagesList(
                                                stages: stages,
                                                color: projectAccent,
                                                isDark: isDark,
                                                isReadOnly: !canModifyStages,
                                                onToggleStage: (stageIdx) =>
                                                    _toggleStage(
                                                      rawIndex,
                                                      stageIdx,
                                                    ),
                                                onRemoveStage: (stageIdx) =>
                                                    _removeStage(
                                                      rawIndex,
                                                      stageIdx,
                                                    ),
                                                onReorderStage:
                                                    (oldIdx, newIdx) =>
                                                        _reorderStage(
                                                          rawIndex,
                                                          oldIdx,
                                                          newIdx,
                                                        ),
                                              ),
                                            const SizedBox(height: 14),

                                            if (canModifyStages)
                                              // Inline "+ Add Stage" Input Field
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _getController(
                                                            rawIndex,
                                                          ),
                                                      keyboardType:
                                                          TextInputType.text,
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                      ),
                                                      decoration: InputDecoration(
                                                        hintText: '+ Add custom milestone stage...',
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 13,
                                                            ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: isDark
                                                                ? AppColors
                                                                      .darkBorder
                                                                : AppColors
                                                                      .lightBorder,
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                      ),
                                                      onSubmitted: (_) =>
                                                          _addNewStage(
                                                            rawIndex,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  InstantPressFeedback(
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            projectAccent,
                                                        foregroundColor:
                                                            Colors.black,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 13,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4.0,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _addNewStage(
                                                            rawIndex,
                                                          ),
                                                      child: Text(
                                                        AppStrings.addStage,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (!canModifyStages)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.lock_clock_outlined,
                                                      size: 13,
                                                      color: isDark
                                                          ? AppColors
                                                                .textLightMuted
                                                          : AppColors
                                                                .textDarkMuted,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Milestone stages managed by Site Supervisors, Designers & PMs.',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textLightMuted
                                                              : AppColors
                                                                    .textDarkMuted,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 12),
                                    // Bottom info bar: Handover Target
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Handover: ${p['handover']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textLightMuted
                                                : AppColors.textDarkMuted,
                                          ),
                                        ),
                                        Text(
                                          totalCount == 0
                                              ? '0 execution stages'
                                              : '${totalCount - doneCount} stages remaining',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: projectAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(4.0),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _expandedProjects.remove(projectKey);
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withValues(alpha: 0.03),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          border: Border.all(
                                            color: (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)
                                                .withValues(alpha: 0.4),
                                            width: 0.6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Collapse Project Details',
                                                style: TextStyle(
                                                  fontSize: 11.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppColors.textLightMuted
                                                      : AppColors.textDarkMuted,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_drop_up_rounded,
                                              size: 18,
                                              color: isDark
                                                  ? AppColors.textLightMuted
                                                  : AppColors.textDarkMuted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Left signature typology accent bar (5px)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 5.0,
                              child: Container(color: projectAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                ),
        ),
      ],
    );
  }
}
