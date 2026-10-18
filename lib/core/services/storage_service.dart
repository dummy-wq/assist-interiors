import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Centralized local persistent storage service for Assist Interiors.
/// Backed by SharedPreferences (NSUserDefaults on iOS, Android SharedPreferences on Android,
/// and local key-value storage on desktop / web).
class StorageService {
  static SharedPreferences? _prefs;

  static const String _keyProjects = 'assist_projects_v1';
  static const String _keyTasks = 'assist_tasks_v1';
  static const String _keyVendors = 'assist_vendors_v1';
  static const String _keyInvoices = 'assist_invoices_v1';
  static const String _keyExpenses = 'assist_expenses_v1';
  static const String _keyLeads = 'assist_leads_v1';
  static const String _keySiteLogs = 'assist_sitelogs_v1';
  static const String _keyMilestones = 'assist_milestones_v1';
  static const String _keyDesignItems = 'assist_design_items_v1';
  static const String _keyApprovedUsers = 'assist_approved_users_v1';
  static const String _keyPendingUsers = 'assist_pending_users_v1';
  static const String _keyAppLanguage = 'assist_app_language_v1';

  /// Initialize persistent storage engine on app boot or in tests.
  static Future<void> init([SharedPreferences? mockPrefs]) async {
    _prefs = mockPrefs ?? await SharedPreferences.getInstance();

    // Populate preExistingProjects from stored projects
    final storedProjects = getProjects();
    if (storedProjects.isNotEmpty) {
      AppConstants.preExistingProjects.clear();
      for (final p in storedProjects) {
        final name = p['name'] as String?;
        if (name != null && !AppConstants.preExistingProjects.contains(name)) {
          AppConstants.preExistingProjects.add(name);
        }
      }
    }
  }

