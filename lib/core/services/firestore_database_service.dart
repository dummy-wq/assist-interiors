import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        .set(project.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    if (!isCloudConnected) return;
    await _projectsRef.doc(project.id).update(project.toMap());
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
}
