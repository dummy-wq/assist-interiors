import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

class CloudUploadResult {
  final String storagePath;
  final String downloadUrl;

  const CloudUploadResult({
    required this.storagePath,
    required this.downloadUrl,
  });
}

/// Handles uploading and deleting binary project assets (site photos, CAD/PDF/BOQ files)
/// in Firebase Cloud Storage so uploaded media is accessible across all studio devices.
class CloudStorageService {
  CloudStorageService._();

  static const String _fallbackSyncEmail = 'sync.usr001@assistinteriors.in';
  static const String _fallbackSyncPassword = 'AssistSync#2026!USR-001';

  static bool get isAvailable => Firebase.apps.isNotEmpty;

  /// Ensures there is an active [FirebaseAuth] session before performing
  /// Firebase Storage or Firestore operations, even when the user opened the
  /// app from a persisted local session or Quick Demo role switch.
  static Future<bool> ensureAuthenticated({
    String? preferredEmail,
    String? preferredPassword,
  }) async {
    if (Firebase.apps.isEmpty) return false;
    if (FirebaseAuth.instance.currentUser != null) return true;

    final auth = FirebaseAuth.instance;

    // 1. Try user-supplied email & password first if valid (>= 6 chars).
    if (preferredEmail != null &&
        preferredEmail.contains('@') &&
        preferredPassword != null &&
        preferredPassword.length >= 6) {
      try {
        await auth.signInWithEmailAndPassword(
          email: preferredEmail,
          password: preferredPassword,
        );
        if (auth.currentUser != null) return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          try {
            await auth.createUserWithEmailAndPassword(
              email: preferredEmail,
              password: preferredPassword,
            );
            if (auth.currentUser != null) return true;
          } catch (_) {}
        }
      } catch (_) {}
    }

