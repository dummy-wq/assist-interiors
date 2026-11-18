import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/invoice_model.dart';
import 'cloud_storage_service.dart';
import 'database_service.dart';
import 'local_database_service.dart';
import 'firestore_database_service.dart';
import 'storage_service.dart';

enum CloudSyncState { synced, syncing, offline }

class BackendManager {
  static final BackendManager instance = BackendManager._();
  BackendManager._();

  static final ValueNotifier<CloudSyncState> syncStateNotifier =
      ValueNotifier<CloudSyncState>(CloudSyncState.offline);

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirestoreDatabaseService _firestoreDb = FirestoreDatabaseService();
  final List<StreamSubscription<dynamic>> _realtimeSubscriptions = [];
  bool _realtimeSyncActive = false;

  static void setSyncState(CloudSyncState state) {
    syncStateNotifier.value = state;
  }

  CloudSyncState get currentSyncState {
    if (!isCloudConnected || !isAuthenticatedCloud) {
      return CloudSyncState.offline;
    }
    return syncStateNotifier.value;
  }

  DatabaseService get activeService {
    if (Firebase.apps.isNotEmpty) {
      return _firestoreDb;
    }
    return _localDb;
  }

  bool get isCloudConnected => Firebase.apps.isNotEmpty;
  bool get isAuthenticatedCloud =>
      isCloudConnected && FirebaseAuth.instance.currentUser != null;

  Future<void> init() async {
    await _localDb.init();
    if (Firebase.apps.isNotEmpty) {
      syncStateNotifier.value = CloudSyncState.syncing;
      try {
        await _firestoreDb.init();
        final authed = await CloudStorageService.ensureAuthenticated();
        if (authed) {
          await _ensureFirestoreUserBootstrap();
          syncStateNotifier.value = CloudSyncState.synced;
          unawaited(syncLocalToCloud());
        } else {
          syncStateNotifier.value = CloudSyncState.offline;
        }
      } catch (e) {
        syncStateNotifier.value = CloudSyncState.offline;
        debugPrint('Firestore initialization error: $e');
      }
    } else {
      syncStateNotifier.value = CloudSyncState.offline;
    }
  }

  Future<void> _ensureFirestoreUserBootstrap() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .set({
        'id': fbUser.uid,
        'fullName': 'Rajesh Sharma',
        'email': fbUser.email ?? 'rajesh@assistinteriors.in',
        'phone': '+91 98100 12345',
        'role': 'proprietor',
        'status': 'approved',
        'seenByProprietor': true,
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore user bootstrap note: $e');
    }
  }

