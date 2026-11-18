import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/invoice_model.dart';
import 'database_service.dart';

class FirestoreDatabaseService implements DatabaseService {
  FirebaseFirestore? _firestore;

  @override
  bool get isCloudConnected => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (_firestore == null) {
      _firestore = FirebaseFirestore.instance;
      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore settings note: $e');
      }
    }
    return _firestore!;
  }

  @override
  Future<void> init() async {
    // If Firebase apps exist, initialize firestore settings
    if (isCloudConnected) {
      try {
        final _ = _db;
      } catch (e) {
        debugPrint('Firestore initialization warning: $e');
      }
    }
  }

  // --- PROJECTS ---
  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _db.collection('projects');

  @override
  Stream<List<ProjectModel>> streamProjects() {
    if (!isCloudConnected) return const Stream.empty();
    return _projectsRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createProject(ProjectModel project) async {
    if (!isCloudConnected) return;
    await _projectsRef
        .doc(project.id)
        .set(sanitizeForFirestore(project.toMap()), SetOptions(merge: true));
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    if (!isCloudConnected) return;
    await _projectsRef
        .doc(project.id)
        .set(sanitizeForFirestore(project.toMap()), SetOptions(merge: true));
  }

  @override
  Future<void> deleteProject(String id) async {
    if (!isCloudConnected) return;
    await _projectsRef.doc(id).delete();
  }

  // --- TASKS ---
  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _db.collection('tasks');

  @override
  Stream<List<TaskModel>> streamTasks() {
    if (!isCloudConnected) return const Stream.empty();
    return _tasksRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createTask(TaskModel task) async {
    if (!isCloudConnected) return;
    await _tasksRef.doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    if (!isCloudConnected) return;
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  @override
  Future<void> deleteTask(String id) async {
    if (!isCloudConnected) return;
    await _tasksRef.doc(id).delete();
  }

  // --- VENDORS ---
  CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      _db.collection('vendors');

  @override
  Stream<List<VendorModel>> streamVendors() {
    if (!isCloudConnected) return const Stream.empty();
    return _vendorsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VendorModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createVendor(VendorModel vendor) async {
    if (!isCloudConnected) return;
    await _vendorsRef
        .doc(vendor.id)
        .set(vendor.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateVendor(VendorModel vendor) async {
    if (!isCloudConnected) return;
    await _vendorsRef.doc(vendor.id).update(vendor.toMap());
  }

  @override
  Future<void> deleteVendor(String id) async {
    if (!isCloudConnected) return;
    await _vendorsRef.doc(id).delete();
  }

  // --- INVOICES ---
  CollectionReference<Map<String, dynamic>> get _invoicesRef =>
      _db.collection('invoices');

  @override
  Stream<List<InvoiceModel>> streamInvoices() {
    if (!isCloudConnected) return const Stream.empty();
    return _invoicesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    if (!isCloudConnected) return;
    await _invoicesRef
        .doc(invoice.id)
        .set(invoice.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    if (!isCloudConnected) return;
    await _invoicesRef.doc(invoice.id).update(invoice.toMap());
  }

  @override
  Future<void> deleteInvoice(String id) async {
    if (!isCloudConnected) return;
    await _invoicesRef.doc(id).delete();
  }

  @override
  Future<void> clearAll() async {
    if (!isCloudConnected) return;
    final pBatch = _db.batch();
    final pDocs = await _projectsRef.get();
    for (final doc in pDocs.docs) {
      pBatch.delete(doc.reference);
    }
    await pBatch.commit();
  }

  bool get isAuthenticatedSession =>
      isCloudConnected && FirebaseAuth.instance.currentUser != null;

  /// Recursively sanitizes Flutter [Color] / [DateTime] values and nested
  /// lists (`List<List<...>>`) into Firestore-safe primitives.
  static Map<String, dynamic> sanitizeForFirestore(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      out[key] = _sanitizeValue(value);
    });
    return out;
  }

  static dynamic _sanitizeValue(dynamic value, {bool insideList = false}) {
    if (value is Color) return value.toARGB32();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((k, v) {
        map[k.toString()] = _sanitizeValue(v);
      });
      return map;
    }
    if (value is List) {
      final sanitizedList =
          value.map((e) => _sanitizeValue(e, insideList: true)).toList();
      if (insideList) {
        return <String, dynamic>{'_nestedList': sanitizedList};
      }
      return sanitizedList;
    }
    return value;
  }

  /// Restores any Firestore-encoded nested lists (`{'_nestedList': [...]}`)
  /// back into native Dart nested `List` structures.
  static Map<String, dynamic> unsanitizeFromFirestore(
    Map<String, dynamic> raw,
  ) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      out[key] = _unsanitizeValue(value);
    });
    return out;
  }

  static dynamic _unsanitizeValue(dynamic value) {
    if (value is Map) {
      if (value.length == 1 &&
          value.containsKey('_nestedList') &&
          value['_nestedList'] is List) {
        return (value['_nestedList'] as List).map(_unsanitizeValue).toList();
      }
      final map = <String, dynamic>{};
      value.forEach((k, v) {
        map[k.toString()] = _unsanitizeValue(v);
      });
      return map;
    }
    if (value is List) {
      return value.map(_unsanitizeValue).toList();
    }
    return value;
  }

  /// Upserts a single document in [collection] by [docId] with merge semantics.
  Future<void> upsertDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (!isAuthenticatedSession || docId.isEmpty) return;
    try {
      final sanitized = sanitizeForFirestore({
        ...data,
        'id': data['id'] ?? docId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _db
          .collection(collection)
          .doc(docId)
          .set(sanitized, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore upsertDocument($collection/$docId) error: $e');
    }
  }

  /// Deletes a single document in [collection] by [docId].
  Future<void> deleteDocument(String collection, String docId) async {
    if (!isAuthenticatedSession || docId.isEmpty) return;
    try {
      await _db.collection(collection).doc(docId).delete();
    } catch (e) {
      debugPrint('Firestore deleteDocument($collection/$docId) error: $e');
    }
  }

  /// Batch-syncs a list of map records to [collection], replacing each
  /// document's fields (including emptied photo/asset lists) and removing
  /// any cloud document no longer present in [records].
  Future<void> syncCollection(
    String collection,
    List<Map<String, dynamic>> records,
  ) async {
    if (!isAuthenticatedSession) return;
    try {
      final batch = _db.batch();
      final colRef = _db.collection(collection);
      final activeIds = <String>{};
      for (int i = 0; i < records.length; i++) {
        final raw = records[i];
        final id = (raw['id'] ?? raw['name'] ?? '${collection}_$i')
            .toString()
            .replaceAll(RegExp(r'[/\\]'), '_');
        activeIds.add(id);
        final sanitized = sanitizeForFirestore({
          ...raw,
          'id': id,
          'createdAt': raw['createdAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        batch.set(colRef.doc(id), sanitized);
      }
      final existingSnap = await colRef.get();
      for (final doc in existingSnap.docs) {
        if (!activeIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore syncCollection($collection) error: $e');
    }
  }

  /// Fetches all documents in [collection] from Firestore.
  Future<List<Map<String, dynamic>>> fetchCollection(String collection) async {
    if (!isAuthenticatedSession) return const [];
    try {
      final snap = await _db.collection(collection).get();
      return snap.docs
          .map((d) => unsanitizeFromFirestore({'id': d.id, ...d.data()}))
          .toList();
    } catch (e) {
      debugPrint('Firestore fetchCollection($collection) error: $e');
      return const [];
    }
  }
}
