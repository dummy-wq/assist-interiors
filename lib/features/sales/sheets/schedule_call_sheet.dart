import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/phone_call_service.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

import '../../../core/utils/app_notification.dart';
class ScheduleCallSheet {
  ScheduleCallSheet._();

  /// Returns `true` when [lead] has an active scheduled follow-up call
  /// that has not yet been marked as made.
  static bool hasActiveScheduledCall(Map<String, dynamic> lead) {
    final nextCallDate = (lead['nextCallDate'] ?? '').toString().trim();
    if (nextCallDate.isEmpty) return false;
    if (lead['isReminderDismissed'] == true) return false;
    if (lead['hasReminder'] == false) return false;
    return true;
  }

  /// Returns the most recently scheduled active call lead from [leads], or
  /// `null` if no active scheduled call exists.
  static Map<String, dynamic>? latestScheduledLead(
    List<Map<String, dynamic>> leads,
  ) {
    final active = leads.where(hasActiveScheduledCall).toList();
    if (active.isEmpty) return null;

    DateTime? parseIso(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    active.sort((a, b) {
      final aTime =
          parseIso(a['callScheduledAt']) ??
          parseIso(a['updatedAt']) ??
          parseIso(a['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          parseIso(b['callScheduledAt']) ??
          parseIso(b['updatedAt']) ??
          parseIso(b['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return active.first;
  }

  /// Marks the scheduled follow-up call on [lead] as made and clears the
  /// active reminder so it no longer appears as pending/scheduled.
  static Future<Map<String, dynamic>> markCallAsMade(
    Map<String, dynamic> lead, {
    String? discussionNote,
  }) async {
    final leadId = (lead['id'] ?? '').toString();
    final now = DateTime.now();
    final existingNotes = lead['notes'] is List
        ? List<dynamic>.from(lead['notes'] as List)
        : <dynamic>[];
    final trimmedNote = (discussionNote ?? '').trim();
    existingNotes.insert(0, {
      'date': DateFormat('dd MMM yyyy, hh:mm a').format(now),
      'text': trimmedNote.isNotEmpty
          ? 'Call made: $trimmedNote'
          : 'Scheduled follow-up call marked as made.',
    });

    final updatedFields = <String, dynamic>{
      'nextCallDate': '',
      'nextCallTime': '',
      'reminderNote': '',
      'hasReminder': false,
      'isReminderDismissed': true,
      'lastCallMadeAt': now.toIso8601String(),
      'notes': existingNotes,
      'updatedAt': now.toIso8601String(),
    };

    if (leadId.isNotEmpty) {
      await StorageService.updateLead(leadId, updatedFields);
    }
    final updatedLead = <String, dynamic>{...lead, ...updatedFields};
    MobileActionSheets.leadUpdatedNotifier.value = updatedLead;
    return updatedLead;
  }

  static void show(
    BuildContext context,
    Map<String, dynamic> lead, {
    VoidCallback? onUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final leadId = lead['id'] as String;
    final phone = (lead['phone'] as String? ?? '').trim();
    final isCurrentlyScheduled = hasActiveScheduledCall(lead);

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

    showAppModalBottomSheet(
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
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Reminder Reason / Deliverable Target'),
                        ),
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
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Log Call / Discussion Remarks (Optional)',
                          ),
                        ),
                        hintText: 'e.g. Client requested Italian marble catalog and revised layout',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
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

                        final nowIso = DateTime.now().toIso8601String();
                        final updatedFields = {
                          'nextCallDate': dateFormatted,
                          'nextCallTime': timeFormatted,
                          'callScheduledAt': nowIso,
                          'reminderNote': reminderNoteCtrl.text.trim(),
                          'hasReminder': true,
                          'isReminderDismissed': false,
                          'notes': existingNotes,
                          'updatedAt': nowIso,
                        };

                        await StorageService.updateLead(leadId, updatedFields);
                        MobileActionSheets.leadUpdatedNotifier.value = {
                          ...lead,
                          ...updatedFields,
                        };
                        onUpdated?.call();

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        AppNotification.show(context, message: 'Call scheduled for $dateFormatted at $timeFormatted!', backgroundColor: AppColors.success);
                      },
                    ),
                    if (isCurrentlyScheduled) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: BorderSide(
                            color: AppColors.success.withValues(alpha: 0.7),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Mark Call as Made',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          await markCallAsMade(
                            lead,
                            discussionNote: discussionCtrl.text,
                          );
                          onUpdated?.call();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          AppNotification.show(
                            context,
                            message: 'Call with $clientName marked as made.',
                            backgroundColor: AppColors.success,
                          );
                        },
                      ),
                    ],
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
