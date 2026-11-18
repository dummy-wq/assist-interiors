import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'storage_service.dart';

/// Represents a single site photo inside a segmented project archive folder.
class ArchivedProjectPhoto {
  final String projectId;
  final String projectName;
  final String projectFolderName;
  final String fileName;
  final String relativeArchivePath;
  final String title;
  final String tag;
  final String capturedBy;
  final String timestamp;
  final String uploadedAt;
  final int retentionMonths;
  final String reservedUntil;
  final Uint8List bytes;

  const ArchivedProjectPhoto({
    required this.projectId,
    required this.projectName,
    required this.projectFolderName,
    required this.fileName,
    required this.relativeArchivePath,
    required this.title,
    required this.tag,
    required this.capturedBy,
    required this.timestamp,
    required this.uploadedAt,
    required this.retentionMonths,
    required this.reservedUntil,
    required this.bytes,
  });

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'projectName': projectName,
        'projectFolderName': projectFolderName,
        'fileName': fileName,
        'relativeArchivePath': relativeArchivePath,
        'title': title,
        'tag': tag,
        'capturedBy': capturedBy,
        'timestamp': timestamp,
        'uploadedAt': uploadedAt,
        'retentionMonths': retentionMonths,
        'reservedUntil': reservedUntil,
        'byteLength': bytes.length,
      };
}

/// Represents a project directory inside the hierarchical photo export.
class ProjectPhotoFolder {
  final String projectId;
  final String projectName;
  final String folderName;
  final String location;
  final String status;
  final List<ArchivedProjectPhoto> photos;

  const ProjectPhotoFolder({
    required this.projectId,
    required this.projectName,
    required this.folderName,
    required this.location,
    required this.status,
    required this.photos,
  });

  int get totalBytes => photos.fold(0, (sum, p) => sum + p.bytes.length);

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'projectName': projectName,
        'folderName': folderName,
        'location': location,
        'status': status,
        'photoCount': photos.length,
        'photos': photos.map((p) => p.toMap()).toList(),
      };
}

/// Complete hierarchical manifest of all project photo folders and backend retention settings.
class ProjectPhotoArchiveManifest {
  final String archiveRootName;
  final int photoRetentionMonths;
  final int cadRetentionMonths;
  final String generatedAt;
  final List<ProjectPhotoFolder> projectFolders;

  const ProjectPhotoArchiveManifest({
    required this.archiveRootName,
    required this.photoRetentionMonths,
    required this.cadRetentionMonths,
    required this.generatedAt,
    required this.projectFolders,
  });

  int get totalProjects => projectFolders.length;
  int get totalProjectsWithPhotos =>
      projectFolders.where((f) => f.photos.isNotEmpty).length;
  int get totalPhotos =>
      projectFolders.fold(0, (sum, f) => sum + f.photos.length);
  int get totalBytes =>
      projectFolders.fold(0, (sum, f) => sum + f.totalBytes);

  Map<String, dynamic> toMap() => {
        'archiveRootName': archiveRootName,
        'photoRetentionPolicy': '$photoRetentionMonths Months',
        'cadRetentionPolicy': '$cadRetentionMonths Months',
        'generatedAt': generatedAt,
        'totalProjects': totalProjects,
        'totalPhotos': totalPhotos,
        'projectFolders': projectFolders.map((f) => f.toMap()).toList(),
      };
}

/// Result of exporting & packaging all project photos into a segmented hierarchy.
class PhotoArchiveExportResult {
  final ProjectPhotoArchiveManifest manifest;
  final Uint8List zipBytes;
  final String? zipFilePath;
  final String? extractedDirectoryPath;

  const PhotoArchiveExportResult({
    required this.manifest,
    required this.zipBytes,
    this.zipFilePath,
    this.extractedDirectoryPath,
  });
}

/// Service that manages backend site photo retention (6 months default, 12 months extended)
/// and packages all uploaded photos into a project-segmented folder hierarchy & ZIP archive.
class PhotoArchiveService {
  PhotoArchiveService._();

  // Valid 1x1 PNG header/footer base bytes used when synthesizing offline/seeded site photo files.
  static final List<int> _basePngHeader = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  static String sanitizeSegment(String input) {
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'Untitled' : cleaned;
  }

