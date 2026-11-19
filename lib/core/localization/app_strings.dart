/// Centralized English string labels & plain-word mappings for Assist Interiors.
class AppStrings {
  static const Map<String, String> _englishLabels = {
    'Upload BOQ': 'Upload Material List',
    'Add Invoice': 'New Invoice',
    'Add Amendment': 'New Change Request',
    'PROJECT TIMELINE SPREADSHEET': 'EXCEL TIMELINE FILE',
  };

  /// Returns the normalized English string for [text].
  static String tr(String text) {
    final trimmed = text.trim();
    return _englishLabels[text] ?? _englishLabels[trimmed] ?? text;
  }

  // Navigation & Tabs
  static const String tabHub = 'Hub';
  static const String tabSales = 'Sales';
  static const String tabDesign = 'Design';
  static const String tabProjects = 'Projects';
  static const String tabMaterials = 'Materials';
  static const String tabMaterialRequests = 'Material Requests';
  static const String tabAmendments = 'Change Requests';
  static const String tabVendors = 'Vendors';
  static const String tabTasks = 'Tasks';
  static const String tabAccounts = 'Accounts';
  static const String tabTeam = 'Team';
  static const String tabMore = 'More';

  // Actions & Buttons
  static const String projectsPortfolio = 'Projects Portfolio';
  static const String addNewProject = 'Add New Project';
  static const String updateProgress = 'Update Progress';
  static const String markAsDelayed = 'Mark Delayed';
  static const String revertToOnTrack = 'Revert to On Track';
  static const String editProject = 'Edit Project';
  static const String editProjectDetails = 'Edit Project Details';
  static const String saveChanges = 'Save Changes';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String close = 'Close';
  static const String submit = 'Submit';
  static const String addTask = 'Add Task';
  static const String newTask = '+ New Task';
  static const String addLead = 'Add New Lead';
  static const String saveLead = 'Save Lead to Pipeline';
  static const String addVendor = 'Add Vendor';
  static const String saveVendor = 'Save Vendor Profile';
  static const String createInvoice = 'Create Invoice';
  static const String addExpense = 'Add Expense';
  static const String inviteStaff = 'Invite Staff';
  static const String scheduleCall = 'Schedule Call';
  static const String updateStatus = 'Update Status';
  static const String initiateProject = 'Initiate Turnkey Project';
  static const String financialCommitment = 'FINANCIAL COMMITMENT';
  static const String complete = 'COMPLETE';
  static const String hideStages = 'Hide Stages';
  static const String addStage = 'Add Stage';
  static const String addNewTask = 'Add Task';
  static const String onboardVendor = 'Onboard Vendor';

  // Statuses
  static const String statusOnTrack = 'On Track';
  static const String statusDelayed = 'Delayed';
  static const String statusCompleted = 'Completed';
  static const String statusDesignPlanning = 'Design and Planning';
  static const String all = 'All';
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String inReview = 'In Review';
  static const String done = 'Done';
  static const String urgent = 'Urgent';
  static const String high = 'High';
  static const String medium = 'Medium';
  static const String low = 'Low';

  // Metrics & Headers
  static const String activeSites = 'Active Sites';
  static const String contractValue = 'Contract Value';
  static const String averageProgress = 'Average Progress';
  static const String handovers = 'Upcoming Handovers';
  static const String tasksAndMilestones = 'Tasks & Milestones';
  static const String dueThisWeek = 'Due This Week';
  static const String noProjectsListed = 'No Projects Listed';
  static const String netCashPosition = 'Net Cash Position';
  static const String totalInflow = 'Total Inflow';
  static const String totalOutflow = 'Total Outflow';
}

/// Syntactic sugar extension for consistent copy access: `'Add Task'.tr`
extension AppTranslateExtension on String {
  String get tr => AppStrings.tr(this);
}
