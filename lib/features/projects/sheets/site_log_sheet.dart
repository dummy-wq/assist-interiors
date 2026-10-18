import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class SiteLogSheet {
  SiteLogSheet._();

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logController = TextEditingController();
    final workersController = TextEditingController(text: '26');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        final List<String> attachedPhotos = [];

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
                                Icons.add_a_photo_rounded,
                                color: AppColors.brandPeach,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Post Daily Site Update',
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
                      controller: workersController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Labour Headcount Present Today',
                        prefixIcon: Icon(Icons.groups_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: logController,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Daily Progress & Work Completed Notes',
                        hintText: 'e.g. Master bedroom plywood grid installed. Plastering finished in living room.',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Attached Photos Strip
                    if (attachedPhotos.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attached Site Photos (${attachedPhotos.length}):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              _showPhotoCaptureDialog(context, (photo) {
                                setModalState(() {
                                  attachedPhotos.add(photo);
                                });
                              });
                            },
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 14,
                              color: AppColors.brandPeach,
                            ),
                            label: const Text(
                              '+ Add More',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.brandPeach,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attachedPhotos.map((photo) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: AppColors.brandPeach.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,
                                  color: AppColors.brandPeach,
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Text(
                                    photo,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      attachedPhotos.remove(photo);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      OutlinedButton.icon(
                        onPressed: () {
                          _showPhotoCaptureDialog(context, (photo) {
                            setModalState(() {
                              attachedPhotos.add(photo);
                            });
                          });
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Attach Site Photos (Optional)'),
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
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPeach,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit Site Report to PM'),
                      onPressed: () {
                        final title = logController.text.trim();
                        final workers =
                            int.tryParse(workersController.text.trim()) ?? 26;
                        final newLog = {
                          'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
                          'title': title.isNotEmpty
                              ? title
                              : 'Daily Site Inspection',
                          'description':
                              'On-site workforce: $workers workers deployed across civil, carpentry, and electrical works.',
                          'time': DateFormat('hh:mm a').format(DateTime.now()),
                          'workers': workers,
                          'hasPhotos': attachedPhotos.isNotEmpty,
                          'photoCount': attachedPhotos.length,
                          'photos': attachedPhotos,
                        };
                        final allLogs = StorageService.getSiteLogs();
                        allLogs.insert(0, newLog);
                        StorageService.saveSiteLogs(allLogs);
                        MobileActionSheets.siteLogCreatedNotifier.value =
                            newLog;

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              attachedPhotos.isNotEmpty
                                  ? 'Daily site log posted with ${attachedPhotos.length} photos!'
                                  : 'Daily site log posted!',
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

  static void _showPhotoCaptureDialog(
    BuildContext context,
    void Function(String photoName) onSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customController = TextEditingController();

    final presetCaptures = [
      'Living Room Framing & False Ceiling',
      'Master Bedroom Drywall & Wiring',
      'Kitchen Quartz Installation & Plumbing',
      'Balcony Glass Railing & Weatherproofing',
      'Bathroom Italian Marble Tile Laying',
      'Main Foyer Teak Veneer Panelling',
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
                        Icons.add_a_photo_rounded,
                        color: AppColors.brandPeach,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Site Photo to Attach',
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
              ...presetCaptures.map((item) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: AppColors.brandPeach,
                  ),
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textLightPrimary
                          : AppColors.textDarkPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.brandPeach,
                  ),
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: customController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Or enter custom site photo description...',
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.check_rounded,
                      color: AppColors.brandPeach,
                    ),
                    onPressed: () {
                      final val = customController.text.trim();
                      if (val.isNotEmpty) {
                        onSelected(val);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    onSelected(val.trim());
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
