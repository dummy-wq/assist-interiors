import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/services/cloud_storage_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/app_modal_sheet.dart';
import '../../../core/widgets/custom_entry_dropdown.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

class _QueuedDeliverableFile {
  final String name;
  final String? path;
  final Uint8List bytes;
  final int size;
  final String extension;
  String deliverableType;
  String format;

  _QueuedDeliverableFile({
    required this.name,
    required this.path,
    required this.bytes,
    required this.size,
    required this.extension,
    required this.deliverableType,
    required this.format,
  });
}

class UploadRenderSheet extends StatefulWidget {
  final String? preselectedProject;
  final String? initialType;
  final ValueChanged<Map<String, dynamic>>? onUploaded;

  const UploadRenderSheet({
    super.key,
    this.preselectedProject,
    this.initialType,
    this.onUploaded,
  });

  static void show(
    BuildContext context, {
    String? preselectedProject,
    String? initialType,
    ValueChanged<Map<String, dynamic>>? onUploaded,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
      ),
      builder: (context) {
        return UploadRenderSheet(
          preselectedProject: preselectedProject,
          initialType: initialType,
          onUploaded: onUploaded,
        );
      },
    );
  }

  @override
  State<UploadRenderSheet> createState() => _UploadRenderSheetState();
}

class _UploadRenderSheetState extends State<UploadRenderSheet> {
  final List<_QueuedDeliverableFile> _pickedFiles = [];
  bool _isPickingFile = false;

