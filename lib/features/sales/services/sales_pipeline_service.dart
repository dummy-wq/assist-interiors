import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/project_model.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/spreadsheet_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../dashboard/widgets/mobile_action_sheets.dart';

/// Centralized service orchestrating the interior sales pipeline:
/// Lead -> Followup (Call) -> Site Visit -> BOQ -> Approved (Move to Projects & Cross-Tab Propagation)
class SalesPipelineService {
  SalesPipelineService._();

  static const List<String> pipelineSequence = [
    'Lead',
    'Followup (Call)',
    'Site Visit',
    'BOQ',
    'Approved',
  ];

  /// Resolves the 0-based index of any stage string in the 5-step pipeline.
  /// Handles both new canonical stages and backward-compatible legacy aliases.
  static int getStageIndex(String stage) {
    final lower = stage.toLowerCase().trim();
    if (lower == 'approved' ||
        lower == 'closed won' ||
        lower.contains('approved') ||
        lower.contains('won')) {
      return 4;
    }
    if (lower == 'boq' ||
        lower.contains('boq') ||
        lower.contains('pitch') ||
        lower.contains('proposal') ||
        lower.contains('negotiation')) {
      return 3;
    }
    if (lower == 'site visit' ||
        lower.contains('visit') ||
        lower.contains('recce')) {
      return 2;
    }
    if (lower.contains('followup') ||
        lower.contains('follow-up') ||
        lower.contains('call') ||
        lower == 'due reminders') {
      return 1;
    }
    return 0; // Default to 'Lead' (covers 'New Inquiry', 'Lead', etc.)
  }

  /// Determines the next stage in the pipeline progression.
  static String getNextStage(String currentStage) {
    final idx = getStageIndex(currentStage);
    if (idx < pipelineSequence.length - 1) {
      return pipelineSequence[idx + 1];
    }
    return pipelineSequence.last;
  }

  /// Returns true if the lead is in the final approved or closed won state.
  static bool isApproved(String stage) {
    return getStageIndex(stage) == 4;
  }

