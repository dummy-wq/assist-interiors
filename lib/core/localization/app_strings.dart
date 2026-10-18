import 'package:flutter/material.dart';

/// Supported application languages
enum AppLanguage { english, hindi, marathi, tamil, telugu }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.marathi:
        return 'mr';
      case AppLanguage.tamil:
        return 'ta';
      case AppLanguage.telugu:
        return 'te';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिंदी';
      case AppLanguage.marathi:
        return 'मराठी';
      case AppLanguage.tamil:
        return 'தமிழ்';
      case AppLanguage.telugu:
        return 'తెలుగు';
    }
  }

  String get shortCode {
    switch (this) {
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.hindi:
        return 'HI';
      case AppLanguage.marathi:
        return 'MR';
      case AppLanguage.tamil:
        return 'TA';
      case AppLanguage.telugu:
        return 'TE';
    }
  }

  Locale get locale => Locale(code);
}

/// Comprehensive, instantaneous localization dictionary for Assist Interiors.
class AppStrings {
  static AppLanguage currentLanguage = AppLanguage.english;

  static void setLanguage(AppLanguage lang) {
    currentLanguage = lang;
  }

  /// Translates any word or phrase dynamically based on current language.
  /// Falls back to original text if no translation is found.
  static String tr(String text) {
    if (currentLanguage == AppLanguage.english) return text;
    final trimmed = text.trim();
    final match =
        _dictionary[text] ??
        _dictionary[trimmed] ??
        _dictionary[trimmed.toLowerCase()];
    if (match != null) {
      final translation = match[currentLanguage];
      if (translation != null && translation.isNotEmpty) {
        return translation;
      }
    }
    return text;
  }

  // --- Static Getters with Dictionary Integration ---

  // Navigation & Tabs
  static String get tabHub => tr('Hub');
  static String get tabSales => tr('Sales');
  static String get tabProjects => tr('Projects');
  static String get tabVendors => tr('Vendors');
  static String get tabTasks => tr('Tasks');
  static String get tabAccounts => tr('Accounts');
  static String get tabTeam => tr('Team');

  // Actions & Buttons
  static String get projectsPortfolio => tr('Projects Portfolio');
  static String get addNewProject => tr('Add New Project');
  static String get updateProgress => tr('Update Progress');
  static String get markAsDelayed => tr('Mark Delayed');
  static String get revertToOnTrack => tr('Revert to On Track');
  static String get editProject => tr('Edit Project');
  static String get editProjectDetails => tr('Edit Project Details');
  static String get saveChanges => tr('Save Changes');
  static String get cancel => tr('Cancel');
  static String get save => tr('Save');
  static String get delete => tr('Delete');
  static String get close => tr('Close');
  static String get submit => tr('Submit');
  static String get addTask => tr('Add Task');
  static String get newTask => tr('+ New Task');
  static String get addLead => tr('Add New Lead');
  static String get saveLead => tr('Save Lead to Pipeline');
  static String get addVendor => tr('Add Vendor');
  static String get saveVendor => tr('Save Vendor Profile');
  static String get createInvoice => tr('Create Invoice');
  static String get addExpense => tr('Add Expense');
  static String get inviteStaff => tr('Invite Staff');
  static String get scheduleCall => tr('Schedule Call');
  static String get updateStatus => tr('Update Status');
  static String get initiateProject => tr('Initiate Turnkey Project');
  static String get financialCommitment => tr('FINANCIAL COMMITMENT');
  static String get complete => tr('COMPLETE');
  static String get hideStages => tr('Hide Stages');
  static String get addStage => tr('Add Stage');
  static String get addNewTask => tr('Add Task');
  static String get onboardVendor => tr('Onboard Vendor');

  // Statuses
  static String get statusOnTrack => tr('On Track');
  static String get statusDelayed => tr('Delayed');
  static String get statusCompleted => tr('Completed');
  static String get statusDesignPlanning => tr('Design and Planning');
  static String get all => tr('All');
  static String get pending => tr('Pending');
  static String get inProgress => tr('In Progress');
  static String get inReview => tr('In Review');
  static String get done => tr('Done');
  static String get urgent => tr('Urgent');
  static String get high => tr('High');
  static String get medium => tr('Medium');
  static String get low => tr('Low');

