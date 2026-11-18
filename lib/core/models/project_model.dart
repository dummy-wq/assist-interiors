import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProjectStageModel {
  final String id;
  final String title;
  final bool isDone;

  const ProjectStageModel({
    required this.id,
    required this.title,
    required this.isDone,
  });

  ProjectStageModel copyWith({String? id, String? title, bool? isDone}) {
    return ProjectStageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  factory ProjectStageModel.fromMap(Map<String, dynamic> map) {
    return ProjectStageModel(
      id:
          map['id']?.toString() ??
          'stage_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? '',
      isDone: map['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String? client;
  final String location;
  final String category;
  final String status;
  final bool isDelayed;
  final String type;
  final String budget;
  final String spent;
  final String pm;
  final String supervisor;
  final String handover;
  final Color color;
  final bool isChecklistOpen;
  final String? originLeadId;
  final List<ProjectStageModel> stages;
  final List<Map<String, dynamic>> photos;
  final Map<String, dynamic>? timelineSpreadsheet;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    this.client,
    required this.location,
    this.category = 'Residential',
    this.status = 'Design and Planning',
    this.isDelayed = false,
    this.type = 'Turnkey Site',
    this.budget = '₹ 0',
    this.spent = '₹ 0',
    this.pm = 'Unassigned',
    this.supervisor = 'Unassigned',
    this.handover = 'TBD',
    this.color = AppColors.brandPeach,
    this.isChecklistOpen = false,
    this.originLeadId,
    this.stages = const [],
    this.photos = const [],
    this.timelineSpreadsheet,
    required this.createdAt,
  });

  double get progress => stages.isEmpty
      ? 0.0
      : stages.where((s) => s.isDone).length / stages.length;

  ProjectModel copyWith({
    String? id,
    String? name,
    String? client,
    String? location,
    String? category,
    String? status,
    bool? isDelayed,
    String? type,
    String? budget,
    String? spent,
    String? pm,
    String? supervisor,
    String? handover,
    Color? color,
    bool? isChecklistOpen,
    String? originLeadId,
    List<ProjectStageModel>? stages,
    List<Map<String, dynamic>>? photos,
    Map<String, dynamic>? timelineSpreadsheet,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      location: location ?? this.location,
      category: category ?? this.category,
      status: status ?? this.status,
      isDelayed: isDelayed ?? this.isDelayed,
      type: type ?? this.type,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      pm: pm ?? this.pm,
      supervisor: supervisor ?? this.supervisor,
      handover: handover ?? this.handover,
      color: color ?? this.color,
      isChecklistOpen: isChecklistOpen ?? this.isChecklistOpen,
      originLeadId: originLeadId ?? this.originLeadId,
      stages: stages ?? this.stages,
      photos: photos ?? this.photos,
      timelineSpreadsheet: timelineSpreadsheet ?? this.timelineSpreadsheet,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final stagesRaw = map['stages'] as List<dynamic>? ?? [];
    final stagesList = stagesRaw
        .map(
          (s) => ProjectStageModel.fromMap(Map<String, dynamic>.from(s as Map)),
        )
        .toList();

    final photosRaw = map['photos'] as List<dynamic>? ?? [];
    final photosList = photosRaw.map((p) {
      if (p is Map) return Map<String, dynamic>.from(p);
      return {'title': p.toString(), 'timestamp': ''};
    }).toList();

    Color resolvedColor = AppColors.brandPeach;
    if (map['color'] is int) {
      resolvedColor = Color(map['color'] as int);
    } else if (map['color'] is Color) {
      resolvedColor = map['color'] as Color;
    }

    DateTime created = DateTime.now();
    if (map['createdAt'] is String) {
      created = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else if (map['createdAt'] is int) {
      created = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);
    }

    return ProjectModel(
      id:
          docId ??
          map['id']?.toString() ??
          'proj_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'New Project',
      client: map['client']?.toString(),
      location: map['location']?.toString() ?? 'Site Location',
      category: map['category']?.toString() ?? 'Residential',
      status: map['status']?.toString() ?? 'Design and Planning',
      isDelayed: map['isDelayed'] as bool? ?? false,
      type: map['type']?.toString() ?? 'Turnkey Site',
      budget: map['budget']?.toString() ?? '₹ 0',
      spent: map['spent']?.toString() ?? '₹ 0',
      pm: map['pm']?.toString() ?? 'Unassigned',
      supervisor: map['supervisor']?.toString() ?? 'Unassigned',
      handover: map['handover']?.toString() ?? 'TBD',
      color: resolvedColor,
      isChecklistOpen: map['isChecklistOpen'] as bool? ?? false,
      originLeadId: map['originLeadId']?.toString(),
      stages: stagesList,
      photos: photosList,
      timelineSpreadsheet: map['timelineSpreadsheet'] is Map
          ? Map<String, dynamic>.from(map['timelineSpreadsheet'] as Map)
          : null,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (client != null) 'client': client,
      'location': location,
      'category': category,
      'status': status,
      'isDelayed': isDelayed,
      'type': type,
      'budget': budget,
      'spent': spent,
      'pm': pm,
      'supervisor': supervisor,
      'handover': handover,
      'color': color.toARGB32(),
      'isChecklistOpen': isChecklistOpen,
      if (originLeadId != null) 'originLeadId': originLeadId,
      'stages': stages.map((s) => s.toMap()).toList(),
      'photos': photos,
      if (timelineSpreadsheet != null)
        'timelineSpreadsheet': timelineSpreadsheet,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
