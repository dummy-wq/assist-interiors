import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String department;
  final String project;
  final String assignee;
  final String deadline;
  final String status;
  final bool completed;
  final String priority;
  final Color color;
  final String? photoUrl;
  final String? photoLabel;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.department = 'General',
    required this.project,
    this.assignee = 'Unassigned',
    this.deadline = 'Today',
    this.status = 'In Progress',
    this.completed = false,
    this.priority = 'Normal',
    this.color = AppColors.info,
    this.photoUrl,
    this.photoLabel,
    required this.createdAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? department,
    String? project,
    String? assignee,
    String? deadline,
    String? status,
    bool? completed,
    String? priority,
    Color? color,
    String? photoUrl,
    String? photoLabel,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      department: department ?? this.department,
      project: project ?? this.project,
      assignee: assignee ?? this.assignee,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      photoUrl: photoUrl ?? this.photoUrl,
      photoLabel: photoLabel ?? this.photoLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    Color resolvedColor = AppColors.info;
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

    return TaskModel(
      id:
          docId ??
          map['id']?.toString() ??
          'task_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'General Task',
      description: map['description']?.toString() ?? '',
      department: map['department']?.toString() ?? 'General',
      project: map['project']?.toString() ?? 'General Deliverable',
      assignee: map['assignee']?.toString() ?? 'Unassigned',
      deadline:
          map['deadline']?.toString() ?? map['dueDate']?.toString() ?? 'Today',
      status: map['status']?.toString() ?? 'In Progress',
      completed: map['completed'] as bool? ?? false,
      priority: map['priority']?.toString() ?? 'Normal',
      color: resolvedColor,
      photoUrl: map['photoUrl']?.toString(),
      photoLabel: map['photoLabel']?.toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'department': department,
      'project': project,
      'assignee': assignee,
      'deadline': deadline,
      'status': status,
      'completed': completed,
      'priority': priority,
      'color': color.toARGB32(),
      'photoUrl': photoUrl,
      'photoLabel': photoLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