  // Metrics & Headers
  static String get activeSites => tr('Active Sites');
  static String get contractValue => tr('Contract Value');
  static String get averageProgress => tr('Average Progress');
  static String get handovers => tr('Upcoming Handovers');
  static String get tasksAndMilestones => tr('Tasks & Milestones');
  static String get dueThisWeek => tr('Due This Week');
  static String get noProjectsListed => tr('No Projects Listed');
  static String get netCashPosition => tr('Net Cash Position');
  static String get totalInflow => tr('Total Inflow');
  static String get totalOutflow => tr('Total Outflow');

  // Comprehensive Multilingual Translation Dictionary
  static final Map<String, Map<AppLanguage, String>> _dictionary = {
    // --- Navigation ---
    'Hub': {
      AppLanguage.english: 'Hub',
      AppLanguage.hindi: 'हब',
      AppLanguage.marathi: 'हब',
      AppLanguage.tamil: 'மையம்',
      AppLanguage.telugu: 'హబ్',
    },
    'Sales': {
      AppLanguage.english: 'Sales',
      AppLanguage.hindi: 'बिक्री',
      AppLanguage.marathi: 'विक्री',
      AppLanguage.tamil: 'விற்பனை',
      AppLanguage.telugu: 'అమ్మకాలు',
    },
    'Projects': {
      AppLanguage.english: 'Projects',
      AppLanguage.hindi: 'प्रोजेक्ट्स',
      AppLanguage.marathi: 'प्रकल्प',
      AppLanguage.tamil: 'திட்டங்கள்',
      AppLanguage.telugu: 'ప్రాజెక్టులు',
    },
    'Vendors': {
      AppLanguage.english: 'Vendors',
      AppLanguage.hindi: 'वेंडर्स',
      AppLanguage.marathi: 'विक्रेते',
      AppLanguage.tamil: 'விற்பனையாளர்கள்',
      AppLanguage.telugu: 'విక్రేతలు',
    },
    'Tasks': {
      AppLanguage.english: 'Tasks',
      AppLanguage.hindi: 'कार्य',
      AppLanguage.marathi: 'कार्ये',
      AppLanguage.tamil: 'பணிகள்',
      AppLanguage.telugu: 'పనులు',
    },
    'Accounts': {
      AppLanguage.english: 'Accounts',
      AppLanguage.hindi: 'खाते',
      AppLanguage.marathi: 'खाती',
      AppLanguage.tamil: 'கணக்குகள்',
      AppLanguage.telugu: 'ఖాతాలు',
    },
    'Team': {
      AppLanguage.english: 'Team',
      AppLanguage.hindi: 'टीम',
      AppLanguage.marathi: 'संघ',
      AppLanguage.tamil: 'குழு',
      AppLanguage.telugu: 'బృందం',
    },

    // --- Projects & Metrics ---
    'Projects Portfolio': {
      AppLanguage.english: 'Projects Portfolio',
      AppLanguage.hindi: 'प्रोजेक्ट पोर्टफोलियो',
      AppLanguage.marathi: 'प्रकल्प पोर्टफोलिओ',
      AppLanguage.tamil: 'திட்டங்கள் போர்ட்ஃபோலியோ',
      AppLanguage.telugu: 'ప్రాజెక్టుల పోర్ట్‌ఫోలియో',
    },
    'Add New Project': {
      AppLanguage.english: 'Add New Project',
      AppLanguage.hindi: 'नया प्रोजेक्ट जोड़ें',
      AppLanguage.marathi: 'नवीन प्रकल्प जोडा',
      AppLanguage.tamil: 'புதிய திட்டம் சேர்க்க',
      AppLanguage.telugu: 'కొత్త ప్రాజెక్ట్ జోడించండి',
    },
    'Update Progress': {
      AppLanguage.english: 'Update Progress',
      AppLanguage.hindi: 'प्रगति अपडेट करें',
      AppLanguage.marathi: 'प्रगती अपडेट करा',
      AppLanguage.tamil: 'முன்னேற்றத்தைப் புதுப்பிக்கவும்',
      AppLanguage.telugu: 'పురోగతిని నవీకరించండి',
    },
    'Mark Delayed': {
      AppLanguage.english: 'Mark Delayed',
      AppLanguage.hindi: 'विलंबित चिह्नित करें',
      AppLanguage.marathi: 'विलंबित चिन्हांकित करा',
      AppLanguage.tamil: 'தாமதமாக குறிக்கவும்',
      AppLanguage.telugu: 'ఆలస్యంగా గుర్తించండి',
    },
    'Mark as Delayed': {
      AppLanguage.english: 'Mark as Delayed',
      AppLanguage.hindi: 'विलंबित चिह्नित करें',
      AppLanguage.marathi: 'विलंबित चिन्हांकित करा',
      AppLanguage.tamil: 'தாமதமாக குறிக்கவும்',
      AppLanguage.telugu: 'ఆలస్యంగా గుర్తించండి',
    },
    'Revert to On Track': {
      AppLanguage.english: 'Revert to On Track',
      AppLanguage.hindi: 'समय पर वापस करें',
      AppLanguage.marathi: 'ट्रॅकवर परत आणा',
      AppLanguage.tamil: 'சரியான நிலைக்கு மாற்றவும்',
      AppLanguage.telugu: 'సమయానికి మార్చండి',
    },
    'Edit Project': {
      AppLanguage.english: 'Edit Project',
      AppLanguage.hindi: 'प्रोजेक्ट संपादित करें',
      AppLanguage.marathi: 'प्रकल्प संपादित करा',
      AppLanguage.tamil: 'திட்டத்தைத் திருத்து',
      AppLanguage.telugu: 'ప్రాజెక్ట్‌ను సవరించండి',
    },
    'Edit Project Details': {
      AppLanguage.english: 'Edit Project Details',
      AppLanguage.hindi: 'प्रोजेक्ट विवरण संपादित करें',
      AppLanguage.marathi: 'प्रकल्प तपशील संपादित करा',
      AppLanguage.tamil: 'திட்ட விவரங்களைத் திருத்து',
      AppLanguage.telugu: 'ప్రాజెక్ట్ వివరాలను సవరించండి',
    },
    'Project Options': {
      AppLanguage.english: 'Project Options',
      AppLanguage.hindi: 'प्रोजेक्ट विकल्प',
      AppLanguage.marathi: 'प्रकल्प पर्याय',
      AppLanguage.tamil: 'திட்ட விருப்பங்கள்',
      AppLanguage.telugu: 'ప్రాజెక్ట్ ఎంపికలు',
    },
    'Save Changes': {
      AppLanguage.english: 'Save Changes',
      AppLanguage.hindi: 'बदलाव सहेजें',
      AppLanguage.marathi: 'बदल जतन करा',
      AppLanguage.tamil: 'மாற்றங்களைச் சேமிக்க',
      AppLanguage.telugu: 'మార్పులను సేవ్ చేయండి',
    },
    'Project details updated successfully!': {
      AppLanguage.english: 'Project details updated successfully!',
      AppLanguage.hindi: 'प्रोजेक्ट विवरण सफलतापूर्वक अपडेट किया गया!',
      AppLanguage.marathi: 'प्रकल्प तपशील यशस्वीरित्या अद्यतनित केले!',
      AppLanguage.tamil: 'திட்ட விவரங்கள் வெற்றிகரமாக புதுப்பிக்கப்பட்டன!',
      AppLanguage.telugu: 'ప్రాజెక్ట్ వివరాలు విజయవంతంగా నవీకరించబడ్డాయి!',
    },
    'Active Sites': {
      AppLanguage.english: 'Active Sites',
      AppLanguage.hindi: 'सक्रिय साइटें',
      AppLanguage.marathi: 'सक्रिय साइट्स',
      AppLanguage.tamil: 'செயலில் உள்ள தளங்கள்',
      AppLanguage.telugu: 'క్రియాశీల సైట్లు',
    },
    'Contract Value': {
      AppLanguage.english: 'Contract Value',
      AppLanguage.hindi: 'अनुबंध मूल्य',
      AppLanguage.marathi: 'करार मूल्य',
      AppLanguage.tamil: 'ஒப்பந்த மதிப்பு',
      AppLanguage.telugu: 'ఒప్పందం విలువ',
    },
    'Average Progress': {
      AppLanguage.english: 'Average Progress',
      AppLanguage.hindi: 'औसत प्रगति',
      AppLanguage.marathi: 'सरासरी प्रगती',
      AppLanguage.tamil: 'சராசரி முன்னேற்றம்',
      AppLanguage.telugu: 'సగటు పురోగతి',
    },
    'Upcoming Handovers': {
      AppLanguage.english: 'Upcoming Handovers',
      AppLanguage.hindi: 'आगामी हस्तांतरण',
      AppLanguage.marathi: 'आगामी हस्तांतरण',
      AppLanguage.tamil: 'வரவிருக்கும் ஒப்படைப்புகள்',
      AppLanguage.telugu: 'రాబోయే అప్పగింతలు',
    },
    'Handovers': {
      AppLanguage.english: 'Handovers',
      AppLanguage.hindi: 'हस्तांतरण',
      AppLanguage.marathi: 'हस्तांतरण',
      AppLanguage.tamil: 'ஒப்படைப்புகள்',
      AppLanguage.telugu: 'అప్పగింతలు',
    },
    'All': {
      AppLanguage.english: 'All',
      AppLanguage.hindi: 'सभी',
      AppLanguage.marathi: 'सर्व',
      AppLanguage.tamil: 'அனைத்தும்',
      AppLanguage.telugu: 'అన్నీ',
    },
    'Tasks & Milestones': {
      AppLanguage.english: 'Tasks & Milestones',
      AppLanguage.hindi: 'कार्य और मील के पत्थर',
      AppLanguage.marathi: 'कार्ये आणि टप्पे',
      AppLanguage.tamil: 'பணிகள் & மைல்கற்கள்',
      AppLanguage.telugu: 'పనులు & మైలురాళ్ళు',
    },
    'Pending': {
      AppLanguage.english: 'Pending',
      AppLanguage.hindi: 'लंबित',
      AppLanguage.marathi: 'प्रलंबित',
      AppLanguage.tamil: 'நிலுவையில்',
      AppLanguage.telugu: 'పెండింగ్‌లో ఉంది',
    },
    'Due This Week': {
      AppLanguage.english: 'Due This Week',
      AppLanguage.hindi: 'इस सप्ताह देय',
      AppLanguage.marathi: 'या आठवड्यात देय',
      AppLanguage.tamil: 'இந்த வாரம் முடிவடைகிறது',
      AppLanguage.telugu: 'ఈ వారం గడువు',
    },
    'No Projects Listed': {
      AppLanguage.english: 'No Projects Listed',
      AppLanguage.hindi: 'कोई प्रोजेक्ट सूचीबद्ध नहीं',
      AppLanguage.marathi: 'कोणतेही प्रकल्प नाहीत',
      AppLanguage.tamil: 'திட்டங்கள் எதுவும் இல்லை',
      AppLanguage.telugu: 'ప్రాజెక్టులు ఏవీ లేవు',
    },

    // --- Statuses ---
    'On Track': {
      AppLanguage.english: 'On Track',
      AppLanguage.hindi: 'समय पर',
      AppLanguage.marathi: 'वेळेवर',
      AppLanguage.tamil: 'சரியான பாதையில்',
      AppLanguage.telugu: 'సమయానికి',
    },
    'Delayed': {
      AppLanguage.english: 'Delayed',
      AppLanguage.hindi: 'विलंबित',
      AppLanguage.marathi: 'उशीर झाला',
      AppLanguage.tamil: 'தாமதமானது',
      AppLanguage.telugu: 'ఆలస్యం',
    },
    'Completed': {
      AppLanguage.english: 'Completed',
      AppLanguage.hindi: 'पूर्ण हुआ',
      AppLanguage.marathi: 'पूर्ण झाले',
      AppLanguage.tamil: 'முடிந்தது',
      AppLanguage.telugu: 'పూర్తయింది',
    },
    'Design and Planning': {
      AppLanguage.english: 'Design and Planning',
      AppLanguage.hindi: 'डिजाइन और योजना',
      AppLanguage.marathi: 'डिझाइन आणि नियोजन',
      AppLanguage.tamil: 'வடிவமைப்பு & திட்டமிடல்',
      AppLanguage.telugu: 'డిజైన్ & ప్రణాళిక',
    },
    'Design & Planning': {
      AppLanguage.english: 'Design & Planning',
      AppLanguage.hindi: 'डिजाइन और योजना',
      AppLanguage.marathi: 'डिझाइन आणि नियोजन',
      AppLanguage.tamil: 'வடிவமைப்பு & திட்டமிடல்',
      AppLanguage.telugu: 'డిజైన్ & ప్రణాళిక',
    },
    'Site Execution': {
      AppLanguage.english: 'Site Execution',
      AppLanguage.hindi: 'साइट निष्पादन',
      AppLanguage.marathi: 'साइट अंमलबजावणी',
      AppLanguage.tamil: 'தள செயலாக்கம்',
      AppLanguage.telugu: 'సైట్ అమలు',
    },
    'Final Snagging & Handover': {
      AppLanguage.english: 'Final Snagging & Handover',
      AppLanguage.hindi: 'अंतिम सुधार और हस्तांतरण',
      AppLanguage.marathi: 'अंतिम तपासणी आणि हस्तांतरण',
      AppLanguage.tamil: 'இறுதி சரிபார்ப்பு & ஒப்படைப்பு',
      AppLanguage.telugu: 'తుది తనిఖీ & అప్పగింత',
    },
    'In Progress': {
      AppLanguage.english: 'In Progress',
      AppLanguage.hindi: 'प्रगति पर है',
      AppLanguage.marathi: 'प्रगतीपथावर आहे',
      AppLanguage.tamil: 'செயலில் உள்ளது',
      AppLanguage.telugu: 'కొనసాగుతోంది',
    },
    'In Review': {
      AppLanguage.english: 'In Review',
      AppLanguage.hindi: 'समीक्षाधीन',
      AppLanguage.marathi: 'पुनरावलोकनात',
      AppLanguage.tamil: 'மதிப்பாய்வில்',
      AppLanguage.telugu: 'సమీక్షలో ఉంది',
    },
    'Done': {
      AppLanguage.english: 'Done',
      AppLanguage.hindi: 'पूर्ण',
      AppLanguage.marathi: 'झाले',
      AppLanguage.tamil: 'முடிந்தது',
      AppLanguage.telugu: 'పూర్తయింది',
    },
    'Partial': {
      AppLanguage.english: 'Partial',
      AppLanguage.hindi: 'आंशिक',
      AppLanguage.marathi: 'अंशतः',
      AppLanguage.tamil: 'பகுதி',
      AppLanguage.telugu: 'పాక్షికం',
    },
    'Complete': {
      AppLanguage.english: 'Complete',
      AppLanguage.hindi: 'पूर्ण',
      AppLanguage.marathi: 'पूर्ण',
      AppLanguage.tamil: 'முழுமை',
      AppLanguage.telugu: 'పూర్తి',
    },
    'COMPLETE': {
      AppLanguage.english: 'COMPLETE',
      AppLanguage.hindi: 'पूर्ण',
      AppLanguage.marathi: 'पूर्ण',
      AppLanguage.tamil: 'முழுமை',
      AppLanguage.telugu: 'పూర్తి',
    },

    // --- Priorities ---
    'Urgent': {
      AppLanguage.english: 'Urgent',
      AppLanguage.hindi: 'अति आवश्यक',
      AppLanguage.marathi: 'तातडीचे',
      AppLanguage.tamil: 'அவசரம்',
      AppLanguage.telugu: 'అత్యవసరం',
    },
    'High': {
      AppLanguage.english: 'High',
      AppLanguage.hindi: 'उच्च',
      AppLanguage.marathi: 'उच्च',
      AppLanguage.tamil: 'உயர்ந்த',
      AppLanguage.telugu: 'అధిక',
    },
    'Medium': {
      AppLanguage.english: 'Medium',
      AppLanguage.hindi: 'मध्यम',
      AppLanguage.marathi: 'मध्यम',
      AppLanguage.tamil: 'நடுத்தர',
      AppLanguage.telugu: 'మధ్యస్థం',
    },
    'Low': {
      AppLanguage.english: 'Low',
      AppLanguage.hindi: 'कम',
      AppLanguage.marathi: 'कमी',
      AppLanguage.tamil: 'குறைந்த',
      AppLanguage.telugu: 'తక్కువ',
    },
    'Urgent (Critical / Blocker)': {
      AppLanguage.english: 'Urgent (Critical / Blocker)',
      AppLanguage.hindi: 'अति आवश्यक (महत्वपूर्ण)',
      AppLanguage.marathi: 'तातडीचे (महत्त्वाचे)',
      AppLanguage.tamil: 'அவசரம் (முக்கியமானது)',
      AppLanguage.telugu: 'అత్యవసరం (కీలకం)',
    },

    // --- Task Fields ---
    'Create Project Task': {
      AppLanguage.english: 'Create Project Task',
      AppLanguage.hindi: 'प्रोजेक्ट कार्य बनाएं',
      AppLanguage.marathi: 'प्रकल्प कार्य तयार करा',
      AppLanguage.tamil: 'திட்டப் பணியை உருவாக்கவும்',
      AppLanguage.telugu: 'ప్రాజెక్ట్ పనిని సృష్టించండి',
    },
    'Task Title': {
      AppLanguage.english: 'Task Title',
      AppLanguage.hindi: 'कार्य शीर्षक',
      AppLanguage.marathi: 'कार्य शीर्षक',
      AppLanguage.tamil: 'பணி தலைப்பு',
      AppLanguage.telugu: 'పని శీర్షిక',
    },
    'Task Description / Deliverable': {
      AppLanguage.english: 'Task Description / Deliverable',
      AppLanguage.hindi: 'कार्य विवरण / परिणाम',
      AppLanguage.marathi: 'कार्य वर्णन',
      AppLanguage.tamil: 'பணி விளக்கம்',
      AppLanguage.telugu: 'పని వివరణ',
    },
    'Description / Scope of Work': {
      AppLanguage.english: 'Description / Scope of Work',
      AppLanguage.hindi: 'विवरण / कार्य का दायरा',
      AppLanguage.marathi: 'वर्णन / कामाची व्याप्ती',
      AppLanguage.tamil: 'வேலை விவரக்குறிப்பு',
      AppLanguage.telugu: 'పని పరిధి / వివరణ',
    },
    'Associated Project': {
      AppLanguage.english: 'Associated Project',
      AppLanguage.hindi: 'संबंधित प्रोजेक्ट',
      AppLanguage.marathi: 'संबंधित प्रकल्प',
      AppLanguage.tamil: 'தொடர்புடைய திட்டம்',
      AppLanguage.telugu: 'సంబంధిత ప్రాజెక్ట్',
    },
    'Department': {
      AppLanguage.english: 'Department',
      AppLanguage.hindi: 'विभाग',
      AppLanguage.marathi: 'विभाग',
      AppLanguage.tamil: 'துறை',
      AppLanguage.telugu: 'విభాగం',
    },
    'Priority Level': {
      AppLanguage.english: 'Priority Level',
      AppLanguage.hindi: 'प्राथमिकता स्तर',
      AppLanguage.marathi: 'प्राधान्य पातळी',
      AppLanguage.tamil: 'முன்னுரிமை நிலை',
      AppLanguage.telugu: 'ప్రాధాన్యత స్థాయి',
    },
    'Assignee': {
      AppLanguage.english: 'Assignee',
      AppLanguage.hindi: 'सौंपा गया व्यक्ति',
      AppLanguage.marathi: 'नियुक्त व्यक्ती',
      AppLanguage.tamil: 'நியமிக்கப்பட்டவர்',
      AppLanguage.telugu: 'కేటాయించిన వ్యక్తి',
    },
    'Due Date': {
      AppLanguage.english: 'Due Date',
      AppLanguage.hindi: 'नियत तारीख',
      AppLanguage.marathi: 'अंतिम तारीख',
      AppLanguage.tamil: 'கடைசி தேதி',
      AppLanguage.telugu: 'గడువు తేదీ',
    },
    'Add Task': {
      AppLanguage.english: 'Add Task',
      AppLanguage.hindi: 'कार्य जोड़ें',
      AppLanguage.marathi: 'कार्य जोडा',
      AppLanguage.tamil: 'பணி சேர்க்க',
      AppLanguage.telugu: 'పనిని జోడించండి',
    },
    '+ New Task': {
      AppLanguage.english: '+ New Task',
      AppLanguage.hindi: '+ नया कार्य',
      AppLanguage.marathi: '+ नवीन कार्य',
      AppLanguage.tamil: '+ புதிய பணி',
      AppLanguage.telugu: '+ కొత్త పని',
    },

    // --- Departments ---
    'Design & Architecture': {
      AppLanguage.english: 'Design & Architecture',
      AppLanguage.hindi: 'डिजाइन और वास्तुकला',
      AppLanguage.marathi: 'डिझाइन आणि वास्तुकला',
      AppLanguage.tamil: 'வடிவமைப்பு & கட்டமைப்பு',
      AppLanguage.telugu: 'డిజైన్ & ఆర్కిటెక్చర్',
    },
    'Site & Execution': {
      AppLanguage.english: 'Site & Execution',
      AppLanguage.hindi: 'साइट और निष्पादन',
      AppLanguage.marathi: 'साइट आणि अंमलबजावणी',
      AppLanguage.tamil: 'தளம் & செயலாக்கம்',
      AppLanguage.telugu: 'సైట్ & అమలు',
    },
    'Procurement & Vendors': {
      AppLanguage.english: 'Procurement & Vendors',
      AppLanguage.hindi: 'खरीद और वेंडर्स',
      AppLanguage.marathi: 'खरेदी आणि विक्रेते',
      AppLanguage.tamil: 'கொள்முதல் & விற்பனையாளர்கள்',
      AppLanguage.telugu: 'సేకరణ & విక్రేతలు',
    },
    'Accounts & Billing': {
      AppLanguage.english: 'Accounts & Billing',
      AppLanguage.hindi: 'लेखा और बिलिंग',
      AppLanguage.marathi: 'खाते आणि बिलिंग',
      AppLanguage.tamil: 'கணக்குகள் & பில்லிங்',
      AppLanguage.telugu: 'ఖాతాలు & బిల్లింగ్',
    },
    'Client Servicing': {
      AppLanguage.english: 'Client Servicing',
      AppLanguage.hindi: 'ग्राहक सेवा',
      AppLanguage.marathi: 'ग्राहक सेवा',
      AppLanguage.tamil: 'வாடிக்கையாளர் சேவை',
      AppLanguage.telugu: 'క్లయింట్ సర్వీసింగ్',
    },
    'General Management': {
      AppLanguage.english: 'General Management',
      AppLanguage.hindi: 'सामान्य प्रबंधन',
      AppLanguage.marathi: 'सामान्य व्यवस्थापन',
      AppLanguage.tamil: 'பொது மேலாண்மை',
      AppLanguage.telugu: 'సాధారణ నిర్వహణ',
    },

    // --- Form Common Terms ---
    'Project Name': {
      AppLanguage.english: 'Project Name',
      AppLanguage.hindi: 'प्रोजेक्ट का नाम',
      AppLanguage.marathi: 'प्रकल्पाचे नाव',
      AppLanguage.tamil: 'திட்டத்தின் பெயர்',
      AppLanguage.telugu: 'ప్రాజెక్ట్ పేరు',
    },
    'Client Name': {
      AppLanguage.english: 'Client Name',
      AppLanguage.hindi: 'ग्राहक का नाम',
      AppLanguage.marathi: 'ग्राहकाचे नाव',
      AppLanguage.tamil: 'வாடிக்கையாளர் பெயர்',
      AppLanguage.telugu: 'క్లయింట్ పేరు',
    },
    'Client & Site Location': {
      AppLanguage.english: 'Client & Site Location',
      AppLanguage.hindi: 'ग्राहक और साइट का स्थान',
      AppLanguage.marathi: 'ग्राहक आणि साइट स्थान',
      AppLanguage.tamil: 'வாடிக்கையாளர் மற்றும் தள இருப்பிடம்',
      AppLanguage.telugu: 'క్లయింట్ & సైట్ స్థానం',
    },
    'Typology / Area': {
      AppLanguage.english: 'Typology / Area',
      AppLanguage.hindi: 'प्रकार / क्षेत्रफल',
      AppLanguage.marathi: 'प्रकार / क्षेत्रफळ',
      AppLanguage.tamil: 'வகை / பரப்பளவு',
      AppLanguage.telugu: 'రకం / వైశాల్యం',
    },
    'Contract Budget (₹)': {
      AppLanguage.english: 'Contract Budget (₹)',
      AppLanguage.hindi: 'अनुबंध बजट (₹)',
      AppLanguage.marathi: 'करार बजेट (₹)',
      AppLanguage.tamil: 'ஒப்பந்த பட்ஜெட் (₹)',
      AppLanguage.telugu: 'ఒప్పందం బడ్జెట్ (₹)',
    },
    'Project Status': {
      AppLanguage.english: 'Project Status',
      AppLanguage.hindi: 'प्रोजेक्ट स्थिति',
      AppLanguage.marathi: 'प्रकल्प स्थिती',
      AppLanguage.tamil: 'திட்ட நிலை',
      AppLanguage.telugu: 'ప్రాజెక్ట్ స్థితి',
    },
    'Target Handover Date': {
      AppLanguage.english: 'Target Handover Date',
      AppLanguage.hindi: 'हस्तांतरण लक्ष्य तारीख',
      AppLanguage.marathi: 'लक्ष्यित हस्तांतरण तारीख',
      AppLanguage.tamil: 'இலக்கு ஒப்படைப்பு தேதி',
      AppLanguage.telugu: 'లక్ష్యిత అప్పగింత తేదీ',
    },
    'Project Manager': {
      AppLanguage.english: 'Project Manager',
      AppLanguage.hindi: 'प्रोजेक्ट मैनेजर',
      AppLanguage.marathi: 'प्रकल्प व्यवस्थापक',
      AppLanguage.tamil: 'திட்ட மேலாளர்',
      AppLanguage.telugu: 'ప్రాజెక్ట్ మేనేజర్',
    },
    'ARCHITECTURAL MATERIAL SWATCH': {
      AppLanguage.english: 'ARCHITECTURAL MATERIAL SWATCH',
      AppLanguage.hindi: 'वास्तुकला सामग्री का नमूना',
      AppLanguage.marathi: 'वास्तुकला साहित्य नमुना',
      AppLanguage.tamil: 'கட்டடக்கலை பொருள் மாதிரி',
      AppLanguage.telugu: 'ఆర్కిటెక్చరల్ మెటీరియల్ నమూనా',
    },

    // --- Buttons & Common UI ---
    'Cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.hindi: 'रद्द करें',
      AppLanguage.marathi: 'रद्द करा',
      AppLanguage.tamil: 'ரத்து செய்',
      AppLanguage.telugu: 'రద్దు చేయండి',
    },
    'Save': {
      AppLanguage.english: 'Save',
      AppLanguage.hindi: 'सहेजें',
      AppLanguage.marathi: 'जतन करा',
      AppLanguage.tamil: 'சேமிக்க',
      AppLanguage.telugu: 'సేవ్ చేయండి',
    },
    'Delete': {
      AppLanguage.english: 'Delete',
      AppLanguage.hindi: 'हटाएं',
      AppLanguage.marathi: 'हटवा',
      AppLanguage.tamil: 'அழிக்க',
      AppLanguage.telugu: 'తొలగించండి',
    },
    'Close': {
      AppLanguage.english: 'Close',
      AppLanguage.hindi: 'बंद करें',
      AppLanguage.marathi: 'बंद करा',
      AppLanguage.tamil: 'மூடு',
      AppLanguage.telugu: 'మూసివేయండి',
    },
    'Submit': {
      AppLanguage.english: 'Submit',
      AppLanguage.hindi: 'जमा करें',
      AppLanguage.marathi: 'सबमिट करा',
      AppLanguage.tamil: 'சமர்ப்பிக்கவும்',
      AppLanguage.telugu: 'సమర్పించండి',
    },
    'Search': {
      AppLanguage.english: 'Search',
      AppLanguage.hindi: 'खोजें',
      AppLanguage.marathi: 'शोधा',
      AppLanguage.tamil: 'தேடு',
      AppLanguage.telugu: 'వెతకండి',
    },
    'Filter': {
      AppLanguage.english: 'Filter',
      AppLanguage.hindi: 'फ़िल्टर',
      AppLanguage.marathi: 'फिल्टर',
      AppLanguage.tamil: 'வடிகட்டி',
      AppLanguage.telugu: 'ఫిల్టర్',
    },
    'Stages & Checklist': {
      AppLanguage.english: 'Stages & Checklist',
      AppLanguage.hindi: 'चरण और चेकलिस्ट',
      AppLanguage.marathi: 'टप्पे आणि चेकलिस्ट',
      AppLanguage.tamil: 'நிலைகள் & சரிபார்ப்புப் பட்டியல்',
      AppLanguage.telugu: 'దశలు & చెక్‌లిస్ట్',
    },
    'Add Stage': {
      AppLanguage.english: 'Add Stage',
      AppLanguage.hindi: 'चरण जोड़ें',
      AppLanguage.marathi: 'टप्पा जोडा',
      AppLanguage.tamil: 'நிலையைச் சேர்க்கவும்',
      AppLanguage.telugu: 'దశను జోడించండి',
    },
    'FINANCIAL COMMITMENT': {
      AppLanguage.english: 'FINANCIAL COMMITMENT',
      AppLanguage.hindi: 'वित्तीय प्रतिबद्धता',
      AppLanguage.marathi: 'आर्थिक वचनबद्धता',
      AppLanguage.tamil: 'நிதி அர்ப்பணிப்பு',
      AppLanguage.telugu: 'ఆర్థిక నిబద్ధత',
    },
    'Hide Stages': {
      AppLanguage.english: 'Hide Stages',
      AppLanguage.hindi: 'चरण छुपाएं',
      AppLanguage.marathi: 'टप्पे लपवा',
      AppLanguage.tamil: 'நிலைகளை மறை',
      AppLanguage.telugu: 'దశలను దాచు',
    },
    'Onboard Vendor': {
      AppLanguage.english: 'Onboard Vendor',
      AppLanguage.hindi: 'वेंडर जोड़ें',
      AppLanguage.marathi: 'विक्रेता जोडा',
      AppLanguage.tamil: 'விற்பனையாளரை சேர்க்க',
      AppLanguage.telugu: 'విక్రేతను చేర్చండి',
    },
  };
}

/// Syntactic sugar extension for inline translation: `'Add Task'.tr`
extension AppTranslateExtension on String {
  String get tr => AppStrings.tr(this);
}
