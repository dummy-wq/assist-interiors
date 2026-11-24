import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'backend_manager.dart';

/// Centralized local persistent storage service for Assist Interiors.
/// Backed by SharedPreferences (NSUserDefaults on iOS, Android SharedPreferences on Android,
/// and local key-value storage on desktop / web).
class StorageService {
  static SharedPreferences? _prefs;

  /// Emits whenever remote Firestore snapshot data updates local collections.
  static final ValueNotifier<int> cloudSyncNotifier = ValueNotifier<int>(0);
  static bool _isApplyingRemoteUpdate = false;

  static const String _keyProjects = 'assist_projects_v1';
  static const String _keyTasks = 'assist_tasks_v1';
  static const String _keyVendors = 'assist_vendors_v1';
  static const String _keyInvoices = 'assist_invoices_v1';
  static const String _keyExpenses = 'assist_expenses_v1';
  static const String _keyReceipts = 'assist_receipts_v1';
  static const String _keyLeads = 'assist_leads_v1';
  static const String _keySiteLogs = 'assist_sitelogs_v1';
  static const String _keyMilestones = 'assist_milestones_v1';
  static const String _keyDesignItems = 'assist_design_items_v1';
  static const String _keyMaterialRequests = 'assist_material_requests_v1';
  static const String _keyAmendments = 'assist_amendments_v1';
  static const String _keyLabourRoll = 'assist_labour_roll_v1';
  static const String _keyApprovedUsers = 'assist_approved_users_v1';
  static const String _keyPendingUsers = 'assist_pending_users_v1';
  static const String _keyCustomRoles = 'assist_custom_roles_v1';
  static const String _keyCurrentUserId = 'assist_current_user_id_v1';
  static const String _keyTextScaleFactor = 'assist_text_scale_v1';
  static const String _keyOnboardingPrefix = 'assist_onboarding_seen_v1_';
  static const String _keyPhotoRetentionMonths =
      'assist_photo_retention_months_v1';
  static const String _keyCadRetentionMonths = 'assist_cad_retention_months_v1';
  static const String _keySeedVersion = 'assist_seed_version_v1';
  static const String _keyCleanDeliveryWipe = 'assist_clean_delivery_wiped_v1';
  static const int _currentSeedVersion = 3;

  /// Default backend reservation period for uploaded site photos (6 months).
  static const int defaultPhotoRetentionMonths = 6;
  static const int extendedPhotoRetentionMonths = 12;
  static const List<int> supportedPhotoRetentionMonths = [6, 12];

  /// Default backend reservation period for CAD drawings & 3D renders (12 months).
  static const int defaultCadRetentionMonths = 12;
  static const List<int> supportedCadRetentionMonths = [6, 12];

  /// Initialize persistent storage engine on app boot or in tests.
  static Future<void> init([SharedPreferences? mockPrefs]) async {
    _prefs = mockPrefs ?? await SharedPreferences.getInstance();

    final hasWipedForCleanDelivery =
        _prefs?.getBool(_keyCleanDeliveryWipe) ?? false;
    if (!hasWipedForCleanDelivery) {
      await clearAll();
      await clearUsers();
      await _prefs?.setBool(_keyCleanDeliveryWipe, true);
    }

    // Populate preExistingProjects from stored projects
    final storedProjects = getProjects();
    AppConstants.preExistingProjects.clear();
    if (storedProjects.isNotEmpty) {
      for (final p in storedProjects) {
        final name = p['name'] as String?;
        if (name != null && !AppConstants.preExistingProjects.contains(name)) {
          AppConstants.preExistingProjects.add(name);
        }
      }
    }
  }

