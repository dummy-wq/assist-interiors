import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../auth/state/auth_provider.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class LabourAttendanceSheet {
  LabourAttendanceSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final defaultTakenBy = auth.currentUser?.fullName.trim().isNotEmpty == true
        ? auth.currentUser!.fullName.trim()
        : auth.currentRole.title;

    final personNameController = TextEditingController();
    final takenByController = TextEditingController(text: defaultTakenBy);

    DateTime selectedDay = DateTime.now();
    TimeOfDay timeIn = const TimeOfDay(hour: 8, minute: 30);
    TimeOfDay timeOut = const TimeOfDay(hour: 18, minute: 0);

    final List<Map<String, dynamic>> entries = StorageService.getLabourRoll();

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            final dayFormatted =
                DateFormat('EEE, dd MMM yyyy').format(selectedDay);
            final timeInFormatted = timeIn.format(sheetCtx);
            final timeOutFormatted = timeOut.format(sheetCtx);

            void addCurrentPerson() {
              final personName = personNameController.text.trim();
              if (personName.isEmpty) {
                AppNotification.show(
                  sheetCtx,
                  message: 'Please enter the person\'s name.',
                  backgroundColor: AppColors.warning,
                );
                return;
              }
              final takenBy = takenByController.text.trim().isNotEmpty
                  ? takenByController.text.trim()
                  : defaultTakenBy;

              final entry = <String, dynamic>{
                'id': 'labour_${DateTime.now().millisecondsSinceEpoch}_${entries.length}',
                'personName': personName,
                'timeIn': timeInFormatted,
                'timeOut': timeOutFormatted,
                'day': dayFormatted,
                'takenBy': takenBy,
                'createdAt': DateTime.now().toIso8601String(),
              };
              setModalState(() {
                entries.insert(0, entry);
                personNameController.clear();
              });
              StorageService.saveLabourRoll(entries);
              MobileActionSheets.attendanceCountNotifier.value = entries.length;
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: AppSizes.sheetBottomPadding(sheetCtx),
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
                                  Icons.groups_rounded,
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
                                    'On-Site Attendance Roll Call',
                                    style: AppTypography.titleLarge(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Person Name
                    TextField(
                      key: const Key('labour_person_name_field'),
                      controller: personNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Person Name *'),
                        ),
                        hintText: 'e.g. Ramesh Kumar (Carpenter)',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day Selector
                    OutlinedButton.icon(
                      key: const Key('labour_day_btn'),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        'Day: $dayFormatted',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetCtx,
                          initialDate: selectedDay,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDay = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Time In & Time Out Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('labour_time_in_btn'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            icon: const Icon(Icons.login_rounded, size: 15),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'In: $timeInFormatted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: sheetCtx,
                                initialTime: timeIn,
                              );
                              if (picked != null) {
                                setModalState(() => timeIn = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('labour_time_out_btn'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 15),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Out: $timeOutFormatted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: sheetCtx,
                                initialTime: timeOut,
                              );
                              if (picked != null) {
                                setModalState(() => timeOut = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Roll Call Taken By
                    TextField(
                      key: const Key('labour_taken_by_field'),
                      controller: takenByController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Roll Call Taken By (Supervisor / Engineer)'),
                        ),
                        prefixIcon: Icon(Icons.engineering_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      key: const Key('labour_add_entry_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPeach,
                        side: BorderSide(
                          color: AppColors.brandPeach.withValues(alpha: 0.7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      onPressed: addCurrentPerson,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text(
                        'Add Person to Roll Call',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),

                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'RECORDED ROLL CALL (${entries.length})',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, idx) {
                            final item = entries[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (item['personName'] ?? 'Worker')
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textLightPrimary
                                                : AppColors.textDarkPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item['day']} • ${item['timeIn']} – ${item['timeOut']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textLightSecondary
                                                : AppColors.textDarkSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Taken by: ${item['takenBy']}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brandPeach,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setModalState(() {
                                        entries.removeAt(idx);
                                      });
                                      StorageService.saveLabourRoll(entries);
                                      MobileActionSheets
                                              .attendanceCountNotifier.value =
                                          entries.length;
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Verify & Submit Daily Muster Roll'),
                      onPressed: () async {
                        if (personNameController.text.trim().isNotEmpty) {
                          addCurrentPerson();
                        }
                        await StorageService.saveLabourRoll(entries);
                        MobileActionSheets.attendanceCountNotifier.value =
                            entries.length;
                        if (!context.mounted) return;
                        Navigator.pop(modalCtx);
                        AppNotification.show(
                          context,
                          message:
                              'Attendance recorded for ${entries.length} worker(s)!',
                          backgroundColor: AppColors.success,
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