  // ==================== PROJECTS ====================

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
          map['photos'] = (map['photos'] as List).map((p) {
            if (p is Map) return Map<String, dynamic>.from(p);
            return {'title': p.toString(), 'timestamp': '', 'tag': 'Site'};
          }).toList();
        } else {
          map['photos'] = <Map<String, dynamic>>[];
        }
        if (map['designAssets'] is List &&
            (map['designAssets'] as List).isNotEmpty) {
          map['designAssets'] = (map['designAssets'] as List)
              .map((d) => Map<String, dynamic>.from(d as Map))
              .toList();
        } else {
          map['designAssets'] = _defaultDesignAssetsForProject(projName);
        }
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
        return copy;
      }).toList();

      await _prefs?.setString(_keyProjects, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save projects to storage: $e');
    }
  }

  // ==================== TASKS ====================

  static List<Map<String, dynamic>> getTasks() {
    final raw = _prefs?.getString(_keyTasks);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        if (map['statusColor'] is int) {
          map['statusColor'] = Color(map['statusColor'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final serializable = tasks.map((t) {
        final copy = Map<String, dynamic>.from(t);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        if (copy['statusColor'] is Color) {
          copy['statusColor'] = (copy['statusColor'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyTasks, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save tasks to storage: $e');
    }
  }

  // ==================== VENDORS ====================

  static List<Map<String, dynamic>> getVendors() {
    final raw = _prefs?.getString(_keyVendors);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveVendors(List<Map<String, dynamic>> vendors) async {
    try {
      final serializable = vendors.map((v) {
        final copy = Map<String, dynamic>.from(v);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyVendors, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save vendors to storage: $e');
    }
  }

  // ==================== INVOICES ====================

  static List<Map<String, dynamic>> getInvoices() {
    final raw = _prefs?.getString(_keyInvoices);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['statusColor'] is int) {
          map['statusColor'] = Color(map['statusColor'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveInvoices(List<Map<String, dynamic>> invoices) async {
    try {
      final serializable = invoices.map((inv) {
        final copy = Map<String, dynamic>.from(inv);
        if (copy['statusColor'] is Color) {
          copy['statusColor'] = (copy['statusColor'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyInvoices, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save invoices to storage: $e');
    }
  }

  // ==================== EXPENSES / VOUCHERS ====================

  static List<Map<String, dynamic>> getExpenses() {
    final raw = _prefs?.getString(_keyExpenses);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      final serializable = expenses.map((e) {
        final copy = Map<String, dynamic>.from(e);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyExpenses, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save expenses to storage: $e');
    }
  }

  // ==================== LEADS (SALES) ====================

  static List<Map<String, dynamic>> getLeads() {
    final raw = _prefs?.getString(_keyLeads);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveLeads(List<Map<String, dynamic>> leads) async {
    try {
      final serializable = leads.map((l) {
        final copy = Map<String, dynamic>.from(l);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyLeads, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save leads to storage: $e');
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

  static List<Map<String, dynamic>> getSiteLogs() {
    final raw = _prefs?.getString(_keySiteLogs);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveSiteLogs(List<Map<String, dynamic>> logs) async {
    try {
      await _prefs?.setString(_keySiteLogs, jsonEncode(logs));
    } catch (e) {
      debugPrint('Failed to save site logs to storage: $e');
    }
  }

  // ==================== MILESTONES (PM) ====================

  static List<Map<String, dynamic>> getMilestones() {
    final raw = _prefs?.getString(_keyMilestones);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['color'] is int) {
          map['color'] = Color(map['color'] as int);
        }
        if (map['statusColor'] is int) {
          map['statusColor'] = Color(map['statusColor'] as int);
        }
        return map;
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveMilestones(
    List<Map<String, dynamic>> milestones,
  ) async {
    try {
      final serializable = milestones.map((m) {
        final copy = Map<String, dynamic>.from(m);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        if (copy['statusColor'] is Color) {
          copy['statusColor'] = (copy['statusColor'] as Color).toARGB32();
        }
        return copy;
      }).toList();

      await _prefs?.setString(_keyMilestones, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save milestones to storage: $e');
    }
  }

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
    try {
      final serializable = items.map((i) {
        final copy = Map<String, dynamic>.from(i);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        if (copy['statusColor'] is Color) {
          copy['statusColor'] = (copy['statusColor'] as Color).toARGB32();
        }
        return copy;
      }).toList();
      await _prefs?.setString(_keyDesignItems, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save design items to storage: $e');
    }
  }

  // ==================== USERS & STAFF ACCESS ====================

  static List<Map<String, dynamic>> getApprovedUsers() {
    final raw = _prefs?.getString(_keyApprovedUsers);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveApprovedUsers(
    List<Map<String, dynamic>> users,
  ) async {
    try {
      await _prefs?.setString(_keyApprovedUsers, jsonEncode(users));
    } catch (e) {
      debugPrint('Failed to save approved users to storage: $e');
    }
  }

  static List<Map<String, dynamic>> getPendingUsers() {
    final raw = _prefs?.getString(_keyPendingUsers);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> savePendingUsers(List<Map<String, dynamic>> users) async {
    try {
      await _prefs?.setString(_keyPendingUsers, jsonEncode(users));
    } catch (e) {
      debugPrint('Failed to save pending users to storage: $e');
    }
  }

  static Future<void> clearUsers() async {
    await _prefs?.remove(_keyApprovedUsers);
    await _prefs?.remove(_keyPendingUsers);
  }

  // ==================== LANGUAGE PREFERENCE ====================

  static String getLanguage() {
    return _prefs?.getString(_keyAppLanguage) ?? 'en';
  }

  static Future<void> saveLanguage(String code) async {
    await _prefs?.setString(_keyAppLanguage, code);
  }

  // ==================== CLEAR / RESET ====================

  static Future<void> clearAll() async {
    await _prefs?.remove(_keyProjects);
    await _prefs?.remove(_keyTasks);
    await _prefs?.remove(_keyVendors);
    await _prefs?.remove(_keyInvoices);
    await _prefs?.remove(_keyExpenses);
    await _prefs?.remove(_keyLeads);
    await _prefs?.remove(_keySiteLogs);
    await _prefs?.remove(_keyMilestones);
    await _prefs?.remove(_keyDesignItems);
    AppConstants.preExistingProjects.clear();
  }

  /// Seeds 3 realistic architectural filler projects: 1 complete, 1 ongoing, and 1 delayed.
  static Future<void> seedFillerProjectsIfEmpty() async {
    final existing = getProjects();
    if (existing.isNotEmpty) return;

    final fillerProjects = <Map<String, dynamic>>[
      {
        'id': 'proj_filler_001',
        'name': 'DLF Magnolias 4BHK Sky Villa',
        'location': 'Golf Course Road, DLF Phase 5, Gurugram',
        'client': 'Mr. Kabir Singhania',
        'category': 'Residential',
        'status': 'Completed',
        'isDelayed': false,
        'type': '5,400 sq ft Luxury Turnkey',
        'budget': '₹ 1,85,00,000',
        'spent': '₹ 1,82,40,000',
        'pm': 'Rahul Mehta',
        'supervisor': 'Vikram Rao',
        'handover': '10 Oct 2026',
        'color': const Color(0xFFD96B43), // Terracotta Brick
        'swatchName': 'Terracotta Brick',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Initial Site Recce & CAD Surveys', 'isDone': true},
          {'title': '3D Moodboard & Client Sign-off', 'isDone': true},
          {'title': 'Civil Demolition & Wet Masonry', 'isDone': true},
          {'title': 'MEP Rough-ins & False Ceiling Framing', 'isDone': true},
          {'title': 'Italian Marble & Hardwood Flooring', 'isDone': true},
          {'title': 'Custom Millwork, Wardrobes & Veneering', 'isDone': true},
          {'title': 'PU Painting & Architectural Lighting', 'isDone': true},
          {'title': 'Final Snagging & Formal Handover', 'isDone': true},
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_dlf_01',
            'title': 'Living Room Framing & False Ceiling',
            'tag': 'Living Room',
            'timestamp': '08 Oct 2026, 04:30 PM',
            'capturedBy': 'Vikram Rao',
          },
          {
            'id': 'photo_dlf_02',
            'title': 'Italian Marble Flooring Laying & Leveling',
            'tag': 'Flooring',
            'timestamp': '09 Oct 2026, 11:15 AM',
            'capturedBy': 'Vikram Rao',
          },
          {
            'id': 'photo_dlf_03',
            'title': 'Master Bedroom Teak Veneer Wardrobes',
            'tag': 'Master Bed',
            'timestamp': '10 Oct 2026, 06:00 PM',
            'capturedBy': 'Vikram Rao',
          },
        ],
      },
      {
        'id': 'proj_filler_002',
        'name': 'The Camellias Penthouse 18',
        'location': 'Sector 42, Golf Course Road, Gurugram',
        'client': 'Mrs. Ananya Goenka',
        'category': 'Residential',
        'status': 'On Track',
        'isDelayed': false,
        'type': '7,200 sq ft Duplex Penthouse',
        'budget': '₹ 2,60,00,000',
        'spent': '₹ 1,45,00,000',
        'pm': 'Rahul Mehta',
        'supervisor': 'Vikram Rao',
        'handover': '28 Nov 2026',
        'color': const Color(0xFF4E7D63), // Forest Sage
        'swatchName': 'Forest Sage',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {
            'title': 'Architectural 3D Presentation & BOQ Approval',
            'isDone': true,
          },
          {
            'title': 'Civil Alterations & Wet Area Waterproofing',
            'isDone': true,
          },
          {'title': 'HVAC Ducting & Home Automation Rough-in', 'isDone': true},
          {
            'title': 'Premium Veneer Paneling & Kitchen Carcass',
            'isDone': true,
          },
          {
            'title': 'Fluted Glass Partitions & Lighting Installation',
            'isDone': false,
          },
          {
            'title': 'Final Polishing, Soft Furnishings & Handover',
            'isDone': false,
          },
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_cam_01',
            'title': 'HVAC Ducting & Home Automation Rough-in',
            'tag': 'MEP',
            'timestamp': '12 Oct 2026, 02:45 PM',
            'capturedBy': 'Vikram Rao',
          },
          {
            'id': 'photo_cam_02',
            'title': 'Kitchen Quartz Countertop & Carcass Fitting',
            'tag': 'Kitchen',
            'timestamp': '13 Oct 2026, 05:20 PM',
            'capturedBy': 'Vikram Rao',
          },
        ],
      },
      {
        'id': 'proj_filler_003',
        'name': 'Oberoi Sky City Suite',
        'location': 'Western Express Highway, Borivali East, Mumbai',
        'client': 'Dr. Sameer Kulkarni',
        'category': 'Residential',
        'status': 'Delayed',
        'isDelayed': true,
        'type': '3,800 sq ft Contemporary Suite',
        'budget': '₹ 1,20,00,000',
        'spent': '₹ 78,50,000',
        'pm': 'Rahul Mehta',
        'supervisor': 'Vikram Rao',
        'handover': '15 Dec 2026',
        'color': const Color(0xFF4A6B82), // Slate Steel
        'swatchName': 'Slate Steel',
        'isChecklistOpen': false,
        'stages': <Map<String, dynamic>>[
          {'title': 'Site Dimensions & Concept Approval', 'isDone': true},
          {
            'title': 'Electrical Conduit Routing & POP Ceilings',
            'isDone': true,
          },
          {
            'title': 'Imported Quartz Countertops & Modular Joinery',
            'isDone': false,
          },
          {'title': 'Custom Acoustic Wall Paneling', 'isDone': false},
          {
            'title': 'Snag Rectification & Deep Clean Handover',
            'isDone': false,
          },
        ],
        'photos': <Map<String, dynamic>>[
          {
            'id': 'photo_obs_01',
            'title': 'Electrical Conduit Routing & POP Ceilings',
            'tag': 'Electrical',
            'timestamp': '11 Oct 2026, 01:10 PM',
            'capturedBy': 'Vikram Rao',
          },
        ],
      },
    ];

    await saveProjects(fillerProjects);

    if (getInvoices().isEmpty) {
      await saveInvoices([
        {
          'id': 'inv_001',
          'invoiceNumber': 'INV-2026-081',
          'client': 'Mr. Kabir Singhania',
          'project': 'DLF Magnolias 4BHK Sky Villa',
          'amount': '₹ 45,00,000',
          'status': 'Settled',
          'date': '10 Oct 2026',
          'dueDate': '10 Oct 2026',
          'statusColor': AppColors.success,
        },
        {
          'id': 'inv_002',
          'invoiceNumber': 'INV-2026-094',
          'client': 'Mrs. Ananya Goenka',
          'project': 'The Camellias Penthouse 18',
          'amount': '₹ 65,00,000',
          'status': 'Pending',
          'date': '02 Oct 2026',
          'dueDate': '20 Oct 2026',
          'statusColor': AppColors.warning,
        },
      ]);
    }

    if (getExpenses().isEmpty) {
      await saveExpenses([
        {
          'id': 'exp_001',
          'title': 'Italian Marble & Imported Quartz',
          'category': 'Material Procurement',
          'amount': '₹ 18,50,00,000',
          'project': 'The Camellias Penthouse 18',
          'status': 'Disbursed',
          'date': '05 Oct 2026',
          'color': AppColors.brandPeach,
        },
      ]);
    }
  }

  static List<Map<String, dynamic>> _defaultDesignAssetsForProject(
    String projectName,
  ) {
    if (projectName.contains('Magnolias')) {
      return [
        {
          'id': 'asset_dlf_01',
          'title': '2D Floor Plan & Structural Survey CAD',
          'type': 'CAD Drawing',
          'project': projectName,
          'format': '.DWG',
          'version': 'v2.1',
          'fileSize': '16.4 MB',
          'status': 'Approved',
          'date': '08 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Complete dimensional recce with structural column grid and partition boundaries.',
        },
        {
          'id': 'asset_dlf_02',
          'title': 'Living & Double-Height Dining 3D Max Renders',
          'type': '3D Render',
          'project': projectName,
          'format': '.MAX / .JPG',
          'version': 'v3.0',
          'fileSize': '78.2 MB',
          'status': 'Approved',
          'date': '09 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              '4K Photorealistic renders with V-Ray lighting and bespoke chandelier placement.',
        },
        {
          'id': 'asset_dlf_03',
          'title': 'Italian Veneer, Marble & Brass Mood Board',
          'type': 'Mood Board',
          'project': projectName,
          'format': '.PDF / .PNG',
          'version': 'v1.4',
          'fileSize': '22.5 MB',
          'status': 'Approved',
          'date': '07 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Tactile client presentation board featuring Statuario marble & fluted teak veneers.',
        },
        {
          'id': 'asset_dlf_04',
          'title': 'Complete FF&E Architectural BOQ & Schedule',
          'type': 'Material BOQ',
          'project': projectName,
          'format': '.XLSX / .PDF',
          'version': 'v2.0',
          'fileSize': '4.1 MB',
          'status': 'Approved',
          'date': '10 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Detailed line-item quantities for loose furniture, sanitaryware, and automation.',
        },
      ];
    } else if (projectName.contains('Camellias')) {
      return [
        {
          'id': 'asset_cam_01',
          'title': 'Reflected Ceiling Plan (RCP) & Lighting CAD',
          'type': 'CAD Drawing',
          'project': projectName,
          'format': '.DWG',
          'version': 'v3.4',
          'fileSize': '24.8 MB',
          'status': 'Under Client Review',
          'date': '12 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Architectural lighting circuit design with DALI dimming and recessed cove details.',
        },
        {
          'id': 'asset_cam_02',
          'title': 'Master Suite & Private Lounge 4K 3D Renders',
          'type': '3D Render',
          'project': projectName,
          'format': '.MAX / .JPG',
          'version': 'v2.2',
          'fileSize': '92.0 MB',
          'status': 'Under Client Review',
          'date': '11 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Bespoke walk-in wardrobe joinery with integrated LED backlighting and leather finishes.',
        },
        {
          'id': 'asset_cam_03',
          'title': 'HVAC Ducting & Home Automation Conduits',
          'type': 'MEP Layout',
          'project': projectName,
          'format': '.DWG',
          'version': 'v1.8',
          'fileSize': '18.3 MB',
          'status': 'Approved',
          'date': '06 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'VRV duct routing and low-voltage automation conduit distribution drawings.',
        },
        {
          'id': 'asset_cam_04',
          'title': 'Custom Joinery & Imported Veneer BOQ',
          'type': 'Material BOQ',
          'project': projectName,
          'format': '.PDF / .XLSX',
          'version': 'v1.5',
          'fileSize': '6.7 MB',
          'status': 'Approved',
          'date': '09 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Specialty millwork specifications and vendor rate contract schedule.',
        },
      ];
    } else if (projectName.contains('Oberoi')) {
      return [
        {
          'id': 'asset_obs_01',
          'title': 'Acoustical Wall Paneling & Modular Layout CAD',
          'type': 'CAD Drawing',
          'project': projectName,
          'format': '.DWG',
          'version': 'v1.2',
          'fileSize': '19.5 MB',
          'status': 'Revision Requested',
          'date': '13 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Acoustic baffle wall framing revisions requested by client for master bedroom soundproofing.',
        },
        {
          'id': 'asset_obs_02',
          'title': 'Contemporary Suite 3D Photorealistic Render',
          'type': '3D Render',
          'project': projectName,
          'format': '.MAX / .PNG',
          'version': 'v1.0',
          'fileSize': '64.0 MB',
          'status': 'Revision Requested',
          'date': '12 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Perspective views updated with charcoal oak finishes and brass inlay accents.',
        },
        {
          'id': 'asset_obs_03',
          'title': 'Contemporary Textures & Finishes Mood Board',
          'type': 'Mood Board',
          'project': projectName,
          'format': '.PDF',
          'version': 'v1.1',
          'fileSize': '15.0 MB',
          'status': 'Under Client Review',
          'date': '10 Oct 2026',
          'designer': 'Priya Sharma',
          'notes':
              'Curated palette of fabric acoustic panels, microtopping flooring, and matte black fixtures.',
        },
      ];
    } else {
      return [
        {
          'id': 'asset_gen_01',
          'title': '2D Architectural Layout & Civil CAD',
          'type': 'CAD Drawing',
          'project': projectName,
          'format': '.DWG',
          'version': 'v1.0',
          'fileSize': '14.5 MB',
          'status': 'Under Client Review',
          'date': '12 Oct 2026',
          'designer': 'Priya Sharma',
          'notes': 'Initial architectural survey and partition alignment drawing.',
        },
        {
          'id': 'asset_gen_02',
          'title': 'Photorealistic 3D Concept Renders',
          'type': '3D Render',
          'project': projectName,
          'format': '.MAX / .JPG',
          'version': 'v1.0',
          'fileSize': '45.0 MB',
          'status': 'Under Client Review',
          'date': '13 Oct 2026',
          'designer': 'Priya Sharma',
          'notes': 'Concept spatial visualization with realistic lighting simulation.',
        },
      ];
    }
  }
}