  String _selectedType = 'CAD Drawing';
  String _selectedFormat = '.DWG';
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
    if (widget.initialType != null && _types.contains(widget.initialType)) {
      _selectedType = widget.initialType!;
      if (_selectedType == 'Material BOQ') {
        _selectedFormat = '.XLSX';
      }
    }
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      switch (newType) {
        case 'CAD Drawing':
        case 'MEP Layout':
          _selectedFormat = '.DWG';
          break;
        case '3D Render':
          _selectedFormat = '.MAX';
          break;
        case 'Material BOQ':
          _selectedFormat = '.XLSX';
          break;
        case 'Mood Board':
          _selectedFormat = '.PDF';
          break;
      }
    });
  }

  ({String format, String type}) _detectFormatAndType(String ext) {
    final lower = ext.toLowerCase();
    if (lower == 'dwg' || lower == 'dxf' || lower == 'dwf' || lower == 'rvt') {
      return (format: '.DWG', type: 'CAD Drawing');
    } else if (lower == 'max' ||
        lower == '3ds' ||
        lower == 'obj' ||
        lower == 'blend' ||
        lower == 'skp') {
      return (format: '.MAX', type: '3D Render');
    } else if (lower == 'xlsx' || lower == 'xls' || lower == 'csv') {
      return (format: '.XLSX', type: 'Material BOQ');
    } else if (lower == 'pdf') {
      return (
        format: '.PDF',
        type: _types.contains(_selectedType) ? _selectedType : 'CAD Drawing',
      );
    } else if (lower == 'png') {
      return (format: '.PNG', type: '3D Render');
    } else if (lower == 'jpg' || lower == 'jpeg') {
      return (format: '.JPG', type: '3D Render');
    }
    return (format: _selectedFormat, type: _selectedType);
  }

  String _cleanTitleFromFileName(String fileName) {
    final dotIdx = fileName.lastIndexOf('.');
    final baseName = dotIdx != -1 ? fileName.substring(0, dotIdx) : fileName;
    final clean = baseName.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    return clean.isNotEmpty ? clean : fileName;
  }

  void _applyDetectedDefaultsFromFirstFile(_QueuedDeliverableFile firstFile) {
    _selectedFormat = firstFile.format;
    _selectedType = firstFile.deliverableType;
  }

  Future<void> _pickDeliverableFiles() async {
    try {
      final allowed = await PermissionService.requestMediaOrStorage(context);
      if (!allowed) return;
      setState(() => _isPickingFile = true);
      List<PlatformFile> files = [];
      try {
        files = await FilePicker.pickFiles(
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
      } catch (_) {
        files = await FilePicker.pickFiles(type: FileType.any);
      }

      if (files.isNotEmpty) {
        final loaded = <_QueuedDeliverableFile>[];
        for (final f in files) {
          final bytes = await f.readAsBytes();
          final length = f.lengthSync() ?? bytes.length;
          final ext = (f.extension ?? '').toLowerCase();
          final detected = _detectFormatAndType(ext);
          loaded.add(
            _QueuedDeliverableFile(
              name: f.name,
              path: f.path,
              bytes: bytes,
              size: length,
              extension: ext,
              deliverableType: detected.type,
              format: detected.format,
            ),
          );
        }
        setState(() {
          final wasEmpty = _pickedFiles.isEmpty;
          _pickedFiles.addAll(loaded);
          if (wasEmpty && _pickedFiles.isNotEmpty) {
            _applyDetectedDefaultsFromFirstFile(_pickedFiles.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'File permission error: ${e.toString()}',
          backgroundColor: AppColors.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _pickGalleryPhotos() async {
    try {
      final allowed = await PermissionService.requestMediaOrStorage(context);
      if (!allowed) return;
      setState(() => _isPickingFile = true);
      final picker = ImagePicker();
      final List<XFile> photos = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photos.isNotEmpty) {
        final loaded = <_QueuedDeliverableFile>[];
        for (final p in photos) {
          final bytes = await p.readAsBytes();
          final name = p.name.isNotEmpty
              ? p.name
              : p.path.split(RegExp(r'[/\\]')).last;
          final dotIdx = name.lastIndexOf('.');
          final ext = dotIdx != -1
              ? name.substring(dotIdx + 1).toLowerCase()
              : 'jpg';
          final detected = _detectFormatAndType(ext);
          loaded.add(
            _QueuedDeliverableFile(
              name: name,
              path: p.path,
              bytes: bytes,
              size: bytes.length,
              extension: ext,
              deliverableType: detected.type,
              format: detected.format,
            ),
          );
        }
        setState(() {
          final wasEmpty = _pickedFiles.isEmpty;
          _pickedFiles.addAll(loaded);
          if (wasEmpty && _pickedFiles.isNotEmpty) {
            _applyDetectedDefaultsFromFirstFile(_pickedFiles.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Gallery error: ${e.toString()}',
          backgroundColor: AppColors.error,
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

  void _uploadAssetToCloud({
    required Map<String, dynamic> asset,
    required _QueuedDeliverableFile file,
    required String projId,
    required String projName,
  }) {
    if (!CloudStorageService.isAvailable) return;
    final assetId = asset['id'];
    CloudStorageService.uploadDesignAsset(
      projectId: projId,
      projectName: projName,
      filePath: file.path,
      bytes: file.bytes,
      originalFileName: file.name,
      title: (asset['title'] ?? file.name).toString(),
      assetType: (asset['type'] ?? _selectedType).toString(),
      retentionMonths: StorageService.getCadRetentionMonths(),
    ).then((uploadRes) {
      if (uploadRes == null) return;
      final items = StorageService.getDesignItems();
      final iIdx = items.indexWhere((i) => i['id'] == assetId);
      if (iIdx != -1) {
        items[iIdx]['storagePath'] = uploadRes.storagePath;
        items[iIdx]['downloadUrl'] = uploadRes.downloadUrl;
        items[iIdx]['fileUrl'] = uploadRes.downloadUrl;
        StorageService.saveDesignItems(items);
      }

      final projects = StorageService.getProjects();
      final pIdx = projects.indexWhere((p) => p['name'] == projName);
      if (pIdx != -1 && projects[pIdx]['designAssets'] is List) {
        final assets = List<Map<String, dynamic>>.from(
          (projects[pIdx]['designAssets'] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        final aIdx = assets.indexWhere((a) => a['id'] == assetId);
        if (aIdx != -1) {
          assets[aIdx]['storagePath'] = uploadRes.storagePath;
          assets[aIdx]['downloadUrl'] = uploadRes.downloadUrl;
          assets[aIdx]['fileUrl'] = uploadRes.downloadUrl;
          projects[pIdx]['designAssets'] = assets;
          StorageService.saveProjects(projects);
        }
      }
      StorageService.cloudSyncNotifier.value =
          StorageService.cloudSyncNotifier.value + 1;
    });
  }

  void _submit() {
    const version = 'v1.0';
    const defaultStatus = 'Under Client Review';
    final proj = _selectedProject ?? 'Active Site';
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    const statusColor = AppColors.brandPeach;

    final allItems = StorageService.getDesignItems();
    final allProjects = StorageService.getProjects();
    final normProj = proj.trim().toLowerCase();
    final projIdx = allProjects.indexWhere(
      (p) => (p['name'] ?? '').toString().trim().toLowerCase() == normProj,
    );
    String projId = '';
    List<Map<String, dynamic>> projectAssets = [];
    if (projIdx != -1) {
      projId = (allProjects[projIdx]['id'] ?? '').toString();
      projectAssets = List<Map<String, dynamic>>.from(
        (allProjects[projIdx]['designAssets'] as List?) ?? [],
      );
    }

    final createdAssets = <Map<String, dynamic>>[];

    if (_pickedFiles.isEmpty) {
      final newAsset = <String, dynamic>{
        'id': 'asset_${now.millisecondsSinceEpoch}',
        'title': '$_selectedType Deliverable',
        'type': _selectedType,
        'project': proj,
        if (projId.isNotEmpty) 'projectId': projId,
        'format': _selectedFormat,
        'version': version,
        'fileSize': '15.0 MB',
        'status': defaultStatus,
        'date': formattedDate,
        'designer': 'Priya Sharma',
        'fileName': null,
        'filePath': null,
        'isUploaded': false,
        'notes': '',
        'color': AppColors.brandPeach,
        'statusColor': statusColor,
      };
      createdAssets.add(newAsset);
    } else {
      for (var i = 0; i < _pickedFiles.length; i++) {
        final file = _pickedFiles[i];
        final itemTitle = _cleanTitleFromFileName(file.name);

        final newAsset = <String, dynamic>{
          'id': 'asset_${now.millisecondsSinceEpoch}_$i',
          'title': itemTitle,
          'type': file.deliverableType,
          'project': proj,
          if (projId.isNotEmpty) 'projectId': projId,
          'format': file.format,
          'version': version,
          'fileSize': _formatFileSize(file.size),
          'status': defaultStatus,
          'date': formattedDate,
          'designer': 'Priya Sharma',
          'fileName': file.name,
          'filePath': file.path,
          'isUploaded': true,
          'notes': '',
          'color': AppColors.brandPeach,
          'statusColor': statusColor,
        };
        createdAssets.add(newAsset);
      }
    }

    for (final asset in createdAssets.reversed) {
      allItems.insert(0, asset);
      if (projIdx != -1) {
        projectAssets.insert(0, asset);
      }
    }
    StorageService.saveDesignItems(allItems);
    if (projIdx != -1) {
      allProjects[projIdx]['designAssets'] = projectAssets;
      StorageService.saveProjects(allProjects);
    }

    for (var i = 0; i < _pickedFiles.length; i++) {
      _uploadAssetToCloud(
        asset: createdAssets[i],
        file: _pickedFiles[i],
        projId: projId,
        projName: proj,
      );
    }

    for (final asset in createdAssets) {
      MobileActionSheets.renderCreatedNotifier.value = asset;
      widget.onUploaded?.call(asset);
    }

    Navigator.pop(context);
    AppNotification.show(
      context,
      message: createdAssets.length > 1
          ? '${createdAssets.length} deliverables uploaded successfully!'
          : '${createdAssets.first['title']} uploaded successfully!',
      backgroundColor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = StorageService.getProjects();
    final projectNames = <String>[
      for (final p in projects) (p['name'] as String? ?? 'Project'),
    ];
    if (_selectedProject != null &&
        _selectedProject!.isNotEmpty &&
        !projectNames.contains(_selectedProject)) {
      projectNames.insert(0, _selectedProject!);
    }

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
                          Icons.cloud_upload_rounded,
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
                              'Upload Drawing or Render',
                              style: AppTypography.titleLarge(isDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '2D Drawings, 3D Renders, Mood Boards & PDFs',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : AppColors.textDarkMuted,
                              ),
                              maxLines: 2,
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
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CAD / Architectural Deliverable Multi-File & Multi-Photo Upload Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: _pickedFiles.isNotEmpty
                      ? AppColors.success.withValues(alpha: 0.6)
                      : AppColors.brandPeach.withValues(alpha: 0.5),
                  width: _pickedFiles.isNotEmpty ? 1.0 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Icons.file_present_rounded,
                          color: AppColors.brandPeach,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textLightMuted
                                    : AppColors.textDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedFiles.isNotEmpty)
                        InkWell(
                          onTap: () => setState(() => _pickedFiles.clear()),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_pickedFiles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _pickedFiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final item = _pickedFiles[idx];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
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
                                          Text(
                                            '${_formatFileSize(item.size)} • ${item.format}',
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
                                        size: 15,
                                      ),
                                      onPressed: () => setState(() {
                                        _pickedFiles.removeAt(idx);
                                      }),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CustomEntryDropdown(
                                  key: Key('queued_file_type_dropdown_$idx'),
                                  value: item.deliverableType,
                                  options: _types,
                                  decoration: _inputDecoration(isDark),
                                  borderRadius: BorderRadius.circular(4.0),
                                  customFieldLabel: 'Custom Type',
                                  customFieldHint: 'Enter file type...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      item.deliverableType = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPickingFile
                              ? null
                              : _pickDeliverableFiles,
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
                                ? 'Opening...'
                                : 'Browse Device Storage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPickingFile ? null : _pickGalleryPhotos,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 15,
                            color: AppColors.brandPeach,
                          ),
                          label: Text(
                            'Select Photos',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textLightPrimary
                                  : AppColors.textDarkPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                    ],
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
              isExpanded: true,
              decoration: _inputDecoration(isDark),
              borderRadius: BorderRadius.circular(4.0),
              items: projectNames.map((name) {
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

            if (_pickedFiles.isEmpty) ...[
              // Deliverable Type & Format Row (used when no files are queued yet)
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
                        CustomEntryDropdown(
                          value: _selectedType,
                          options: _types,
                          decoration: _inputDecoration(isDark),
                          borderRadius: BorderRadius.circular(4.0),
                          customFieldLabel: 'Custom Deliverable Type',
                          customFieldHint: 'Enter deliverable type...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: _onTypeChanged,
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
                        CustomEntryDropdown(
                          value: _selectedFormat,
                          options: _formats,
                          decoration: _inputDecoration(isDark),
                          borderRadius: BorderRadius.circular(4.0),
                          customFieldLabel: 'Custom Format',
                          customFieldHint: 'e.g. .SKP, .ZIP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (val) {
                            setState(() => _selectedFormat = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ] else
              const SizedBox(height: 18),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPeach,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(
                _pickedFiles.length > 1
                    ? 'Save ${_pickedFiles.length} Deliverables'
                    : 'Save Deliverable for Client Review',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
