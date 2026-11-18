import '../../../core/permissions/app_permissions.dart';

/// Persisted custom role definition authored exclusively by the Proprietor.
/// Stores an explicit subset of [AppPermissionKey] capabilities and never grants
/// Master Owner governance (`canManageTeam`).
class CustomRoleDefinition {
  final String id;
  final String name;
  final String shortCode;
  final Set<AppPermissionKey> permissions;
  final DateTime createdAt;

  const CustomRoleDefinition({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.permissions,
    required this.createdAt,
  });

  /// Builds a concise 2-5 character uppercase code from a custom role name.
  static String deriveShortCode(String rawName) {
    final cleaned = rawName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return 'CUST';
    if (cleaned.length == 1) {
      final word = cleaned.first;
      return word.length <= 4 ? word : word.substring(0, 4);
    }
    final initials = cleaned.map((w) => w[0]).join();
    return initials.length <= 5 ? initials : initials.substring(0, 5);
  }

  /// Rejects reserved executive/admin names to avoid impersonation in UI badges.
  static bool isReservedRoleName(String rawName) {
    final lower = rawName.trim().toLowerCase();
    return lower.contains('proprietor') ||
        lower == 'master owner' ||
        lower == 'owner' ||
        lower == 'admin' ||
        lower == 'administrator' ||
        lower == 'superadmin';
  }

  CustomRoleDefinition copyWith({
    String? id,
    String? name,
    String? shortCode,
    Set<AppPermissionKey>? permissions,
    DateTime? createdAt,
  }) {
    return CustomRoleDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      permissions: permissions ?? Set<AppPermissionKey>.from(this.permissions),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
      'permissions': permissions.map((p) => p.name).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomRoleDefinition.fromMap(Map<String, dynamic> map) {
    final rawPerms = (map['permissions'] as List<dynamic>?) ?? const [];
    final parsedPerms = <AppPermissionKey>{};
    for (final entry in rawPerms) {
      final keyName = entry.toString();
      for (final candidate in AppPermissionKey.values) {
        if (candidate.name == keyName) {
          parsedPerms.add(candidate);
          break;
        }
      }
    }
    final rawName = (map['name'] as String? ?? 'Custom Role').trim();
    return CustomRoleDefinition(
      id: map['id'] as String? ?? '',
      name: rawName.isNotEmpty ? rawName : 'Custom Role',
      shortCode: (map['shortCode'] as String?)?.trim().isNotEmpty == true
          ? (map['shortCode'] as String).trim().toUpperCase()
          : deriveShortCode(rawName),
      permissions: parsedPerms,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