  // --- CRUD Delegates ---
  Stream<List<ProjectModel>> streamProjects() => activeService.streamProjects();
  Future<void> createProject(ProjectModel project) async {
    await _localDb.createProject(project);
    if (isCloudConnected) {
      await _firestoreDb.createProject(project);
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    await _localDb.updateProject(project);
    if (isCloudConnected) {
      await _firestoreDb.updateProject(project);
    }
  }

  Future<void> deleteProject(String id) async {
    await _localDb.deleteProject(id);
    if (isCloudConnected) {
      await _firestoreDb.deleteProject(id);
    }
  }

  Stream<List<TaskModel>> streamTasks() => activeService.streamTasks();
  Future<void> createTask(TaskModel task) async {
    await _localDb.createTask(task);
    if (isCloudConnected) {
      await _firestoreDb.createTask(task);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    await _localDb.updateTask(task);
    if (isCloudConnected) {
      await _firestoreDb.updateTask(task);
    }
  }

  Future<void> deleteTask(String id) async {
    await _localDb.deleteTask(id);
    if (isCloudConnected) {
      await _firestoreDb.deleteTask(id);
    }
  }

  Stream<List<VendorModel>> streamVendors() => activeService.streamVendors();
  Future<void> createVendor(VendorModel vendor) async {
    await _localDb.createVendor(vendor);
    if (isCloudConnected) {
      await _firestoreDb.createVendor(vendor);
    }
  }

  Future<void> updateVendor(VendorModel vendor) async {
    await _localDb.updateVendor(vendor);
    if (isCloudConnected) {
      await _firestoreDb.updateVendor(vendor);
    }
  }

  Future<void> deleteVendor(String id) async {
    await _localDb.deleteVendor(id);
    if (isCloudConnected) {
      await _firestoreDb.deleteVendor(id);
    }
  }

  Stream<List<InvoiceModel>> streamInvoices() => activeService.streamInvoices();
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _localDb.createInvoice(invoice);
    if (isCloudConnected) {
      await _firestoreDb.createInvoice(invoice);
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _localDb.updateInvoice(invoice);
    if (isCloudConnected) {
      await _firestoreDb.updateInvoice(invoice);
    }
  }

  Future<void> deleteInvoice(String id) async {
    await _localDb.deleteInvoice(id);
    if (isCloudConnected) {
      await _firestoreDb.deleteInvoice(id);
    }
  }

  // --- Extended Collection Sync Delegates (Leads, Design, Materials, Amendments, Expenses, Roles, Settings) ---

  Future<void> upsertCollectionRecord(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (!isCloudConnected) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    if (!await CloudStorageService.ensureAuthenticated()) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    syncStateNotifier.value = CloudSyncState.syncing;
    await _firestoreDb.upsertDocument(collection, docId, data);
    syncStateNotifier.value = CloudSyncState.synced;
  }

  Future<void> deleteDocument(String collection, String docId) async {
    if (!isCloudConnected) return;
    if (!await CloudStorageService.ensureAuthenticated()) return;
    syncStateNotifier.value = CloudSyncState.syncing;
    await _firestoreDb.deleteDocument(collection, docId);
    syncStateNotifier.value = CloudSyncState.synced;
  }

  Future<void> syncCollection(
    String collection,
    List<Map<String, dynamic>> records,
  ) async {
    if (!isCloudConnected) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    if (!await CloudStorageService.ensureAuthenticated()) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    syncStateNotifier.value = CloudSyncState.syncing;
    await _firestoreDb.syncCollection(collection, records);
    syncStateNotifier.value = CloudSyncState.synced;
  }

  Future<List<Map<String, dynamic>>> fetchCollection(String collection) async {
    if (!isCloudConnected) return const [];
    if (!await CloudStorageService.ensureAuthenticated()) return const [];
    return _firestoreDb.fetchCollection(collection);
  }

  Future<void> syncStudioRetentionSettings({
    required int photoRetentionMonths,
    required int cadRetentionMonths,
  }) async {
    if (!isCloudConnected) return;
    if (!await CloudStorageService.ensureAuthenticated()) return;
    syncStateNotifier.value = CloudSyncState.syncing;
    await _firestoreDb.upsertDocument('studio_settings', 'retention_policy', {
      'id': 'retention_policy',
      'photoRetentionMonths': photoRetentionMonths,
      'cadRetentionMonths': cadRetentionMonths,
    });
    syncStateNotifier.value = CloudSyncState.synced;
  }

  /// Sync all existing local records with Firestore when connecting with an authenticated session.
  /// - When a Firestore collection is empty, seeds it from local storage.
  /// - When Firestore already has documents, Firestore is treated as the single source of truth
  ///   so photos or records deleted on one device are never resurrected from another device's local cache.
  Future<void> syncLocalToCloud() async {
    if (!isCloudConnected) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    final authed = await CloudStorageService.ensureAuthenticated();
    if (!authed) {
      syncStateNotifier.value = CloudSyncState.offline;
      return;
    }
    syncStateNotifier.value = CloudSyncState.syncing;
    try {
      await CloudStorageService.syncPendingLocalPhotos();

      final collectionsToSync = <String, List<Map<String, dynamic>>>{
        'projects': StorageService.getProjects(),
        'tasks': StorageService.getTasks(),
        'vendors': StorageService.getVendors(),
        'invoices': StorageService.getInvoices(),
        'leads': StorageService.getLeads(),
        'design_items': StorageService.getDesignItems(),
        'material_requests': StorageService.getMaterialRequests(),
        'amendments': StorageService.getAmendments(),
        'expenses': StorageService.getExpenses(),
        'custom_roles': StorageService.getCustomRoles(),
      };

      for (final entry in collectionsToSync.entries) {
        final col = entry.key;
        final localDocs = entry.value;
        final remoteDocs = await fetchCollection(col);
        if (remoteDocs.isEmpty) {
          if (localDocs.isNotEmpty) {
            await syncCollection(col, localDocs);
          }
        } else {
          await StorageService.applyRemoteCollection(col, remoteDocs);
        }
      }

      await syncStudioRetentionSettings(
        photoRetentionMonths: StorageService.getPhotoRetentionMonths(),
        cadRetentionMonths: StorageService.getCadRetentionMonths(),
      );

      syncStateNotifier.value = CloudSyncState.synced;
      debugPrint(
        'Local database synchronized with Cloud Firestore successfully.',
      );
    } catch (e) {
      syncStateNotifier.value = CloudSyncState.offline;
      debugPrint('Sync error: $e');
    }
  }

  /// Subscribes to real-time Firestore snapshot streams across all studio
  /// collections so changes made on any device appear on open screens without
  /// requiring an app restart.
  void startRealtimeSync({
    void Function(List<Map<String, dynamic>> users)? onUsersSnapshot,
    void Function(List<Map<String, dynamic>> roles)? onCustomRolesSnapshot,
    void Function(int photoMonths, int cadMonths)? onRetentionSnapshot,
  }) {
    if (!isCloudConnected || _realtimeSyncActive) return;
    if (!isAuthenticatedCloud) {
      CloudStorageService.ensureAuthenticated().then((authed) {
        if (authed) {
          startRealtimeSync(
            onUsersSnapshot: onUsersSnapshot,
            onCustomRolesSnapshot: onCustomRolesSnapshot,
            onRetentionSnapshot: onRetentionSnapshot,
          );
        }
      });
      return;
    }
    _realtimeSyncActive = true;

    final db = FirebaseFirestore.instance;
    const syncedCollections = [
      'projects',
      'tasks',
      'vendors',
      'invoices',
      'leads',
      'design_items',
      'material_requests',
      'amendments',
      'expenses',
    ];

    for (final col in syncedCollections) {
      final sub = db.collection(col).snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;
          final docs = snapshot.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
          StorageService.applyRemoteCollection(col, docs);
        },
        onError: (Object e) {
          debugPrint('Realtime sync listener($col) notice: $e');
        },
      );
      _realtimeSubscriptions.add(sub);
    }

    if (onUsersSnapshot != null) {
      final userSub = db.collection('users').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;
          final docs = snapshot.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
          onUsersSnapshot(docs);
        },
        onError: (Object e) {
          debugPrint('Realtime sync listener(users) notice: $e');
        },
      );
      _realtimeSubscriptions.add(userSub);
    }

    if (onCustomRolesSnapshot != null) {
      final rolesSub = db.collection('custom_roles').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) return;
          final docs = snapshot.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
          StorageService.applyRemoteCollection('custom_roles', docs);
          onCustomRolesSnapshot(docs);
        },
        onError: (Object e) {
          debugPrint('Realtime sync listener(custom_roles) notice: $e');
        },
      );
      _realtimeSubscriptions.add(rolesSub);
    }

    if (onRetentionSnapshot != null) {
      final retentionSub = db
          .collection('studio_settings')
          .doc('retention_policy')
          .snapshots()
          .listen(
        (doc) {
          if (!doc.exists) return;
          final data = doc.data();
          if (data == null) return;
          final photoM = (data['photoRetentionMonths'] as num?)?.toInt() ??
              StorageService.defaultPhotoRetentionMonths;
          final cadM = (data['cadRetentionMonths'] as num?)?.toInt() ??
              StorageService.defaultCadRetentionMonths;
          onRetentionSnapshot(photoM, cadM);
        },
        onError: (Object e) {
          debugPrint('Realtime sync listener(studio_settings) notice: $e');
        },
      );
      _realtimeSubscriptions.add(retentionSub);
    }
  }

  /// Cancels all active Firestore real-time listeners (e.g., on sign-out).
  Future<void> stopRealtimeSync() async {
    _realtimeSyncActive = false;
    for (final sub in _realtimeSubscriptions) {
      await sub.cancel();
    }
    _realtimeSubscriptions.clear();
  }

  Future<void> clearAll() async {
    await _localDb.clearAll();
    if (isAuthenticatedCloud) {
      await _firestoreDb.clearAll();
    }
  }
}
