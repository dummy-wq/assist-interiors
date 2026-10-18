import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canCreateProject = AppPermissions.canCreateProject(auth.currentRole);

    showModalBottomSheet(
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
                      children: AppConstants.salesPipelineStages.map((stage) {
                        final isSelected = stage == currentStage;
                        final chipColor = stage == 'Closed Won'
                            ? AppColors.success
                            : (stage == 'Lost / Dropped'
                                  ? AppColors.error
                                  : AppColors.brandPeach);

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
                                : FontWeight.w500,
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
                      }).toList(),
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
                        backgroundColor: currentStage == 'Closed Won'
                            ? AppColors.success
                            : AppColors.brandPeach,
                        foregroundColor: currentStage == 'Closed Won'
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      icon: Icon(
                        currentStage == 'Closed Won'
                            ? Icons.rocket_launch_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                      ),
                      label: Text(
                        currentStage == 'Closed Won'
                            ? (canCreateProject
                                ? 'Mark Won & Launch Project'
                                : 'Mark Won (Handover to PM)')
                            : 'Update Status to $currentStage',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        List<dynamic> existingNotes = [];
                        if (lead['notes'] is List) {
                          existingNotes = List.from(lead['notes'] as List);
                        }
                        existingNotes.insert(0, {
                          'date': DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.now()),
                          'text':
                              'Status updated to "$currentStage"${remarksCtrl.text.trim().isNotEmpty ? ": ${remarksCtrl.text.trim()}" : "."}',
                        });

                        final updatedFields = {
                          'stage': currentStage,
                          'status': currentStage,
                          'notes': existingNotes,
                          'updatedAt': DateTime.now().toIso8601String(),
                        };

                        await StorageService.updateLead(leadId, updatedFields);
                        MobileActionSheets.leadUpdatedNotifier.value = {
                          ...lead,
                          ...updatedFields,
                        };
                        onUpdated?.call();

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        if (currentStage == 'Closed Won' && canCreateProject) {
                          // Trigger Project Launch Sheet
                          MobileActionSheets.showInitiateProjectSheet(
                            context,
                            initialName: '$clientName Residence',
                            initialClient: clientName,
                            initialBudget: (lead['estValue'] as String? ?? '')
                                .replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                currentStage == 'Closed Won'
                                    ? 'Lead marked as Closed Won! Project handover pending PM/Proprietor review.'
                                    : 'Status updated to "$currentStage"!',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