  /// Updates a lead's stage and appends an audit note to its notes array.
  static Future<Map<String, dynamic>> updateLeadStage({
    required Map<String, dynamic> lead,
    required String newStage,
    String? note,
  }) async {
    final leadId = (lead['id'] ?? '').toString();

    List<dynamic> existingNotes = [];
    if (lead['notes'] is List) {
      existingNotes = List.from(lead['notes'] as List);
    }
    existingNotes.insert(0, {
      'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      'text': note ?? 'Pipeline stage updated to "$newStage".',
    });

    final updatedFields = <String, dynamic>{
      'stage': newStage,
      'status': newStage,
      'notes': existingNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (leadId.isNotEmpty) {
      await StorageService.updateLead(leadId, updatedFields);
    }

    final updatedLead = {
      ...lead,
      ...updatedFields,
    };

    MobileActionSheets.leadUpdatedNotifier.value = updatedLead;
    return updatedLead;
  }

  /// Executes the core requirement:
  /// When a lead is Approved (BOQ Approved):
  /// 1. Updates lead status to 'Approved' & 'Closed Won'.
  /// 2. Moves the project into the Projects tab (with 7 milestones & 12-activity Excel timeline).
  /// 3. Propagates the subsequent project to all other tabs:
  ///    - Design Tab: auto-creates approved CAD Layout & BOQ Specification deliverable.
  ///    - Materials Tab: auto-creates Phase 1 core procurement requisition.
  ///    - Accounts Tab: auto-generates 10% mobilization advance invoice.
  ///    - Amendments Tab: registers project in preExistingProjects for variation requests.
  ///    - Hub Tab: updates active site counts and portfolio pipeline volume.
  static Future<Map<String, dynamic>> approveLeadAndMoveToProjects(
    Map<String, dynamic> lead, {
    String? approvedStage,
    String? transitionNote,
  }) async {
    final clientName = (lead['client'] ?? lead['name'] ?? 'Client') as String;
    final leadId = (lead['id'] ?? '').toString();
    final projName = (lead['convertedToProject'] as String?)?.isNotEmpty == true
        ? lead['convertedToProject'] as String
        : '$clientName Residence';

    final rawBudget = (lead['estValue'] as String? ?? '').trim();
    final budgetStr = rawBudget.isNotEmpty ? rawBudget : '₹ 25,00,000';
    final locationStr =
        (lead['location'] as String? ?? 'Site Location').trim();
    final scopeStr = (lead['scope'] as String? ?? 'Turnkey Site').trim();

    // -------------------------------------------------------------------------
    // 1. PROJECTS TAB: Create / Update Turnkey Project
    // -------------------------------------------------------------------------
    final currentProjects = StorageService.getProjects();
    int existingIdx = currentProjects.indexWhere(
      (p) =>
          (p['originLeadId'] != null && p['originLeadId'] == leadId) ||
          (p['name'] != null &&
              p['name'].toString().toLowerCase() == projName.toLowerCase()) ||
          (p['client'] != null &&
              p['client'].toString().toLowerCase() ==
                  clientName.toLowerCase()),
    );

    Map<String, dynamic> project;
    final swatch = AppColors.getProjectSwatch(projName);

    if (existingIdx != -1) {
      project = Map<String, dynamic>.from(currentProjects[existingIdx]);
      project['status'] = 'In Progress';
      project['isDelayed'] = false;
      project['originLeadId'] = leadId;
      if (project['budget'] == null ||
          project['budget'] == '₹ 0' ||
          project['budget'] == '') {
        project['budget'] = budgetStr;
      }
      currentProjects[existingIdx] = project;
    } else {
      project = <String, dynamic>{
        'id': 'proj_${DateTime.now().millisecondsSinceEpoch}',
        'name': projName,
        'location': locationStr.isNotEmpty ? locationStr : 'Site Location',
        'client': clientName,
        'category': 'Residential',
        'type': scopeStr.isNotEmpty ? scopeStr : 'Turnkey Site',
        'area': locationStr.isNotEmpty
            ? locationStr
            : 'Site Measurement Pending',
        'budget': budgetStr,
        'status': 'In Progress',
        'isDelayed': false,
        'startDate': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'endDate': DateFormat('dd MMM yyyy').format(
          DateTime.now().add(const Duration(days: 120)),
        ),
        'progress': 0.10,
        'spent': '₹ 0',
        'pm': 'Assigned PM',
        'supervisor': 'Site Supervisor',
        'handover': DateFormat('dd MMM yyyy').format(
          DateTime.now().add(const Duration(days: 120)),
        ),
        'color': swatch['color'],
        'swatchName': swatch['name'],
        'material': swatch['material'],
        'isChecklistOpen': false,
        'originLeadId': leadId,
        'stages': <Map<String, dynamic>>[
          {
            'title': 'Site Measurement & As-Built CAD',
            'isDone': true,
          },
          {
            'title': 'Concept 3D & Moodboard Sign-off',
            'isDone': true,
          },
          {
            'title': 'Civil Demolition & Wet Masonry',
            'isDone': false,
          },
          {
            'title': 'False Ceiling Framing & Laser Alignment',
            'isDone': false,
          },
          {
            'title': 'Modular Joinery & PU Finishing',
            'isDone': false,
          },
          {
            'title': 'Electrical Fixtures & Lighting Automation',
            'isDone': false,
          },
          {
            'title': 'Final Deep Clean & Client Handover',
            'isDone': false,
          },
        ],
        'photos': <Map<String, dynamic>>[],
        'designAssets': <Map<String, dynamic>>[],
        'timelineSpreadsheet': SpreadsheetService
            .generateDefaultTimelineForProject(projName)
            .toMap(),
      };
      currentProjects.insert(0, project);
    }

    await StorageService.saveProjects(currentProjects);
    if (!AppConstants.preExistingProjects.contains(projName)) {
      AppConstants.preExistingProjects.insert(0, projName);
    }
    await BackendManager.instance.createProject(ProjectModel.fromMap(project));

    // -------------------------------------------------------------------------
    // 2. DESIGN TAB: Auto-seed Concept Layout & BOQ Specification Deliverable
    // -------------------------------------------------------------------------
    final designItems = StorageService.getDesignItems();
    final deliverableTitle = '$projName - Concept Layout & Mood Board';
    if (!designItems.any(
      (d) => d['project'] == projName && d['title'] == deliverableTitle,
    )) {
      final initialDeliverable = {
        'id': 'DSG-${DateTime.now().millisecondsSinceEpoch % 100000}',
        'title': deliverableTitle,
        'project': projName,
        'type': 'CAD Plan',
        'category': 'CAD Plan',
        'version': 'v1.0',
        'status': 'Approved',
        'designer': 'Lead Architect',
        'format': 'DWG / PDF / 3D Render',
        'fileSize': '24.5 MB',
        'notes':
            'Approved architectural layout & BOQ specification handed over from sales approval.',
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'color': AppColors.info,
        'statusColor': AppColors.success,
        'createdAt': DateTime.now().toIso8601String(),
      };
      designItems.insert(0, initialDeliverable);
      await StorageService.saveDesignItems(designItems);
      MobileActionSheets.renderCreatedNotifier.value = initialDeliverable;
    }

    // -------------------------------------------------------------------------
    // 3. MATERIALS TAB: Auto-seed Phase 1 Core Procurement Requisition
    // -------------------------------------------------------------------------
    final materialRequests = StorageService.getMaterialRequests();
    final materialReqName =
        'Phase 1 Core Procurement: Cement, GI Drywall Channels & Conduiting';
    if (!materialRequests.any(
      (m) => m['project'] == projName && m['itemName'] == materialReqName,
    )) {
      final newMatReq = {
        'id': 'MR-${DateTime.now().millisecondsSinceEpoch % 100000}',
        'itemName': materialReqName,
        'category': 'Civil & Masonry',
        'project': projName,
        'quantity': 'Initial BOQ Indent',
        'urgency': 'Standard',
        'status': 'Approved',
        'requestedBy': 'Sales Handover / PM',
        'assignedSupplier': 'Studio Vendor Network',
        'estimatedCost': '₹ 1,80,000',
        'requestDate': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'requiredDate': DateFormat('dd MMM yyyy').format(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'notes':
            'Phase 1 core site materials requisition initiated upon BOQ approval.',
        'color': AppColors.info,
        'createdAt': DateTime.now().toIso8601String(),
      };
      materialRequests.insert(0, newMatReq);
      await StorageService.saveMaterialRequests(materialRequests);
    }

    // -------------------------------------------------------------------------
    // 4. ACCOUNTS TAB: Auto-seed 10% Mobilization Advance Invoice
    // -------------------------------------------------------------------------
    final invoices = StorageService.getInvoices();
    final invoiceTitle = '$projName - Mobilization Advance (10%)';
    if (!invoices.any(
      (i) => i['project'] == projName && i['title'] == invoiceTitle,
    )) {
      final rawInt = CurrencyUtils.parseAmount(budgetStr);
      final advanceAmount =
          rawInt > 0 ? (rawInt * 0.10).round() : 250000;
      final advanceFormatted = CurrencyUtils.formatInr(advanceAmount);

      final invId = 'INV-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final newInvoice = {
        'id': invId,
        'invoiceNumber': invId,
        'title': invoiceTitle,
        'project': projName,
        'projectId': project['id'],
        'client': clientName,
        'leadId': leadId,
        'leadName': clientName,
        'amount': advanceFormatted,
        'status': 'Sent',
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'dueDate': DateFormat('dd MMM yyyy').format(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'qrCodeBase64': AppConstants.samplePaymentQrBase64,
        'upiId': AppConstants.defaultUpiId,
        'notes':
            '10% mobilization advance invoice issued upon client BOQ approval.',
        'color': AppColors.info,
        'statusColor': AppColors.warning,
        'createdAt': DateTime.now().toIso8601String(),
      };
      invoices.insert(0, newInvoice);
      await StorageService.saveInvoices(invoices);
      MobileActionSheets.invoiceCreatedNotifier.value = newInvoice;

      // Link invoice to project
      project['invoices'] = [invId];
      project['originLeadId'] = leadId;
      await StorageService.saveProjects(currentProjects);
    }

    // -------------------------------------------------------------------------
    // 5. SALES TAB: Update Lead to Approved / Closed Won
    // -------------------------------------------------------------------------
    List<dynamic> existingNotes = [];
    if (lead['notes'] is List) {
      existingNotes = List.from(lead['notes'] as List);
    }
    existingNotes.insert(0, {
      'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      'text': transitionNote ??
          'BOQ approved by client! Converted to turnkey site "$projName" and provisioned across Projects, Design, Materials & Accounts.',
    });

    final stageToSet = approvedStage ?? 'Approved';

    final updatedLead = {
      ...lead,
      'stage': stageToSet,
      'status': stageToSet,
      'isConverted': true,
      'convertedToProject': projName,
      'projectId': project['id'],
      'convertedAt': DateTime.now().toIso8601String(),
      'notes': existingNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (leadId.isNotEmpty) {
      await StorageService.updateLead(leadId, updatedLead);
    }

    // -------------------------------------------------------------------------
    // 6. BROADCAST NOTIFIERS for Real-Time Cross-Tab Reactivity
    // -------------------------------------------------------------------------
    MobileActionSheets.leadUpdatedNotifier.value = updatedLead;
    MobileActionSheets.projectCreatedNotifier.value = project;
    MobileActionSheets.projectUpdatedNotifier.value = project;

    return {
      'project': project,
      'lead': updatedLead,
    };
  }
}