  static List<Map<String, dynamic>> _readMapList(
    String key, {
    List<String> colorFields = const ['color'],
  }) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        for (final field in colorFields) {
          if (map[field] is int) {
            map[field] = Color(map[field] as int);
          }
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _writeMapList(
    String key,
    List<Map<String, dynamic>> items, {
    List<String> colorFields = const ['color'],
    String label = 'items',
  }) async {
    try {
      final serializable = colorFields.isEmpty
          ? items
          : items.map((item) {
              final copy = Map<String, dynamic>.from(item);
              for (final field in colorFields) {
                if (copy[field] is Color) {
                  copy[field] = (copy[field] as Color).toARGB32();
                }
              }
              return copy;
            }).toList();
      await _prefs?.setString(key, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save $label to storage: $e');
    }
  }

  // ==================== PROJECTS ====================

  /// Computes normalized completion progress (0.0..1.0) for [project] from its stages.
  static double computeProjectProgress(Map<String, dynamic> project) {
    final stages = project['stages'];
    if (stages is List && stages.isNotEmpty) {
      final doneCount =
          stages.where((s) => s is Map && s['isDone'] == true).length;
      return (doneCount / stages.length).clamp(0.0, 1.0);
    }
    final raw = project['progress'];
    if (raw is num) {
      return raw > 1.0
          ? (raw / 100.0).clamp(0.0, 1.0)
          : raw.toDouble().clamp(0.0, 1.0);
    }
    return project['status'] == 'Completed' ? 1.0 : 0.0;
  }

  /// Synchronizes `progress` (0.0..1.0) and `status` on [project] from its stages and delay flag.
  static void syncProjectProgressAndStatus(Map<String, dynamic> project) {
    project['progress'] = computeProjectProgress(project);
    final stages = project['stages'];
    if (project['isDelayed'] == true) {
      project['status'] = 'Delayed';
      return;
    }
    final manualStatus = (project['manualStatus'] ?? '').toString().trim();
    if (manualStatus.isNotEmpty) {
      project['status'] = manualStatus;
      return;
    }
    if (stages is List && stages.isNotEmpty) {
      final doneCount =
          stages.where((s) => s is Map && s['isDone'] == true).length;
      if (doneCount == stages.length) {
        project['status'] = 'Completed';
      } else {
        final currStatus = (project['status'] ?? '').toString();
        if (currStatus.isEmpty ||
            currStatus == 'Completed' ||
            currStatus == 'Delayed') {
          project['status'] = 'On Track';
        }
      }
    } else {
      final currStatus = (project['status'] ?? '').toString();
      if (currStatus.isEmpty || currStatus == 'Delayed') {
        project['status'] = 'Design and Planning';
      }
    }
  }

  static List<Map<String, dynamic>> getProjects() {
    final raw = _prefs?.getString(_keyProjects);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        // Auto-heal legacy or missing swatches using the architectural palette
        final projName = map['name'] as String? ?? '';
        final swatch = AppColors.getProjectSwatch(projName);
        if (map['color'] == null ||
            map['color'] == AppColors.brandPeach ||
            map['color'] == AppColors.info ||
            map['color'] == AppColors.error) {
          map['color'] = swatch['color'];
          map['swatchName'] = swatch['name'];
        } else if (map['swatchName'] == null) {
          map['swatchName'] = swatch['name'];
        }
        if (map['stages'] is List) {
          map['stages'] = (map['stages'] as List)
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList();
        } else {
          map['stages'] = <Map<String, dynamic>>[];
        }
        if (map['photos'] is List) {
          final activeRetention = getPhotoRetentionMonths();
          map['photos'] = (map['photos'] as List).map((p) {
            final photoMap = p is Map
                ? Map<String, dynamic>.from(p)
                : <String, dynamic>{
                    'title': p.toString(),
                    'timestamp': '',
                    'tag': 'Site',
                  };
            final uploadedIso = photoMap['uploadedAt']?.toString() ??
                DateTime.now().toIso8601String();
            final uploadedDate =
                DateTime.tryParse(uploadedIso) ?? DateTime.now();
            final retention = photoMap['retentionMonths'] is int
                ? photoMap['retentionMonths'] as int
                : activeRetention;
            final reservedUntil = uploadedDate.add(
              Duration(days: retention * 30),
            );
            photoMap['uploadedAt'] = uploadedDate.toIso8601String();
            photoMap['retentionMonths'] = retention;
            photoMap['reservedUntil'] =
                DateFormat('dd MMM yyyy').format(reservedUntil);
            return photoMap;
          }).toList();
        } else {
          map['photos'] = <Map<String, dynamic>>[];
        }
        if (map['designAssets'] is List) {
          map['designAssets'] = (map['designAssets'] as List)
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();
        } else {
          map['designAssets'] = <Map<String, dynamic>>[];
        }
        if (map['timelineSpreadsheet'] is Map) {
          map['timelineSpreadsheet'] = Map<String, dynamic>.from(
            map['timelineSpreadsheet'] as Map,
          );
        } else {
          map['timelineSpreadsheet'] = null;
        }
        syncProjectProgressAndStatus(map);
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    try {
      // Sync names into preExistingProjects
      AppConstants.preExistingProjects.clear();
      for (final p in projects) {
        final name = p['name'] as String?;
        if (name != null && !AppConstants.preExistingProjects.contains(name)) {
          AppConstants.preExistingProjects.add(name);
        }
      }

      final serializable = projects.map((p) {
        syncProjectProgressAndStatus(p);
        final copy = Map<String, dynamic>.from(p);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        if (copy['stages'] is List) {
          copy['stages'] = (copy['stages'] as List)
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList();
        }
        if (copy['photos'] is List) {
          copy['photos'] = (copy['photos'] as List).map((p) {
            if (p is Map) return Map<String, dynamic>.from(p);
            return {'title': p.toString(), 'timestamp': '', 'tag': 'Site'};
          }).toList();
        }
        if (copy['designAssets'] is List) {
          copy['designAssets'] = (copy['designAssets'] as List)
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();
        }
        if (copy['timelineSpreadsheet'] is Map) {
          copy['timelineSpreadsheet'] = Map<String, dynamic>.from(
            copy['timelineSpreadsheet'] as Map,
          );
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyProjects, jsonEncode(serializable));
      if (!_isApplyingRemoteUpdate) {
        BackendManager.instance.syncCollection('projects', projects);
      }
    } catch (e) {
      debugPrint('Failed to save projects to storage: $e');
    }
  }

  // ==================== TASKS ====================

  static List<Map<String, dynamic>> getTasks() => _readMapList(
    _keyTasks,
    colorFields: const ['color', 'statusColor'],
  );

  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    await _writeMapList(
      _keyTasks,
      tasks,
      colorFields: const ['color', 'statusColor'],
      label: 'tasks',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('tasks', tasks);
    }
  }

  // ==================== VENDORS ====================

  static List<Map<String, dynamic>> getVendors() => _readMapList(_keyVendors);

  static Future<void> saveVendors(List<Map<String, dynamic>> vendors) async {
    await _writeMapList(_keyVendors, vendors, label: 'vendors');
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('vendors', vendors);
    }
  }

  // ==================== INVOICES ====================

  static List<Map<String, dynamic>> getInvoices() => _readMapList(
    _keyInvoices,
    colorFields: const ['statusColor', 'color'],
  );

  static Future<void> saveInvoices(List<Map<String, dynamic>> invoices) async {
    await _writeMapList(
      _keyInvoices,
      invoices,
      colorFields: const ['statusColor', 'color'],
      label: 'invoices',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('invoices', invoices);
    }
  }

  static Future<Map<String, dynamic>?> updateInvoice(
    String invoiceId,
    Map<String, dynamic> updatedFields,
  ) async {
    final invoices = getInvoices();
    final idx = invoices.indexWhere(
      (i) => i['id'] == invoiceId || i['invoiceNumber'] == invoiceId,
    );
    if (idx != -1) {
      invoices[idx] = {
        ...invoices[idx],
        ...updatedFields,
      };
      await saveInvoices(invoices);
      return invoices[idx];
    }
    return null;
  }

  static Future<bool> updateInvoiceQrCode(
    String invoiceId, {
    String? qrCodePath,
    String? qrCodeBase64,
    String? upiId,
  }) async {
    final updated = await updateInvoice(invoiceId, {
      'qrCodePath': ?qrCodePath,
      'qrCodeBase64': ?qrCodeBase64,
      'upiId': ?upiId,
    });
    return updated != null;
  }

  static Future<bool> updateInvoiceStatus(
    String invoiceId,
    String status, {
    Color? statusColor,
  }) async {
    final updated = await updateInvoice(invoiceId, {
      'status': status,
      'statusColor': ?statusColor,
    });
    return updated != null;
  }

  // ==================== EXPENSES / VOUCHERS ====================

  static List<Map<String, dynamic>> getExpenses() => _readMapList(
    _keyExpenses,
    colorFields: const ['color', 'statusColor'],
  );

  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    await _writeMapList(
      _keyExpenses,
      expenses,
      colorFields: const ['color', 'statusColor'],
      label: 'expenses',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('expenses', expenses);
    }
  }

  // ==================== RECEIPTS ====================

  static List<Map<String, dynamic>> getReceipts() => _readMapList(
    _keyReceipts,
    colorFields: const ['color', 'statusColor'],
  );

  static Future<void> saveReceipts(List<Map<String, dynamic>> receipts) async {
    await _writeMapList(
      _keyReceipts,
      receipts,
      colorFields: const ['color', 'statusColor'],
      label: 'receipts',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('receipts', receipts);
    }
  }

  // ==================== LABOUR ROLL CALL ====================

  static List<Map<String, dynamic>> getLabourRoll() =>
      _readMapList(_keyLabourRoll);

  static Future<void> saveLabourRoll(
    List<Map<String, dynamic>> entries,
  ) async {
    await _writeMapList(
      _keyLabourRoll,
      entries,
      label: 'labour_roll',
    );
  }

  // ==================== LEADS (SALES) ====================

  static List<Map<String, dynamic>> getLeads() => _readMapList(_keyLeads);

  static Future<void> saveLeads(List<Map<String, dynamic>> leads) async {
    await _writeMapList(_keyLeads, leads, label: 'leads');
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('leads', leads);
    }
  }

