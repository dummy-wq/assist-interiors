import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../../core/services/storage_service.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class UploadRenderSheet extends StatefulWidget {
  final String? preselectedProject;
  final ValueChanged<Map<String, dynamic>>? onUploaded;

  const UploadRenderSheet({
    super.key,
    this.preselectedProject,
    this.onUploaded,
  });

  static void show(
    BuildContext context, {
    String? preselectedProject,
    ValueChanged<Map<String, dynamic>>? onUploaded,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return UploadRenderSheet(
          preselectedProject: preselectedProject,
          onUploaded: onUploaded,
        );
      },
    );
  }

  @override
  State<UploadRenderSheet> createState() => _UploadRenderSheetState();
}

class _UploadRenderSheetState extends State<UploadRenderSheet> {
  final _titleController =
      TextEditingController(text: '3D Photorealistic Render & BOQ');
  final _versionController = TextEditingController(text: 'v1.0');
  final _notesController = TextEditingController();

  PlatformFile? _pickedFile;
  int _pickedFileSize = 0;
  bool _isPickingFile = false;

  String _selectedType = 'CAD Drawing';
  String _selectedFormat = '.DWG';
  String _selectedStatus = 'Under Client Review';
  String? _selectedProject;

  final List<String> _types = [
    'CAD Drawing',
    '3D Render',
    'Material BOQ',
    'Mood Board',
    'MEP Layout',
  ];

  final List<String> _formats = [
    '.DWG',
    '.MAX',
    '.PDF',
    '.XLSX',
    '.JPG',
    '.PNG',
  ];

