import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class AddLeadSheet {
  AddLeadSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final scopeController = TextEditingController();
    final budgetController = TextEditingController();
    final locationController = TextEditingController();
    final referrerController = TextEditingController();
    final reminderNoteController = TextEditingController();

    String selectedReferralSource = 'Client Referral';
    String selectedStage = 'New Inquiry';
    DateTime selectedNextCallDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedNextCallTime = const TimeOfDay(hour: 11, minute: 30);
    bool hasReminder = true;

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
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.brandPeach,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add Prospective Lead',
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
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Client / Company Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\- ]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: budgetController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Est. Budget (e.g. ₹60L)',
                              prefixIcon: Icon(Icons.currency_rupee_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: scopeController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Project Scope (e.g. 4BHK Villa / 5000 sq ft)',
                              prefixIcon: Icon(Icons.home_work_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            keyboardType: TextInputType.streetAddress,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Site Location / City',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                        ),
                      ],
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
                          QuickFadeDropdown<String>(
                            initialValue: selectedReferralSource,
                            decoration: const InputDecoration(
                              labelText: 'Lead Origin / Referral Channel',
                              prefixIcon: Icon(Icons.diversity_3_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                            items: AppConstants.salesReferralSources.map((
                              source,
                            ) {
                              return DropdownMenuItem(
                                value: source,
                                child: Text(
                                  source,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(
                                  () => selectedReferralSource = val,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: referrerController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText:
                                  'Referrer Name / Partner Details (Optional)',
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
                          QuickFadeDropdown<String>(
                            initialValue: selectedStage,
                            decoration: const InputDecoration(
                              labelText: 'Initial Pipeline Status',
                              prefixIcon: Icon(Icons.timeline_rounded),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                            ),
                            items: AppConstants.salesPipelineStages.map((stg) {
                              return DropdownMenuItem(
                                value: stg,
                                child: Text(
                                  stg,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedStage = val);
                              }
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
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
                              labelText: 'Call Reminder / Follow-up Note',
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
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Save Lead to Pipeline'),
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final budgetRaw = budgetController.text.trim();
                        final budgetStr = budgetRaw.isNotEmpty
                            ? (budgetRaw.startsWith('₹')
                                  ? budgetRaw
                                  : '₹ $budgetRaw')
                            : '₹ 25L';

                        final newLead = {
                          'id': 'lead_${DateTime.now().millisecondsSinceEpoch}',
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
                          'reminderNote': reminderNoteController.text.trim(),
                          'hasReminder': hasReminder,
                          'isReminderDismissed': false,
                          'notes': <Map<String, dynamic>>[
                            {
                              'date': DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(DateTime.now()),
                              'text':
                                  'Lead captured via $selectedReferralSource${referrerController.text.trim().isNotEmpty ? " (Ref: ${referrerController.text.trim()})" : ""}. Initial status: $selectedStage.',
                            },
                          ],
                          'color': AppColors.brandPeach,
                          'date': DateFormat('dd MMM yyyy')
                              .format(DateTime.now()),
                        };
                        final allLeads = StorageService.getLeads();
                        allLeads.insert(0, newLead);
                        StorageService.saveLeads(allLeads);
                        MobileActionSheets.leadCreatedNotifier.value = newLead;

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lead "$name" saved to pipeline with call reminder for $nextCallDateFormatted!',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