    // 2. Fallback to deterministic studio sync account so Email/Password auth
    // always succeeds across Android and Web without requiring re-login.
    try {
      await auth.signInWithEmailAndPassword(
        email: _fallbackSyncEmail,
        password: _fallbackSyncPassword,
      );
      if (auth.currentUser != null) return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        try {
          await auth.createUserWithEmailAndPassword(
            email: _fallbackSyncEmail,
            password: _fallbackSyncPassword,
          );
          if (auth.currentUser != null) return true;
        } catch (createErr) {
          debugPrint('Studio sync account creation note: $createErr');
        }
      } else {
        debugPrint('Studio sync sign-in note (${e.code}): ${e.message}');
      }
    } catch (e) {
      debugPrint('Studio sync auth error: $e');
    }

    // 3. Final fallback to anonymous auth if enabled.
    try {
      await auth.signInAnonymously();
      return auth.currentUser != null;
    } catch (_) {
      return auth.currentUser != null;
    }
  }

  /// Sanitizes a project name or ID into a safe Storage folder segment.
  static String _safeSegment(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return cleaned.isEmpty ? 'general' : cleaned;
  }

  /// Uploads a site photo to `projects/{projectId}/photos/{fileName}` in
  /// Firebase Storage and returns its [CloudUploadResult], or `null` if
  /// offline / unavailable.
  static Future<CloudUploadResult?> uploadSitePhoto({
    String? projectId,
    String? projectName,
    String? filePath,
    Uint8List? bytes,
    String? customFileName,
    String? title,
    String? tag,
    String? capturedBy,
    int? retentionMonths,
  }) async {
    if (!await ensureAuthenticated()) return null;
    try {
      final rawProject = projectId ?? projectName ?? 'general';
      final safeProject = _safeSegment(rawProject);
      final fileName = customFileName ??
          'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'projects/$safeProject/photos/$fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'projectId': rawProject,
          'title': ?title,
          'tag': ?tag,
          'capturedBy': ?capturedBy,
          if (retentionMonths != null)
            'retentionMonths': retentionMonths.toString(),
          'uploadedBy': FirebaseAuth.instance.currentUser?.email ??
              FirebaseAuth.instance.currentUser?.uid ??
              'studio_staff',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask task;
      if (bytes != null && bytes.isNotEmpty) {
        task = ref.putData(bytes, metadata);
      } else if (!kIsWeb && filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (!await file.exists()) return null;
        final fileBytes = await file.readAsBytes();
        task = ref.putData(fileBytes, metadata);
      } else {
        return null;
      }

      await task.timeout(const Duration(seconds: 30));
      final url = await ref.getDownloadURL();
      return CloudUploadResult(storagePath: storagePath, downloadUrl: url);
    } catch (e) {
      debugPrint('Firebase Storage uploadSitePhoto error: $e');
      return null;
    }
  }

  /// Scans local projects for any site photos saved locally without a cloud
  /// `downloadUrl` and uploads them to Firebase Storage so previously captured
  /// phone photos automatically appear in Firebase Console and on Web.
  static Future<bool> syncPendingLocalPhotos() async {
    if (kIsWeb || !await ensureAuthenticated()) return false;
    var anyUploaded = false;
    try {
      final projects = StorageService.getProjects();
      for (final project in projects) {
        final projectKey =
            (project['id'] ?? project['name'] ?? 'project').toString();
        for (final listKey in const ['photos', 'sitePhotos']) {
          final rawList = project[listKey];
          if (rawList is! List) continue;
          for (var i = 0; i < rawList.length; i++) {
            final item = rawList[i];
            if (item is! Map) continue;
            final photo = Map<String, dynamic>.from(item);
            final existingDownload =
                (photo['downloadUrl'] ?? '').toString().trim();
            if (existingDownload.startsWith('http://') ||
                existingDownload.startsWith('https://')) {
              continue;
            }
            final candidatePath =
                (photo['localPath'] ?? photo['imageUrl'] ?? photo['path'] ?? '')
                    .toString()
                    .trim();
            if (candidatePath.isEmpty ||
                candidatePath.startsWith('http://') ||
                candidatePath.startsWith('https://') ||
                candidatePath.startsWith('assets/')) {
              continue;
            }
            final file = File(candidatePath);
            if (!await file.exists()) continue;
            final result = await uploadSitePhoto(
              projectId: projectKey,
              filePath: candidatePath,
              title: photo['title']?.toString(),
              tag: photo['tag']?.toString(),
              capturedBy: photo['capturedBy']?.toString(),
            );
            if (result != null && result.downloadUrl.isNotEmpty) {
              photo['localPath'] = candidatePath;
              photo['storagePath'] = result.storagePath;
              photo['downloadUrl'] = result.downloadUrl;
              photo['imageUrl'] = result.downloadUrl;
              rawList[i] = photo;
              anyUploaded = true;
            }
          }
        }
      }
      if (anyUploaded) {
        await StorageService.saveProjects(projects);
      }
    } catch (e) {
      debugPrint('syncPendingLocalPhotos note: $e');
    }
    return anyUploaded;
  }

  /// Discovers any photos already uploaded to Firebase Storage under
  /// `projects/<project>/photos/` and attaches their `downloadUrl` and metadata
  /// to the matching project if not yet present in Firestore / local storage.
  static Future<bool> reconcileStoragePhotosWithProjects() async {
    if (!await ensureAuthenticated()) return false;
    var anyChanged = false;
    try {
      final rootRef = FirebaseStorage.instance.ref().child('projects');
      final rootList = await rootRef.listAll();
      if (rootList.prefixes.isEmpty) return false;

      final projects = StorageService.getProjects();
      if (projects.isEmpty) return false;

      for (final folderRef in rootList.prefixes) {
        final folderName = folderRef.name;
        var pIdx = projects.indexWhere((p) {
          final idSeg = _safeSegment((p['id'] ?? '').toString());
          final nameSeg = _safeSegment((p['name'] ?? '').toString());
          return idSeg == folderName || nameSeg == folderName;
        });
        if (pIdx == -1) pIdx = 0;

        final photosRef = folderRef.child('photos');
        ListResult photosList;
        try {
          photosList = await photosRef.listAll();
        } catch (_) {
          continue;
        }
        if (photosList.items.isEmpty) continue;

        final project = Map<String, dynamic>.from(projects[pIdx]);
        final existingPhotos = project['photos'] is List
            ? List<Map<String, dynamic>>.from(
                (project['photos'] as List).whereType<Map>().map(
                  (m) => Map<String, dynamic>.from(m),
                ),
              )
            : <Map<String, dynamic>>[];

        for (final item in photosList.items) {
          final storagePath = item.fullPath;
          final matchIdx = existingPhotos.indexWhere((ph) {
            final sp = (ph['storagePath'] ?? '').toString();
            final dl = (ph['downloadUrl'] ?? ph['imageUrl'] ?? '').toString();
            return sp == storagePath ||
                dl.contains(item.name) ||
                dl.contains(Uri.encodeComponent(item.name));
          });

          if (matchIdx != -1) {
            final existingUrl =
                (existingPhotos[matchIdx]['downloadUrl'] ?? '').toString();
            if (!existingUrl.startsWith('http')) {
              final url = await item.getDownloadURL();
              existingPhotos[matchIdx]['storagePath'] = storagePath;
              existingPhotos[matchIdx]['downloadUrl'] = url;
              existingPhotos[matchIdx]['imageUrl'] = url;
              existingPhotos[matchIdx]['hasImage'] = true;
              existingPhotos[matchIdx]['isUploaded'] = true;
              anyChanged = true;
            }
          } else {
            final url = await item.getDownloadURL();
            FullMetadata? meta;
            try {
              meta = await item.getMetadata();
            } catch (_) {}
            final custom = meta?.customMetadata ?? const <String, String>{};
            final created = meta?.timeCreated ?? DateTime.now();
            existingPhotos.insert(0, <String, dynamic>{
              'id': 'cloud_${item.name}',
              'title': (custom['title'] != null &&
                      custom['title']!.trim().isNotEmpty)
                  ? custom['title']!
                  : 'Site Inspection Photo',
              'tag': (custom['tag'] != null && custom['tag']!.trim().isNotEmpty)
                  ? custom['tag']!
                  : 'Site Progress',
              'timestamp': custom['uploadedAt'] ?? created.toIso8601String(),
              'capturedBy': (custom['capturedBy'] != null &&
                      custom['capturedBy']!.trim().isNotEmpty)
                  ? custom['capturedBy']!
                  : 'Site Supervisor',
              'storagePath': storagePath,
              'downloadUrl': url,
              'imageUrl': url,
              'hasImage': true,
              'isUploaded': true,
            });
            anyChanged = true;
          }
        }

        if (anyChanged) {
          project['photos'] = existingPhotos;
          projects[pIdx] = project;
        }
      }

      if (anyChanged) {
        await StorageService.saveProjects(projects);
        StorageService.cloudSyncNotifier.value =
            StorageService.cloudSyncNotifier.value + 1;
      }
    } catch (e) {
      debugPrint('reconcileStoragePhotosWithProjects note: $e');
    }
    return anyChanged;
  }

  /// Uploads a CAD / PDF / BOQ / Excel file to
  /// `projects/{projectId}/design_assets/{fileName}` and returns its [CloudUploadResult].
  static Future<CloudUploadResult?> uploadDesignAsset({
    String? projectId,
    String? projectName,
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    String? originalFileName,
    String? title,
    String? assetType,
    int? retentionMonths,
    String contentType = 'application/octet-stream',
  }) async {
    if (!await ensureAuthenticated()) return null;
    try {
      final rawProject = projectId ?? projectName ?? 'general';
      final safeProject = _safeSegment(rawProject);
      final rawFile = originalFileName ?? fileName ?? 'asset';
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${_safeSegment(rawFile)}';
      final storagePath = 'projects/$safeProject/design_assets/$safeName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'projectId': rawProject,
          'originalFileName': rawFile,
          'title': ?title,
          'assetType': ?assetType,
          if (retentionMonths != null)
            'retentionMonths': retentionMonths.toString(),
          'uploadedBy': FirebaseAuth.instance.currentUser?.email ??
              FirebaseAuth.instance.currentUser?.uid ??
              'studio_staff',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask task;
      if (bytes != null && bytes.isNotEmpty) {
        task = ref.putData(bytes, metadata);
      } else if (!kIsWeb && filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (!await file.exists()) return null;
        final fileBytes = await file.readAsBytes();
        task = ref.putData(fileBytes, metadata);
      } else {
        return null;
      }

      await task.timeout(const Duration(seconds: 40));
      final url = await ref.getDownloadURL();
      return CloudUploadResult(storagePath: storagePath, downloadUrl: url);
    } catch (e) {
      debugPrint('Firebase Storage uploadDesignAsset error: $e');
      return null;
    }
  }

  /// Deletes a file in Firebase Storage given its [storagePath] and/or [downloadUrl].
  static Future<void> deleteFile({
    String? storagePath,
    String? downloadUrl,
  }) async {
    if (!await ensureAuthenticated()) return;
    if (storagePath != null && storagePath.trim().isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref().child(storagePath.trim()).delete();
        return;
      } catch (e) {
        debugPrint('Firebase Storage deleteFile(storagePath) note: $e');
      }
    }
    if (downloadUrl != null && downloadUrl.trim().isNotEmpty) {
      await deleteByUrl(downloadUrl.trim());
    }
  }

  /// Deletes a file in Firebase Storage given its download URL.
  static Future<void> deleteByUrl(String downloadUrl) async {
    if (!await ensureAuthenticated() || downloadUrl.isEmpty) return;
    if (!downloadUrl.contains('firebasestorage.googleapis.com') &&
        !downloadUrl.startsWith('gs://')) {
      return;
    }
    try {
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Firebase Storage deleteByUrl note: $e');
    }
  }
}
