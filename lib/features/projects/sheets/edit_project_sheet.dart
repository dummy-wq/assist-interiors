import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';

class EditProjectSheet {
  EditProjectSheet._();

  static void show(
    BuildContext context, {
    required Map<String, dynamic> project,
    required void Function(Map<String, dynamic> updatedProject)
    onProjectUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameController = TextEditingController(
      text: project['name'] as String? ?? '',
    );
    final locationController = TextEditingController(
      text: project['location'] as String? ?? '',
    );
    final budgetController = TextEditingController(
      text: (project['budget'] as String? ?? '').replaceAll('₹', '').trim(),
    );
    final typeController = TextEditingController(
      text: project['type'] as String? ?? '',
    );
    final handoverController = TextEditingController(
      text: project['handover'] as String? ?? 'TBD',
    );
    final pmController = TextEditingController(
      text: project['pm'] as String? ?? 'Unassigned',
    );

    String selectedStatus = project['status'] as String? ?? 'On Track';
    if (![
      'Design and Planning',
      'On Track',
      'Delayed',
      'Completed',
    ].contains(selectedStatus)) {
      selectedStatus = 'On Track';
    }

    final currentSwatchName = project['swatchName'] as String? ?? '';
    Map<String, dynamic> selectedSwatch = AppColors.architecturalSwatches
        .firstWhere(
          (swatch) => swatch['name'] == currentSwatchName,
          orElse: () => AppColors.getProjectSwatch(nameController.text),
        );

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
                                  color: AppColors.brandPeach.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppStrings.tr('Edit Project Details'),
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

                    // Project Name
                    TextField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('Project Name'),
                        prefixIcon: const Icon(Icons.apartment_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location / Client Details
                    TextField(
                      controller: locationController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('Client & Site Location'),
                        prefixIcon: const Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scope / Typology & Budget
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: typeController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('Typology / Area'),
                              hintText: 'e.g. 5400 sq ft Villa',
                              prefixIcon: const Icon(
                                Icons.architecture_rounded,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: budgetController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('Contract Budget (₹)'),
                              prefixIcon: const Icon(
                                Icons.currency_rupee_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Dropdown
                    QuickFadeDropdown<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      dropdownColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(4.0),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.brandPeach,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('Project Status'),
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Design and Planning',
                          child: Text(AppStrings.tr('Design and Planning')),
                        ),
                        DropdownMenuItem(
                          value: 'On Track',
                          child: Text(AppStrings.tr('On Track')),
                        ),
                        DropdownMenuItem(
                          value: 'Delayed',
                          child: Text(AppStrings.tr('Delayed')),
                        ),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text(AppStrings.tr('Completed')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Handover Target & Project Manager
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: handoverController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('Target Handover Date'),
                              hintText: 'e.g. 28 Nov 2026',
                              prefixIcon: const Icon(
                                Icons.calendar_month_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pmController,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('Project Manager'),
                              prefixIcon: const Icon(Icons.person_pin_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Architectural Swatch Selection
                    Text(
                      AppStrings.tr('ARCHITECTURAL MATERIAL SWATCH'),
                      style: AppTypography.labelLarge(isDark).copyWith(
                        color: AppColors.brandPeach,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppColors.architecturalSwatches.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final swatch = AppColors.architecturalSwatches[index];
                          final Color swatchColor = swatch['color'] as Color;
                          final String swatchName = swatch['name'] as String;
                          final isSelected =
                              selectedSwatch['name'] == swatchName;

                          return Tooltip(
                            message: swatchName,
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedSwatch = swatch;
                                });
                              },
                              borderRadius: BorderRadius.circular(8.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: swatchColor,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                        : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: swatchColor.withValues(
                                        alpha: isSelected ? 0.45 : 0.2,
                                      ),
                                      blurRadius: isSelected ? 6 : 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color:
                                            ThemeData.estimateBrightnessForColor(
                                                  swatchColor,
                                                ) ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    InstantPressFeedback(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPeach,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                        onPressed: () {
                          final updatedName = nameController.text.trim().isEmpty
                              ? 'Project Site'
                              : nameController.text.trim();
                          final updatedBudget =
                              budgetController.text.trim().isNotEmpty
                              ? (budgetController.text.trim().startsWith('₹')
                                    ? budgetController.text.trim()
                                    : '₹ ${budgetController.text.trim()}')
                              : project['budget'] as String? ?? '₹ 0';

                          final Color chosenColor =
                              selectedSwatch['color'] as Color;

                          final updatedProject = Map<String, dynamic>.from(
                            project,
                          );
                          updatedProject['name'] = updatedName;
                          updatedProject['location'] =
                              locationController.text.trim().isNotEmpty
                              ? locationController.text.trim()
                              : project['location'];
                          updatedProject['type'] =
                              typeController.text.trim().isNotEmpty
                              ? typeController.text.trim()
                              : project['type'];
                          updatedProject['budget'] = updatedBudget;
                          updatedProject['status'] = selectedStatus;
                          updatedProject['isDelayed'] =
                              selectedStatus == 'Delayed';
                          updatedProject['handover'] =
                              handoverController.text.trim().isNotEmpty
                              ? handoverController.text.trim()
                              : project['handover'];
                          updatedProject['pm'] =
                              pmController.text.trim().isNotEmpty
                              ? pmController.text.trim()
                              : project['pm'];
                          updatedProject['color'] = chosenColor;
                          updatedProject['swatchName'] = selectedSwatch['name'];
                          updatedProject['material'] =
                              selectedSwatch['material'];

                          if (!AppConstants.preExistingProjects.contains(
                            updatedName,
                          )) {
                            AppConstants.preExistingProjects.add(updatedName);
                          }

                          onProjectUpdated(updatedProject);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.tr(
                                  'Project details updated successfully!',
                                ),
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          AppStrings.tr('Save Changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
}
