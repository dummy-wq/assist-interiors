import 'dart:async';

import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/invoice_model.dart';
import 'database_service.dart';
import 'storage_service.dart';

class LocalDatabaseService implements DatabaseService {
  final List<ProjectModel> _projects = [];
  final List<TaskModel> _tasks = [];
  final List<VendorModel> _vendors = [];
  final List<InvoiceModel> _invoices = [];

  final _projectsController = StreamController<List<ProjectModel>>.broadcast();
  final _tasksController = StreamController<List<TaskModel>>.broadcast();
  final _vendorsController = StreamController<List<VendorModel>>.broadcast();
  final _invoicesController = StreamController<List<InvoiceModel>>.broadcast();

  @override
  bool get isCloudConnected => false;

  @override
  Future<void> init() async {
    _projects.clear();
    _projects.addAll(
      StorageService.getProjects().map((p) => ProjectModel.fromMap(p)),
    );

    _tasks.clear();
    _tasks.addAll(StorageService.getTasks().map((t) => TaskModel.fromMap(t)));

    _vendors.clear();
    _vendors.addAll(
      StorageService.getVendors().map((v) => VendorModel.fromMap(v)),
    );

    _invoices.clear();
    _invoices.addAll(
      StorageService.getInvoices().map((i) => InvoiceModel.fromMap(i)),
    );

    _notifyAll();
  }

  void _notifyAll() {
    if (!_projectsController.isClosed) {
      _projectsController.add(List.unmodifiable(_projects));
    }
    if (!_tasksController.isClosed) {
      _tasksController.add(List.unmodifiable(_tasks));
    }
    if (!_vendorsController.isClosed) {
      _vendorsController.add(List.unmodifiable(_vendors));
    }
    if (!_invoicesController.isClosed) {
      _invoicesController.add(List.unmodifiable(_invoices));
    }
  }

  // --- PROJECTS ---
  @override
  Stream<List<ProjectModel>> streamProjects() {
    Timer.run(() {
      if (!_projectsController.isClosed) {
        _projectsController.add(List.unmodifiable(_projects));
      }
    });
    return _projectsController.stream;
  }

  @override
  Future<void> createProject(ProjectModel project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    await _persistProjects();
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
      await _persistProjects();
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _persistProjects();
  }

  Future<void> _persistProjects() async {
    await StorageService.saveProjects(_projects.map((p) => p.toMap()).toList());
    if (!_projectsController.isClosed) {
      _projectsController.add(List.unmodifiable(_projects));
    }
  }

  // --- TASKS ---
  @override
  Stream<List<TaskModel>> streamTasks() {
    Timer.run(() {
      if (!_tasksController.isClosed) {
        _tasksController.add(List.unmodifiable(_tasks));
      }
    });
    return _tasksController.stream;
  }

  @override
  Future<void> createTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.insert(0, task);
    }
    await _persistTasks();
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
      await _persistTasks();
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _persistTasks();
  }

  Future<void> _persistTasks() async {
    await StorageService.saveTasks(_tasks.map((t) => t.toMap()).toList());
    if (!_tasksController.isClosed) {
      _tasksController.add(List.unmodifiable(_tasks));
    }
  }

  // --- VENDORS ---
  @override
  Stream<List<VendorModel>> streamVendors() {
    Timer.run(() {
      if (!_vendorsController.isClosed) {
        _vendorsController.add(List.unmodifiable(_vendors));
      }
    });
    return _vendorsController.stream;
  }

  @override
  Future<void> createVendor(VendorModel vendor) async {
    final index = _vendors.indexWhere((v) => v.id == vendor.id);
    if (index >= 0) {
      _vendors[index] = vendor;
    } else {
      _vendors.insert(0, vendor);
    }
    await _persistVendors();
  }

  @override
  Future<void> updateVendor(VendorModel vendor) async {
    final index = _vendors.indexWhere((v) => v.id == vendor.id);
    if (index >= 0) {
      _vendors[index] = vendor;
      await _persistVendors();
    }
  }

  @override
  Future<void> deleteVendor(String id) async {
    _vendors.removeWhere((v) => v.id == id);
    await _persistVendors();
  }

  Future<void> _persistVendors() async {
    await StorageService.saveVendors(_vendors.map((v) => v.toMap()).toList());
    if (!_vendorsController.isClosed) {
      _vendorsController.add(List.unmodifiable(_vendors));
    }
  }

  // --- INVOICES ---
  @override
  Stream<List<InvoiceModel>> streamInvoices() {
    Timer.run(() {
      if (!_invoicesController.isClosed) {
        _invoicesController.add(List.unmodifiable(_invoices));
      }
    });
    return _invoicesController.stream;
  }

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
    } else {
      _invoices.insert(0, invoice);
    }
    await _persistInvoices();
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
      await _persistInvoices();
    }
  }

  @override
  Future<void> deleteInvoice(String id) async {
    _invoices.removeWhere((i) => i.id == id);
    await _persistInvoices();
  }

  Future<void> _persistInvoices() async {
    await StorageService.saveInvoices(_invoices.map((i) => i.toMap()).toList());
    if (!_invoicesController.isClosed) {
      _invoicesController.add(List.unmodifiable(_invoices));
    }
  }

  @override
  Future<void> clearAll() async {
    _projects.clear();
    _tasks.clear();
    _vendors.clear();
    _invoices.clear();
    await StorageService.clearAll();
    _notifyAll();
  }
}