  /// Checks whether a photo uploaded at [uploadedIso] is still within the backend
  /// reservation window of [retentionMonths] months relative to [referenceTime].
  static bool isWithinRetentionWindow({
    required String? uploadedIso,
    required int retentionMonths,
    DateTime? referenceTime,
  }) {
    if (uploadedIso == null || uploadedIso.isEmpty) return true;
    final uploaded = DateTime.tryParse(uploadedIso);
    if (uploaded == null) return true;
    final now = referenceTime ?? DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionMonths * 30));
    return !uploaded.isBefore(cutoff);
  }

  /// Builds the segmented project hierarchy for all uploaded site photos within the
  /// active backend retention window (6 months by default, or 12 months when extended).
  static ProjectPhotoArchiveManifest buildSegmentedProjectHierarchy({
    List<Map<String, dynamic>>? projects,
    int? photoRetentionMonths,
    int? cadRetentionMonths,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final resolvedProjects = projects ?? StorageService.getProjects();
    final resolvedPhotoRetention =
        photoRetentionMonths ?? StorageService.getPhotoRetentionMonths();
    final resolvedCadRetention =
        cadRetentionMonths ?? StorageService.getCadRetentionMonths();

    final dateStamp = DateFormat('yyyyMMdd').format(now);
    final archiveRootName = 'Assist_Interiors_Photo_Archive_$dateStamp';

    final List<ProjectPhotoFolder> folders = [];

    for (int i = 0; i < resolvedProjects.length; i++) {
      final proj = resolvedProjects[i];
      final projId = (proj['id'] ?? 'PRJ-${i + 1}').toString();
      final projName = (proj['name'] ?? 'Project ${i + 1}').toString();
      final location = (proj['location'] ?? '').toString();
      final status = (proj['status'] ?? 'On Track').toString();

      final folderIndex = (i + 1).toString().padLeft(2, '0');
      final folderName = '${folderIndex}_${sanitizeSegment(projName)}';

      final rawPhotos = (proj['photos'] as List?) ?? const [];
      final List<ArchivedProjectPhoto> archivedPhotos = [];

      for (int pIdx = 0; pIdx < rawPhotos.length; pIdx++) {
        final raw = rawPhotos[pIdx];
        final photoMap = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{'title': raw.toString()};

        final uploadedAt =
            photoMap['uploadedAt']?.toString() ?? now.toIso8601String();
        if (!isWithinRetentionWindow(
          uploadedIso: uploadedAt,
          retentionMonths: resolvedPhotoRetention,
          referenceTime: now,
        )) {
          continue;
        }

        final title =
            (photoMap['title'] ?? 'Site Inspection Photo ${pIdx + 1}')
                .toString();
        final tag = (photoMap['tag'] ?? 'Site').toString();
        final capturedBy =
            (photoMap['capturedBy'] ?? 'Site Supervisor').toString();
        final timestamp = (photoMap['timestamp'] ??
                DateFormat('dd MMM yyyy').format(now))
            .toString();

        final uploadedDate = DateTime.tryParse(uploadedAt) ?? now;
        final reservedUntilDate = uploadedDate.add(
          Duration(days: resolvedPhotoRetention * 30),
        );
        final reservedUntil =
            DateFormat('dd MMM yyyy').format(reservedUntilDate);

        final photoNum = (pIdx + 1).toString().padLeft(2, '0');
        final imagePath = photoMap['imagePath']?.toString();
        String ext = '.png';
        Uint8List? fileBytes;

        if (imagePath != null &&
            imagePath.isNotEmpty &&
            !kIsWeb &&
            File(imagePath).existsSync()) {
          try {
            fileBytes = File(imagePath).readAsBytesSync();
            final dotIdx = imagePath.lastIndexOf('.');
            if (dotIdx != -1 && dotIdx < imagePath.length - 1) {
              ext = imagePath.substring(dotIdx).toLowerCase();
            }
          } catch (_) {
            fileBytes = null;
          }
        }

        fileBytes ??= _synthesizeSitePhotoBytes(
          projectName: projName,
          title: title,
          tag: tag,
          capturedBy: capturedBy,
          timestamp: timestamp,
          reservedUntil: reservedUntil,
        );

        final fileName =
            'Photo_${photoNum}_${sanitizeSegment(tag)}_${sanitizeSegment(title)}$ext';
        final relativePath = '$folderName/$fileName';

        archivedPhotos.add(
          ArchivedProjectPhoto(
            projectId: projId,
            projectName: projName,
            projectFolderName: folderName,
            fileName: fileName,
            relativeArchivePath: relativePath,
            title: title,
            tag: tag,
            capturedBy: capturedBy,
            timestamp: timestamp,
            uploadedAt: uploadedAt,
            retentionMonths: resolvedPhotoRetention,
            reservedUntil: reservedUntil,
            bytes: fileBytes,
          ),
        );
      }

      folders.add(
        ProjectPhotoFolder(
          projectId: projId,
          projectName: projName,
          folderName: folderName,
          location: location,
          status: status,
          photos: archivedPhotos,
        ),
      );
    }

    return ProjectPhotoArchiveManifest(
      archiveRootName: archiveRootName,
      photoRetentionMonths: resolvedPhotoRetention,
      cadRetentionMonths: resolvedCadRetention,
      generatedAt: DateFormat('dd MMM yyyy, hh:mm a').format(now),
      projectFolders: folders,
    );
  }

  static Uint8List _synthesizeSitePhotoBytes({
    required String projectName,
    required String title,
    required String tag,
    required String capturedBy,
    required String timestamp,
    required String reservedUntil,
  }) {
    final metadataComment = utf8.encode(
      '\nASSIST_INTERIORS_PHOTO_METADATA:'
      'project=$projectName|title=$title|tag=$tag|'
      'capturedBy=$capturedBy|timestamp=$timestamp|reservedUntil=$reservedUntil',
    );
    final builder = BytesBuilder(copy: false)
      ..add(_basePngHeader)
      ..add(metadataComment);
    return builder.toBytes();
  }

  /// Generates a `.zip` archive byte buffer with each project segmented into its own
  /// subfolder (`<archiveRootName>/<projectFolder>/<photoFileName>`).
  static Uint8List generateSegmentedZipBytes(
    ProjectPhotoArchiveManifest manifest,
  ) {
    final archive = Archive();
    final root = manifest.archiveRootName;

    // 1. Root retention & hierarchy manifest JSON
    final rootManifestJson =
        const JsonEncoder.withIndent('  ').convert(manifest.toMap());
    final rootManifestBytes = utf8.encode(rootManifestJson);
    archive.addFile(
      ArchiveFile.bytes(
        '$root/backend_retention_manifest.json',
        rootManifestBytes,
      ),
    );

    // 2. Per-project segmented folder hierarchy
    for (final folder in manifest.projectFolders) {
      final projectManifestJson =
          const JsonEncoder.withIndent('  ').convert(folder.toMap());
      archive.addFile(
        ArchiveFile.bytes(
          '$root/${folder.folderName}/project_photos_manifest.json',
          utf8.encode(projectManifestJson),
        ),
      );

      for (final photo in folder.photos) {
        archive.addFile(
          ArchiveFile.bytes(
            '$root/${photo.relativeArchivePath}',
            photo.bytes,
          ),
        );
      }
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Packages all uploaded site photos segmented by project hierarchy into a `.zip`
  /// archive and writes the segmented folder hierarchy to disk when supported.
  static Future<PhotoArchiveExportResult> downloadSegmentedProjectPhotosArchive({
    List<Map<String, dynamic>>? projects,
    int? photoRetentionMonths,
    int? cadRetentionMonths,
    String? customOutputDirectoryPath,
  }) async {
    final manifest = buildSegmentedProjectHierarchy(
      projects: projects,
      photoRetentionMonths: photoRetentionMonths,
      cadRetentionMonths: cadRetentionMonths,
    );
    final zipBytes = generateSegmentedZipBytes(manifest);

    String? zipPath;
    String? extractedDirPath;

    if (!kIsWeb) {
      try {
        final baseDir = customOutputDirectoryPath != null
            ? Directory(customOutputDirectoryPath)
            : Directory(
                '${Directory.systemTemp.path}/assist_interiors_exports',
              );
        if (!baseDir.existsSync()) {
          baseDir.createSync(recursive: true);
        }

        final zipFile = File('${baseDir.path}/${manifest.archiveRootName}.zip');
        zipFile.writeAsBytesSync(zipBytes, flush: true);
        zipPath = zipFile.path;

        final rootExtractDir =
            Directory('${baseDir.path}/${manifest.archiveRootName}');
        if (!rootExtractDir.existsSync()) {
          rootExtractDir.createSync(recursive: true);
        }

        final rootManifestFile = File(
          '${rootExtractDir.path}/backend_retention_manifest.json',
        );
        rootManifestFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(manifest.toMap()),
        );

        for (final folder in manifest.projectFolders) {
          final projDir =
              Directory('${rootExtractDir.path}/${folder.folderName}');
          if (!projDir.existsSync()) {
            projDir.createSync(recursive: true);
          }
          final projManifestFile = File(
            '${projDir.path}/project_photos_manifest.json',
          );
          projManifestFile.writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(folder.toMap()),
          );
          for (final photo in folder.photos) {
            final photoFile = File('${projDir.path}/${photo.fileName}');
            photoFile.writeAsBytesSync(photo.bytes, flush: true);
          }
        }
        extractedDirPath = rootExtractDir.path;
      } catch (e) {
        debugPrint('Photo archive filesystem export notice: $e');
      }
    }

    return PhotoArchiveExportResult(
      manifest: manifest,
      zipBytes: zipBytes,
      zipFilePath: zipPath,
      extractedDirectoryPath: extractedDirPath,
    );
  }
}
