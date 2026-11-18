import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/photo_archive_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/pill_box.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/widgets/role_onboarding_guide.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../auth/state/auth_provider.dart';
import '../../team/widgets/staff_management_sheet.dart';
import '../views/studio_settings_archive_screen.dart';

/// Left side pane drawer enlisting studio controls (Notifications, Dark/Light Mode Switch,
/// Demo Role Swap, Language Selector), Backend Image & CAD Retention Time Periods
/// (6 Months default / 12 Months extended), and Proprietor Segmented Project Photo Archive Download.
class StudioSidePaneDrawer extends StatefulWidget {
  const StudioSidePaneDrawer({super.key});

  @override
  State<StudioSidePaneDrawer> createState() => _StudioSidePaneDrawerState();
}

class _StudioSidePaneDrawerState extends State<StudioSidePaneDrawer> {
  bool _isDownloadingArchive = false;

  Future<void> _downloadSegmentedPhotoArchive(
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

    setState(() => _isDownloadingArchive = true);
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
      setState(() => _isDownloadingArchive = false);
      HapticFeedback.mediumImpact();
      if (!context.mounted) return;
      AppNotification.show(
        context,
        message:
            'Downloaded ${result.manifest.totalPhotos} photos across ${result.manifest.totalProjects} projects (${result.manifest.archiveRootName}.zip)${savedLocation != null ? ' -> $savedLocation' : ''}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingArchive = false);
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
    final pendingCount = auth.pendingUsers.length;
    final unseenCount = auth.unseenPendingCount;

    final manifest = PhotoArchiveService.buildSegmentedProjectHierarchy(
      photoRetentionMonths: auth.photoRetentionMonths,
      cadRetentionMonths: auth.cadRetentionMonths,
    );

    return Drawer(
      key: const Key('studio_left_side_pane'),
      width: 330,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(8.0)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Brand & Active User
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                border: Border(
                  bottom: BorderSide(
                    color:
                        (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                            .withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        auth.currentRole.color.withValues(alpha: 0.2),
                    child: Icon(
                      auth.currentRole.icon,
                      color: auth.currentRole.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName,
                          style: AppTypography.titleMedium(isDark).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth.currentUser?.effectiveRoleTitle ??
                              auth.currentRole.title,
                          style: AppTypography.labelSmall(isDark).copyWith(
                            color: auth.currentRole.color,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const SyncStatusBadge(),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close Side Pane',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Controls & Retention Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Notifications (Proprietor Onboarding Requests)
                    if (auth.canManageTeam) ...[
                      _buildSectionLabel('NOTIFICATIONS & APPROVALS', isDark),
                      const SizedBox(height: 6),
                      InkWell(
                        key: const Key('proprietor_notifications_btn'),
                        borderRadius: BorderRadius.circular(6.0),
                        onTap: () {
                          Navigator.of(context).pop();
                          showStaffManagementSheet(
                            context,
                            initialTabIndex: 0,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: unseenCount > 0
                                ? AppColors.brandPeach.withValues(alpha: 0.14)
                                : (isDark
                                    ? AppColors.darkCardElevated
                                    : AppColors.lightBackground),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: unseenCount > 0
                                  ? AppColors.brandPeach
                                  : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.7),
                              width: unseenCount > 0 ? 1.0 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                pendingCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 18,
                                color: pendingCount > 0
                                    ? AppColors.brandPeach
                                    : (isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Team Onboarding Requests',
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
                                      pendingCount > 0
                                          ? '$pendingCount request(s) awaiting review'
                                          : 'All staff requests reviewed',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              if (pendingCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: unseenCount > 0
                                        ? AppColors.error
                                        : AppColors.brandPeach,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: AppTypography.labelSmall(
                                      isDark,
                                    ).copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Dark / Light Mode Switch
                    _buildSectionLabel('APPEARANCE & THEME', isDark),
                    const SizedBox(height: 6),
                    Tooltip(
                      message: 'Toggle Theme',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6.0),
                        onTap: () => auth.toggleTheme(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                          child: Row(
                            children: [
                              Icon(
                                auth.isDarkMode
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 18,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.isDarkMode
                                      ? 'Dark Mode Active'
                                      : 'Light Mode Active',
                                  style: AppTypography.bodyMedium(
                                    isDark,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textLightPrimary
                                        : AppColors.textDarkPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                key: const Key('side_pane_theme_switch'),
                                value: auth.isDarkMode,
                                activeThumbColor: AppColors.brandPeach,
                                onChanged: (_) => auth.toggleTheme(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Role Swap for Demo
                    _buildSectionLabel('DEMO ROLE SWAP', isDark),
                    const SizedBox(height: 6),
                    Tooltip(
                      message: 'Switch Demo Role',
                      child: QuickFadeDropdown<UserRole>(
                        key: const Key('side_pane_role_dropdown'),
                        value: auth.currentRole,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightCard,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            auth.currentRole.icon,
                            size: 18,
                            color: auth.currentRole.color,
                          ),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(
                              '${role.title} (${AppPermissions.getRoleAccessSummary(role)})',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(isDark).copyWith(
                                fontSize: 12,
                                fontWeight: role == auth.currentRole
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newRole) {
                          if (newRole != null) {
                            auth.switchRole(newRole);
                            AppNotification.show(
                              context,
                              message:
                                  'Active demo role switched to ${newRole.title}',
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Language Selector
                    _buildSectionLabel(AppStrings.tr('INTERFACE LANGUAGE'), isDark),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final lang in AppLanguage.values)
                          PillBox(
                            label: lang.nativeName,
                            isSelected: auth.language == lang,
                            activeColor: AppColors.brandPeach,
                            onSelected: () {
                              auth.setLanguage(lang);
                              AppNotification.show(
                                context,
                                message: 'Language set to ${lang.nativeName}',
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4b. Text Size Selector for Easier Reading
                    _buildSectionLabel(AppStrings.tr('Text Size').toUpperCase(), isDark),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: PillBox(
                            label: AppStrings.tr('Normal'),
                            isSelected: auth.textScaleFactor <= 1.05,
                            activeColor: AppColors.brandPeach,
                            onSelected: () => auth.setTextScaleFactor(1.0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: PillBox(
                            label: AppStrings.tr('Large'),
                            isSelected: auth.textScaleFactor > 1.05 &&
                                auth.textScaleFactor < 1.25,
                            activeColor: AppColors.brandPeach,
                            onSelected: () => auth.setTextScaleFactor(1.15),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: PillBox(
                            label: AppStrings.tr('Extra Large'),
                            isSelected: auth.textScaleFactor >= 1.25,
                            activeColor: AppColors.brandPeach,
                            onSelected: () => auth.setTextScaleFactor(1.30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4c. First-Time Quick Guide Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        key: const Key('side_pane_quick_guide_btn'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          RoleOnboardingGuide.show(
                            context,
                            role: auth.currentRole,
                            force: true,
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded, size: 17),
                        label: Text(AppStrings.tr('Show Quick Guide')),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Image Retention & CAD Retention Time Periods
                    _buildSectionLabel(
                      'BACKEND IMAGE RETENTION (DEFAULT 6M)',
                      isDark,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: PillBox(
                            key: const Key('side_pane_photo_retention_6m'),
                            label: '6 Months (Default)',
                            isSelected: auth.photoRetentionMonths == 6,
                            activeColor: AppColors.brandPeach,
                            onSelected: () {
                              if (!canConfigureRetention) {
                                AppNotification.show(
                                  context,
                                  message:
                                      'Only the Proprietor can change photo retention.',
                                );
                                return;
                              }
                              auth.setPhotoRetentionMonths(6);
                              AppNotification.show(
                                context,
                                message:
                                    'Site photo backend retention set to 6 Months (Default).',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: PillBox(
                            key: const Key('side_pane_photo_retention_12m'),
                            label: '12 Months',
                            isSelected: auth.photoRetentionMonths == 12,
                            activeColor: AppColors.success,
                            onSelected: () {
                              if (!canConfigureRetention) {
                                AppNotification.show(
                                  context,
                                  message:
                                      'Only the Proprietor can change photo retention.',
                                );
                                return;
                              }
                              auth.setPhotoRetentionMonths(12);
                              AppNotification.show(
                                context,
                                message:
                                    'Site photo backend retention extended to 12 Months.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildSectionLabel(
                      'CAD & 3D RENDER RETENTION PERIOD',
                      isDark,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final months
                            in StorageService.supportedCadRetentionMonths) ...[
                          if (months !=
                              StorageService.supportedCadRetentionMonths.first)
                            const SizedBox(width: 6),
                          Expanded(
                            child: PillBox(
                              key: Key('side_pane_cad_retention_${months}m'),
                              label: '${months}M',
                              isSelected: auth.cadRetentionMonths == months,
                              activeColor: AppColors.info,
                              onSelected: () {
                                if (!canConfigureRetention) {
                                  AppNotification.show(
                                    context,
                                    message:
                                        'Only the Proprietor can change CAD retention.',
                                  );
                                  return;
                                }
                                auth.setCadRetentionMonths(months);
                                AppNotification.show(
                                  context,
                                  message:
                                      'CAD & 3D retention set to $months Months.',
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 6. Proprietor Project Photo Archive Export & Full Settings Screen
                    _buildSectionLabel(
                      'PROJECT PHOTO HIERARCHY & ARCHIVE',
                      isDark,
                    ),
                    const SizedBox(height: 6),
                    if (canConfigureRetention) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          key: const Key('side_pane_download_photos_btn'),
                          onPressed: _isDownloadingArchive
                              ? null
                              : () =>
                                  _downloadSegmentedPhotoArchive(context, auth),
                          icon: _isDownloadingArchive
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.folder_zip_rounded, size: 16),
                          label: Text(
                            _isDownloadingArchive
                                ? 'Packaging Folders...'
                                : 'Download All Photos (${manifest.totalPhotos} in ${manifest.totalProjects} Folders)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        key: const Key('side_pane_open_settings_btn'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          StudioSettingsArchiveScreen.open(context);
                        },
                        icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                        label: const Text('Studio Settings & Photo Archive'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer: Sign Out Button
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                border: Border(
                  top: BorderSide(
                    color:
                        (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                            .withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
              ),
              child: Tooltip(
                message: 'Sign Out',
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    key: const Key('side_pane_sign_out_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.65),
                        width: 0.9,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      auth.logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: Text(AppStrings.tr('Sign Out')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: AppTypography.labelSmall(isDark).copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
      ),
    );
  }
}