  final List<String> _statuses = [
    'Under Client Review',
    'Approved by Client',
    'Internal Review',
    'Revision Requested',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProject = widget.preselectedProject;
    if (_selectedProject == null || _selectedProject!.isEmpty) {
      final projects = StorageService.getProjects();
      if (projects.isNotEmpty) {
        _selectedProject = projects.first['name'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      switch (newType) {
        case 'CAD Drawing':
        case 'MEP Layout':
          _selectedFormat = '.DWG';
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Architectural Floor Plan & CAD Survey';
          }
          break;
        case '3D Render':
          _selectedFormat = '.MAX';
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Photorealistic 3ds Max Interior Render';
          }
          break;
        case 'Material BOQ':
          _selectedFormat = '.XLSX';
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Architectural Material Specification & BOQ';
          }
          break;
        case 'Mood Board':
          _selectedFormat = '.PDF';
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Material Finishes & Textures Mood Board';
          }
          break;
      }
    });
  }

  Future<void> _pickDeliverableFile() async {
    try {
      setState(() => _isPickingFile = true);
      PlatformFile? file;
      try {
        file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: [
            'dwg',
            'dxf',
            'pdf',
            'max',
            'xlsx',
            'xls',
            'csv',
            'png',
            'jpg',
            'jpeg',
            'dwf',
            'rvt',
            'skp',
            'obj',
            '3ds',
            'blend',
            'doc',
            'docx',
          ],
        );
      } catch (e) {
        // Fallback for file managers/platforms where custom MIME filters are not supported
        file = await FilePicker.pickFile(
          type: FileType.any,
        );
      }

      final selectedFile = file;
      if (selectedFile != null) {
        final length = selectedFile.lengthSync() ?? (await selectedFile.length()) ?? 0;
        setState(() {
          _pickedFile = selectedFile;
          _pickedFileSize = length;

          final ext = (selectedFile.extension ?? '').toLowerCase();
          if (ext == 'dwg' || ext == 'dxf' || ext == 'dwf' || ext == 'rvt') {
            _selectedFormat = '.DWG';
            _selectedType = 'CAD Drawing';
          } else if (ext == 'max' ||
              ext == '3ds' ||
              ext == 'obj' ||
              ext == 'blend' ||
              ext == 'skp') {
            _selectedFormat = '.MAX';
            _selectedType = '3D Render';
          } else if (ext == 'xlsx' || ext == 'xls' || ext == 'csv') {
            _selectedFormat = '.XLSX';
            _selectedType = 'Material BOQ';
          } else if (ext == 'pdf') {
            _selectedFormat = '.PDF';
            if (!_types.contains(_selectedType)) {
              _selectedType = 'CAD Drawing';
            }
          } else if (ext == 'png') {
            _selectedFormat = '.PNG';
            _selectedType = 'Mood Board';
          } else if (ext == 'jpg' || ext == 'jpeg') {
            _selectedFormat = '.JPG';
            _selectedType = 'Mood Board';
          }

          // Auto-populate title from file name if default/empty
          final dotIdx = selectedFile.name.lastIndexOf('.');
          final baseName =
              dotIdx != -1 ? selectedFile.name.substring(0, dotIdx) : selectedFile.name;
          final cleanTitle =
              baseName.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
          if (cleanTitle.isNotEmpty &&
              (_titleController.text.isEmpty ||
                  _titleController.text == '3D Photorealistic Render & BOQ' ||
                  _titleController.text.startsWith('Architectural Floor Plan') ||
                  _titleController.text.startsWith('Photorealistic 3ds Max'))) {
            _titleController.text = cleanTitle;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File permission error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _submit() {
    final title = _titleController.text.trim().isEmpty
        ? '$_selectedType Deliverable'
        : _titleController.text.trim();
    final version = _versionController.text.trim().isEmpty
        ? 'v1.0'
        : _versionController.text.trim();
    final proj = _selectedProject ?? 'Active Site';
    final fileSize = _pickedFile != null
        ? _formatFileSize(_pickedFileSize)
        : '15.0 MB';

    final newAsset = {
      'id': 'asset_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'type': _selectedType,
      'project': proj,
      'format': _selectedFormat,
      'version': version,
      'fileSize': fileSize,
      'status': _selectedStatus,
      'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
      'designer': 'Priya Sharma',
      'fileName': _pickedFile?.name,
      'filePath': _pickedFile?.path,
      'isUploaded': _pickedFile != null,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (_pickedFile != null
              ? 'Local architectural file (${_pickedFile!.name}) uploaded from device storage.'
              : 'Architectural deliverable uploaded for client review and coordination.'),
      'color': AppColors.brandPeach,
      'statusColor': _selectedStatus.contains('Approv')
          ? AppColors.success
          : (_selectedStatus.contains('Revis')
              ? AppColors.error
              : AppColors.brandPeach),
    };

    // 1. Save to global design items
    final allItems = StorageService.getDesignItems();
    allItems.insert(0, newAsset);
    StorageService.saveDesignItems(allItems);

    // 2. Attach to project if matching
    final allProjects = StorageService.getProjects();
    final projIdx = allProjects.indexWhere((p) => p['name'] == proj);
    if (projIdx != -1) {
      final assets = List<Map<String, dynamic>>.from(
        (allProjects[projIdx]['designAssets'] as List?) ?? [],
      );
      assets.insert(0, newAsset);
      allProjects[projIdx]['designAssets'] = assets;
      StorageService.saveProjects(allProjects);
    }

    MobileActionSheets.renderCreatedNotifier.value = newAsset;
    widget.onUploaded?.call(newAsset);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title uploaded successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = StorageService.getProjects();

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.brandPeach,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Design Deliverable',
                          style: AppTypography.titleLarge(isDark),
                        ),
                        Text(
                          'CAD Drawings, 3D Renders, Mood Boards & BOQ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textLightMuted
                                : AppColors.textDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CAD / Architectural Deliverable File Upload Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: _pickedFile != null
                      ? AppColors.success.withValues(alpha: 0.6)
                      : AppColors.brandPeach.withValues(alpha: 0.5),
                  width: _pickedFile != null ? 1.0 : 0.8,
                ),
              ),
              child: _pickedFile == null
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandPeach
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Icon(
                                Icons.file_present_rounded,
                                color: AppColors.brandPeach,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELECT CAD / 3D / BOQ FILE',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Upload .DWG, .DXF, .MAX, .PDF, .XLSX, or Renders',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textLightMuted
                                          : AppColors.textDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isPickingFile ? null : _pickDeliverableFile,
                            icon: _isPickingFile
                                ? const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.file_upload_outlined,
                                    size: 15,
                                  ),
                            label: Text(
                              _isPickingFile
                                  ? 'Opening File Browser...'
                                  : 'Browse Device Storage',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandPeach,
                              side: const BorderSide(
                                color: AppColors.brandPeach,
                                width: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile!.name,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textLightPrimary
                                          : AppColors.textDarkPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatFileSize(_pickedFileSize)} • $_selectedFormat • Local File Selected',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                              ),
                              onPressed: () =>
                                  setState(() => _pickedFile = null),
                              tooltip: 'Remove selected file',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDeliverableFile,
                          child: const Text(
                            'Choose a different file',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPeach,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Project Selector Dropdown
            Text(
              'ASSOCIATED PROJECT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 6),
            QuickFadeDropdown<String>(
              value: _selectedProject,
              decoration: _inputDecoration(isDark),
              borderRadius: BorderRadius.circular(4.0),
              items: projects.map((p) {
                final name = p['name'] as String? ?? 'Project';
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedProject = val);
              },
            ),
            const SizedBox(height: 12),

            // Deliverable Type & Format Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERABLE TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      QuickFadeDropdown<String>(
                        value: _selectedType,
                        decoration: _inputDecoration(isDark),
                        borderRadius: BorderRadius.circular(4.0),
                        items: _types.map((t) {
                          return DropdownMenuItem<String>(
                            value: t,
                            child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) _onTypeChanged(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FORMAT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textLightMuted
                              : AppColors.textDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      QuickFadeDropdown<String>(
                        value: _selectedFormat,
                        decoration: _inputDecoration(isDark),
                        borderRadius: BorderRadius.circular(4.0),
                        items: _formats.map((f) {
                          return DropdownMenuItem<String>(
                            value: f,
                            child: Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFormat = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title Field
            Text(
              'DELIVERABLE TITLE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(isDark).copyWith(
                hintText: 'e.g. Master Suite Reflected Ceiling Plan & CAD',
              ),
            ),
            const SizedBox(height: 12),

            // Version Field
            Text(
              'VERSION TAG',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _versionController,
              decoration: _inputDecoration(isDark).copyWith(
                hintText: 'v1.0, v2.1...',
              ),
            ),
            const SizedBox(height: 12),

            // Approval Status Dropdown
            Text(
              'CLIENT APPROVAL STATUS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 6),
            QuickFadeDropdown<String>(
              value: _selectedStatus,
              decoration: _inputDecoration(isDark),
              borderRadius: BorderRadius.circular(4.0),
              items: _statuses.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 12),

            // Technical Notes Field
            Text(
              'TECHNICAL SPECIFICATION & REVISION NOTES',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textLightMuted
                    : AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: _inputDecoration(isDark).copyWith(
                hintText: 'Add revision scope, drawing layers, or BOQ summary...',
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text(
                'Save Deliverable for Client Review',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(
          color: AppColors.brandPeach,
          width: 1.2,
        ),
      ),
    );
  }
}
