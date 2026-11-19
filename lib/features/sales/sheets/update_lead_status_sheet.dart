import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/models/project_model.dart';
import '../services/sales_pipeline_service.dart';
import '../../dashboard/views/main_dashboard_screen.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class UpdateLeadStatusSheet {
  UpdateLeadStatusSheet._();

  static void show(
    BuildContext context,
    Map<String, dynamic> lead, {
    VoidCallback? onUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final leadId = lead['id'] as String;
    String currentStage =
        (lead['stage'] ?? lead['status'] ?? 'New Inquiry') as String;
    final remarksCtrl = TextEditingController();

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: AppSizes.sheetBottomPadding(context),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandPeach.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Icon(
                                Icons.timeline_rounded,
                                color: AppColors.brandPeach,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Pipeline Status',
                                  style: AppTypography.titleLarge(isDark),
                                ),
                                Text(
                                  'Client: $clientName',
                                  style: AppTypography.bodySmall(isDark),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Pipeline Milestone Stage',
                      style: AppTypography.labelLarge(isDark),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: () {
                        final stagesList = <String>[
                          ...AppConstants.salesPipelineStages,
                          for (final legacy in const [
                            'Site Visit Scheduled',
                            'Closed Won',
                          ])
                            if (!AppConstants.salesPipelineStages.contains(
                              legacy,
                            ))
                              legacy,
                        ];
                        if (currentStage.isNotEmpty &&
                            !stagesList.contains(currentStage)) {
                          stagesList.add(currentStage);
                        }
                        return stagesList.map((stage) {
                          final isSelected = stage == currentStage;
                          final isAppr = SalesPipelineService.isApproved(stage);
                          final chipColor = isAppr
                              ? AppColors.success
                              : (stage == 'Lost / Dropped'
                                    ? AppColors.error
                                    : (stage == 'BOQ'
                                          ? AppColors.info
                                          : (stage.contains('Visit')
                                                ? AppColors.brandOrange
                                                : AppColors.brandPeach)));

                          return ChoiceChip(
                            label: Text(stage),
                            selected: isSelected,
                            selectedColor: chipColor.withValues(alpha: 0.25),
                            backgroundColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? chipColor
                                  : (isDark
                                        ? AppColors.textLightPrimary
                                        : AppColors.textDarkPrimary),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              side: BorderSide(
                                color: isSelected
                                    ? chipColor
                                    : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => currentStage = stage);
                              }
                            },
                          );
                        }).toList();
                      }(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: remarksCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Status Transition Note (Optional)',
                        hintText: 'e.g. Site visit completed, client approved contemporary Italian theme',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SalesPipelineService.isApproved(currentStage)
                            ? AppColors.success
                            : AppColors.brandPeach,
                        foregroundColor: SalesPipelineService.isApproved(currentStage)
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      icon: Icon(
                        SalesPipelineService.isApproved(currentStage)
                            ? Icons.rocket_launch_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                      ),
                      label: Text(
                        currentStage == 'Closed Won'
                            ? 'Mark Won & Update Projects'
                            : (SalesPipelineService.isApproved(currentStage)
                                ? 'Approve & Move to Projects'
                                : 'Update Status to $currentStage'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final isAppr = SalesPipelineService.isApproved(currentStage);
                        Map<String, dynamic>? affectedProject;

                        if (isAppr) {
                          final result =
                              await SalesPipelineService.approveLeadAndMoveToProjects(
                            lead,
                            approvedStage: currentStage,
                            transitionNote: remarksCtrl.text.trim().isNotEmpty
                                ? 'Status updated to "$currentStage": ${remarksCtrl.text.trim()}'
                                : null,
                          );
                          affectedProject = result['project'];
                        } else if (currentStage == 'Lost / Dropped') {
                          final currentProjects = StorageService.getProjects();
                          final leadConvertedName =
                              lead['convertedToProject'] as String?;
                          int existingIdx = currentProjects.indexWhere(
                            (p) =>
                                (p['originLeadId'] != null &&
                                    p['originLeadId'] == leadId) ||
                                (leadConvertedName != null &&
                                    p['name'] == leadConvertedName),
                          );
                          if (existingIdx != -1) {
                            final existing = Map<String, dynamic>.from(
                              currentProjects[existingIdx],
                            );
                            if (existing['status'] == 'Design and Planning' ||
                                existing['status'] == 'New') {
                              existing['status'] = 'Cancelled';
                              currentProjects[existingIdx] = existing;
                              affectedProject = existing;
                              await StorageService.saveProjects(currentProjects);
                              await BackendManager.instance.updateProject(
                                ProjectModel.fromMap(existing),
                              );
                              MobileActionSheets.projectUpdatedNotifier.value =
                                  existing;
                            }
                          }
                          await SalesPipelineService.updateLeadStage(
                            lead: lead,
                            newStage: currentStage,
                            note: remarksCtrl.text.trim().isNotEmpty
                                ? 'Status updated to "$currentStage": ${remarksCtrl.text.trim()}'
                                : 'Lead marked as Lost / Dropped.',
                          );
                        } else {
                          await SalesPipelineService.updateLeadStage(
                            lead: lead,
                            newStage: currentStage,
                            note: remarksCtrl.text.trim().isNotEmpty
                                ? 'Status updated to "$currentStage": ${remarksCtrl.text.trim()}'
                                : 'Status updated to "$currentStage".',
                          );
                        }

                        onUpdated?.call();

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        AppNotification.show(context, message: isAppr
                                  ? 'Lead approved! Project "${affectedProject?['name'] ?? clientName}" is live across Projects, Design, Materials & Accounts.'
                                  : 'Status updated to "$currentStage"!', backgroundColor: AppColors.success, action: isAppr
                                ? SnackBarAction(
                                    label: 'VIEW IN PROJECTS',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      MainDashboardScreen.navigateToTab(2);
                                    },
                                  )
                                : null);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
