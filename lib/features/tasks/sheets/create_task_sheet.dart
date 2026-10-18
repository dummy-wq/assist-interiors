import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class CreateTaskSheet {
  CreateTaskSheet._();

  static const List<String> departments = [
    'Design & Architecture',
    'Site & Execution',
    'Procurement & Vendors',
    'Accounts & Billing',
    'Client Servicing',
    'General Management',
  ];

  static const List<String> priorities = ['Low', 'Medium', 'High', 'Urgent'];

  static void show(
    BuildContext context, {
    void Function(Map<String, dynamic> newTask)? onTaskCreated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    // Dynamically retrieve available projects
    final List<String> projectList = [];
    final storedProjects = StorageService.getProjects();
    for (final p in storedProjects) {
      final name = p['name']?.toString();
      if (name != null && name.isNotEmpty && !projectList.contains(name)) {
        projectList.add(name);
      }
    }
    for (final p in AppConstants.preExistingProjects) {
      if (!projectList.contains(p)) {
        projectList.add(p);
      }
    }
    if (projectList.isEmpty) {
      projectList.add('General Deliverable');
    }

    // Dynamically retrieve available staff for Assignee dropdown
    final List<String> staffList = [
      'Unassigned',
      'Rajesh Sharma (Proprietor)',
      'Ananya Sen (Project Manager)',
      'Vikram Malhotra (Designer)',
      'Suresh Kumar (Site Supervisor)',
      'Pooja Iyer (Accounts)',
      'Kavita Reddy (Sales)',
    ];
    final approvedUsers = StorageService.getApprovedUsers();
    for (final u in approvedUsers) {
      final name = u['fullName']?.toString();
      final role = u['role']?.toString();
      if (name != null && name.isNotEmpty) {
        final entry = role != null && role.isNotEmpty ? '$name ($role)' : name;
        if (!staffList.contains(entry) &&
            !staffList.any((s) => s.startsWith(name))) {
          staffList.add(entry);
        }
      }
    }

    String selectedProject = projectList.first;
    String selectedAssignee = staffList.first;
    String selectedDepartment = departments[1]; // 'Site & Execution' default
    String selectedPriority = 'Medium';
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 2));
    String? attachedPhotoName;
    String? attachedPhotoUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isUrgent = selectedPriority == 'Urgent';

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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? AppColors.error.withValues(alpha: 0.15)
                                      : AppColors.brandPeach.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Icon(
                                  isUrgent
                                      ? Icons.warning_rounded
                                      : Icons.task_alt_rounded,
                                  color: isUrgent
                                      ? AppColors.error
                                      : AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Create Project Task',
                                  style: AppTypography.titleLarge(isDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Associated Project (MUST remain first DropdownButtonFormField for widget tests)
                    QuickFadeDropdown<String>(
                      isExpanded: true,
                      initialValue: selectedProject,
                      dropdownColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(4.0),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandPeach,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Associated Project',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      items: projectList.map((project) {
                        return DropdownMenuItem<String>(
                          value: project,
                          child: Text(
                            project,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedProject = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Task Title
                    TextField(
                      controller: titleController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'Task Description / Deliverable',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Task Description / Scope
                    TextField(
                      controller: descriptionController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description / Scope of Work',
                        hintText: 'Details on requirements, material specs, or site milestones...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 36),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Department Dropdown
                    QuickFadeDropdown<String>(
                      isExpanded: true,
                      initialValue: selectedDepartment,
                      dropdownColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(4.0),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandPeach,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(
                            dept,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedDepartment = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 5. Priority Dropdown (Low, Medium, High, Urgent)
                    QuickFadeDropdown<String>(
                      isExpanded: true,
                      initialValue: selectedPriority,
                      dropdownColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(4.0),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandPeach,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Priority Level',
                        prefixIcon: Icon(
                          isUrgent
                              ? Icons.warning_rounded
                              : Icons.flag_outlined,
                          color: isUrgent ? AppColors.error : null,
                        ),
                        enabledBorder: isUrgent
                            ? OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              )
                            : null,
                      ),
                      items: priorities.map((p) {
                        Color? itemColor;
                        if (p == 'Urgent') itemColor = AppColors.error;
                        if (p == 'High') itemColor = AppColors.warning;
                        if (p == 'Medium') itemColor = AppColors.info;
                        if (p == 'Low') itemColor = AppColors.success;

                        return DropdownMenuItem<String>(
                          value: p,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  p == 'Urgent'
                                      ? 'Urgent (Critical / Blocker)'
                                      : p,
                                  style: TextStyle(
                                    fontWeight: p == 'Urgent'
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: p == 'Urgent'
                                        ? AppColors.error
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedPriority = val;
                          });
                        }
                      },
                    ),

                    // Urgent Red Alert Banner
                    if (isUrgent) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'URGENT: This task will be flagged with high-visibility red alert and prioritized across site teams.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 6. Assignee Dropdown
                    QuickFadeDropdown<String>(
                      isExpanded: true,
                      initialValue: selectedAssignee,
                      dropdownColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(4.0),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandPeach,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Assignee',
                        prefixIcon: Icon(Icons.person_pin_circle_outlined),
                      ),
                      items: staffList.map((person) {
                        return DropdownMenuItem<String>(
                          value: person,
                          child: Text(
                            person,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedAssignee = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 7. Due Date with Calendar Selector
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.brandPeach,
                                  onPrimary: Colors.black,
                                  surface: isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard,
                                  onSurface: isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(4.0),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.brandPeach,
                          ),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(selectedDueDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textLightPrimary
                                : AppColors.textDarkPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 8. Optional Photo / Reference Attachment
                    if (attachedPhotoName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: AppColors.brandPeach.withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.brandPeach.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: AppColors.brandPeach,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    attachedPhotoName!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1.5),
                                  const Text(
                                    'Visual reference attached to task',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.brandPeach,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Remove Photo',
                              onPressed: () {
                                setModalState(() {
                                  attachedPhotoName = null;
                                  attachedPhotoUrl = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          _showAttachPhotoDialog(context, (name, url) {
                            setModalState(() {
                              attachedPhotoName = name;
                              attachedPhotoUrl = url;
                            });
                          });
                        },
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 16,
                        ),
                        label: const Text('Attach Reference Photo (Optional)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.textLightSecondary
                              : AppColors.textDarkSecondary,
                          side: BorderSide(
                            color:
                                (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Submit Button
                    InstantPressFeedback(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUrgent
                              ? AppColors.error
                              : AppColors.brandPeach,
                          foregroundColor: isUrgent
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                        onPressed: () {
                          final taskTitle = titleController.text.trim();
                          if (taskTitle.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a task title.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final formattedDueDate = DateFormat('dd MMM yyyy')
                              .format(selectedDueDate);
                          final assignedName = selectedAssignee.contains('(')
                              ? selectedAssignee.split('(').first.trim()
                              : selectedAssignee;

                          final newTask = {
                            'title': taskTitle,
                            'description': descriptionController.text.trim(),
                            'department': selectedDepartment,
                            'project': selectedProject,
                            'assignee': assignedName,
                            'deadline': formattedDueDate,
                            'dueDate': formattedDueDate,
                            'status': 'In Progress',
                            'priority': selectedPriority,
                            'completed': false,
                            'photoUrl': attachedPhotoUrl,
                            'photoLabel': attachedPhotoName,
                            'color': selectedPriority == 'Urgent'
                                ? AppColors.error
                                : (selectedPriority == 'High'
                                      ? AppColors.warning
                                      : (selectedPriority == 'Low'
                                            ? AppColors.success
                                            : AppColors.brandPeach)),
                          };

                          onTaskCreated?.call(newTask);
                          MobileActionSheets.taskCreatedNotifier.value =
                              newTask;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task added to $selectedProject!'),
                              backgroundColor: selectedPriority == 'Urgent'
                                  ? AppColors.error
                                  : AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text(
                          'Add Task',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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

  static void _showAttachPhotoDialog(
    BuildContext context,
    void Function(String name, String url) onSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customNameController = TextEditingController();

    final presetReferences = [
      {
        'label': 'Site Framing & Drywall Elevation',
        'sub': 'Civil & Structural layout',
        'icon': Icons.architecture_rounded,
      },
      {
        'label': 'False Ceiling Profile & LED Cove Spec',
        'sub': 'Electrical ceiling drawing',
        'icon': Icons.light_mode_outlined,
      },
      {
        'label': 'Kitchen Quartz Countertop Alignment',
        'sub': 'Stone & fabrication detail',
        'icon': Icons.countertops_rounded,
      },
      {
        'label': 'Master Wardrobe Carcase Joinery',
        'sub': 'Carpentry millwork reference',
        'icon': Icons.chair_rounded,
      },
      {
        'label': 'Electrical Switchboard Conduit Spec',
        'sub': 'Wiring and breaker layout',
        'icon': Icons.electrical_services_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.brandPeach,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Task Photo / Blueprint',
                        style: AppTypography.titleMedium(isDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Choose an architectural reference or specify a custom photo label:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textLightMuted
                      : AppColors.textDarkMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...presetReferences.map((ref) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandPeach.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Icon(
                      ref['icon'] as IconData,
                      size: 16,
                      color: AppColors.brandPeach,
                    ),
                  ),
                  title: Text(
                    ref['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                  subtitle: Text(
                    ref['sub'] as String,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                  ),
                  onTap: () {
                    onSelected(
                      ref['label'] as String,
                      'asset://mock/${ref['label']}',
                    );
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: customNameController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Or enter custom photo / drawing name...',
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.check_rounded,
                      color: AppColors.brandPeach,
                    ),
                    onPressed: () {
                      final text = customNameController.text.trim();
                      if (text.isNotEmpty) {
                        onSelected(text, 'asset://mock/$text');
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    onSelected(val.trim(), 'asset://mock/${val.trim()}');
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
