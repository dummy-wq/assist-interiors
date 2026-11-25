import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
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
    String? leadId,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!AppPermissions.canCreateProject(
      auth.currentRole,
      user: auth.currentUser,
    )) {
      AppNotification.show(
        context,
        message:
            'Action restricted: Only Proprietor and Project Managers can create projects.',
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leads = StorageService.getLeads();

    // Check if an initial lead was passed or matches
    String? selectedLeadId = leadId;
    if (selectedLeadId == null && initialClient != null && initialClient.isNotEmpty) {
      final match = leads.firstWhere(
        (l) => (l['client'] ?? l['name']) == initialClient,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        selectedLeadId = match['id'] as String?;
      }
    }

    final nameController = TextEditingController(text: initialName);
    final clientController = TextEditingController(text: initialClient);
    final budgetController = TextEditingController(text: initialBudget);
    final areaController = TextEditingController();

    // If a lead is pre-selected and fields are blank, populate them
    if (selectedLeadId != null) {
      final leadMatch = leads.firstWhere(
        (l) => l['id'] == selectedLeadId,
        orElse: () => <String, dynamic>{},
      );
      if (leadMatch.isNotEmpty) {
        final cName = (leadMatch['client'] ?? leadMatch['name'] ?? '').toString();
        if (nameController.text.isEmpty && cName.isNotEmpty) {
          nameController.text = '$cName Residence';
        }
        if (clientController.text.isEmpty && cName.isNotEmpty) {
          clientController.text = cName;
        }
        if (budgetController.text.isEmpty) {
          final parsed = CurrencyUtils.parseAmount(leadMatch['estValue']);
          if (parsed > 0) {
            budgetController.text = '$parsed';
          }
        }
      }
    }

    Map<String, dynamic> selectedSwatch =
        initialName != null && initialName.isNotEmpty
            ? AppColors.getProjectSwatch(initialName)
            : AppColors.architecturalSwatches.first;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                                  Icons.apartment_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Initiate Turnkey Project',
                                      style: AppTypography.titleLarge(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      selectedLeadId != null
                                          ? 'Originating from Sales Pipeline'
                                          : 'Turnkey Studio Execution',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
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

                    // 1. Sales Origin Pipeline Selector
                    QuickFadeDropdown<String?>(
                      initialValue: selectedLeadId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sales Lead (Optional)',
                        prefixIcon: Icon(Icons.hub_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'None',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        ...leads.map((l) {
                          final lId = l['id'] as String;
                          final cName =
                              (l['client'] ?? l['name'] ?? 'Lead') as String;
                          return DropdownMenuItem<String?>(
                            value: lId,
                            child: Text(
                              cName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: lId == selectedLeadId
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (newId) {
                        setSheetState(() {
                          selectedLeadId = newId;
                          if (newId != null) {
                            final match = leads.firstWhere(
                              (l) => l['id'] == newId,
                              orElse: () => <String, dynamic>{},
                            );
                            if (match.isNotEmpty) {
                              final c = (match['client'] ??
                                      match['name'] ??
                                      '')
                                  .toString();
                              nameController.text = '$c Residence';
                              clientController.text = c;
                              final parsed =
                                  CurrencyUtils.parseAmount(match['estValue']);
                              if (parsed > 0) {
                                budgetController.text = '$parsed';
                              }
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Project Name
                    TextField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Project Name (e.g. DLF Magnolias 4BHK)'),
                        ),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Client & Budget
                    TextField(
                      controller: clientController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Client Name'),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9,]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Budget (₹)'),
                        ),
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Area
                    TextField(
                      controller: areaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Super Built-Up Area (sq ft)'),
                        ),
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
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppColors.architecturalSwatches.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final swatch =
                              AppColors.architecturalSwatches[index];
                          final Color swatchColor = swatch['color'] as Color;
                          final String swatchName = swatch['name'] as String;
                          final isSelected =
                              selectedSwatch['name'] == swatchName;

                          return Tooltip(
                            message: swatchName,
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
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

                    // Launch Project Button
                    InstantPressFeedback(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPeach,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          final projName = nameController.text.trim().isEmpty
                              ? 'New Project Site'
                              : nameController.text.trim();
                          final clientName =
                              clientController.text.trim().isNotEmpty
                                  ? clientController.text.trim()
                                  : 'Site Location';
                          final Color chosenColor =
                              selectedSwatch['color'] as Color;

                          final newProj = {
                            'id':
                                'proj_${DateTime.now().millisecondsSinceEpoch}',
                            'name': projName,
                            'location': clientName,
                            'client': clientName,
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
                            'originLeadId': selectedLeadId,
                            'stages': <Map<String, dynamic>>[],
                            'photos': <Map<String, dynamic>>[],
                            'designAssets': <Map<String, dynamic>>[],
                          };

                          // 1. Save Project to persistent Storage
                          final currentProjects = StorageService.getProjects();
                          if (!currentProjects
                              .any((p) => p['name'] == projName)) {
                            currentProjects.add(newProj);
                            await StorageService.saveProjects(currentProjects);
                          }

                          // 2. If originating from a sales lead, mark lead as Closed Won & link project
                          if (selectedLeadId != null) {
                            final allLeads = StorageService.getLeads();
                            final leadIdx = allLeads.indexWhere(
                              (l) => l['id'] == selectedLeadId,
                            );
                            if (leadIdx != -1) {
                              final lead = allLeads[leadIdx];
                              List<dynamic> existingNotes = [];
                              if (lead['notes'] is List) {
                                existingNotes =
                                    List.from(lead['notes'] as List);
                              }
                              existingNotes.insert(0, {
                                'date': DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(DateTime.now()),
                                'text':
                                    'Converted to Turnkey Project: "$projName". Handed over to Design & Execution.',
                              });
                              final updatedLead = {
                                ...lead,
                                'stage': 'Approved',
                                'status': 'Approved',
                                'isConverted': true,
                                'convertedToProject': projName,
                                'convertedAt':
                                    DateTime.now().toIso8601String(),
                                'notes': existingNotes,
                                'updatedAt': DateTime.now().toIso8601String(),
                              };
                              allLeads[leadIdx] = updatedLead;
                              await StorageService.saveLeads(allLeads);
                              MobileActionSheets.leadUpdatedNotifier.value =
                                  updatedLead;
                            }
                          }

                          if (!AppConstants.preExistingProjects
                              .contains(projName)) {
                            AppConstants.preExistingProjects.add(projName);
                          }

                          onProjectCreated?.call(newProj);
                          MobileActionSheets.projectCreatedNotifier.value =
                              newProj;

                          if (context.mounted) {
                            Navigator.pop(context);
                            AppNotification.show(context, message: 'Project "$projName" initialized and synced across studio!', backgroundColor: AppColors.success);
                          }
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
              ),
            );
          },
        );
      },
    );
  }
}
