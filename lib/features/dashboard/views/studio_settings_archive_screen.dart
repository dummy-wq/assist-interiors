import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/photo_archive_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../auth/state/auth_provider.dart';
import '../../team/widgets/staff_management_sheet.dart';

/// Dedicated Studio Settings, Backend Retention Governance & Project-Segmented Photo Archive Screen.
class StudioSettingsArchiveScreen extends StatefulWidget {
  const StudioSettingsArchiveScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 170),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (_, _, _) => const StudioSettingsArchiveScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<StudioSettingsArchiveScreen> createState() =>
      _StudioSettingsArchiveScreenState();
}

class _StudioSettingsArchiveScreenState
    extends State<StudioSettingsArchiveScreen> {
  bool _isExporting = false;
  PhotoArchiveExportResult? _lastExportResult;
  final Set<String> _expandedFolderNames = {};

  @override
  void initState() {
    super.initState();
    final manifest = PhotoArchiveService.buildSegmentedProjectHierarchy();
    for (final folder in manifest.projectFolders) {
      _expandedFolderNames.add(folder.folderName);
    }
  }

  Future<void> _handleDownloadAllPhotos(
    BuildContext context,
    AuthProvider auth,
  ) async {
    if (!auth.canManageTeam && auth.currentRole != UserRole.proprietor) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only the Proprietor can bulk-download all project photo archives.',
      );
      return;
    }

    final allowed = await PermissionService.requestMediaOrStorage(context);
    if (!allowed || !context.mounted) return;

    setState(() => _isExporting = true);
    try {
      final result =
          await PhotoArchiveService.downloadSegmentedProjectPhotosArchive(
        photoRetentionMonths: auth.photoRetentionMonths,
        cadRetentionMonths: auth.cadRetentionMonths,
      );
      String? savedLocation = result.zipFilePath;
      try {
        final pickedSaveUri = await FilePicker.saveFile(
          dialogTitle: 'Save Project Photo Archive',
          fileName: '${result.manifest.archiveRootName}.zip',
          bytes: Uint8List.fromList(result.zipBytes),
        );
        if (pickedSaveUri != null) {
          savedLocation = pickedSaveUri.toString();
        }
      } catch (e) {
        debugPrint('FilePicker.saveFile fallback notice: $e');
      }
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _lastExportResult = result;
      });
      HapticFeedback.mediumImpact();
      if (!context.mounted) return;
      AppNotification.show(
        context,
        message:
            'Downloaded ${result.manifest.totalPhotos} photos across ${result.manifest.totalProjects} projects (${result.manifest.archiveRootName}.zip)${savedLocation != null ? ' -> $savedLocation' : ''}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      if (!context.mounted) return;
      AppNotification.show(
        context,
        message: 'Could not export photo archive: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canConfigureRetention =
        auth.canManageTeam || auth.currentRole == UserRole.proprietor;

    final manifest = PhotoArchiveService.buildSegmentedProjectHierarchy(
      photoRetentionMonths: auth.photoRetentionMonths,
      cadRetentionMonths: auth.cadRetentionMonths,
    );

    final totalCadAssets = StorageService.getProjects().fold<int>(
      0,
      (sum, p) => sum + ((p['designAssets'] as List?)?.length ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Text(
          'Studio Settings & Media Archive',
          style: AppTypography.titleLarge(isDark).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ScreenScrollView(
        children: [
          const ScreenHeader(
            'Studio Controls, Retention & Photo Archive',
            subtitle:
                'Backend media reservation policies, segmented project photo exports, and workspace preferences',
          ),
          const SizedBox(height: ScreenLayout.headerGap),

          // Summary KPI Strip
          StatStrip(
            cards: [
              StatCard(
                title: 'Photo Retention',
                value: '${auth.photoRetentionMonths} Months',
                subtitle: auth.photoRetentionMonths == 6 ? 'Default' : 'Extended',
                icon: Icons.photo_library_rounded,
                accentColor: AppColors.brandPeach,
              ),
              StatCard(
                title: 'CAD Retention',
                value: '${auth.cadRetentionMonths} Months',
                icon: Icons.architecture_rounded,
                accentColor: AppColors.info,
              ),
              StatCard(
                title: 'Reserved Photos',
                value: '${manifest.totalPhotos} Photos',
                subtitle: '${manifest.totalProjects} folders',
                icon: Icons.folder_copy_rounded,
                accentColor: AppColors.success,
              ),
              StatCard(
                title: 'CAD & 3D Sets',
                value: '$totalCadAssets Files',
                icon: Icons.layers_rounded,
                accentColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: ScreenLayout.sectionGap),

          // 1. Backend Retention Governance Card
          _buildRetentionGovernanceCard(
            context: context,
            auth: auth,
            isDark: isDark,
            canConfigureRetention: canConfigureRetention,
          ),
          const SizedBox(height: ScreenLayout.sectionGap),

          // 2. Segmented Project Photo Hierarchy & Bulk Download Card
          _buildSegmentedPhotoArchiveCard(
            context: context,
            auth: auth,
            isDark: isDark,
            manifest: manifest,
            canDownload: canConfigureRetention,
          ),
          const SizedBox(height: ScreenLayout.sectionGap),

          // 3. Workspace Appearance, Role Swap & Notifications Card
          _buildWorkspaceControlsCard(
            context: context,
            auth: auth,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionGovernanceCard({
    required BuildContext context,
    required AuthProvider auth,
    required bool isDark,
    required bool canConfigureRetention,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPeach.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: AppColors.brandPeach,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend Media & CAD Retention Policies',
                      style: AppTypography.titleMedium(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Uploaded site photos are reserved on the backend for 6 months by default, with an option to extend to 12 months.',
                      style: AppTypography.bodySmall(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Site Photo Retention Period (6 Months Default vs 12 Months Option)
          Text(
            'UPLOADED SITE PHOTOS RETENTION PERIOD',
            style: AppTypography.labelSmall(isDark).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PillBox(
                  key: const Key('settings_photo_retention_6m'),
                  label: '6 Months (Default)',
                  icon: Icons.schedule_rounded,
                  isSelected: auth.photoRetentionMonths == 6,
                  activeColor: AppColors.brandPeach,
                  onSelected: () {
                    if (!canConfigureRetention) {
                      AppNotification.show(
                        context,
                        message:
                            'Only the Proprietor can modify backend retention policies.',
                      );
                      return;
                    }
                    HapticFeedback.selectionClick();
                    auth.setPhotoRetentionMonths(6);
                    AppNotification.show(
                      context,
                      message:
                          'Backend site photo retention set to 6 Months (Default).',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PillBox(
                  key: const Key('settings_photo_retention_12m'),
                  label: '12 Months (Extended)',
                  icon: Icons.verified_user_rounded,
                  isSelected: auth.photoRetentionMonths == 12,
                  activeColor: AppColors.success,
                  onSelected: () {
                    if (!canConfigureRetention) {
                      AppNotification.show(
                        context,
                        message:
                            'Only the Proprietor can modify backend retention policies.',
                      );
                      return;
                    }
                    HapticFeedback.selectionClick();
                    auth.setPhotoRetentionMonths(12);
                    AppNotification.show(
                      context,
                      message:
                          'Backend site photo retention extended to 12 Months.',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CAD & 3D Render Retention Period
          Text(
            'CAD DRAWINGS, GFC SETS & 3D RENDERS RETENTION PERIOD',
            style: AppTypography.labelSmall(isDark).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final months in StorageService.supportedCadRetentionMonths) ...[
                if (months != StorageService.supportedCadRetentionMonths.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: PillBox(
                    key: Key('settings_cad_retention_${months}m'),
                    label: months == 12
                        ? '12 Months (Default)'
                        : '$months Months',
                    icon: Icons.architecture_rounded,
                    isSelected: auth.cadRetentionMonths == months,
                    activeColor: AppColors.info,
                    onSelected: () {
                      if (!canConfigureRetention) {
                        AppNotification.show(
                          context,
                          message:
                              'Only the Proprietor can modify CAD retention policies.',
                        );
                        return;
                      }
                      HapticFeedback.selectionClick();
                      auth.setCadRetentionMonths(months);
                      AppNotification.show(
                        context,
                        message:
                            'Backend CAD & 3D deliverable retention set to $months Months.',
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedPhotoArchiveCard({
    required BuildContext context,
    required AuthProvider auth,
    required bool isDark,
    required ProjectPhotoArchiveManifest manifest,
    required bool canDownload,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppSizes.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPeach.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: const Icon(
                      Icons.folder_zip_rounded,
                      color: AppColors.brandPeach,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project-Segmented Photo Hierarchy Archive',
                        style: AppTypography.titleMedium(isDark).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${manifest.totalPhotos} site photos organized into ${manifest.totalProjects} project folders • Reserved for ${auth.photoRetentionMonths} months',
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                ],
              ),
              if (canDownload)
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    key: const Key('download_all_project_photos_btn'),
                    onPressed: _isExporting
                        ? null
                        : () => _handleDownloadAllPhotos(context, auth),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(
                      _isExporting
                          ? 'Packaging Archive...'
                          : 'Download All Photos (.ZIP)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPeach,
                      foregroundColor: Colors.black,
                    ),
                  ),
                )
              else
                const StatusTagPill(
                  label: 'Proprietor Exclusive Export',
                  accentColor: AppColors.warning,
                ),
            ],
          ),

          if (_lastExportResult != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archive Exported: ${_lastExportResult!.manifest.archiveRootName}.zip',
                          style: AppTypography.bodyMedium(isDark).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        if (_lastExportResult!.zipFilePath != null)
                          Text(
                            'Saved to: ${_lastExportResult!.zipFilePath}',
                            style: AppTypography.bodySmall(isDark),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Hierarchical Tree Root Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.7),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  size: 15,
                  color: AppColors.brandPeach,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${manifest.archiveRootName}/',
                    style: AppTypography.bodySmall(isDark).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPeach,
                    ),
                  ),
                ),
                StatusTagPill(
                  label: '${manifest.photoRetentionMonths}M Backend Lock',
                  accentColor: AppColors.brandPeach,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (manifest.projectFolders.isEmpty)
            const EmptyStateCard(
              icon: Icons.photo_album_outlined,
              title: 'No Project Photo Folders Available',
              message:
                  'Create a project and upload site inspection photos to populate the hierarchical archive.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: manifest.projectFolders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final folder = manifest.projectFolders[index];
                final isExpanded =
                    _expandedFolderNames.contains(folder.folderName);

                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)
                          .withValues(alpha: 0.7),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(6.0),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedFolderNames.remove(folder.folderName);
                            } else {
                              _expandedFolderNames.add(folder.folderName);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.folder_open_rounded
                                    : Icons.folder_rounded,
                                size: 18,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '├── ${folder.folderName}/',
                                      style: AppTypography.bodyMedium(
                                        isDark,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${folder.projectName} • ${folder.photos.length} Photo(s)',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              StatusTagPill(
                                label: '${folder.photos.length} files',
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : AppColors.textDarkMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        if (folder.photos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '└── (No site photos uploaded in this project folder yet)',
                              style: AppTypography.bodySmall(isDark),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                            child: Column(
                              children: [
                                for (int pIdx = 0;
                                    pIdx < folder.photos.length;
                                    pIdx++) ...[
                                  if (pIdx > 0) const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.image_outlined,
                                        size: 14,
                                        color: AppColors.brandPeach,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              folder.photos[pIdx].fileName,
                                              style: AppTypography.bodySmall(
                                                isDark,
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.textLightPrimary
                                                    : AppColors.textDarkPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${folder.photos[pIdx].title} • By ${folder.photos[pIdx].capturedBy} • Reserved until ${folder.photos[pIdx].reservedUntil}',
                                              style: AppTypography.labelSmall(
                                                isDark,
                                              ).copyWith(fontSize: 10),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusTagPill(
                                        label: folder.photos[pIdx].tag,
                                        accentColor: AppColors.info,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceControlsCard({
    required BuildContext context,
    required AuthProvider auth,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace Preferences & Demo Controls',
            style: AppTypography.titleMedium(isDark).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Theme Mode Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    auth.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 18,
                    color: AppColors.brandPeach,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    auth.isDarkMode ? 'Dark Studio Mode' : 'Light Studio Mode',
                    style: AppTypography.bodyMedium(isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: auth.isDarkMode,
                activeThumbColor: AppColors.brandPeach,
                onChanged: (_) => auth.toggleTheme(),
              ),
            ],
          ),
          const Divider(height: 20),

          // Demo Role Switcher
          Text(
            'ACTIVE DEMO ROLE',
            style: AppTypography.labelSmall(isDark).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          QuickFadeDropdown<UserRole>(
            value: auth.currentRole,
            isExpanded: true,
            items: UserRole.values
                .map(
                  (r) => DropdownMenuItem<UserRole>(
                    value: r,
                    child: Text(r.title),
                  ),
                )
                .toList(),
            onChanged: (newRole) {
              if (newRole != null) {
                auth.switchRole(newRole);
                AppNotification.show(
                  context,
                  message: 'Active demo role switched to ${newRole.title}',
                );
              }
            },
          ),
          if (auth.canManageTeam) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () =>
                    showStaffManagementSheet(context, initialTabIndex: 0),
                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                label: Text(
                  'Staff Onboarding Notifications (${auth.pendingUsers.length} Pending)',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
