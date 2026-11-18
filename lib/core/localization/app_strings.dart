import 'package:flutter/material.dart';

/// Supported application languages
enum AppLanguage { english, hindi, kannada, marathi, tamil, telugu }

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.kannada:
        return 'kn';
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
      case AppLanguage.kannada:
        return 'ಕನ್ನಡ';
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
      case AppLanguage.kannada:
        return 'KN';
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
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  static void setLanguage(AppLanguage lang) {
    currentLanguage = lang;
    languageNotifier.value = lang;
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
  static String get tabDesign => tr('Design');
  static String get tabProjects => tr('Projects');
  static String get tabMaterials => tr('Materials');
  static String get tabMaterialRequests => tr('Material Requests');
  static String get tabAmendments => tr('Change Requests');
  static String get tabVendors => tr('Vendors');
  static String get tabTasks => tr('Tasks');
  static String get tabAccounts => tr('Accounts');
  static String get tabTeam => tr('Team');
  static String get tabMore => tr('More');

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
      AppLanguage.kannada: 'ಮುಖಪುಟ',
      AppLanguage.marathi: 'हब',
      AppLanguage.tamil: 'மையம்',
      AppLanguage.telugu: 'హబ్',
    },
    'Sales': {
      AppLanguage.english: 'Sales',
      AppLanguage.hindi: 'बिक्री',
      AppLanguage.kannada: 'ಮಾರಾಟ',
      AppLanguage.marathi: 'विक्री',
      AppLanguage.tamil: 'விற்பனை',
      AppLanguage.telugu: 'అమ్మకాలు',
    },
    'Design': {
      AppLanguage.english: 'Design',
      AppLanguage.hindi: 'डिज़ाइन',
      AppLanguage.kannada: 'ವಿನ್ಯಾಸ',
      AppLanguage.marathi: 'डिझाईन',
      AppLanguage.tamil: 'வடிவமைப்பு',
      AppLanguage.telugu: 'రూపకల్పన',
    },
    'Projects': {
      AppLanguage.english: 'Projects',
      AppLanguage.hindi: 'प्रोजेक्ट्स',
      AppLanguage.kannada: 'ಪ್ರಾಜೆಕ್ಟ್‌ಗಳು',
      AppLanguage.marathi: 'प्रकल्प',
      AppLanguage.tamil: 'திட்டங்கள்',
      AppLanguage.telugu: 'ప్రాజెక్టులు',
    },
    'Materials': {
      AppLanguage.english: 'Materials',
      AppLanguage.hindi: 'सामग्री',
      AppLanguage.kannada: 'ಸಾಮಗ್ರಿ',
      AppLanguage.marathi: 'साहित्य',
      AppLanguage.tamil: 'பொருட்கள்',
      AppLanguage.telugu: 'సామగ్రి',
    },
    'Material Requests': {
      AppLanguage.english: 'Material Requests',
      AppLanguage.hindi: 'सामग्री अनुरोध',
      AppLanguage.kannada: 'ಸಾಮಗ್ರಿ ವಿನಂತಿಗಳು',
      AppLanguage.marathi: 'साहित्य विनंत्या',
      AppLanguage.tamil: 'பொருள் கோரிக்கைகள்',
      AppLanguage.telugu: 'సామగ్రి అభ్యర్థనలు',
    },
    'Amendments': {
      AppLanguage.english: 'Change Requests',
      AppLanguage.hindi: 'बदलाव अनुरोध',
      AppLanguage.kannada: 'ಬದಲಾವಣೆ ವಿನಂತಿಗಳು',
      AppLanguage.marathi: 'बदल विनंत्या',
      AppLanguage.tamil: 'மாற்றக் கோரிக்கைகள்',
      AppLanguage.telugu: 'మార్పు అభ్యర్థనలు',
    },
    'Change Requests': {
      AppLanguage.english: 'Change Requests',
      AppLanguage.hindi: 'बदलाव अनुरोध',
      AppLanguage.kannada: 'ಬದಲಾವಣೆ ವಿನಂತಿಗಳು',
      AppLanguage.marathi: 'बदल विनंत्या',
      AppLanguage.tamil: 'மாற்றக் கோரிக்கைகள்',
      AppLanguage.telugu: 'మార్పు అభ్యర్థనలు',
    },
    'Vendors': {
      AppLanguage.english: 'Vendors',
      AppLanguage.hindi: 'वेंडर्स',
      AppLanguage.kannada: 'ಮಾರಾಟಗಾರರು',
      AppLanguage.marathi: 'विक्रेते',
      AppLanguage.tamil: 'விற்பனையாளர்கள்',
      AppLanguage.telugu: 'విక్రేతలు',
    },
    'Tasks': {
      AppLanguage.english: 'Tasks',
      AppLanguage.hindi: 'कार्य',
      AppLanguage.kannada: 'ಕೆಲಸಗಳು',
      AppLanguage.marathi: 'कार्ये',
      AppLanguage.tamil: 'பணிகள்',
      AppLanguage.telugu: 'పనులు',
    },
    'Accounts': {
      AppLanguage.english: 'Accounts',
      AppLanguage.hindi: 'खाते',
      AppLanguage.kannada: 'ಖಾತೆಗಳು',
      AppLanguage.marathi: 'खाती',
      AppLanguage.tamil: 'கணக்குகள்',
      AppLanguage.telugu: 'ఖాతాలు',
    },
    'Team': {
      AppLanguage.english: 'Team',
      AppLanguage.hindi: 'टीम',
      AppLanguage.kannada: 'ತಂಡ',
      AppLanguage.marathi: 'संघ',
      AppLanguage.tamil: 'குழு',
      AppLanguage.telugu: 'బృందం',
    },
    'More': {
      AppLanguage.english: 'More',
      AppLanguage.hindi: 'अधिक',
      AppLanguage.kannada: 'ಇನ್ನಷ್ಟು',
      AppLanguage.marathi: 'अधिक',
      AppLanguage.tamil: 'மேலும்',
      AppLanguage.telugu: 'మరిన్ని',
    },
    'Projects Portfolio': {
      AppLanguage.english: 'Projects Portfolio',
      AppLanguage.hindi: 'प्रोजेक्ट पोर्टफोलियो',
      AppLanguage.kannada: 'ಪ್ರಾಜೆಕ್ಟ್ ಪಟ್ಟಿ',
      AppLanguage.marathi: 'प्रकल्प पोर्टफोलिओ',
      AppLanguage.tamil: 'திட்டங்கள் போர்ட்ஃபோலியோ',
      AppLanguage.telugu: 'ప్రాజెక్టుల పోర్ట్‌ఫోలియో',
    },
    'Add New Project': {
      AppLanguage.english: 'Add New Project',
      AppLanguage.hindi: 'नया प्रोजेक्ट जोड़ें',
      AppLanguage.kannada: 'ಹೊಸ ಪ್ರಾಜೆಕ್ಟ್ ಸೇರಿಸಿ',
      AppLanguage.marathi: 'नवीन प्रकल्प जोडा',
      AppLanguage.tamil: 'புதிய திட்டம் சேர்க்க',
      AppLanguage.telugu: 'కొత్త ప్రాజెక్ట్ జోడించండి',
    },
    'Update Progress': {
      AppLanguage.english: 'Update Progress',
      AppLanguage.hindi: 'प्रगति अपडेट करें',
      AppLanguage.kannada: 'ಪ್ರಗತಿ ನವೀಕರಿಸಿ',
      AppLanguage.marathi: 'प्रगती अपडेट करा',
      AppLanguage.tamil: 'முன்னேற்றத்தைப் புதுப்பிக்கவும்',
      AppLanguage.telugu: 'పురోగతిని నవీకరించండి',
    },
    'Mark Delayed': {
      AppLanguage.english: 'Mark Delayed',
      AppLanguage.hindi: 'विलंबित चिह्नित करें',
      AppLanguage.kannada: 'ವಿಳಂಬವಾಗಿದೆ ಎಂದು ಗುರುತಿಸಿ',
      AppLanguage.marathi: 'विलंबित चिन्हांकित करा',
      AppLanguage.tamil: 'தாமதமாக குறிக்கவும்',
      AppLanguage.telugu: 'ఆలస్యంగా గుర్తించండి',
    },
    'Mark as Delayed': {
      AppLanguage.english: 'Mark as Delayed',
      AppLanguage.hindi: 'विलंबित चिह्नित करें',
      AppLanguage.kannada: 'ವಿಳಂಬವಾಗಿದೆ ಎಂದು ಗುರುತಿಸಿ',
      AppLanguage.marathi: 'विलंबित चिन्हांकित करा',
      AppLanguage.tamil: 'தாமதமாக குறிக்கவும்',
      AppLanguage.telugu: 'ఆలస్యంగా గుర్తించండి',
    },
    'Revert to On Track': {
      AppLanguage.english: 'Revert to On Track',
      AppLanguage.hindi: 'समय पर वापस करें',
      AppLanguage.kannada: 'ಸಮಯಕ್ಕೆ ಸರಿಯಾಗಿದೆ ಎಂದು ಬದಲಿಸಿ',
      AppLanguage.marathi: 'ट्रॅकवर परत आणा',
      AppLanguage.tamil: 'சரியான நிலைக்கு மாற்றவும்',
      AppLanguage.telugu: 'సమయానికి మార్చండి',
    },
    'Edit Project': {
      AppLanguage.english: 'Edit Project',
      AppLanguage.hindi: 'प्रोजेक्ट संपादित करें',
      AppLanguage.kannada: 'ಪ್ರಾಜೆಕ್ಟ್ ತಿದ್ದುಪಡಿ',
      AppLanguage.marathi: 'प्रकल्प संपादित करा',
      AppLanguage.tamil: 'திட்டத்தைத் திருத்து',
      AppLanguage.telugu: 'ప్రాజెక్ట్‌ను సవరించండి',
    },
    'Edit Project Details': {
      AppLanguage.english: 'Edit Project Details',
      AppLanguage.hindi: 'प्रोजेक्ट विवरण संपादित करें',
      AppLanguage.kannada: 'ಪ್ರಾಜೆಕ್ಟ್ ವಿವರಗಳನ್ನು ತಿದ್ದುಪಡಿ ಮಾಡಿ',
      AppLanguage.marathi: 'प्रकल्प तपशील संपादित करा',
      AppLanguage.tamil: 'திட்ட விவரங்களைத் திருத்து',
      AppLanguage.telugu: 'ప్రాజెక్ట్ వివరాలను సవరించండి',
    },
    'Save Changes': {
      AppLanguage.english: 'Save Changes',
      AppLanguage.hindi: 'बदलाव सहेजें',
      AppLanguage.kannada: 'ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿ',
      AppLanguage.marathi: 'बदल जतन करा',
      AppLanguage.tamil: 'மாற்றங்களைச் சேமிக்க',
      AppLanguage.telugu: 'మార్పులను సేవ్ చేయండి',
    },
    'Active Sites': {
      AppLanguage.english: 'Active Sites',
      AppLanguage.hindi: 'सक्रिय साइटें',
      AppLanguage.kannada: 'ಸಕ್ರಿಯ ಸೈಟ್‌ಗಳು',
      AppLanguage.marathi: 'सक्रिय साइट्स',
      AppLanguage.tamil: 'செயலில் உள்ள தளங்கள்',
      AppLanguage.telugu: 'క్రియాశీల సైట్లు',
    },
    'Contract Value': {
      AppLanguage.english: 'Contract Value',
      AppLanguage.hindi: 'अनुबंध मूल्य',
      AppLanguage.kannada: 'ಒಪ್ಪಂದದ ಮೌಲ್ಯ',
      AppLanguage.marathi: 'करार मूल्य',
      AppLanguage.tamil: 'ஒப்பந்த மதிப்பு',
      AppLanguage.telugu: 'ఒప్పందం విలువ',
    },
    'Average Progress': {
      AppLanguage.english: 'Average Progress',
      AppLanguage.hindi: 'औसत प्रगति',
      AppLanguage.kannada: 'ಸರಾಸರಿ ಪ್ರಗತಿ',
      AppLanguage.marathi: 'सरासरी प्रगती',
      AppLanguage.tamil: 'சராசரி முன்னேற்றம்',
      AppLanguage.telugu: 'సగటు పురోగతి',
    },
    'Upcoming Handovers': {
      AppLanguage.english: 'Upcoming Handovers',
      AppLanguage.hindi: 'आगामी हस्तांतरण',
      AppLanguage.kannada: 'ಮುಂಬರುವ ಹಸ್ತಾಂತರಗಳು',
      AppLanguage.marathi: 'आगामी हस्तांतरण',
      AppLanguage.tamil: 'வரவிருக்கும் ஒப்படைப்புகள்',
      AppLanguage.telugu: 'రాబోయే అప్పగింతలు',
    },
    'All': {
      AppLanguage.english: 'All',
      AppLanguage.hindi: 'सभी',
      AppLanguage.kannada: 'ಎಲ್ಲಾ',
      AppLanguage.marathi: 'सर्व',
      AppLanguage.tamil: 'அனைத்தும்',
      AppLanguage.telugu: 'అన్నీ',
    },
    'On Track': {
      AppLanguage.english: 'On Track',
      AppLanguage.hindi: 'समय पर',
      AppLanguage.kannada: 'ಸಮಯಕ್ಕೆ ಸರಿಯಾಗಿದೆ',
      AppLanguage.marathi: 'वेळेवर',
      AppLanguage.tamil: 'சரியான பாதையில்',
      AppLanguage.telugu: 'సమయానికి',
    },
    'Delayed': {
      AppLanguage.english: 'Delayed',
      AppLanguage.hindi: 'विलंबित',
      AppLanguage.kannada: 'ವಿಳಂಬವಾಗಿದೆ',
      AppLanguage.marathi: 'उशीर झाला',
      AppLanguage.tamil: 'தாமதமானது',
      AppLanguage.telugu: 'ఆలస్యం',
    },
    'Completed': {
      AppLanguage.english: 'Completed',
      AppLanguage.hindi: 'पूर्ण हुआ',
      AppLanguage.kannada: 'ಪೂರ್ಣಗೊಂಡಿದೆ',
      AppLanguage.marathi: 'पूर्ण झाले',
      AppLanguage.tamil: 'முடிந்தது',
      AppLanguage.telugu: 'పూర్తయింది',
    },
    'Design and Planning': {
      AppLanguage.english: 'Design and Planning',
      AppLanguage.hindi: 'डिजाइन और योजना',
      AppLanguage.kannada: 'ವಿನ್ಯಾಸ ಮತ್ತು ಯೋಜನೆ',
      AppLanguage.marathi: 'डिझाइन आणि नियोजन',
      AppLanguage.tamil: 'வடிவமைப்பு & திட்டமிடல்',
      AppLanguage.telugu: 'డిజైన్ & ప్రణాళిక',
    },
    'Cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.hindi: 'रद्द करें',
      AppLanguage.kannada: 'ರದ್ದುಮಾಡಿ',
      AppLanguage.marathi: 'रद्द करा',
      AppLanguage.tamil: 'ரத்து செய்',
      AppLanguage.telugu: 'రద్దు చేయండి',
    },
    'Save': {
      AppLanguage.english: 'Save',
      AppLanguage.hindi: 'सहेजें',
      AppLanguage.kannada: 'ಉಳಿಸಿ',
      AppLanguage.marathi: 'जतन करा',
      AppLanguage.tamil: 'சேமிக்க',
      AppLanguage.telugu: 'సేవ్ చేయండి',
    },
    'Delete': {
      AppLanguage.english: 'Delete',
      AppLanguage.hindi: 'हटाएं',
      AppLanguage.kannada: 'ತೆಗೆದುಹಾಕಿ',
      AppLanguage.marathi: 'हटवा',
      AppLanguage.tamil: 'அழிக்க',
      AppLanguage.telugu: 'తొలగించండి',
    },
    'Close': {
      AppLanguage.english: 'Close',
      AppLanguage.hindi: 'बंद करें',
      AppLanguage.kannada: 'ಮುಚ್ಚಿ',
      AppLanguage.marathi: 'बंद करा',
      AppLanguage.tamil: 'மூடு',
      AppLanguage.telugu: 'మూసివేయండి',
    },
    'Home': {
      AppLanguage.english: 'Home',
      AppLanguage.hindi: 'होम',
      AppLanguage.kannada: 'ಮನೆ',
      AppLanguage.marathi: 'होम',
      AppLanguage.tamil: 'முகப்பு',
      AppLanguage.telugu: 'హోమ్',
    },
    'Sites': {
      AppLanguage.english: 'Sites',
      AppLanguage.hindi: 'साइट्स',
      AppLanguage.kannada: 'ಸೈಟ್‌ಗಳು',
      AppLanguage.marathi: 'साइट्स',
      AppLanguage.tamil: 'தளங்கள்',
      AppLanguage.telugu: 'సైట్లు',
    },
    'Issues': {
      AppLanguage.english: 'Issues',
      AppLanguage.hindi: 'समस्याएं',
      AppLanguage.kannada: 'ಸಮಸ್ಯೆಗಳು',
      AppLanguage.marathi: 'समस्या',
      AppLanguage.tamil: 'சிக்கல்கள்',
      AppLanguage.telugu: 'సమస్యలు',
    },
    'Executive Studio Hub': {
      AppLanguage.english: 'Executive Studio Hub',
      AppLanguage.hindi: 'स्टूडियो मुख्य हब',
      AppLanguage.kannada: 'ಸ್ಟುಡಿಯೋ ಮುಖಪುಟ',
      AppLanguage.marathi: 'स्टुडिओ मुख्य हब',
      AppLanguage.tamil: 'ஸ்டுடியோ மையம்',
      AppLanguage.telugu: 'స్టూడియో ప్రధాన హబ్',
    },
    'Studio Home': {
      AppLanguage.english: 'Studio Home',
      AppLanguage.hindi: 'स्टूडियो होम',
      AppLanguage.kannada: 'ಸ್ಟುಡಿಯೋ ಮುಖಪುಟ',
      AppLanguage.marathi: 'स्टुडिओ होम',
      AppLanguage.tamil: 'ஸ்டுடியோ முகப்பு',
      AppLanguage.telugu: 'స్టూడియో హోమ్',
    },
    'Quick Actions — Tap What You Need': {
      AppLanguage.english: 'Quick Actions — Tap What You Need',
      AppLanguage.hindi: 'त्वरित कार्य — जो चाहिए उसे चुनें',
      AppLanguage.kannada: 'ತ್ವರಿತ ಕ್ರಿಯೆಗಳು — ನಿಮಗೆ ಬೇಕಾದದ್ದನ್ನು ಒತ್ತಿ',
      AppLanguage.marathi: 'त्वरित कृती — हवे ते निवडा',
      AppLanguage.tamil: 'விரைவு செயல்கள் — தேவையானதைத் தட்டவும்',
      AppLanguage.telugu: 'త్వరిత చర్యలు — కావలసినది ఎంచుకోండి',
    },
    'Take Site Photo': {
      AppLanguage.english: 'Take Site Photo',
      AppLanguage.hindi: 'साइट फ़ोटो लें',
      AppLanguage.kannada: 'ಸೈಟ್ ಫೋಟೋ ತೆಗೆಯಿರಿ',
      AppLanguage.marathi: 'साइट फोटो काढा',
      AppLanguage.tamil: 'தளப் புகைப்படம் எடுக்கவும்',
      AppLanguage.telugu: 'సైట్ ఫోటో తీయండి',
    },
    'Upload Drawing': {
      AppLanguage.english: 'Upload Drawing',
      AppLanguage.hindi: 'ड्राइंग अपलोड करें',
      AppLanguage.kannada: 'ಡ್ರಾಯಿಂಗ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      AppLanguage.marathi: 'ड्रॉइंग अपलोड करा',
      AppLanguage.tamil: 'வரைபடம் பதிவேற்று',
      AppLanguage.telugu: 'డ్రాయింగ్ అప్‌లోడ్',
    },
    'New Invoice': {
      AppLanguage.english: 'New Invoice',
      AppLanguage.hindi: 'नया बिल बनाएं',
      AppLanguage.kannada: 'ಹೊಸ ಬಿಲ್ ರಚಿಸಿ',
      AppLanguage.marathi: 'नवीन बिल बनवा',
      AppLanguage.tamil: 'புதிய பில்',
      AppLanguage.telugu: 'కొత్త బిల్లు',
    },
    'Add New Lead': {
      AppLanguage.english: 'Add New Lead',
      AppLanguage.hindi: 'नया ग्राहक जोड़ें',
      AppLanguage.kannada: 'ಹೊಸ ಗ್ರಾಹಕರನ್ನು ಸೇರಿಸಿ',
      AppLanguage.marathi: 'नवीन ग्राहक जोडा',
      AppLanguage.tamil: 'புதிய வாடிக்கையாளர் சேர்க்கவும்',
      AppLanguage.telugu: 'కొత్త కస్టమర్‌ను జోడించండి',
    },
    'Add Project': {
      AppLanguage.english: 'Add Project',
      AppLanguage.hindi: 'प्रोजेक्ट जोड़ें',
      AppLanguage.kannada: 'ಪ್ರಾಜೆಕ್ಟ್ ಸೇರಿಸಿ',
      AppLanguage.marathi: 'प्रकल्प जोडा',
      AppLanguage.tamil: 'திட்டம் சேர்',
      AppLanguage.telugu: 'ప్రాజెక్ట్ జోడించండి',
    },
    'Upload Material List': {
      AppLanguage.english: 'Upload Material List',
      AppLanguage.hindi: 'सामग्री सूची अपलोड करें',
      AppLanguage.kannada: 'ಸಾಮಗ್ರಿ ಪಟ್ಟಿ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      AppLanguage.marathi: 'साहित्य यादी अपलोड करा',
      AppLanguage.tamil: 'பொருள் பட்டியலை பதிவேற்றவும்',
      AppLanguage.telugu: 'సామగ్రి జాబితా అప్‌లోడ్ చేయండి',
    },
    'Upload BOQ': {
      AppLanguage.english: 'Upload Material List',
      AppLanguage.hindi: 'सामग्री सूची अपलोड करें',
      AppLanguage.kannada: 'ಸಾಮಗ್ರಿ ಪಟ್ಟಿ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      AppLanguage.marathi: 'साहित्य यादी अपलोड करा',
      AppLanguage.tamil: 'பொருள் பட்டியலை பதிவேற்றவும்',
      AppLanguage.telugu: 'సామగ్రి జాబితా అప్‌లోడ్ చేయండి',
    },
    'Add Invoice': {
      AppLanguage.english: 'New Invoice',
      AppLanguage.hindi: 'नया बिल बनाएं',
      AppLanguage.kannada: 'ಹೊಸ ಬಿಲ್ ರಚಿಸಿ',
      AppLanguage.marathi: 'नवीन बिल बनवा',
      AppLanguage.tamil: 'புதிய பில் சேர்',
      AppLanguage.telugu: 'కొత్త బిల్లు జోడించండి',
    },
    'Add Amendment': {
      AppLanguage.english: 'New Change Request',
      AppLanguage.hindi: 'नया बदलाव अनुरोध',
      AppLanguage.kannada: 'ಹೊಸ ಬದಲಾವಣೆ ವಿನಂತಿ',
      AppLanguage.marathi: 'नवीन बदल विनंती',
      AppLanguage.tamil: 'புதிய மாற்றக் கோரிக்கை',
      AppLanguage.telugu: 'కొత్త మార్పు అభ్యర్థన',
    },
    'Progress': {
      AppLanguage.english: 'Progress',
      AppLanguage.hindi: 'प्रगति',
      AppLanguage.kannada: 'ಪ್ರಗತಿ',
      AppLanguage.marathi: 'प्रगती',
      AppLanguage.tamil: 'முன்னேற்றம்',
      AppLanguage.telugu: 'పురోగతి',
    },
    'Photos': {
      AppLanguage.english: 'Photos',
      AppLanguage.hindi: 'फ़ोटो',
      AppLanguage.kannada: 'ಫೋಟೋಗಳು',
      AppLanguage.marathi: 'फोटो',
      AppLanguage.tamil: 'புகைப்படங்கள்',
      AppLanguage.telugu: 'ఫోటోలు',
    },
    'Files': {
      AppLanguage.english: 'Files',
      AppLanguage.hindi: 'फ़ाइलें',
      AppLanguage.kannada: 'ಫೈಲ್‌ಗಳು',
      AppLanguage.marathi: 'फाइल्स',
      AppLanguage.tamil: 'கோப்புகள்',
      AppLanguage.telugu: 'ఫైళ్లు',
    },
    'Billing': {
      AppLanguage.english: 'Billing',
      AppLanguage.hindi: 'बिलिंग',
      AppLanguage.kannada: 'ಬಿಲ್ಲಿಂಗ್',
      AppLanguage.marathi: 'बिलिंग',
      AppLanguage.tamil: 'பில்லிங்',
      AppLanguage.telugu: 'బిల్లింగ్',
    },
    '✓ Saved · Synced': {
      AppLanguage.english: '✓ Saved · Synced',
      AppLanguage.hindi: '✓ सहेजा गया · सिंक है',
      AppLanguage.kannada: '✓ ಉಳಿಸಲಾಗಿದೆ · ಸಿಂಕ್ ಆಗಿದೆ',
      AppLanguage.marathi: '✓ जतन · सिंक झाले',
      AppLanguage.tamil: '✓ சேமிக்கப்பட்டது · ஒத்திசைக்கப்பட்டது',
      AppLanguage.telugu: '✓ సేవ్ చేయబడింది · సింక్ అయింది',
    },
    '⏳ Syncing...': {
      AppLanguage.english: '⏳ Syncing...',
      AppLanguage.hindi: '⏳ सिंक हो रहा है...',
      AppLanguage.kannada: '⏳ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ...',
      AppLanguage.marathi: '⏳ सिंक होत आहे...',
      AppLanguage.tamil: '⏳ ஒத்திசைக்கிறது...',
      AppLanguage.telugu: '⏳ సింక్ అవుతోంది...',
    },
    '⚠ Offline – will sync later': {
      AppLanguage.english: '⚠ Offline – will sync later',
      AppLanguage.hindi: '⚠ ऑफ़लाइन – बाद में सिंक होगा',
      AppLanguage.kannada: '⚠ ಆಫ್‌ಲೈನ್ – ನಂತರ ಸಿಂಕ್ ಆಗುತ್ತದೆ',
      AppLanguage.marathi: '⚠ ऑफलाइन – नंतर सिंक होईल',
      AppLanguage.tamil: '⚠ ஆஃப்லைன் – பின்னர் ஒத்திசைக்கும்',
      AppLanguage.telugu: '⚠ ఆఫ్‌లైన్ – తర్వాత సింక్ అవుతుంది',
    },
    'Photo saved on phone. It will upload when you\'re back online.': {
      AppLanguage.english:
          'Photo saved on phone. It will upload when you\'re back online.',
      AppLanguage.hindi:
          'फ़ोटो फ़ोन पर सहेजी गई। इंटरनेट आने पर यह अपलोड हो जाएगी।',
      AppLanguage.kannada:
          'ಫೋಟೋ ಫೋನ್‌ನಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ. ಆನ್‌ಲೈನ್ ಬಂದಾಗ ಅಪ್‌ಲೋಡ್ ಆಗುತ್ತದೆ.',
    },
    'Photo removed': {
      AppLanguage.english: 'Photo removed',
      AppLanguage.hindi: 'फ़ोटो हटा दी गई',
      AppLanguage.kannada: 'ಫೋಟೋ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
    },
    'File removed': {
      AppLanguage.english: 'File removed',
      AppLanguage.hindi: 'फ़ाइल हटा दी गई',
      AppLanguage.kannada: 'ಫೈಲ್ ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
    },
    'Undo': {
      AppLanguage.english: 'Undo',
      AppLanguage.hindi: 'वापस लाएं',
      AppLanguage.kannada: 'ಹಿಂಪಡೆಯಿರಿ',
      AppLanguage.marathi: 'पूर्ववत करा',
      AppLanguage.tamil: 'செயல்தவிர்',
      AppLanguage.telugu: 'అన్డు',
    },
    'Remove Photo': {
      AppLanguage.english: 'Remove Photo',
      AppLanguage.hindi: 'फ़ोटो हटाएं',
      AppLanguage.kannada: 'ಫೋಟೋ ತೆಗೆದುಹಾಕಿ',
    },
    'No photos yet. Tap below to take your first site photo.': {
      AppLanguage.english:
          'No photos yet. Tap below to take your first site photo.',
      AppLanguage.hindi:
          'अभी कोई फ़ोटो नहीं है। पहली साइट फ़ोटो लेने के लिए नीचे टैप करें।',
      AppLanguage.kannada:
          'ಇನ್ನೂ ಯಾವುದೇ ಫೋಟೋಗಳಿಲ್ಲ. ಮೊದಲ ಸೈಟ್ ಫೋಟೋ ತೆಗೆಯಲು ಕೆಳಗೆ ಒತ್ತಿ.',
    },
    'No drawings or material lists yet. Tap below to upload one.': {
      AppLanguage.english:
          'No drawings or material lists yet. Tap below to upload one.',
      AppLanguage.hindi:
          'अभी कोई ड्राइंग या सामग्री सूची नहीं है। अपलोड करने के लिए नीचे टैप करें।',
      AppLanguage.kannada:
          'ಇನ್ನೂ ಡ್ರಾಯಿಂಗ್ ಅಥವಾ ಸಾಮಗ್ರಿ ಪಟ್ಟಿಗಳಿಲ್ಲ. ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ಕೆಳಗೆ ಒತ್ತಿ.',
    },
    'No bills or invoices linked yet.': {
      AppLanguage.english: 'No bills or invoices linked yet.',
      AppLanguage.hindi: 'अभी कोई बिल जुड़ा नहीं है।',
      AppLanguage.kannada: 'ಇನ್ನೂ ಯಾವುದೇ ಬಿಲ್‌ಗಳು ಲಿಂಕ್ ಆಗಿಲ್ಲ.',
    },
    'No projects yet. Tap below to add your first project.': {
      AppLanguage.english:
          'No projects yet. Tap below to add your first project.',
      AppLanguage.hindi:
          'अभी कोई प्रोजेक्ट नहीं है। अपना पहला प्रोजेक्ट जोड़ने के लिए नीचे टैप करें।',
      AppLanguage.kannada:
          'ಇನ್ನೂ ಯಾವುದೇ ಪ್ರಾಜೆಕ್ಟ್‌ಗಳಿಲ್ಲ. ನಿಮ್ಮ ಮೊದಲ ಪ್ರಾಜೆಕ್ಟ್ ಸೇರಿಸಲು ಕೆಳಗೆ ಒತ್ತಿ.',
    },
    'Reset Password': {
      AppLanguage.english: 'Reset Password',
      AppLanguage.hindi: 'पासवर्ड रीसेट करें',
      AppLanguage.kannada: 'ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ',
    },
    'Enter New Password': {
      AppLanguage.english: 'Enter New Password',
      AppLanguage.hindi: 'नया पासवर्ड दर्ज करें',
      AppLanguage.kannada: 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ',
    },
    'Confirm New Password': {
      AppLanguage.english: 'Confirm New Password',
      AppLanguage.hindi: 'पासवर्ड की पुष्टि करें',
      AppLanguage.kannada: 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    },
    'Open Externally in Excel / Viewer': {
      AppLanguage.english: 'Open Externally in Excel / Viewer',
      AppLanguage.hindi: 'एक्सेल / व्यूअर में खोलें',
      AppLanguage.kannada: 'ಎಕ್ಸೆಲ್ / ವೀಕ್ಷಕದಲ್ಲಿ ತೆರೆಯಿರಿ',
    },
    'Upload & Link Excel File (.xlsx)': {
      AppLanguage.english: 'Upload & Link Excel File (.xlsx)',
      AppLanguage.hindi: 'एक्सेल फ़ाइल (.xlsx) अपलोड और लिंक करें',
      AppLanguage.kannada: 'ಎಕ್ಸೆಲ್ ಫೈಲ್ (.xlsx) ಅಪ್‌ಲೋಡ್ ಮತ್ತು ಲಿಂಕ್ ಮಾಡಿ',
    },
    'Replace File': {
      AppLanguage.english: 'Replace File',
      AppLanguage.hindi: 'फ़ाइल बदलें',
      AppLanguage.kannada: 'ಫೈಲ್ ಬದಲಾಯಿಸಿ',
    },
    'Remove File': {
      AppLanguage.english: 'Remove File',
      AppLanguage.hindi: 'फ़ाइल हटाएं',
      AppLanguage.kannada: 'ಫೈಲ್ ತೆಗೆದುಹಾಕಿ',
    },
    'No Excel Timeline File Linked': {
      AppLanguage.english: 'No Excel Timeline File Linked',
      AppLanguage.hindi: 'कोई एक्सेल टाइमलाइन फ़ाइल जुड़ी नहीं है',
      AppLanguage.kannada: 'ಯಾವುದೇ ಎಕ್ಸೆಲ್ ಟೈಮ್‌ಲೈನ್ ಫೈಲ್ ಲಿಂಕ್ ಆಗಿಲ್ಲ',
    },
    'Text Size': {
      AppLanguage.english: 'Text Size',
      AppLanguage.hindi: 'टेक्स्ट का आकार',
      AppLanguage.kannada: 'ಪಠ್ಯದ ಗಾತ್ರ',
    },
    'Normal': {
      AppLanguage.english: 'Normal',
      AppLanguage.hindi: 'सामान्य',
      AppLanguage.kannada: 'ಸಾಮಾನ್ಯ',
    },
    'Large': {
      AppLanguage.english: 'Large',
      AppLanguage.hindi: 'बड़ा',
      AppLanguage.kannada: 'ದೊಡ್ಡದು',
    },
    'Extra Large': {
      AppLanguage.english: 'Extra Large',
      AppLanguage.hindi: 'बहुत बड़ा',
      AppLanguage.kannada: 'ಅತಿ ದೊಡ್ಡದು',
    },
    'Quick Start Guide': {
      AppLanguage.english: 'Quick Start Guide',
      AppLanguage.hindi: 'त्वरित उपयोग गाइड',
      AppLanguage.kannada: 'ತ್ವರಿತ ಬಳಕೆ ಮಾರ್ಗದರ್ಶಿ',
    },
    'Show Quick Guide': {
      AppLanguage.english: 'Show Quick Guide',
      AppLanguage.hindi: 'गाइड दिखाएं',
      AppLanguage.kannada: 'ಮಾರ್ಗದರ್ಶಿ ತೋರಿಸಿ',
    },
    'Next': {
      AppLanguage.english: 'Next',
      AppLanguage.hindi: 'अगला',
      AppLanguage.kannada: 'ಮುಂದೆ',
    },
    'Got It': {
      AppLanguage.english: 'Got It',
      AppLanguage.hindi: 'समझ गया',
      AppLanguage.kannada: 'ಅರ್ಥವಾಯಿತು',
    },
    'Skip': {
      AppLanguage.english: 'Skip',
      AppLanguage.hindi: 'छोड़ें',
      AppLanguage.kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    },
    'Sign Out': {
      AppLanguage.english: 'Sign Out',
      AppLanguage.hindi: 'साइन आउट',
      AppLanguage.kannada: 'ಸೈನ್ ಔಟ್',
      AppLanguage.marathi: 'साइन आउट',
      AppLanguage.tamil: 'வெளியேறு',
      AppLanguage.telugu: 'సైన్ అవుట్',
    },
    'Drawings & Renders': {
      AppLanguage.english: 'Drawings & Renders',
      AppLanguage.hindi: 'ड्राइंग और 3D व्यू',
      AppLanguage.kannada: 'ಡ್ರಾಯಿಂಗ್‌ಗಳು ಮತ್ತು ರೆಂಡರ್‌ಗಳು',
    },
    'Drawings & Files': {
      AppLanguage.english: 'Drawings & Files',
      AppLanguage.hindi: 'ड्राइंग और फ़ाइलें',
      AppLanguage.kannada: 'ಡ್ರಾಯಿಂಗ್‌ಗಳು ಮತ್ತು ಫೈಲ್‌ಗಳು',
    },
    'Team & Staff': {
      AppLanguage.english: 'Team & Staff',
      AppLanguage.hindi: 'टीम और कर्मचारी',
      AppLanguage.kannada: 'ತಂಡ ಮತ್ತು ಸಿಬ್ಬಂದಿ',
    },
    'Team & Access': {
      AppLanguage.english: 'Team & Access',
      AppLanguage.hindi: 'टीम और अनुमतियां',
      AppLanguage.kannada: 'ತಂಡ ಮತ್ತು ಪ್ರವೇಶ',
    },
    'Studio Settings & Photo Archive': {
      AppLanguage.english: 'Studio Settings & Photo Archive',
      AppLanguage.hindi: 'स्टूडियो सेटिंग्स और फ़ोटो संग्रह',
      AppLanguage.kannada: 'ಸ್ಟುಡಿಯೋ ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಮತ್ತು ಫೋಟೋ ಆರ್ಕೈವ್',
    },
    'INTERFACE LANGUAGE': {
      AppLanguage.english: 'INTERFACE LANGUAGE',
      AppLanguage.hindi: 'ऐप की भाषा',
      AppLanguage.kannada: 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ',
    },
    'APPEARANCE & THEME': {
      AppLanguage.english: 'APPEARANCE & THEME',
      AppLanguage.hindi: 'रंग और थीम',
      AppLanguage.kannada: 'ನೋಟ ಮತ್ತು ಥೀಮ್',
    },
    'Dark Mode Active': {
      AppLanguage.english: 'Dark Mode Active',
      AppLanguage.hindi: 'डार्क मोड चालू',
      AppLanguage.kannada: 'ಡಾರ್ಕ್ ಮೋಡ್ ಸಕ್ರಿಯವಾಗಿದೆ',
    },
    'Light Mode Active': {
      AppLanguage.english: 'Light Mode Active',
      AppLanguage.hindi: 'लाइट मोड चालू',
      AppLanguage.kannada: 'ಲೈಟ್ ಮೋಡ್ ಸಕ್ರಿಯವಾಗಿದೆ',
    },
    'Manage Roles & Access': {
      AppLanguage.english: 'Manage Roles & Access',
      AppLanguage.hindi: 'भूमिका और अनुमतियां प्रबंधित करें',
      AppLanguage.kannada: 'ಪಾತ್ರಗಳು ಮತ್ತು ಪ್ರವೇಶ ನಿರ್ವಹಿಸಿ',
    },
    'Edit Role & Access': {
      AppLanguage.english: 'Edit Role & Access',
      AppLanguage.hindi: 'भूमिका बदलें',
      AppLanguage.kannada: 'ಪಾತ್ರ ಮತ್ತು ಪ್ರವೇಶ ಬದಲಿಸಿ',
    },
    'Dismiss Staff': {
      AppLanguage.english: 'Dismiss Staff',
      AppLanguage.hindi: 'कर्मचारी हटाएं',
      AppLanguage.kannada: 'ಸಿಬ್ಬಂದಿಯನ್ನು ತೆಗೆದುಹಾಕಿ',
    },
    'Cloud Synced': {
      AppLanguage.english: 'Synced',
      AppLanguage.hindi: 'सिंक है',
      AppLanguage.kannada: 'ಸಿಂಕ್ ಆಗಿದೆ',
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
    'Submit': {
      AppLanguage.english: 'Submit',
      AppLanguage.hindi: 'जमा करें',
      AppLanguage.kannada: 'ಸಲ್ಲಿಸಿ',
      AppLanguage.marathi: 'सबमिट करा',
      AppLanguage.tamil: 'சமர்ப்பிக்கவும்',
      AppLanguage.telugu: 'సమర్పించండి',
    },
    'Search': {
      AppLanguage.english: 'Search',
      AppLanguage.hindi: 'खोजें',
      AppLanguage.kannada: 'ಹುಡುಕಿ',
      AppLanguage.marathi: 'शोधा',
      AppLanguage.tamil: 'தேடு',
      AppLanguage.telugu: 'వెతకండి',
    },
    'Filter': {
      AppLanguage.english: 'Filter',
      AppLanguage.hindi: 'फ़िल्टर',
      AppLanguage.kannada: 'ಫಿಲ್ಟರ್',
      AppLanguage.marathi: 'फिल्टर',
      AppLanguage.tamil: 'வடிகட்டி',
      AppLanguage.telugu: 'ఫిల్టర్',
    },
    'Stages & Checklist': {
      AppLanguage.english: 'Stages & Checklist',
      AppLanguage.hindi: 'चरण और चेकलिस्ट',
      AppLanguage.kannada: 'ಹಂತಗಳು ಮತ್ತು ಪರಿಶೀಲನಾಪಟ್ಟಿ',
      AppLanguage.marathi: 'टप्पे आणि चेकलिस्ट',
      AppLanguage.tamil: 'நிலைகள் & சரிபார்ப்புப் பட்டியல்',
      AppLanguage.telugu: 'దశలు & చెక్‌లిస్ట్',
    },
    'Add Stage': {
      AppLanguage.english: 'Add Stage',
      AppLanguage.hindi: 'चरण जोड़ें',
      AppLanguage.kannada: 'ಹಂತ ಸೇರಿಸಿ',
      AppLanguage.marathi: 'टप्पा जोडा',
      AppLanguage.tamil: 'நிலையைச் சேர்க்கவும்',
      AppLanguage.telugu: 'దశను జోడించండి',
    },
    'FINANCIAL COMMITMENT': {
      AppLanguage.english: 'FINANCIAL COMMITMENT',
      AppLanguage.hindi: 'वित्तीय प्रतिबद्धता',
      AppLanguage.kannada: 'ಬಜೆಟ್ ಮತ್ತು ಖರ್ಚು',
      AppLanguage.marathi: 'आर्थिक वचनबद्धता',
      AppLanguage.tamil: 'நிதி அர்ப்பணிப்பு',
      AppLanguage.telugu: 'ఆర్థిక నిబద్ధత',
    },
    'Hide Stages': {
      AppLanguage.english: 'Hide Stages',
      AppLanguage.hindi: 'चरण छुपाएं',
      AppLanguage.kannada: 'ಹಂತಗಳನ್ನು ಮರೆಮಾಡಿ',
      AppLanguage.marathi: 'टप्पे लपवा',
      AppLanguage.tamil: 'நிலைகளை மறை',
      AppLanguage.telugu: 'దశలను దాచు',
    },
    'Onboard Vendor': {
      AppLanguage.english: 'Onboard Vendor',
      AppLanguage.hindi: 'वेंडर जोड़ें',
      AppLanguage.kannada: 'ಮಾರಾಟಗಾರರನ್ನು ಸೇರಿಸಿ',
      AppLanguage.marathi: 'विक्रेता जोडा',
      AppLanguage.tamil: 'விற்பனையாளரை சேர்க்க',
      AppLanguage.telugu: 'విక్రేతను చేర్చండి',
    },
    'Sites & Photos': {
      AppLanguage.english: 'Sites & Photos',
      AppLanguage.hindi: 'साइट और फ़ोटो',
      AppLanguage.marathi: 'साइट्स आणि फोटो',
      AppLanguage.tamil: 'தளங்கள் & புகைப்படங்கள்',
      AppLanguage.telugu: 'సైట్లు & ఫోటోలు',
    },
    'Request Materials': {
      AppLanguage.english: 'Request Materials',
      AppLanguage.hindi: 'सामग्री मांगें',
      AppLanguage.marathi: 'साहित्य मागवा',
      AppLanguage.tamil: 'பொருட்கள் கோருக',
      AppLanguage.telugu: 'మెటీరియల్స్ కోరండి',
    },
    'Report Site Issue': {
      AppLanguage.english: 'Report Site Issue',
      AppLanguage.hindi: 'साइट समस्या दर्ज करें',
      AppLanguage.marathi: 'साइट समस्या नोंदवा',
      AppLanguage.tamil: 'தள சிக்கலைப் புகாரளிக்கவும்',
      AppLanguage.telugu: 'సైట్ సమస్యను నివేదించండి',
    },
    'Design Drawings': {
      AppLanguage.english: 'Design Drawings',
      AppLanguage.hindi: 'डिज़ाइन ड्राइंग',
      AppLanguage.marathi: 'डिझाइन ड्रॉइंग्स',
      AppLanguage.tamil: 'வடிவமைப்பு வரைபடங்கள்',
      AppLanguage.telugu: 'డిజైన్ డ్రాయింగ్స్',
    },
    'Ongoing Projects': {
      AppLanguage.english: 'Ongoing Projects',
      AppLanguage.hindi: 'चल रहे प्रोजेक्ट्स',
      AppLanguage.marathi: 'सुरू असलेले प्रोजेक्ट्स',
      AppLanguage.tamil: 'நடக்கும் திட்டங்கள்',
      AppLanguage.telugu: 'కొనసాగుతున్న ప్రాజెక్టులు',
    },
    'Pending Receivables': {
      AppLanguage.english: 'Pending Receivables',
      AppLanguage.hindi: 'बकाया राशि',
      AppLanguage.marathi: 'येणे बाकी रक्कम',
      AppLanguage.tamil: 'நிலுவையில் உள்ள வரவுகள்',
      AppLanguage.telugu: 'రావలసిన బకాయిలు',
    },
    'Net Cash Flow': {
      AppLanguage.english: 'Net Cash Flow',
      AppLanguage.hindi: 'शुद्ध नकदी प्रवाह',
      AppLanguage.marathi: 'निव्वळ रोख प्रवाह',
      AppLanguage.tamil: 'நிகர பணப்புழக்கம்',
      AppLanguage.telugu: 'నికర నగదు ప్రవాహం',
    },
    'Sales & Client Pipeline': {
      AppLanguage.english: 'Sales & Client Pipeline',
      AppLanguage.hindi: 'बिक्री और क्लाइंट पाइपलाइन',
      AppLanguage.marathi: 'विक्री आणि क्लायंट पाइपलाइन',
      AppLanguage.tamil: 'விற்பனை & வாடிக்கையாளர் பட்டியல்',
      AppLanguage.telugu: 'సేల్స్ & క్లయింట్ పైప్‌లైన్',
    },
    'Design Studio': {
      AppLanguage.english: 'Design Studio',
      AppLanguage.hindi: 'डिज़ाइन स्टूडियो',
      AppLanguage.marathi: 'डिझाइन स्टुडिओ',
      AppLanguage.tamil: 'வடிவமைப்பு ஸ்டுடியோ',
      AppLanguage.telugu: 'డిజైన్ స్టూडिओ',
    },
    'Site Amendments': {
      AppLanguage.english: 'Site Amendments',
      AppLanguage.hindi: 'साइट संशोधन',
      AppLanguage.marathi: 'साइट बदल',
      AppLanguage.tamil: 'தள திருத்தங்கள்',
      AppLanguage.telugu: 'సైట్ మార్పులు',
    },
    'Accounts & Ledgers': {
      AppLanguage.english: 'Accounts & Ledgers',
      AppLanguage.hindi: 'खाते और बहीखाता',
      AppLanguage.marathi: 'खाती आणि लेजर',
      AppLanguage.tamil: 'கணக்குகள் & லெட்ஜர்கள்',
      AppLanguage.telugu: 'ఖాతాలు & లెడ్జర్లు',
    },
    'Team & Tasks': {
      AppLanguage.english: 'Team & Tasks',
      AppLanguage.hindi: 'टीम और कार्य',
      AppLanguage.marathi: 'टीम आणि कामे',
      AppLanguage.tamil: 'குழு & பணிகள்',
      AppLanguage.telugu: 'టీమ్ & పనులు',
    },
    'Filter Projects': {
      AppLanguage.english: 'Filter Projects',
      AppLanguage.hindi: 'प्रोजेक्ट फ़िल्टर',
      AppLanguage.marathi: 'प्रोजेक्ट फिल्टर',
      AppLanguage.tamil: 'திட்டங்களை வடிகட்டு',
      AppLanguage.telugu: 'ప్రాజెక్టులు ఫిల్టర్',
    },
    'Filter Drawings': {
      AppLanguage.english: 'Filter Drawings',
      AppLanguage.hindi: 'ड्राइंग फ़िल्टर',
      AppLanguage.kannada: 'ಡ್ರಾಯಿಂಗ್ ಫಿಲ್ಟರ್',
      AppLanguage.marathi: 'ड्रॉइंग फिल्टर',
      AppLanguage.tamil: 'வரைபடங்கள் வடிகட்டு',
      AppLanguage.telugu: 'డ్రాయింగ్స్ ఫిల్టర్',
    },
    'Add Lead': {
      AppLanguage.english: 'Add Lead',
      AppLanguage.hindi: 'ग्राहक जोड़ें',
      AppLanguage.kannada: 'ಗ್ರಾಹಕರನ್ನು ಸೇರಿಸಿ',
      AppLanguage.marathi: 'लीड जोडा',
      AppLanguage.tamil: 'லீட் சேர்',
      AppLanguage.telugu: 'లీడ్ జోడించండి',
    },
    'Pending Sign-Off': {
      AppLanguage.english: 'Pending Sign-Off',
      AppLanguage.hindi: 'स्वीकृति लंबित',
      AppLanguage.kannada: 'ಅನುಮೋದನೆ ಬಾಕಿ ಇದೆ',
      AppLanguage.marathi: 'मंजुरी प्रलंबित',
      AppLanguage.tamil: 'ஒப்புதல் நிலுவை',
      AppLanguage.telugu: 'ఆమోదం పెండింగ్',
    },
    'Print Invoice': {
      AppLanguage.english: 'Print Invoice',
      AppLanguage.hindi: 'बिल प्रिंट करें',
      AppLanguage.kannada: 'ಬಿಲ್ ಪ್ರಿಂಟ್ ಮಾಡಿ',
      AppLanguage.marathi: 'बिल प्रिंट करा',
      AppLanguage.tamil: 'பில் அச்சிடு',
      AppLanguage.telugu: 'బిల్లు ప్రింట్',
    },
    'P&L Report': {
      AppLanguage.english: 'P&L Report',
      AppLanguage.hindi: 'लाभ-हानि रिपोर्ट',
      AppLanguage.kannada: 'ಲಾಭ-ನಷ್ಟ ವರದಿ',
      AppLanguage.marathi: 'नफा-तोटा अहवाल',
      AppLanguage.tamil: 'லாப-நஷ்ட அறிக்கை',
      AppLanguage.telugu: 'లాభ-నష్ట నివేదిక',
    },
    'Record Expense': {
      AppLanguage.english: 'Record Expense',
      AppLanguage.hindi: 'खर्च दर्ज करें',
      AppLanguage.kannada: 'ಖರ್ಚು ದಾಖಲಿಸಿ',
      AppLanguage.marathi: 'खर्च नोंदवा',
      AppLanguage.tamil: 'செலவு பதிவு',
      AppLanguage.telugu: 'ఖర్చు నమోదు',
    },
    'Labour Roll': {
      AppLanguage.english: 'Labour Roll',
      AppLanguage.hindi: 'श्रमिक हाज़िरी',
      AppLanguage.kannada: 'ಕಾರ್ಮಿಕರ ಹಾಜರಾತಿ',
      AppLanguage.marathi: 'कामगार हजेरी',
      AppLanguage.tamil: 'தொழிலாளர் வருகை',
      AppLanguage.telugu: 'కార్మికుల హాజరు',
    },
    'New Request': {
      AppLanguage.english: 'New Request',
      AppLanguage.hindi: 'नया अनुरोध',
      AppLanguage.kannada: 'ಹೊಸ ವಿನಂತಿ',
      AppLanguage.marathi: 'नवीन विनंती',
      AppLanguage.tamil: 'புதிய கோரிக்கை',
      AppLanguage.telugu: 'కొత్త అభ్యర్థన',
    },
    'Track Dispatch': {
      AppLanguage.english: 'Track Dispatch',
      AppLanguage.hindi: 'डिस्पैच ट्रैक करें',
      AppLanguage.kannada: 'ರವಾನೆಯನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ',
      AppLanguage.marathi: 'डिस्पॅच ट्रॅक करा',
      AppLanguage.tamil: 'அனுப்புதலைக் கண்காணி',
      AppLanguage.telugu: 'డిస్పాచ్ ట్రాక్',
    },
    'Step Back': {
      AppLanguage.english: 'Step Back',
      AppLanguage.hindi: 'पीछे जाएं',
      AppLanguage.kannada: 'ಹಿಂದಕ್ಕೆ ಹೋಗಿ',
      AppLanguage.marathi: 'मागे जा',
      AppLanguage.tamil: 'பின்செல்',
      AppLanguage.telugu: 'వెనుకకు వెళ్ళండి',
    },
    'Cloud Sync On': {
      AppLanguage.english: 'Cloud Sync On',
      AppLanguage.hindi: 'क्लाउड सिंक चालू',
      AppLanguage.kannada: 'ಕ್ಲೌಡ್ ಸಿಂಕ್ ಆನ್',
      AppLanguage.marathi: 'क्लाउड सिंक सुरू',
      AppLanguage.tamil: 'கிளவுட் ஒத்திசைவு இயக்கம்',
      AppLanguage.telugu: 'క్లౌడ్ సింక్ ఆన్',
    },
    'Saved on Phone (Offline)': {
      AppLanguage.english: 'Saved on Phone (Offline)',
      AppLanguage.hindi: 'फ़ोन पर सहेजा गया (ऑफ़लाइन)',
      AppLanguage.kannada: 'ಫೋನ್‌ನಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ (ಆಫ್‌ಲೈನ್)',
      AppLanguage.marathi: 'फोनवर जतन केले (ऑफलाइन)',
      AppLanguage.tamil: 'தொலைபேசியில் சேமிக்கப்பட்டது',
      AppLanguage.telugu: 'ఫోన్‌లో సేవ్ చేయబడింది',
    },
    'Change Requests & Scope': {
      AppLanguage.english: 'Change Requests & Scope',
      AppLanguage.hindi: 'बदलाव अनुरोध और दायरा',
      AppLanguage.kannada: 'ಬದಲಾವಣೆ ವಿನಂತಿಗಳು',
    },
    'Scope, cost, or timeline changes requested by client or site': {
      AppLanguage.english:
          'Scope, cost, or timeline changes requested by client or site',
      AppLanguage.hindi:
          'ग्राहक या साइट की ओर से काम, खर्च या समय में बदलाव के अनुरोध',
      AppLanguage.kannada:
          'ಗ್ರಾಹಕರು ಅಥವಾ ಸೈಟ್‌ನಿಂದ ಕೇಳಲಾದ ಕೆಲಸ, ವೆಚ್ಚ ಅಥವಾ ಸಮಯದ ಬದಲಾವಣೆಗಳು',
    },
    'Drawings, 3D views & material lists': {
      AppLanguage.english: 'Drawings, 3D views & material lists',
      AppLanguage.hindi: '2D प्लान, 3D व्यू और सामग्री की सूची',
      AppLanguage.kannada: '2D ಪ್ಲಾನ್‌ಗಳು, 3D ವೀಕ್ಷಣೆಗಳು ಮತ್ತು ಸಾಮಗ್ರಿ ಪಟ್ಟಿಗಳು',
    },
    'Zone': {
      AppLanguage.english: 'Zone',
      AppLanguage.hindi: 'क्षेत्र',
      AppLanguage.kannada: 'ವಿಭಾಗ',
    },
    'Recorded': {
      AppLanguage.english: 'Recorded',
      AppLanguage.hindi: 'समय',
      AppLanguage.kannada: 'ಸಮಯ',
    },
    'Captured By': {
      AppLanguage.english: 'Captured By',
      AppLanguage.hindi: 'किसने लिया',
      AppLanguage.kannada: 'ತೆಗೆದವರು',
    },
    'PROJECT TIMELINE SPREADSHEET': {
      AppLanguage.english: 'EXCEL TIMELINE FILE',
      AppLanguage.hindi: 'एक्सेल टाइमलाइन फ़ाइल',
      AppLanguage.kannada: 'ಎಕ್ಸೆಲ್ ಟೈಮ್‌ಲೈನ್ ಫೈಲ್',
    },
    'Team & Staff Directory': {
      AppLanguage.english: 'Team & Staff Directory',
      AppLanguage.hindi: 'टीम और कर्मचारी सूची',
      AppLanguage.kannada: 'ತಂಡ ಮತ್ತು ಸಿಬ್ಬಂದಿ ಪಟ್ಟಿ',
    },
    'Manage approved staff, reset passwords & check new access requests': {
      AppLanguage.english:
          'Manage approved staff, reset passwords & check new access requests',
      AppLanguage.hindi:
          'कर्मचारियों को प्रबंधित करें, पासवर्ड रीसेट करें और नए अनुरोध देखें',
      AppLanguage.kannada:
          'ಸಿಬ್ಬಂದಿಯನ್ನು ನಿರ್ವಹಿಸಿ, ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ ಮತ್ತು ಹೊಸ ವಿನಂತಿಗಳನ್ನು ಪರಿಶೀಲಿಸಿ',
    },
    'No Change Requests Found': {
      AppLanguage.english: 'No Change Requests Found',
      AppLanguage.hindi: 'कोई बदलाव अनुरोध नहीं मिला',
      AppLanguage.kannada: 'ಯಾವುದೇ ಬದಲಾವಣೆ ವಿನಂತಿಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
    },
    'No change requests yet. Tap below to log a scope or cost change.': {
      AppLanguage.english:
          'No change requests yet. Tap below to log a scope or cost change.',
      AppLanguage.hindi:
          'अभी कोई बदलाव अनुरोध नहीं है। नया बदलाव दर्ज करने के लिए नीचे टैप करें।',
      AppLanguage.kannada:
          'ಇನ್ನೂ ಯಾವುದೇ ಬದಲಾವಣೆ ವಿನಂತಿಗಳಿಲ್ಲ. ಹೊಸದನ್ನು ದಾಖಲಿಸಲು ಕೆಳಗೆ ಒತ್ತಿ.',
    },
    'New Change Request': {
      AppLanguage.english: 'New Change Request',
      AppLanguage.hindi: 'नया बदलाव अनुरोध',
      AppLanguage.kannada: 'ಹೊಸ ಬದಲಾವಣೆ ವಿನಂತಿ',
    },
    'No client leads yet. Tap below to add your first lead.': {
      AppLanguage.english:
          'No client leads yet. Tap below to add your first lead.',
      AppLanguage.hindi:
          'अभी कोई ग्राहक लीड नहीं है। पहला ग्राहक जोड़ने के लिए नीचे टैप करें।',
      AppLanguage.kannada:
          'ಇನ್ನೂ ಯಾವುದೇ ಗ್ರಾಹಕರ ಲೀಡ್‌ಗಳಿಲ್ಲ. ಮೊದಲ ಗ್ರಾಹಕರನ್ನು ಸೇರಿಸಲು ಕೆಳಗೆ ಒತ್ತಿ.',
    },
  };
}

/// Syntactic sugar extension for inline translation: `'Add Task'.tr`
extension AppTranslateExtension on String {
  String get tr => AppStrings.tr(this);
}
