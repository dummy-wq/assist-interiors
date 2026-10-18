import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/invoice_model.dart';
import 'database_service.dart';
import 'local_database_service.dart';
import 'firestore_database_service.dart';

class BackendManager {
  static final BackendManager instance = BackendManager._();
  BackendManager._();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirestoreDatabaseService _firestoreDb = FirestoreDatabaseService();

  DatabaseService get activeService {
    if (Firebase.apps.isNotEmpty) {
      return _firestoreDb;
    }
    return _localDb;
  }

  bool get isCloudConnected => Firebase.apps.isNotEmpty;

  Future<void> init() async {
    await _localDb.init();
    if (Firebase.apps.isNotEmpty) {
      try {
        await _firestoreDb.init();
      } catch (e) {
        debugPrint('Firestore initialization error: $e');
      }
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

  /// Sync all existing local records to Firestore when connecting
  Future<void> syncLocalToCloud() async {
    if (!isCloudConnected) return;
    try {
      // Projects
      final projectsStream = _localDb.streamProjects();
      final projects = await projectsStream.first;
      for (final p in projects) {
        await _firestoreDb.createProject(p);
      }

      // Tasks
      final tasks = await _localDb.streamTasks().first;
      for (final t in tasks) {
        await _firestoreDb.createTask(t);
      }

      // Vendors
      final vendors = await _localDb.streamVendors().first;
      for (final v in vendors) {
        await _firestoreDb.createVendor(v);
      }

      // Invoices
      final invoices = await _localDb.streamInvoices().first;
      for (final i in invoices) {
        await _firestoreDb.createInvoice(i);
      }
      debugPrint(
        'Local database synchronized to Cloud Firestore successfully.',
      );
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> clearAll() async {
    await _localDb.clearAll();
    if (isCloudConnected) {
      await _firestoreDb.clearAll();
    }
  }
}