  static Future<void> updateLead(
    String id,
    Map<String, dynamic> updatedFields,
  ) async {
    final leads = getLeads();
    final idx = leads.indexWhere((l) => l['id'] == id);
    if (idx != -1) {
      leads[idx] = {...leads[idx], ...updatedFields};
      await saveLeads(leads);
    }
  }

  static Future<void> deleteLead(String id) async {
    final leads = getLeads();
    leads.removeWhere((l) => l['id'] == id);
    await saveLeads(leads);
  }

  // ==================== SITE LOGS (SUPERVISOR) ====================

  static List<Map<String, dynamic>> getSiteLogs() => _readMapList(
    _keySiteLogs,
    colorFields: const [],
  );

  static Future<void> saveSiteLogs(List<Map<String, dynamic>> logs) =>
      _writeMapList(
        _keySiteLogs,
        logs,
        colorFields: const [],
        label: 'site logs',
      );

  // ==================== MILESTONES (PM) ====================

  static List<Map<String, dynamic>> getMilestones() => _readMapList(
    _keyMilestones,
    colorFields: const ['color', 'statusColor'],
  );

  static Future<void> saveMilestones(List<Map<String, dynamic>> milestones) =>
      _writeMapList(
        _keyMilestones,
        milestones,
        colorFields: const ['color', 'statusColor'],
        label: 'milestones',
      );

  // ==================== DESIGN ITEMS ====================

