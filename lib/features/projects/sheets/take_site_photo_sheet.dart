import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/instant_press_feedback.dart';

class TakeSitePhotoSheet {
  TakeSitePhotoSheet._();

  static void show(
    BuildContext context, {
    required Map<String, dynamic> project,
    required void Function(Map<String, dynamic> photo) onPhotoAdded,
    bool initialUploadMode = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectName = project['name'] as String? ?? 'Project Site';

    final textController = TextEditingController();
    String selectedTag = 'Living Room';
    String? selectedPreset;
    String? capturedImagePath;
    bool isCapturing = false;

    final tags = [
      'Living Room',
      'Master Bed',
      'Kitchen',
      'Bath',
      'Balcony',
      'MEP & Ceiling',
      'Flooring',
      'Joinery',
      'Entire Site',
    ];

    final presets = [
      'Civil Demolition & Wet Masonry',
      'False Ceiling Framing & Laser Alignment',
      'Electrical Conduiting & Switchbox Grooves',
      'Italian Marble Laying & Leveling',
      'Modular Kitchen Carcass & Countertop Fitting',
      'Wardrobe Carcass & Veneer Pressing',
      'Bathroom Waterproofing & Vitrified Tiling',
      'Wall Primer, Putty & PU Painting',
      'Architectural Lighting & Fixtures',
      'Final Snag Rectification & Deep Clean',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom +
                    AppSizes.sheetBottomPadding(modalContext),
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
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
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
                                      'Take Site Photo',
                                      style: AppTypography.titleLarge(isDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      projectName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (initialUploadMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPeach.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: AppColors.brandPeach.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              size: 14,
                              color: AppColors.brandPeach,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Upload Mode: Choose an existing photo from Gallery or Files',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brandPeach,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Camera Viewfinder Simulation Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: AppColors.brandPeach.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'OPTICAL VIEWFINDER • LIVE SITE CAMERA',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat('hh:mm:ss a').format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: AppColors.brandPeach,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 125,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                            child: capturedImagePath != null &&
                                    !kIsWeb &&
                                    File(capturedImagePath!).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          File(capturedImagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.75),
                                              borderRadius:
                                                  BorderRadius.circular(3.0),
                                              border: Border.all(
                                                color: AppColors.brandPeach,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 11,
                                                  color: AppColors.brandPeach,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'PHOTO CAPTURED',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.6,
                                                    color: AppColors.brandPeach,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Viewfinder Crosshairs & Grid
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Icon(
                                          Icons.crop_free_rounded,
                                          size: 22,
                                          color: AppColors.brandPeach.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Icon(
                                          Icons.crop_free_rounded,
                                          size: 22,
                                          color: AppColors.brandPeach.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 32,
                                            color: AppColors.brandPeach,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Zone: $selectedTag',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textLightPrimary
                                                  : AppColors.textDarkPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InstantPressFeedback(
                                  child: ElevatedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final picker = ImagePicker();
                                              final XFile? file =
                                                  await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1920,
                                                maxHeight: 1080,
                                                imageQuality: 85,
                                              );
                                              if (file != null) {
                                                setModalState(() {
                                                  capturedImagePath =
                                                      file.path;
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Camera capture error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                ScaffoldMessenger.of(modalContext)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Camera error: ${e.toString()}',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.error,
                                                    behavior:
                                                        SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.photo_camera_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Take Photo',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandPeach,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InstantPressFeedback(
                                  child: OutlinedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final picker = ImagePicker();
                                              final XFile? file =
                                                  await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1920,
                                                maxHeight: 1080,
                                                imageQuality: 85,
                                              );
                                              if (file != null) {
                                                setModalState(() {
                                                  capturedImagePath =
                                                      file.path;
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'Gallery pick error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                ScaffoldMessenger.of(modalContext)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gallery error: ${e.toString()}',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.error,
                                                    behavior:
                                                        SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 14,
                                      color: AppColors.brandPeach,
                                    ),
                                    label: Text(
                                      'Gallery',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 0.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InstantPressFeedback(
                                  child: OutlinedButton.icon(
                                    onPressed: isCapturing
                                        ? null
                                        : () async {
                                            try {
                                              setModalState(
                                                () => isCapturing = true,
                                              );
                                              final result =
                                                  await FilePicker.pickFile(
                                                type: FileType.image,
                                              );
                                              if (result != null &&
                                                  result.path != null) {
                                                setModalState(() {
                                                  capturedImagePath =
                                                      result.path;
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(
                                                'File picker photo error: $e',
                                              );
                                              if (modalContext.mounted) {
                                                ScaffoldMessenger.of(modalContext)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'File access error: ${e.toString()}',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.error,
                                                    behavior:
                                                        SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            } finally {
                                              setModalState(
                                                () => isCapturing = false,
                                              );
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.folder_open_rounded,
                                      size: 14,
                                      color: AppColors.brandPeach,
                                    ),
                                    label: Text(
                                      'Files',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textLightPrimary
                                            : AppColors.textDarkPrimary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 0.8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (capturedImagePath != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setModalState(
                                () => capturedImagePath = null,
                              ),
                              borderRadius: BorderRadius.circular(3.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 12,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Retake / Clear Photo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          InstantPressFeedback(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                final timestamp = DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(now);
                                final title = textController.text.trim().isNotEmpty
                                    ? textController.text.trim()
                                    : (selectedPreset ??
                                        '$selectedTag Site Progress Capture');

                                onPhotoAdded({
                                  'id':
                                      'photo_${now.millisecondsSinceEpoch}',
                                  'title': title,
                                  'tag': selectedTag,
                                  'timestamp': timestamp,
                                  'capturedBy': 'Site Supervisor',
                                  'imagePath': capturedImagePath,
                                  'hasImage': capturedImagePath != null,
                                  'isUploaded': capturedImagePath != null,
                                });
                                Navigator.pop(modalContext);
                              },
                              icon: const Icon(
                                Icons.camera_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Instant Camera Shutter (Capture Now)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground,
                                foregroundColor: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                                elevation: 0,
                                side: BorderSide(
                                  color: (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.8),
                                  width: 0.8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Area / Zone Selector
                    Text(
                      'SITE ZONE / ROOM',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tags.map((tag) {
                          final isSelected = selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.black
                                      : (isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.brandPeach,
                              backgroundColor: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightBackground,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.brandPeach
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: 0.8,
                                ),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() => selectedTag = tag);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Milestone Presets
                    Text(
                      'OR CHOOSE INSPECTION MILESTONE PRESET',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppColors.textLightMuted
                            : AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: presets.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                              .withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final item = presets[index];
                          final isSelected = selectedPreset == item;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedPreset = item;
                                textController.text = item;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.camera_alt_outlined,
                                    size: 14,
                                    color: isSelected
                                        ? AppColors.brandPeach
                                        : (isDark
                                            ? AppColors.textLightMuted
                                            : AppColors.textDarkMuted),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.brandPeach
                                            : (isDark
                                                ? AppColors.textLightPrimary
                                                : AppColors.textDarkPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Description
                    Text(
                      'CUSTOM PHOTO TITLE / OBSERVATION NOTE',
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
                    TextField(
                      controller: textController,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. Master bathroom Italian marble tile dry lay...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    InstantPressFeedback(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final title = textController.text.trim().isNotEmpty
                              ? textController.text.trim()
                              : (selectedPreset ??
                                  '$selectedTag Inspection Photo');
                          final now = DateTime.now();
                          final timestamp = DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(now);

                          onPhotoAdded({
                            'id': 'photo_${now.millisecondsSinceEpoch}',
                            'title': title,
                            'tag': selectedTag,
                            'timestamp': timestamp,
                            'capturedBy': 'Site Supervisor',
                            'imagePath': capturedImagePath,
                            'hasImage': capturedImagePath != null,
                            'isUploaded': capturedImagePath != null,
                          });
                          Navigator.pop(modalContext);
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text(
                          'Save & Attach Photo to Project',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPeach,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
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
