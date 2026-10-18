import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class AssignMilestoneSheet {
  AssignMilestoneSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskController = TextEditingController();
    final assigneeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: AppSizes.sheetBottomPadding(context),
          ),
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
                          color: AppColors.brandPeach.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.brandPeach,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Assign Milestone / Task',
                        style: AppTypography.titleLarge(isDark),
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
              TextField(
                controller: taskController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task / Milestone Description',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assigneeController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Assignee (Supervisor / Designer / Vendor)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPeach,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Dispatch Task Milestone'),
                onPressed: () {
                  final title = taskController.text.trim();
                  final assignee = assigneeController.text.trim();
                  if (title.isEmpty) return;
                  final newMilestone = {
                    'id': 'milestone_${DateTime.now().millisecondsSinceEpoch}',
                    'title': title,
                    'task': title,
                    'project': AppConstants.preExistingProjects.isNotEmpty
                        ? AppConstants.preExistingProjects.first
                        : 'General Site',
                    'assignee': assignee.isNotEmpty ? assignee : 'Site Team',
                    'daysLeft': '3 Days',
                    'deadline': 'Pending',
                    'status': 'In Progress',
                    'color': AppColors.info,
                    'statusColor': AppColors.info,
                  };
                  final allMilestones = StorageService.getMilestones();
                  allMilestones.insert(0, newMilestone);
                  StorageService.saveMilestones(allMilestones);
                  MobileActionSheets.milestoneCreatedNotifier.value =
                      newMilestone;

                  // Cross-dispatch into Tasks pipeline
                  final newTask = {
                    'id': 'task_${DateTime.now().millisecondsSinceEpoch}',
                    'title': title,
                    'project': AppConstants.preExistingProjects.isNotEmpty
                        ? AppConstants.preExistingProjects.first
                        : 'General Deliverable',
                    'assignee': assignee.isNotEmpty ? assignee : 'Site Team',
                    'deadline': 'In 3 Days',
                    'status': 'In Progress',
                    'completed': false,
                    'priority': 'High',
                    'color': AppColors.info,
                  };
                  MobileActionSheets.taskCreatedNotifier.value = newTask;

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Milestone scheduled and task dispatched to team!',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
