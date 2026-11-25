import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/custom_entry_dropdown.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/spreadsheet_service.dart';
import '../../dashboard/views/main_dashboard_screen.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class AddLeadSheet {
  AddLeadSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final scopeController = TextEditingController();
    final locationController = TextEditingController();
    final referrerController = TextEditingController();
    final reminderNoteController = TextEditingController();

    String selectedReferralSource = 'Client Referral';
    String selectedStage = 'Lead';
    DateTime selectedNextCallDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedNextCallTime = const TimeOfDay(hour: 11, minute: 30);
    bool hasReminder = true;
    bool autoCreateProject = true;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: AppSizes.sheetShape,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final nextCallDateFormatted = DateFormat('dd MMM yyyy')
                .format(selectedNextCallDate);
            final nextCallTimeFormatted = selectedNextCallTime.format(context);

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
                                  Icons.person_add_alt_1_rounded,
                                  color: AppColors.brandPeach,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Add Prospective Lead',
                                    style: AppTypography.titleLarge(isDark),
                                  ),
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
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Client / Company Name'),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\- ]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Phone Number'),
                        ),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scopeController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Project Scope (e.g. 4BHK Villa / 5000 sq ft)',
                          ),
                        ),
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Site Location / City'),
                        ),
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Referral Vertical Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.share_location_rounded,
                                size: 16,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'REFERRAL & LEAD SOURCE',
                                style: AppTypography.labelLarge(isDark)
                                    .copyWith(
                                      color: AppColors.brandPeach,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomEntryDropdown(
                            value: selectedReferralSource,
                            options: AppConstants.salesReferralSources,
                            customFieldLabel: 'Custom Referral Channel',
                            customFieldHint: 'Enter referral source...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Lead Origin / Referral Channel',
                              prefixIcon: Icon(Icons.diversity_3_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(
                                () => selectedReferralSource = val,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: referrerController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Referrer Name / Partner Details (Optional)',
                                ),
                              ),
                              prefixIcon: Icon(Icons.handshake_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Current Status & Next Call Date with Reminder Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.alarm_on_rounded,
                                size: 16,
                                color: AppColors.brandPeach,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'STATUS & NEXT CALL REMINDER',
                                style: AppTypography.labelLarge(isDark)
                                    .copyWith(
                                      color: AppColors.brandPeach,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomEntryDropdown(
                            value: selectedStage,
                            options: AppConstants.salesPipelineStages,
                            customFieldLabel: 'Custom Pipeline Status',
                            customFieldHint: 'Enter custom stage...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Initial Pipeline Status',
                              prefixIcon: Icon(Icons.timeline_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() => selectedStage = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    nextCallDateFormatted,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedNextCallDate,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      setModalState(
                                        () => selectedNextCallDate = picked,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    nextCallTimeFormatted,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () async {
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: selectedNextCallTime,
                                    );
                                    if (pickedTime != null) {
                                      setModalState(
                                        () => selectedNextCallTime = pickedTime,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: reminderNoteController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('Call Reminder / Follow-up Note'),
                              ),
                              hintText: 'e.g. Confirm 3D render presentation & site recce',
                              prefixIcon: Icon(Icons.edit_note_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: autoCreateProject
                              ? AppColors.brandPeach.withValues(alpha: 0.5)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 18,
                            color: AppColors.brandPeach,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-initialize Turnkey Project',
                                  style: AppTypography.bodySmall(isDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: autoCreateProject
                                        ? AppColors.brandPeach
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Provisions project, moodboard & 10% advance invoice',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? AppColors.textLightSecondary
                                        : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: autoCreateProject,
                            activeThumbColor: AppColors.brandPeach,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              setModalState(() => autoCreateProject = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Save Lead to Pipeline'),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        const budgetStr = '₹ 25L';

                        final leadId =
                            'lead_${DateTime.now().millisecondsSinceEpoch}';

                        String projName = '';
                        Map<String, dynamic>? newProj;

                        if (autoCreateProject) {
                          projName = '$name Residence';
                          final swatch = AppColors.getProjectSwatch(projName);
                          final chosenColor = swatch['color'] as Color;

                          newProj = {
                            'id':
                                'proj_${DateTime.now().millisecondsSinceEpoch}',
                            'name': projName,
                            'location': locationController.text.trim().isNotEmpty
                                ? locationController.text.trim()
                                : 'Site Location',
                            'client': name,
                            'category': 'Residential',
                            'type': scopeController.text.trim().isNotEmpty
                                ? scopeController.text.trim()
                                : 'Turnkey Site',
                            'area': locationController.text.trim().isNotEmpty
                                ? locationController.text.trim()
                                : 'Site Measurement Pending',
                            'budget': budgetStr,
                            'status': 'Design and Planning',
                            'isDelayed': false,
                            'startDate': DateFormat('dd MMM yyyy')
                                .format(DateTime.now()),
                            'endDate': 'TBD',
                            'progress': 0.05,
                            'spent': '₹ 0',
                            'pm': 'Unassigned',
                            'supervisor': 'Unassigned',
                            'handover': 'TBD',
                            'color': chosenColor,
                            'swatchName': swatch['name'],
                            'material': swatch['material'],
                            'isChecklistOpen': false,
                            'originLeadId': leadId,
                            'stages': <Map<String, dynamic>>[
                              {
                                'title':
                                    'Site Measurement & As-Built CAD',
                                'isDone': false,
                              },
                              {
                                'title':
                                    'Concept 3D & Moodboard Sign-off',
                                'isDone': false,
                              },
                              {
                                'title':
                                    'Civil Demolition & Wet Masonry',
                                'isDone': false,
                              },
                              {
                                'title':
                                    'False Ceiling Framing & Laser Alignment',
                                'isDone': false,
                              },
                              {
                                'title':
                                    'Modular Joinery & PU Finishing',
                                'isDone': false,
                              },
                            ],
                            'photos': <Map<String, dynamic>>[],
                            'designAssets': <Map<String, dynamic>>[],
                            'timelineSpreadsheet': SpreadsheetService
                                .generateDefaultTimelineForProject(projName)
                                .toMap(),
                          };

                          final currentProjects = StorageService.getProjects();
                          if (!currentProjects
                              .any((p) => p['name'] == projName)) {
                            currentProjects.insert(0, newProj);
                            await StorageService.saveProjects(currentProjects);
                          }

                          if (!AppConstants.preExistingProjects
                              .contains(projName)) {
                            AppConstants.preExistingProjects.insert(0, projName);
                          }
                        }

                        final newLead = {
                          'id': leadId,
                          'client': name,
                          'name': name,
                          'phone': phoneController.text.trim().isNotEmpty
                              ? phoneController.text.trim()
                              : '+91 98000 11111',
                          'scope': scopeController.text.trim().isNotEmpty
                              ? scopeController.text.trim()
                              : 'Turnkey Scope',
                          'estValue': budgetStr,
                          'location': locationController.text.trim().isNotEmpty
                              ? locationController.text.trim()
                              : 'Site Consultation Pending',
                          'referralSource': selectedReferralSource,
                          'referralBy': referrerController.text.trim(),
                          'stage': selectedStage,
                          'status': selectedStage,
                          'nextCallDate': nextCallDateFormatted,
                          'nextCallTime': nextCallTimeFormatted,
                          'callScheduledAt': DateTime.now().toIso8601String(),
                          'reminderNote': reminderNoteController.text.trim(),
                          'hasReminder': hasReminder,
                          'isReminderDismissed': false,
                          'isConverted': autoCreateProject,
                          'convertedToProject':
                              autoCreateProject ? projName : null,
                          'convertedAt': autoCreateProject
                              ? DateTime.now().toIso8601String()
                              : null,
                          'notes': <Map<String, dynamic>>[
                            {
                              'date': DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(DateTime.now()),
                              'text': autoCreateProject
                                  ? 'Lead captured via $selectedReferralSource${referrerController.text.trim().isNotEmpty ? " (Ref: ${referrerController.text.trim()})" : ""}. Turnkey Project "$projName" automatically initialized in studio pipeline.'
                                  : 'Lead captured via $selectedReferralSource${referrerController.text.trim().isNotEmpty ? " (Ref: ${referrerController.text.trim()})" : ""}. Initial status: $selectedStage.',
                            },
                          ],
                          'color': AppColors.brandPeach,
                          'date': DateFormat('dd MMM yyyy')
                              .format(DateTime.now()),
                        };
                        final allLeads = StorageService.getLeads();
                        allLeads.insert(0, newLead);
                        await StorageService.saveLeads(allLeads);
                        MobileActionSheets.leadCreatedNotifier.value = newLead;

                        if (autoCreateProject && newProj != null) {
                          MobileActionSheets.projectCreatedNotifier.value =
                              newProj;
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          AppNotification.show(context, message: autoCreateProject
                                    ? 'Lead "$name" saved & Turnkey Project "$projName" initialized!'
                                    : 'Lead "$name" saved to pipeline with call reminder for $nextCallDateFormatted!', backgroundColor: AppColors.success, action: autoCreateProject
                                  ? SnackBarAction(
                                      label: 'VIEW IN PROJECTS',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        MainDashboardScreen.navigateToTab(2);
                                      },
                                    )
                                  : null);
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