  static List<Map<String, dynamic>> getDesignItems() {
    final raw = _prefs?.getString(_keyDesignItems);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['color'] is int) {
            map['color'] = Color(map['color'] as int);
          } else if (map['color'] is! Color) {
            map['color'] = const Color(0xFF6C5CE7);
          }
          if (map['statusColor'] is int) {
            map['statusColor'] = Color(map['statusColor'] as int);
          } else if (map['statusColor'] is! Color) {
            map['statusColor'] = const Color(0xFF6C5CE7);
          }
          return map;
        }).toList();
      } catch (_) {}
    }

    // Fallback: Aggregate all project-level design deliverables
    final allProjects = getProjects();
    final aggregated = <Map<String, dynamic>>[];
    for (final p in allProjects) {
      final assets = p['designAssets'] as List<dynamic>?;
      if (assets != null) {
        for (final a in assets) {
          if (a is Map) aggregated.add(Map<String, dynamic>.from(a));
        }
      }
    }
    return aggregated;
  }

  static Future<void> saveDesignItems(List<Map<String, dynamic>> items) async {
    await _writeMapList(
      _keyDesignItems,
      items,
      colorFields: const ['color', 'statusColor'],
      label: 'design items',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('design_items', items);
    }
  }

  // ==================== MATERIAL REQUESTS ====================

  static List<Map<String, dynamic>> getMaterialRequests() =>
      _readMapList(_keyMaterialRequests);

  static Future<void> saveMaterialRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    await _writeMapList(
      _keyMaterialRequests,
      requests,
      label: 'material requests',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('material_requests', requests);
    }
  }

  static Future<void> seedFillerMaterialRequestsIfEmpty() async {
    // Intentionally empty: materials start clean with zero pre-filled boxes.
  }

  // ==================== AMENDMENTS ====================

  static List<Map<String, dynamic>> getAmendments() =>
      _readMapList(_keyAmendments);

  static Future<void> saveAmendments(List<Map<String, dynamic>> amendments) async {
    await _writeMapList(_keyAmendments, amendments, label: 'amendments');
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('amendments', amendments);
    }
  }

  static Future<void> seedFillerAmendmentsIfEmpty() async {
    final existing = getAmendments();
    if (existing.isNotEmpty) return;

    final defaultAmendments = <Map<String, dynamic>>[
      {
        'id': 'AMD-2026-101',
        'title': 'Private Cinema Dolby Atmos Acoustic Baffle & Suede Wall',
        'project': 'Veridian Golf Links Residence',
        'initiatedBy': 'Client Request',
        'costImpact': '+₹ 4,20,000',
        'timelineImpact': '+6 Days',
        'priority': 'High',
        'status': 'Client Approved',
        'requestedBy': 'Justice Siddharth Luthra',
        'description':
            'Upgraded basement lounge to a 9.2.4 Dolby Atmos screening room with concealed acoustic timber slat absorbers and alcantara wall panels.',
        'clientSignOffDate': '12 Nov 2026',
        'color': AppColors.success,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      },
      {
        'id': 'AMD-2026-102',
        'title': 'Cantilevered Brass & Onyx Floating Bar Counter',
        'project': 'Saffron Heritage Courtyard Villa',
        'initiatedBy': 'Design Refinement',
        'costImpact': '+₹ 2,95,000',
        'timelineImpact': '+4 Days',
        'priority': 'Medium',
        'status': 'Under Review',
        'requestedBy': 'Vikram Malhotra (Designer)',
        'description':
            'Backlit honey onyx monolithic bar island with concealed structural steel cantilever bracket and PVD brushed champagne brass fascia.',
        'clientSignOffDate': 'Pending Client Sign-off',
        'color': AppColors.warning,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      },
      {
        'id': 'AMD-2026-103',
        'title': 'Double-Glazed Thermal Break Balcony Slider Frame Upgrade',
        'project': 'Solstice Terrace Duplex 19B',
        'initiatedBy': 'Site Engineering Condition',
        'costImpact': '+₹ 1,65,000',
        'timelineImpact': '+8 Days',
        'priority': 'Urgent',
        'status': 'In Execution',
        'requestedBy': 'Suresh Kumar (Supervisor)',
        'description':
            'High wind-load exposure on 19th-floor terrace required upgrading standard slim-profile aluminum track to reinforced acoustic DGU system.',
        'clientSignOffDate': '09 Nov 2026',
        'color': AppColors.info,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
      },
      {
        'id': 'AMD-2026-104',
        'title': 'Heated Italian Travertine Spa Deck & Steam Enclosure',
        'project': 'Aurelia Sea-Facing Penthouse 42',
        'initiatedBy': 'Client Request',
        'costImpact': '+₹ 3,50,000',
        'timelineImpact': '+5 Days',
        'priority': 'Medium',
        'status': 'Completed',
        'requestedBy': 'Mrs. Rhea Birla',
        'description':
            'Added underfloor electric radiant heating mat and frameless low-iron glass steam generator enclosure in the master bath suite.',
        'clientSignOffDate': '02 Nov 2026',
        'color': AppColors.brandPeach,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 8))
            .toIso8601String(),
      },
    ];

    await saveAmendments(defaultAmendments);
  }

  // ==================== USERS & STAFF ACCESS ====================

  static List<Map<String, dynamic>> getApprovedUsers() => _readMapList(
    _keyApprovedUsers,
    colorFields: const [],
  );

  static Future<void> saveApprovedUsers(List<Map<String, dynamic>> users) =>
      _writeMapList(
        _keyApprovedUsers,
        users,
        colorFields: const [],
        label: 'approved users',
      );

  static List<Map<String, dynamic>> getPendingUsers() => _readMapList(
    _keyPendingUsers,
    colorFields: const [],
  );

  static Future<void> savePendingUsers(List<Map<String, dynamic>> users) =>
      _writeMapList(
        _keyPendingUsers,
        users,
        colorFields: const [],
        label: 'pending users',
      );

  static List<Map<String, dynamic>> getCustomRoles() => _readMapList(
    _keyCustomRoles,
    colorFields: const [],
  );

  static Future<void> saveCustomRoles(List<Map<String, dynamic>> roles) async {
    await _writeMapList(
      _keyCustomRoles,
      roles,
      colorFields: const [],
      label: 'custom roles',
    );
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncCollection('custom_roles', roles);
    }
  }

  static Future<void> clearUsers() async {
    await _prefs?.remove(_keyApprovedUsers);
    await _prefs?.remove(_keyPendingUsers);
    await _prefs?.remove(_keyCustomRoles);
    await _prefs?.remove(_keyCurrentUserId);
  }

  static String? getCurrentUserId() => _prefs?.getString(_keyCurrentUserId);

  static Future<void> saveCurrentUserId(String? userId) async {
    if (userId == null || userId.isEmpty) {
      await _prefs?.remove(_keyCurrentUserId);
    } else {
      await _prefs?.setString(_keyCurrentUserId, userId);
    }
  }

  // ==================== ACCESSIBILITY & ONBOARDING PREFERENCES ====================

  static double getTextScaleFactor() {
    final val = _prefs?.getDouble(_keyTextScaleFactor);
    if (val != null && val >= 0.9 && val <= 1.5) return val;
    return 1.0;
  }

  static Future<void> saveTextScaleFactor(double factor) async {
    await _prefs?.setDouble(_keyTextScaleFactor, factor);
  }

  static bool hasSeenOnboardingTips(String roleName) {
    return _prefs?.getBool('$_keyOnboardingPrefix$roleName') ?? false;
  }

  static Future<void> markOnboardingTipsSeen(String roleName) async {
    await _prefs?.setBool('$_keyOnboardingPrefix$roleName', true);
  }

  static Future<void> resetOnboardingTips(String roleName) async {
    await _prefs?.setBool('$_keyOnboardingPrefix$roleName', false);
  }

  // ==================== CLEAR / RESET ====================

  static Future<void> clearAll() async {
    await _prefs?.remove(_keyProjects);
    await _prefs?.remove(_keyTasks);
    await _prefs?.remove(_keyVendors);
    await _prefs?.remove(_keyInvoices);
    await _prefs?.remove(_keyExpenses);
    await _prefs?.remove(_keyReceipts);
    await _prefs?.remove(_keyLeads);
    await _prefs?.remove(_keySiteLogs);
    await _prefs?.remove(_keyMilestones);
    await _prefs?.remove(_keyDesignItems);
    await _prefs?.remove(_keyMaterialRequests);
    await _prefs?.remove(_keyAmendments);
    await _prefs?.remove(_keyLabourRoll);
    await _prefs?.remove(_keySeedVersion);
    AppConstants.preExistingProjects.clear();
  }

  /// Clears outdated placeholder data when upgrading seed version and populates
  /// fresh showcase data across all modules (Projects, Sales Leads, Tasks,
  /// Vendors, Invoices, Expenses, Material Requests, Amendments, Site Logs, Milestones).
  static Future<void> seedFillerProjectsIfEmpty() async {
    final storedVersion = _prefs?.getInt(_keySeedVersion) ?? 0;
    if (storedVersion != _currentSeedVersion) {
      await clearAll();
      await _prefs?.setInt(_keySeedVersion, _currentSeedVersion);
    }

    final existing = getProjects();
    if (existing.isNotEmpty) return;

    final fillerProjects = <Map<String, dynamic>>[
      {
        'id': 'proj_showcase_101',
        'name': 'Aurelia Sea-Facing Penthouse 42',
        'location': 'Worli Sea Face, Mumbai',
        'client': 'Vikramaditya & Rhea Birla',
        'category': 'Residential',
        'status': 'Completed',
        'isDelayed': false,
        'type': '6,800 sq ft Sky Penthouse',
        'budget': '₹ 3,40,00,000',
        'spent': '₹ 3,32,00,000',
        'pm': 'Ananya Sen',
        'supervisor': 'Suresh Kumar',
        'handover': '12 Nov 2026',
        'color': const Color(0xFFD96B43), // Terracotta Brick
        'swatchName': 'Terracotta Brick',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Laser 3D LiDAR Survey & Structural Audit', 'isDone': true},
          {'title': 'Bespoke Spatial Moodboard & BOQ Sign-off', 'isDone': true},
          {'title': 'Civil Acoustic Masonry & Waterproofing', 'isDone': true},
          {'title': 'VRV HVAC Ducting & Lutron QSX Rough-ins', 'isDone': true},
          {'title': 'Bookmatched Statuario & Chevron Oak Flooring', 'isDone': true},
          {'title': 'Smoked Eucalyptus Veneer & Wardrobe Millwork', 'isDone': true},
          {'title': 'Architectural Cove Lighting & Soft Furnishings', 'isDone': true},
          {'title': 'White-Glove Snagging & Key Handover', 'isDone': true},
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_aur_01',
            'title': 'Double-Height Sea-Facing Lounge Bookmatched Marble',
            'tag': 'Living Room',
            'timestamp': '08 Nov 2026, 05:15 PM',
            'capturedBy': 'Suresh Kumar',
          },
          {
            'id': 'photo_aur_02',
            'title': 'Master Suite Smoked Oak Walk-In Wardrobe Joinery',
            'tag': 'Master Bed',
            'timestamp': '10 Nov 2026, 02:30 PM',
            'capturedBy': 'Suresh Kumar',
          },
          {
            'id': 'photo_aur_03',
            'title': 'Lutron Architectural Scene Commissioning',
            'tag': 'Electrical',
            'timestamp': '11 Nov 2026, 06:45 PM',
            'capturedBy': 'Ananya Sen',
          },
        ],
      },
      {
        'id': 'proj_showcase_102',
        'name': 'Veridian Golf Links Residence',
        'location': 'Golf Links, Lutyens New Delhi',
        'client': 'Justice Siddharth & Nandini Luthra',
        'category': 'Residential',
        'status': 'On Track',
        'isDelayed': false,
        'type': '8,200 sq ft Heritage Bungalow',
        'budget': '₹ 2,80,00,000',
        'spent': '₹ 1,68,00,000',
        'pm': 'Ananya Sen',
        'supervisor': 'Suresh Kumar',
        'handover': '18 Dec 2026',
        'color': const Color(0xFF4E7D63), // Forest Sage
        'swatchName': 'Forest Sage',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Architectural GFC Drawings & BOQ Lock', 'isDone': true},
          {'title': 'Structural Retrofitting & Courtyard Skylight', 'isDone': true},
          {'title': 'Underfloor Hydronic Piping & MEP Conduits', 'isDone': true},
          {'title': 'Calacatta Oro Marble Dry-Lay & Polishing', 'isDone': true},
          {'title': 'Chef Island Kitchen & Burma Teak Paneling', 'isDone': false},
          {'title': 'Bespoke Brass Chandeliers & Final Styling', 'isDone': false},
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_ver_01',
            'title': 'Central Atrium Skylight Steel Trusses & Glazing',
            'tag': 'Civil',
            'timestamp': '14 Nov 2026, 11:20 AM',
            'capturedBy': 'Suresh Kumar',
          },
          {
            'id': 'photo_ver_02',
            'title': 'Calacatta Oro Slab Inspection & Dry-Lay Alignment',
            'tag': 'Flooring',
            'timestamp': '16 Nov 2026, 03:40 PM',
            'capturedBy': 'Suresh Kumar',
          },
        ],
      },
      {
        'id': 'proj_showcase_103',
        'name': 'Solstice Terrace Duplex 19B',
        'location': '100ft Road, Indiranagar, Bengaluru',
        'client': 'Devika & Pranav Narayan',
        'category': 'Residential',
        'status': 'Delayed',
        'isDelayed': true,
        'type': '4,400 sq ft Biophilic Duplex',
        'budget': '₹ 1,55,00,000',
        'spent': '₹ 82,00,000',
        'pm': 'Ananya Sen',
        'supervisor': 'Suresh Kumar',
        'handover': '05 Jan 2027',
        'color': const Color(0xFF4A6B82), // Slate Steel
        'swatchName': 'Slate Steel',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Spatial Zoning & 3D Walkthrough Sign-off', 'isDone': true},
          {'title': 'Acoustic Ceiling Framing & Electrical Routing', 'isDone': true},
          {'title': 'Double-Glazed Terrace Slider & Deck Pergola', 'isDone': false},
          {'title': 'Custom Fluted Glass Study & Bar Millwork', 'isDone': false},
          {
            'title': 'Snag Rectification & Acoustic Glazing Handover',
            'isDone': false,
          },
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_sol_01',
            'title': 'Terrace Structural Beam Drop & Slider Track Recce',
            'tag': 'Site Snag',
            'timestamp': '13 Nov 2026, 01:15 PM',
            'capturedBy': 'Suresh Kumar',
          },
        ],
      },
      {
        'id': 'proj_showcase_104',
        'name': 'Saffron Heritage Courtyard Villa',
        'location': 'Road No. 36, Jubilee Hills, Hyderabad',
        'client': 'Dr. Aravind & Shalini Reddy',
        'category': 'Residential',
        'status': 'Design and Planning',
        'isDelayed': false,
        'type': '6,100 sq ft Courtyard Villa',
        'budget': '₹ 2,15,00,000',
        'spent': '₹ 24,00,000',
        'pm': 'Ananya Sen',
        'supervisor': 'Suresh Kumar',
        'handover': '22 Feb 2027',
        'color': const Color(0xFFB38B59), // Warm Ochre
        'swatchName': 'Warm Ochre',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Site Topographical Survey & Concept Brief', 'isDone': true},
          {'title': '3D Courtyard Renders & Material Palette Sign-off', 'isDone': false},
          {'title': 'Civil Demolition & Lime Plaster Prep', 'isDone': false},
          {'title': 'MEP & Smart Home Automation Conduiting', 'isDone': false},
          {'title': 'Handcrafted Athangudi Tile & Teak Joinery', 'isDone': false},
          {'title': 'Landscape Lighting & Final Commissioning', 'isDone': false},
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_saf_01',
            'title': 'Existing Courtyard Colonade & Daylight Study',
            'tag': 'Survey',
            'timestamp': '15 Nov 2026, 10:00 AM',
            'capturedBy': 'Vikram Malhotra',
          },
        ],
      },
    ];

    await saveProjects(fillerProjects);

    if (getInvoices().isEmpty) {
      await saveInvoices([
        {
          'id': 'inv_showcase_01',
          'invoiceNumber': 'INV-2026-201',
          'title': 'Aurelia Penthouse 42 — Final Handover Tranche',
          'client': 'Vikramaditya & Rhea Birla',
          'project': 'Aurelia Sea-Facing Penthouse 42',
          'projectId': 'proj_showcase_101',
          'leadId': 'lead_showcase_005',
          'leadName': 'Vikramaditya & Rhea Birla',
          'amount': '₹ 68,00,000',
          'status': 'Settled',
          'date': '10 Nov 2026',
          'dueDate': '12 Nov 2026',
          'statusColor': AppColors.success,
          'qrCodeBase64': AppConstants.samplePaymentQrBase64,
          'upiId': AppConstants.defaultUpiId,
        },
        {
          'id': 'inv_showcase_02',
          'invoiceNumber': 'INV-2026-204',
          'title': 'Veridian Golf Links — Milestone 3 (Marble & Millwork)',
          'client': 'Justice Siddharth & Nandini Luthra',
          'project': 'Veridian Golf Links Residence',
          'projectId': 'proj_showcase_102',
          'leadId': 'lead_showcase_002',
          'leadName': 'Justice Siddharth & Nandini Luthra',
          'amount': '₹ 56,00,000',
          'status': 'Pending Payment',
          'date': '14 Nov 2026',
          'dueDate': '24 Nov 2026',
          'statusColor': AppColors.warning,
          'qrCodeBase64': AppConstants.samplePaymentQrBase64,
          'upiId': AppConstants.defaultUpiId,
        },
        {
          'id': 'inv_showcase_03',
          'invoiceNumber': 'INV-2026-207',
          'title': 'Solstice Duplex 19B — MEP & Structural Glazing Tranche',
          'client': 'Devika & Pranav Narayan',
          'project': 'Solstice Terrace Duplex 19B',
          'projectId': 'proj_showcase_103',
          'leadId': 'lead_showcase_003',
          'leadName': 'Devika & Pranav Narayan',
          'amount': '₹ 31,00,000',
          'status': 'Settled',
          'date': '05 Nov 2026',
          'dueDate': '12 Nov 2026',
          'statusColor': AppColors.success,
          'qrCodeBase64': AppConstants.samplePaymentQrBase64,
          'upiId': AppConstants.defaultUpiId,
        },
        {
          'id': 'inv_showcase_04',
          'invoiceNumber': 'INV-2026-210',
          'title': 'Saffron Courtyard Villa — 10% Mobilization & Design Retainer',
          'client': 'Dr. Aravind & Shalini Reddy',
          'project': 'Saffron Heritage Courtyard Villa',
          'projectId': 'proj_showcase_104',
          'leadId': 'lead_showcase_004',
          'leadName': 'Dr. Aravind & Shalini Reddy',
          'amount': '₹ 21,50,000',
          'status': 'Pending Payment',
          'date': '16 Nov 2026',
          'dueDate': '23 Nov 2026',
          'statusColor': AppColors.warning,
          'qrCodeBase64': AppConstants.samplePaymentQrBase64,
          'upiId': AppConstants.defaultUpiId,
        },
      ]);
    }

    if (getExpenses().isEmpty) {
      await saveExpenses([
        {
          'id': 'exp_showcase_01',
          'title': 'Calacatta Oro Slab Lot #14 & Air-Suspension Freight',
          'category': 'Material Procurement',
          'amount': '₹ 18,40,000',
          'project': 'Veridian Golf Links Residence',
          'status': 'Disbursed',
          'date': '12 Nov 2026',
          'color': AppColors.brandPeach,
        },
        {
          'id': 'exp_showcase_02',
          'title': 'Lutron QSX Processors & DALI Driver Batch',
          'category': 'Electrical & Automation',
          'amount': '₹ 12,60,000',
          'project': 'Aurelia Sea-Facing Penthouse 42',
          'status': 'Disbursed',
          'date': '08 Nov 2026',
          'color': AppColors.info,
        },
        {
          'id': 'exp_showcase_03',
          'title': 'Custom Acoustic DGU Slider Extrusions & Site Rigging',
          'category': 'Site Civil & Glazing',
          'amount': '₹ 6,75,000',
          'project': 'Solstice Terrace Duplex 19B',
          'status': 'Disbursed',
          'date': '14 Nov 2026',
          'color': AppColors.warning,
        },
      ]);
    }

    await seedFillerTasksIfEmpty();
    await seedFillerVendorsIfEmpty();
    await seedFillerMaterialRequestsIfEmpty();
    await seedFillerAmendmentsIfEmpty();
    await seedFillerLeadsIfEmpty();
    await seedFillerSiteLogsIfEmpty();
    await seedFillerMilestonesIfEmpty();
  }

  static Future<void> seedFillerTasksIfEmpty() async {
    if (getTasks().isNotEmpty) return;

    await saveTasks([
      {
        'id': 'TSK-2026-301',
        'title': 'Approve acoustic DGU shop drawings for 19th-floor terrace',
        'description':
            'Verify wind-load calculations and thermal-break mullion profiles with structural consultant.',
        'project': 'Solstice Terrace Duplex 19B',
        'assignee': 'Vikram Malhotra (Designer)',
        'department': 'Design & Architecture',
        'priority': 'Urgent',
        'status': 'In Progress',
        'deadline': 'Today, 06:00 PM',
        'dueDate': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'color': AppColors.error,
        'statusColor': AppColors.error,
      },
      {
        'id': 'TSK-2026-302',
        'title': 'Supervise Calacatta Oro bookmatch dry-lay in central atrium',
        'description':
            'Confirm vein continuity across 18 slabs before epoxy bedding.',
        'project': 'Veridian Golf Links Residence',
        'assignee': 'Suresh Kumar (Supervisor)',
        'department': 'Site Execution & Civil',
        'priority': 'High',
        'status': 'In Progress',
        'deadline': 'Tomorrow',
        'dueDate': DateFormat('dd MMM yyyy')
            .format(DateTime.now().add(const Duration(days: 1))),
        'color': AppColors.warning,
        'statusColor': AppColors.warning,
      },
      {
        'id': 'TSK-2026-303',
        'title': 'Present courtyard lighting & Burma teak ceiling renders',
        'description':
            'Walk Dr. & Mrs. Reddy through warm 2700K indirect lighting scenes.',
        'project': 'Saffron Heritage Courtyard Villa',
        'assignee': 'Vikram Malhotra (Designer)',
        'department': 'Design & Architecture',
        'priority': 'Medium',
        'status': 'Review Required',
        'deadline': 'In 2 Days',
        'dueDate': DateFormat('dd MMM yyyy')
            .format(DateTime.now().add(const Duration(days: 2))),
        'color': AppColors.info,
        'statusColor': AppColors.info,
      },
      {
        'id': 'TSK-2026-304',
        'title': 'Release 50% advance PO for Blum Legrabox kitchen hardware',
        'description':
            'Cross-check proforma invoice against approved modular kitchen BOQ.',
        'project': 'Veridian Golf Links Residence',
        'assignee': 'Pooja Iyer (Accounts)',
        'department': 'Accounts & Billing',
        'priority': 'Medium',
        'status': 'In Progress',
        'deadline': 'In 3 Days',
        'dueDate': DateFormat('dd MMM yyyy')
            .format(DateTime.now().add(const Duration(days: 3))),
        'color': AppColors.brandPeach,
        'statusColor': AppColors.brandPeach,
      },
      {
        'id': 'TSK-2026-305',
        'title': 'Sign off final snagging dossier & warranty certificates',
        'description':
            'Hand over MEP as-built drawings, Lutron scene backup, and appliance warranties.',
        'project': 'Aurelia Sea-Facing Penthouse 42',
        'assignee': 'Ananya Sen (PM)',
        'department': 'Project Management',
        'priority': 'High',
        'status': 'Completed',
        'deadline': 'Completed',
        'dueDate': '12 Nov 2026',
        'color': AppColors.success,
        'statusColor': AppColors.success,
      },
    ]);
  }

  static Future<void> seedFillerVendorsIfEmpty() async {
    if (getVendors().isNotEmpty) return;

    await saveVendors([
      {
        'id': 'VND-2026-01',
        'name': 'Carrara Stone & Surfaces',
        'category': 'Italian Marble & Tiles',
        'contact': 'Arjun Singhvi',
        'contactPerson': 'Arjun Singhvi',
        'phone': '+91 98201 44510',
        'email': 'arjun@carrarastone.in',
        'city': 'Mumbai / Kishangarh',
        'rating': '4.9',
        'openPOs': 2,
        'paymentStatus': 'Partial',
        'status': 'Active',
        'amountDue': '₹ 4,48,000',
        'outstanding': '₹ 4,48,000',
        'notes': 'Direct importer of bookmatched Statuario & Calacatta Oro.',
        'color': AppColors.warning,
      },
      {
        'id': 'VND-2026-02',
        'name': 'Hafele & Blum Architectural Hub',
        'category': 'Hardware & Fittings',
        'contact': 'Nikhil Malhotra',
        'contactPerson': 'Nikhil Malhotra',
        'phone': '+91 98114 77820',
        'email': 'orders@hafeleblumhub.in',
        'city': 'New Delhi',
        'rating': '4.8',
        'openPOs': 3,
        'paymentStatus': 'Pending',
        'status': 'Active',
        'amountDue': '₹ 2,64,000',
        'outstanding': '₹ 2,64,000',
        'notes': 'Authorized studio partner for Servo-Drive and tandem systems.',
        'color': AppColors.error,
      },
      {
        'id': 'VND-2026-03',
        'name': 'Decowood & Century Veneers',
        'category': 'Plywood & Veneer',
        'contact': 'Mahesh Bhargava',
        'contactPerson': 'Mahesh Bhargava',
        'phone': '+91 98452 33901',
        'email': 'mahesh@decowoodstudio.in',
        'city': 'Gurugram',
        'rating': '4.7',
        'openPOs': 1,
        'paymentStatus': 'Partial',
        'status': 'Active',
        'amountDue': '₹ 1,90,000',
        'outstanding': '₹ 1,90,000',
        'notes': 'Sequential crown-cut Burma teak and smoked eucalyptus flitches.',
        'color': AppColors.warning,
      },
      {
        'id': 'VND-2026-04',
        'name': 'Lumina Smart Controls',
        'category': 'Electrical & Automation',
        'contact': 'Rohan Kulkarni',
        'contactPerson': 'Rohan Kulkarni',
        'phone': '+91 99208 61234',
        'email': 'rohan@luminacontrols.in',
        'city': 'Mumbai',
        'rating': '4.9',
        'openPOs': 0,
        'paymentStatus': 'Complete',
        'status': 'Active',
        'amountDue': '₹ 0',
        'outstanding': '₹ 0',
        'notes': 'Lutron HomeWorks QSX & KNX certified integration partner.',
        'color': AppColors.success,
      },
      {
        'id': 'VND-2026-05',
        'name': 'Saint-Gobain Studio Glassworks',
        'category': 'Lighting & Fixtures',
        'contact': 'Divya Krishnan',
        'contactPerson': 'Divya Krishnan',
        'phone': '+91 98804 51920',
        'email': 'divya@sgstudioglass.in',
        'city': 'Bengaluru',
        'rating': '4.8',
        'openPOs': 1,
        'paymentStatus': 'Partial',
        'status': 'Active',
        'amountDue': '₹ 1,53,000',
        'outstanding': '₹ 1,53,000',
        'notes': 'Acoustic DGU glazing, low-iron mirrors, and PVD brass partitions.',
        'color': AppColors.warning,
      },
    ]);
  }

  static Future<void> seedFillerSiteLogsIfEmpty() async {
    if (getSiteLogs().isNotEmpty) return;

    await saveSiteLogs([
      {
        'id': 'LOG-2026-01',
        'project': 'Veridian Golf Links Residence',
        'supervisor': 'Suresh Kumar',
        'workersCount': 22,
        'note':
            'Atrium Calacatta marble dry-lay 80% complete. MEP pressure test passed at 6 bar.',
        'timestamp': 'Today, 04:15 PM',
      },
      {
        'id': 'LOG-2026-02',
        'project': 'Solstice Terrace Duplex 19B',
        'supervisor': 'Suresh Kumar',
        'workersCount': 14,
        'note':
            'Terrace slider sub-frame laser-leveled. Acoustic ceiling mineral wool batting installed.',
        'timestamp': 'Yesterday, 06:00 PM',
      },
    ]);
  }

  static Future<void> seedFillerMilestonesIfEmpty() async {
    if (getMilestones().isNotEmpty) return;

    await saveMilestones([
      {
        'id': 'MS-2026-01',
        'title': 'Calacatta Atrium Flooring & Brass Inlay Sign-off',
        'project': 'Veridian Golf Links Residence',
        'owner': 'Ananya Sen',
        'deadline': 'In 4 Days',
        'status': 'On Track',
        'color': AppColors.success,
        'statusColor': AppColors.success,
      },
      {
        'id': 'MS-2026-02',
        'title': 'Acoustic Terrace DGU Frame Delivery & Rigging',
        'project': 'Solstice Terrace Duplex 19B',
        'owner': 'Suresh Kumar',
        'deadline': 'Urgent • 2 Days',
        'status': 'Delayed',
        'color': AppColors.error,
        'statusColor': AppColors.error,
      },
    ]);
  }

  static Future<void> seedFillerLeadsIfEmpty() async {
    final existing = getLeads();
    if (existing.isNotEmpty) return;

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    final tomorrow = DateFormat('dd MMM yyyy')
        .format(DateTime.now().add(const Duration(days: 1)));
    final inThreeDays = DateFormat('dd MMM yyyy')
        .format(DateTime.now().add(const Duration(days: 3)));

    final defaultLeads = <Map<String, dynamic>>[
      {
        'id': 'lead_showcase_001',
        'client': 'Ishaan & Tara Malhotra',
        'name': 'Ishaan & Tara Malhotra',
        'phone': '+91 98111 45020',
        'scope': '6BHK Heritage Bungalow Turnkey',
        'location': 'Amrita Shergill Marg, New Delhi',
        'estValue': '₹ 4,20,00,000',
        'referralSource': 'Architect Partner',
        'referralBy': 'Ar. Kabir Singh',
        'stage': 'Lead',
        'status': 'Lead',
        'nextCallDate': today,
        'nextCallTime': '11:30 AM',
        'reminderNote':
            'Discovery call to discuss Lutyens heritage conservation norms and scope.',
        'isConverted': false,
        'convertedToProject': null,
        'createdAt': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        'notes': [
          {
            'date': DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.now().subtract(const Duration(hours: 6))),
            'text':
                'Referred by Ar. Kabir Singh. Family seeking warm modernist interiors with private art gallery lighting.',
          }
        ],
      },
      {
        'id': 'lead_showcase_002',
        'client': 'Raghavendra & Kriti Rao',
        'name': 'Raghavendra & Kriti Rao',
        'phone': '+91 98450 77812',
        'scope': '4BHK Sky Villa Interiors',
        'location': 'Sadashivanagar, Bengaluru',
        'estValue': '₹ 1,85,00,000',
        'referralSource': 'Client Referral',
        'referralBy': 'Vikramaditya Birla',
        'stage': 'Followup (Call)',
        'status': 'Followup (Call)',
        'nextCallDate': today,
        'nextCallTime': '03:00 PM',
        'reminderNote':
            'Follow up on initial spatial zoning options and confirm weekend site recce.',
        'isConverted': false,
        'convertedToProject': null,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'notes': [
          {
            'date': DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.now().subtract(const Duration(days: 2))),
            'text':
                'Introductory call completed. Shared portfolio of Aurelia Penthouse 42.',
          }
        ],
      },
      {
        'id': 'lead_showcase_003',
        'client': 'Zoya & Farhan Merchant',
        'name': 'Zoya & Farhan Merchant',
        'phone': '+91 98203 91400',
        'scope': 'Sea-View Triplex Fitout',
        'location': 'Pali Hill, Bandra West, Mumbai',
        'estValue': '₹ 2,95,00,000',
        'referralSource': 'Instagram / Social Media',
        'referralBy': '@assistinteriors.studio',
        'stage': 'Site Visit',
        'status': 'Site Visit',
        'nextCallDate': tomorrow,
        'nextCallTime': '04:30 PM',
        'reminderNote':
            'On-site LiDAR measurement and structural beam inspection with PM.',
        'isConverted': false,
        'convertedToProject': null,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
        'notes': [
          {
            'date': DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.now().subtract(const Duration(days: 4))),
            'text':
                'Shell possession received by client. Laser recce scheduled with design lead.',
          }
        ],
      },
      {
        'id': 'lead_showcase_004',
        'client': 'Harshvardhan & Mira Jindal',
        'name': 'Harshvardhan & Mira Jindal',
        'phone': '+91 98102 66319',
        'scope': '5BHK Turnkey Residence & Spa Deck',
        'location': 'Vasant Vihar, New Delhi',
        'estValue': '₹ 3,60,00,000',
        'referralSource': 'Real Estate Consultant',
        'referralBy': 'Sotheby’s Realty India',
        'stage': 'BOQ',
        'status': 'BOQ',
        'nextCallDate': inThreeDays,
        'nextCallTime': '12:00 PM',
        'reminderNote':
            'Present itemized FF&E BOQ, Italian marble slab schedule, and 4K renders.',
        'isConverted': false,
        'convertedToProject': null,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 6))
            .toIso8601String(),
        'notes': [
          {
            'date': DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.now().subtract(const Duration(days: 6))),
            'text':
                'Site visit completed. Client shortlisted Calacatta Oro and fluted walnut joinery.',
          }
        ],
      },
      {
        'id': 'lead_showcase_005',
        'client': 'Vikramaditya & Rhea Birla',
        'name': 'Vikramaditya & Rhea Birla',
        'phone': '+91 98200 11888',
        'scope': '6,800 sq ft Sky Penthouse Turnkey',
        'location': 'Worli Sea Face, Mumbai',
        'estValue': '₹ 3,40,00,000',
        'referralSource': 'Client Referral',
        'referralBy': 'Executive Studio Board',
        'stage': 'Approved',
        'status': 'Approved',
        'nextCallDate': tomorrow,
        'nextCallTime': '05:00 PM',
        'reminderNote':
            'Post-handover white-glove walkthrough and art curation sign-off.',
        'isConverted': true,
        'convertedToProject': 'Aurelia Sea-Facing Penthouse 42',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 15))
            .toIso8601String(),
        'notes': [
          {
            'date': DateFormat('dd MMM yyyy, hh:mm a')
                .format(DateTime.now().subtract(const Duration(days: 15))),
            'text':
                'BOQ signed off and converted to turnkey execution project Aurelia Sea-Facing Penthouse 42.',
          }
        ],
      },
    ];

    await saveLeads(defaultLeads);
  }

  // ==================== BACKEND RETENTION POLICIES ====================

  /// Returns the active backend photo retention period in months (6 by default, or 12).
  static int getPhotoRetentionMonths() {
    final stored = _prefs?.getInt(_keyPhotoRetentionMonths);
    if (stored != null && supportedPhotoRetentionMonths.contains(stored)) {
      return stored;
    }
    return defaultPhotoRetentionMonths;
  }

  /// Updates the backend photo retention period (6 months default or 12 months extended)
  /// and refreshes the reservation window across all stored project photos.
  static Future<void> setPhotoRetentionMonths(int months) async {
    final validMonths = supportedPhotoRetentionMonths.contains(months)
        ? months
        : defaultPhotoRetentionMonths;
    await _prefs?.setInt(_keyPhotoRetentionMonths, validMonths);

    final projects = getProjects();
    if (projects.isNotEmpty) {
      for (final proj in projects) {
        final photos = proj['photos'];
        if (photos is List) {
          for (final ph in photos) {
            if (ph is Map<String, dynamic>) {
              final uploadedIso = ph['uploadedAt']?.toString() ??
                  DateTime.now().toIso8601String();
              final uploadedDate =
                  DateTime.tryParse(uploadedIso) ?? DateTime.now();
              final reservedUntil = uploadedDate.add(
                Duration(days: validMonths * 30),
              );
              ph['retentionMonths'] = validMonths;
              ph['reservedUntil'] =
                  DateFormat('dd MMM yyyy').format(reservedUntil);
            }
          }
        }
      }
      await saveProjects(projects);
    }
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncStudioRetentionSettings(
        photoRetentionMonths: validMonths,
        cadRetentionMonths: getCadRetentionMonths(),
      );
    }
  }

  /// Returns the active CAD & 3D deliverable retention period in months (12 by default; supports 6, 12, 24).
  static int getCadRetentionMonths() {
    final stored = _prefs?.getInt(_keyCadRetentionMonths);
    if (stored != null && supportedCadRetentionMonths.contains(stored)) {
      return stored;
    }
    return defaultCadRetentionMonths;
  }

  /// Updates the backend CAD & 3D deliverable retention period (6, 12, or 24 months).
  static Future<void> setCadRetentionMonths(int months) async {
    final validMonths = supportedCadRetentionMonths.contains(months)
        ? months
        : defaultCadRetentionMonths;
    await _prefs?.setInt(_keyCadRetentionMonths, validMonths);
    if (!_isApplyingRemoteUpdate) {
      BackendManager.instance.syncStudioRetentionSettings(
        photoRetentionMonths: getPhotoRetentionMonths(),
        cadRetentionMonths: validMonths,
      );
    }
  }

  static dynamic _unwrapNestedLists(dynamic value) {
    if (value is Map) {
      if (value.length == 1 &&
          value.containsKey('_nestedList') &&
          value['_nestedList'] is List) {
        return (value['_nestedList'] as List).map(_unwrapNestedLists).toList();
      }
      final map = <String, dynamic>{};
      value.forEach((k, v) {
        map[k.toString()] = _unwrapNestedLists(v);
      });
      return map;
    }
    if (value is List) {
      return value.map(_unwrapNestedLists).toList();
    }
    return value;
  }

  /// Applies an incoming Firestore snapshot for [collection] to local storage
  /// without echoing writes back to Firestore, then notifies all listening views.
  static Future<void> applyRemoteCollection(
    String collection,
    List<Map<String, dynamic>> docs,
  ) async {
    if (docs.isEmpty) return;
    _isApplyingRemoteUpdate = true;
    try {
      final hydrated = docs.map((d) {
        final copy = Map<String, dynamic>.from(_unwrapNestedLists(d) as Map);
        if (copy['color'] is int) {
          copy['color'] = Color(copy['color'] as int);
        }
        if (copy['statusColor'] is int) {
          copy['statusColor'] = Color(copy['statusColor'] as int);
        }
        return copy;
      }).toList();

      switch (collection) {
        case 'projects':
          await saveProjects(hydrated);
          break;
        case 'tasks':
          await saveTasks(hydrated);
          break;
        case 'vendors':
          await saveVendors(hydrated);
          break;
        case 'invoices':
          await saveInvoices(hydrated);
          break;
        case 'expenses':
          await saveExpenses(hydrated);
          break;
        case 'receipts':
          await saveReceipts(hydrated);
          break;
        case 'leads':
          await saveLeads(hydrated);
          break;
        case 'design_items':
          await saveDesignItems(hydrated);
          break;
        case 'material_requests':
          await saveMaterialRequests(hydrated);
          break;
        case 'amendments':
          await saveAmendments(hydrated);
          break;
        case 'custom_roles':
          await saveCustomRoles(hydrated);
          break;
      }
      cloudSyncNotifier.value = cloudSyncNotifier.value + 1;
    } finally {
      _isApplyingRemoteUpdate = false;
    }
  }
}
