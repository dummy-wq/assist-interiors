import '../../../core/constants/app_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import 'custom_role_model.dart';

enum UserAccountStatus { pendingApproval, approved, rejected }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final UserAccountStatus status;
  final DateTime createdAt;

  /// Optional Proprietor-assigned custom role fields & granular permissions.
  final String? customRoleId;
  final String? customRoleName;
  final Set<AppPermissionKey>? customPermissions;

  /// Salted SHA-256 credential digest for registered accounts.
  final String? passwordHash;
  final String? passwordSalt;

  /// Tracks whether Proprietor has acknowledged this pending sign-up notification.
  final bool seenByProprietor;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.status = UserAccountStatus.approved,
    required this.createdAt,
    this.customRoleId,
    this.customRoleName,
    this.customPermissions,
    this.passwordHash,
    this.passwordSalt,
    this.seenByProprietor = false,
  });

  bool get hasCustomAccess =>
      (customRoleName != null && customRoleName!.trim().isNotEmpty) ||
      customPermissions != null;

  String get effectiveRoleTitle =>
      (customRoleName != null && customRoleName!.trim().isNotEmpty)
          ? customRoleName!.trim()
          : role.title;

  String get effectiveRoleShortCode {
    if (customRoleName != null && customRoleName!.trim().isNotEmpty) {
      return CustomRoleDefinition.deriveShortCode(customRoleName!);
    }
    return role.shortCode;
  }

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    UserAccountStatus? status,
    DateTime? createdAt,
    String? customRoleId,
    String? customRoleName,
    Set<AppPermissionKey>? customPermissions,
    bool clearCustomRole = false,
    String? passwordHash,
    String? passwordSalt,
    bool? seenByProprietor,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customRoleId: clearCustomRole ? null : (customRoleId ?? this.customRoleId),
      customRoleName:
          clearCustomRole ? null : (customRoleName ?? this.customRoleName),
      customPermissions: clearCustomRole
          ? null
          : (customPermissions ?? this.customPermissions),
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      seenByProprietor: seenByProprietor ?? this.seenByProprietor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (customRoleId != null) 'customRoleId': customRoleId,
      if (customRoleName != null) 'customRoleName': customRoleName,
      if (customPermissions != null)
        'customPermissions': customPermissions!.map((p) => p.name).toList(),
      if (passwordHash != null) 'passwordHash': passwordHash,
      if (passwordSalt != null) 'passwordSalt': passwordSalt,
      'seenByProprietor': seenByProprietor,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    Set<AppPermissionKey>? parsedCustomPerms;
    if (map['customPermissions'] is List) {
      parsedCustomPerms = <AppPermissionKey>{};
      for (final item in (map['customPermissions'] as List)) {
        final keyStr = item.toString();
        for (final candidate in AppPermissionKey.values) {
          if (candidate.name == keyStr) {
            parsedCustomPerms.add(candidate);
            break;
          }
        }
      }
    }

    return AppUser(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.sales,
      ),
      status: UserAccountStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => UserAccountStatus.approved,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customRoleId: map['customRoleId'] as String?,
      customRoleName: map['customRoleName'] as String?,
      customPermissions: parsedCustomPerms,
      passwordHash: map['passwordHash'] as String?,
      passwordSalt: map['passwordSalt'] as String?,
      seenByProprietor: map['seenByProprietor'] as bool? ?? false,
    );
  }
}
