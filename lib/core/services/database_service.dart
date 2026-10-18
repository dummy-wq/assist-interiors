import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/vendor_model.dart';
import '../models/invoice_model.dart';

abstract class DatabaseService {
  Future<void> init();
  bool get isCloudConnected;

  // Projects
  Stream<List<ProjectModel>> streamProjects();
  Future<void> createProject(ProjectModel project);
  Future<void> updateProject(ProjectModel project);
  Future<void> deleteProject(String id);

  // Tasks
  Stream<List<TaskModel>> streamTasks();
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);

  // Vendors
  Stream<List<VendorModel>> streamVendors();
  Future<void> createVendor(VendorModel vendor);
  Future<void> updateVendor(VendorModel vendor);
  Future<void> deleteVendor(String id);

  // Invoices
  Stream<List<InvoiceModel>> streamInvoices();
  Future<void> createInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(String id);

  Future<void> clearAll();
}
