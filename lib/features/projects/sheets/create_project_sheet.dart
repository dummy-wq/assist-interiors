import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class CreateProjectSheet {
  CreateProjectSheet._();

  static void show(
    BuildContext context, {
    void Function(Map<String, dynamic> newProject)? onProjectCreated,
    String? initialName,
    String? initialClient,
    String? initialBudget,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canCreateProject(auth.currentRole)) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Project Managers can create projects.',
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: initialName);
    final clientController = TextEditingController(text: initialClient);
    final budgetController = TextEditingController(text: initialBudget);
    final areaController = TextEditingController();
    Map<String, dynamic> selectedSwatch =
        initialName != null && initialName.isNotEmpty
        ? AppColors.getProjectSwatch(initialName)
        : AppColors.architecturalSwatches.first;

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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandPeach.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.brandPeach,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Initiate Turnkey Project',
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
              TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Project Name (e.g. DLF Magnolias 4BHK)',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: clientController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Client Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Budget (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Super Built-Up Area (sq ft)',
                  prefixIcon: Icon(Icons.square_foot_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Architectural Material Swatch Selector
              Text(
                'Material Palette Swatch',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textLightMuted
                      : AppColors.textDarkMuted,
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setPickerState) {
                  return SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppColors.architecturalSwatches.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final swatch = AppColors.architecturalSwatches[index];
                        final Color swatchColor = swatch['color'] as Color;
                        final String swatchName = swatch['name'] as String;
                        final isSelected = selectedSwatch['name'] == swatchName;

                        return Tooltip(
                          message: swatchName,
                          child: InkWell(
                            onTap: () {
                              setPickerState(() {
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
                                      ? (isDark ? Colors.white : Colors.black87)
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
                  );
                },
              ),
              const SizedBox(height: 20),
              InstantPressFeedback(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPeach,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final projName = nameController.text.trim().isEmpty
                        ? 'New Project Site'
                        : nameController.text.trim();
                    final Color chosenColor = selectedSwatch['color'] as Color;
                    final newProj = {
                      'name': projName,
                      'location': clientController.text.trim().isNotEmpty
                          ? clientController.text.trim()
                          : 'Site Location',
                      'category': 'Residential',
                      'status': 'Design and Planning',
                      'isDelayed': false,
                      'type': areaController.text.trim().isNotEmpty
                          ? '${areaController.text.trim()} sq ft Turnkey'
                          : 'Turnkey Site',
                      'budget': budgetController.text.trim().isNotEmpty
                          ? '₹ ${budgetController.text.trim()}'
                          : '₹ 0',
                      'spent': '₹ 0',
                      'pm': 'Unassigned',
                      'supervisor': 'Unassigned',
                      'handover': 'TBD',
                      'color': chosenColor,
                      'swatchName': selectedSwatch['name'],
                      'material': selectedSwatch['material'],
                      'isChecklistOpen': false,
                      'stages': <Map<String, dynamic>>[],
                    };
                    if (!AppConstants.preExistingProjects.contains(projName)) {
                      AppConstants.preExistingProjects.add(projName);
                    }
                    onProjectCreated?.call(newProj);
                    MobileActionSheets.projectCreatedNotifier.value = newProj;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Project "$projName" initialized!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Launch Project',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
