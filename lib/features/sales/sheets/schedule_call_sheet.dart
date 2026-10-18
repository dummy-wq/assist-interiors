import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/phone_call_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class ScheduleCallSheet {
  ScheduleCallSheet._();

  static void show(
    BuildContext context,
    Map<String, dynamic> lead, {
    VoidCallback? onUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final leadId = lead['id'] as String;
    final phone = (lead['phone'] as String? ?? '').trim();

    DateTime chosenDate = DateTime.now().add(const Duration(days: 1));
    if ((lead['nextCallDate'] as String? ?? '').isNotEmpty) {
      try {
        final parsed = DateFormat('dd MMM yyyy')
            .parse(lead['nextCallDate'] as String);
        chosenDate = parsed;
      } catch (_) {}
    }

    TimeOfDay chosenTime = const TimeOfDay(hour: 11, minute: 30);
    final reminderNoteCtrl = TextEditingController(
      text: lead['reminderNote'] as String? ?? '',
    );
    final discussionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateFormatted = DateFormat('dd MMM yyyy').format(chosenDate);
            final timeFormatted = chosenTime.format(context);

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
                                  Icons.phone_callback_rounded,
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
                                      'Schedule Call & Reminder',
                                      style: AppTypography.titleLarge(isDark),
                                    ),
                                    Text(
                                      phone.isNotEmpty
                                          ? 'Client: $clientName  ·  $phone'
                                          : 'Client: $clientName',
                                      style: AppTypography.bodySmall(isDark),
                                      overflow: TextOverflow.ellipsis,
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
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: AppColors.brandPeach.withValues(alpha: 0.6),
                          ),
                        ),
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 18,
                          color: AppColors.brandPeach,
                        ),
                        label: Text(
                          'Direct Dial ($phone)',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textLightPrimary
                                : AppColors.textDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => PhoneCallService.dialNumber(
                          context,
                          phoneNumber: phone,
                          contactName: clientName,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Next Follow-up Call Date & Time',
                      style: AppTypography.labelLarge(isDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                            ),
                            label: Text(dateFormatted),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: chosenDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 7),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => chosenDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                            ),
                            label: Text(timeFormatted),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: chosenTime,
                              );
                              if (pickedTime != null) {
                                setModalState(() => chosenTime = pickedTime);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reminderNoteCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Reason / Deliverable Target',
                        hintText: 'e.g. Share revised 3D kitchen render and finalize quote',
                        prefixIcon: Icon(Icons.notification_important_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discussionCtrl,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Log Call / Discussion Remarks (Optional)',
                        hintText: 'e.g. Client requested Italian marble catalog and revised layout',
                        prefixIcon: Icon(Icons.notes_rounded),
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
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'Save Call Schedule & Reminder',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        List<dynamic> existingNotes = [];
                        if (lead['notes'] is List) {
                          existingNotes = List.from(lead['notes'] as List);
                        }
                        if (discussionCtrl.text.trim().isNotEmpty) {
                          existingNotes.insert(0, {
                            'date': DateFormat('dd MMM yyyy, hh:mm a')
                                .format(DateTime.now()),
                            'text': discussionCtrl.text.trim(),
                          });
                        }

                        final updatedFields = {
                          'nextCallDate': dateFormatted,
                          'nextCallTime': timeFormatted,
                          'reminderNote': reminderNoteCtrl.text.trim(),
                          'hasReminder': true,
                          'isReminderDismissed': false,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Call scheduled for $dateFormatted at $timeFormatted!',
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
