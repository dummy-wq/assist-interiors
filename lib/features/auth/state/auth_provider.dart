import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/services/backend_manager.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/security_hash.dart';
import '../models/custom_role_model.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  ThemeMode _themeMode = ThemeMode.dark;
  AppFontTheme _fontTheme = AppFontTheme.plusJakartaSans;
  int _photoRetentionMonths = StorageService.defaultPhotoRetentionMonths;
  int _cadRetentionMonths = StorageService.defaultCadRetentionMonths;
  double _textScaleFactor = 1.0;
  bool _isProductionMode = false;
  String? _lastAuthError;

  /// Emits whenever a new staff sign-up request arrives so active Proprietor
  /// sessions display an immediate alert.
  final ValueNotifier<AppUser?> newSignupNotificationNotifier =
      ValueNotifier<AppUser?>(null);

  // Pre-configured default staff directory
  static final List<AppUser> _defaultApprovedUsers = [
    AppUser(
      id: 'USR-001',
      fullName: 'Rajesh Sharma',
      email: 'rajesh@assistinteriors.in',
      phone: '+91 98100 12345',
      role: UserRole.proprietor,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 1, 1),
      seenByProprietor: true,
    ),
    AppUser(
      id: 'USR-002',
      fullName: 'Kavita Reddy',
      email: 'kavita.sales@assistinteriors.in',
      phone: '+91 98711 23456',
      role: UserRole.sales,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 3, 15),
      seenByProprietor: true,
    ),
    AppUser(
      id: 'USR-003',
      fullName: 'Ananya Sen',
      email: 'ananya.pm@assistinteriors.in',
      phone: '+91 99102 34567',
      role: UserRole.projectManager,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 2, 10),
      seenByProprietor: true,
    ),
    AppUser(
      id: 'USR-004',
      fullName: 'Vikram Malhotra',
      email: 'vikram.design@assistinteriors.in',
      phone: '+91 98203 45678',
      role: UserRole.designer,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 4, 1),
      seenByProprietor: true,
    ),
    AppUser(
      id: 'USR-005',
      fullName: 'Pooja Iyer',
      email: 'pooja.accounts@assistinteriors.in',
      phone: '+91 98304 56789',
      role: UserRole.accounts,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 1, 20),
      seenByProprietor: true,
    ),
    AppUser(
      id: 'USR-006',
      fullName: 'Suresh Kumar',
      email: 'suresh.site@assistinteriors.in',
      phone: '+91 98405 67890',
      role: UserRole.supervisor,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 5, 12),
      seenByProprietor: true,
    ),
  ];

  // Default pending sign-ups requiring Proprietor approval
  static final List<AppUser> _defaultPendingUsers = [
    AppUser(
      id: 'PEND-101',
      fullName: 'Rohan Gupta',
      email: 'rohan.g@gmail.com',
      phone: '+91 97110 88231',
      role: UserRole.supervisor,
      status: UserAccountStatus.pendingApproval,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      seenByProprietor: false,
    ),
    AppUser(
      id: 'PEND-102',
      fullName: 'Tanvi Mehra',
      email: 'tanvi.m@gmail.com',
      phone: '+91 98112 99423',
      role: UserRole.designer,
      status: UserAccountStatus.pendingApproval,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      seenByProprietor: false,
    ),
  ];

  final List<AppUser> _approvedUsers = [];
  final List<AppUser> _pendingUsers = [];
  final List<CustomRoleDefinition> _customRoles = [];

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole get currentRole => _currentUser?.role ?? UserRole.proprietor;
  String get userName => _currentUser?.fullName ?? 'Guest';
  String? get lastAuthError => _lastAuthError;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get textScaleFactor => _textScaleFactor;
  bool get shouldShowOnboardingTips => _isProductionMode;
  int get photoRetentionMonths => _photoRetentionMonths;
  int get cadRetentionMonths => _cadRetentionMonths;
  List<AppUser> get pendingUsers => List.unmodifiable(_pendingUsers);
  List<AppUser> get approvedUsers => List.unmodifiable(_approvedUsers);
  List<CustomRoleDefinition> get customRoles => List.unmodifiable(_customRoles);

  /// True strictly when the active authenticated session belongs to the Master Proprietor.
  bool get canManageTeam =>
      AppPermissions.canManageTeam(currentRole, user: _currentUser);

  /// Permission check respecting custom per-user / custom-role permissions.
  bool can(AppPermissionKey key) =>
      AppPermissions.hasPermission(currentRole, key, user: _currentUser);

  int get unseenPendingCount =>
      _pendingUsers.where((u) => !u.seenByProprietor).length;

  // Initialize with persisted or default users. When [autoDemoLogin] is false
  // (production app entrypoint), fresh installs with no saved session start on
  // the LoginScreen instead of auto-opening as Proprietor.
  AuthProvider({bool autoDemoLogin = true}) {
    _isProductionMode = !autoDemoLogin;
    _textScaleFactor = StorageService.getTextScaleFactor();
    _photoRetentionMonths = StorageService.getPhotoRetentionMonths();
    _cadRetentionMonths = StorageService.getCadRetentionMonths();
    _loadPersistedUsers(seedDemoTeam: autoDemoLogin);
    _loadPersistedCustomRoles();
    final savedUserId = StorageService.getCurrentUserId();
    if (savedUserId != null && savedUserId.isNotEmpty) {
      final matches = _approvedUsers.where((u) => u.id == savedUserId).toList();
      _currentUser = matches.isNotEmpty
          ? matches.first
          : (autoDemoLogin && _approvedUsers.isNotEmpty
                ? _approvedUsers.first
                : null);
    } else if (autoDemoLogin) {
      _currentUser = _approvedUsers.isNotEmpty ? _approvedUsers.first : null;
    } else {
      _currentUser = null;
    }
    _startCloudRealtimeSyncIfReady();
  }

  void _startCloudRealtimeSyncIfReady() {
    if (!BackendManager.instance.isCloudConnected) return;
    BackendManager.instance.startRealtimeSync(
      onUsersSnapshot: applyRemoteUsers,
      onCustomRolesSnapshot: applyRemoteCustomRoles,
      onRetentionSnapshot: applyRemoteRetentionSettings,
    );
  }

  static bool _isSameUserRecord(AppUser a, AppUser b) {
    if (a.id == b.id) return true;
    if (a.email.isNotEmpty &&
        b.email.isNotEmpty &&
        a.email.toLowerCase() == b.email.toLowerCase()) {
      return true;
    }
    final phoneA = normalizePhone(a.phone);
    final phoneB = normalizePhone(b.phone);
    return phoneA.length >= 7 && phoneA == phoneB;
  }

  void applyRemoteUsers(List<Map<String, dynamic>> remoteDocs) {
    if (remoteDocs.isEmpty) return;
    bool changed = false;
    AppUser? newlyArrivedPending;

    for (final raw in remoteDocs) {
      final remoteUser = AppUser.fromMap(raw);
      if (remoteUser.email.isEmpty && remoteUser.phone.isEmpty) continue;
      if (remoteUser.email.toLowerCase() == 'sync.usr001@assistinteriors.in') {
        continue;
      }

      if (remoteUser.status == UserAccountStatus.approved) {
        _pendingUsers.removeWhere((u) => _isSameUserRecord(u, remoteUser));
        final idx = _approvedUsers.indexWhere(
          (u) => _isSameUserRecord(u, remoteUser),
        );
        if (idx == -1) {
          _approvedUsers.add(remoteUser);
          changed = true;
        } else {
          final existing = _approvedUsers[idx];
          _approvedUsers[idx] = remoteUser.copyWith(
            id: existing.id,
            passwordHash: remoteUser.passwordHash ?? existing.passwordHash,
            passwordSalt: remoteUser.passwordSalt ?? existing.passwordSalt,
          );
          if (_currentUser?.id == existing.id) {
            _currentUser = _approvedUsers[idx];
          }
          changed = true;
        }
      } else if (remoteUser.status == UserAccountStatus.pendingApproval) {
        final alreadyPending = _pendingUsers.any(
          (u) => _isSameUserRecord(u, remoteUser),
        );
        final alreadyApproved = _approvedUsers.any(
          (u) => _isSameUserRecord(u, remoteUser),
        );
        if (!alreadyPending && !alreadyApproved) {
          _pendingUsers.insert(0, remoteUser);
          newlyArrivedPending = remoteUser;
          changed = true;
        }
      }
    }

    if (changed) {
      StorageService.saveApprovedUsers(
        _approvedUsers.map((u) => u.toMap()).toList(),
      );
      StorageService.savePendingUsers(
        _pendingUsers.map((u) => u.toMap()).toList(),
      );
      if (newlyArrivedPending != null) {
        newSignupNotificationNotifier.value = newlyArrivedPending;
      }
      notifyListeners();
    }
  }

  void applyRemoteCustomRoles(List<Map<String, dynamic>> remoteDocs) {
    if (remoteDocs.isEmpty) return;
    _customRoles
      ..clear()
      ..addAll(remoteDocs.map(CustomRoleDefinition.fromMap));
    notifyListeners();
  }

  void applyRemoteRetentionSettings(int photoMonths, int cadMonths) {
    bool changed = false;
    if (StorageService.supportedPhotoRetentionMonths.contains(photoMonths) &&
        _photoRetentionMonths != photoMonths) {
      _photoRetentionMonths = photoMonths;
      changed = true;
    }
    if (StorageService.supportedCadRetentionMonths.contains(cadMonths) &&
        _cadRetentionMonths != cadMonths) {
      _cadRetentionMonths = cadMonths;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    newSignupNotificationNotifier.dispose();
    super.dispose();
  }

  void _loadPersistedUsers({bool seedDemoTeam = true}) {
    final storedApproved = StorageService.getApprovedUsers();
    if (storedApproved.isNotEmpty) {
      _approvedUsers.clear();
      _approvedUsers.addAll(storedApproved.map(AppUser.fromMap));
    } else {
      _approvedUsers.clear();
      if (seedDemoTeam) {
        _approvedUsers.addAll(_defaultApprovedUsers);
      } else {
        // Production studio starts clean with only the Master Proprietor account
        _approvedUsers.add(_defaultApprovedUsers.first);
      }
      StorageService.saveApprovedUsers(
        _approvedUsers.map((u) => u.toMap()).toList(),
      );
    }

    final storedPending = StorageService.getPendingUsers();
    if (storedPending.isNotEmpty) {
      _pendingUsers.clear();
      _pendingUsers.addAll(storedPending.map(AppUser.fromMap));
    } else {
      _pendingUsers.clear();
      if (seedDemoTeam) {
        _pendingUsers.addAll(_defaultPendingUsers);
        StorageService.savePendingUsers(
          _pendingUsers.map((u) => u.toMap()).toList(),
        );
      }
    }
  }

  void _loadPersistedCustomRoles() {
    final storedRoles = StorageService.getCustomRoles();
    _customRoles.clear();
    _customRoles.addAll(storedRoles.map(CustomRoleDefinition.fromMap));
  }

  void _saveUsersToStorage() {
    final approvedMaps = _approvedUsers.map((u) => u.toMap()).toList();
    final pendingMaps = _pendingUsers.map((u) => u.toMap()).toList();
    StorageService.saveApprovedUsers(approvedMaps);
    StorageService.savePendingUsers(pendingMaps);
    _syncUsersToCloud(approvedMaps, pendingMaps);
  }

  void _syncUsersToCloud(
    List<Map<String, dynamic>> approvedMaps,
    List<Map<String, dynamic>> pendingMaps,
  ) {
    if (!BackendManager.instance.isAuthenticatedCloud) return;
    for (final u in approvedMaps) {
      final id = u['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        BackendManager.instance.upsertCollectionRecord('users', id, u);
      }
    }
    for (final u in pendingMaps) {
      final id = u['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        BackendManager.instance.upsertCollectionRecord('users', id, u);
      }
    }
  }

  void _saveCustomRolesToStorage() {
    StorageService.saveCustomRoles(
      _customRoles.map((r) => r.toMap()).toList(),
    );
  }

  static String normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  static String phoneToAuthEmail(String phone) {
    final norm = normalizePhone(phone);
    return '$norm@phone.assistinteriors.in';
  }

  bool isEmailInUse(String email) {
    final normalized = email.trim().toLowerCase();
    return _approvedUsers.any((u) => u.email.toLowerCase() == normalized) ||
        _pendingUsers.any((u) => u.email.toLowerCase() == normalized);
  }

  bool isPhoneInUse(String phone) {
    final norm = normalizePhone(phone);
    if (norm.isEmpty) return false;
    return _approvedUsers.any((u) => normalizePhone(u.phone) == norm) ||
        _pendingUsers.any((u) => normalizePhone(u.phone) == norm);
  }

  bool _matchesIdentifier(AppUser u, String identifier) {
    final trimmed = identifier.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    if (u.email.toLowerCase() == trimmed) return true;
    final normPhone = normalizePhone(identifier);
    return normPhone.length >= 7 && normalizePhone(u.phone) == normPhone;
  }

  bool login(
    String identifier,
    String password, {
    bool syncFirebase = true,
  }) {
    _lastAuthError = null;

    final approvedMatch =
        _approvedUsers.where((u) => _matchesIdentifier(u, identifier)).toList();

    if (approvedMatch.isNotEmpty) {
      final user = approvedMatch.first;
      if (user.status != UserAccountStatus.approved) {
        _lastAuthError = 'Account access is suspended or not yet approved.';
        return false;
      }

      if (user.passwordHash != null && user.passwordSalt != null) {
        final verified = SecurityHash.verifyPassword(
          password,
          user.passwordSalt!,
          user.passwordHash!,
        );
        if (!verified) {
          _lastAuthError = 'Incorrect password. Please try again.';
          return false;
        }
      }

      _currentUser = user;
      StorageService.saveCurrentUserId(user.id);
      notifyListeners();
      if (syncFirebase) {
        _signInFirebaseSession(user.email, password, user);
      }
      return true;
    }

    // Strictly block login for pending applicants
    final pending = _pendingUsers.where(
      (u) => _matchesIdentifier(u, identifier),
    );
    if (pending.isNotEmpty) {
      _lastAuthError =
          'This account is pending approval by the Proprietor. Please wait for authorization.';
      return false;
    }

    _lastAuthError = 'No approved account found for "$identifier".';
    return false;
  }

  void quickLoginAs(UserRole role) {
    _lastAuthError = null;
    _currentUser = _approvedUsers.firstWhere(
      (u) => u.role == role && !u.hasCustomAccess,
      orElse: () => _approvedUsers.firstWhere(
        (u) => u.role == role,
        orElse: () => _approvedUsers.first,
      ),
    );
    StorageService.saveCurrentUserId(_currentUser?.id);
    notifyListeners();
  }

  void switchRole(UserRole role) {
    quickLoginAs(role);
  }

  /// Signs in directly as a specific approved team member (e.g. a user with a custom role).
  void quickLoginAsUser(AppUser user) {
    if (user.status != UserAccountStatus.approved) return;
    final match = _approvedUsers.where((u) => u.id == user.id).toList();
    if (match.isEmpty) return;
    _lastAuthError = null;
    _currentUser = match.first;
    StorageService.saveCurrentUserId(_currentUser?.id);
    notifyListeners();
  }

  AppUser signUp({
    required String fullName,
    String email = '',
    required String phone,
    required UserRole requestedRole,
    String? password,
    String? customRoleId,
    String? customRoleName,
  }) {
    _lastAuthError = null;
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = email.trim().isNotEmpty
        ? email.trim()
        : phoneToAuthEmail(cleanPhone);

    if (cleanName.isEmpty || normalizePhone(cleanPhone).length < 10) {
      _lastAuthError = 'Please provide your full name and a valid 10-digit phone number.';
      throw ArgumentError(_lastAuthError);
    }

    if (isPhoneInUse(cleanPhone) || isEmailInUse(cleanEmail)) {
      _lastAuthError =
          'An account or request with this phone number already exists.';
      throw StateError(_lastAuthError!);
    }

    // Security guard: self-registration can never request Master Proprietor.
    final safeRole = requestedRole == UserRole.proprietor
        ? UserRole.supervisor
        : requestedRole;

    String? salt;
    String? hash;
    if (password != null && password.isNotEmpty) {
      salt = SecurityHash.generateSalt();
      hash = SecurityHash.hashPassword(password, salt);
    }

    // Guard against reserved role names in self-submitted custom role strings
    final safeCustomName =
        customRoleName != null &&
            customRoleName.trim().isNotEmpty &&
            !CustomRoleDefinition.isReservedRoleName(customRoleName)
        ? customRoleName.trim()
        : null;

    final newUser = AppUser(
      id: 'PEND-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fullName: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      role: safeRole,
      status: UserAccountStatus.pendingApproval,
      createdAt: DateTime.now(),
      customRoleId: safeCustomName != null ? customRoleId : null,
      customRoleName: safeCustomName,
      passwordHash: hash,
      passwordSalt: salt,
      seenByProprietor: false,
    );

    _pendingUsers.insert(0, newUser);
    _saveUsersToStorage();
    newSignupNotificationNotifier.value = newUser;
    notifyListeners();
    if (password != null && password.isNotEmpty) {
      _registerFirebaseUser(newUser, password);
    }
    return newUser;
  }

  Future<void> _signInFirebaseSession(
    String email,
    String password,
    AppUser localUser,
  ) async {
    if (Firebase.apps.isEmpty || password.isEmpty) return;
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'id': uid,
          'fullName': localUser.fullName,
          'email': localUser.email,
          'phone': localUser.phone,
          'role': localUser.role.name,
          'status': localUser.status.name,
          'createdAt': localUser.createdAt.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        _startCloudRealtimeSyncIfReady();
        await BackendManager.instance.syncLocalToCloud();
      }
    } catch (e) {
      debugPrint('Firebase Auth session sign-in note: $e');
    }
  }

  /// Signs in across both local cache and live Firestore `/users` directory
  /// so accounts created/approved on another device can log in seamlessly on a new phone.
  Future<bool> loginAsync(String identifier, String password) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final remoteUsers = await BackendManager.instance.fetchCollection(
          'users',
        );
        if (remoteUsers.isNotEmpty) {
          applyRemoteUsers(remoteUsers);
        }
      } catch (e) {
        debugPrint('Cloud user refresh note: $e');
      }
    }

    final localOk = login(identifier, password, syncFirebase: false);
    if (!localOk || _currentUser == null) {
      return false;
    }

    // Lock in password hash on first login for pre-seeded or Proprietor-invited accounts
    if ((_currentUser!.passwordHash == null ||
            _currentUser!.passwordSalt == null) &&
        password.trim().isNotEmpty) {
      final salt = SecurityHash.generateSalt();
      final hash = SecurityHash.hashPassword(password, salt);
      final updated = _currentUser!.copyWith(
        passwordHash: hash,
        passwordSalt: salt,
      );
      final idx = _approvedUsers.indexWhere((u) => u.id == updated.id);
      if (idx != -1) {
        _approvedUsers[idx] = updated;
      }
      _currentUser = updated;
      _saveUsersToStorage();
    }

    if (Firebase.apps.isNotEmpty) {
      _startCloudRealtimeSyncIfReady();
      BackendManager.instance.syncLocalToCloud();
    }
    notifyListeners();
    return true;
  }

  Future<void> _registerFirebaseUser(AppUser user, String password) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await BackendManager.instance.upsertCollectionRecord(
        'users',
        user.id,
        user.toMap(),
      );
    } catch (e) {
      debugPrint('Firestore sign-up sync note: $e');
    }
  }

  /// Directly invites and adds an approved staff member to the team directory.
  /// Strictly restricted to Master Proprietor.
  AppUser? inviteStaffMember({
    required String fullName,
    required String email,
    String phone = '',
    required UserRole role,
    String? customRoleId,
    String? customRoleName,
    Set<AppPermissionKey>? customPermissions,
  }) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can invite staff members.';
      return null;
    }

    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim().isEmpty ? '+91 90000 00000' : phone.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _lastAuthError = 'Please provide a valid staff name and email address.';
      return null;
    }

    if (isEmailInUse(cleanEmail)) {
      _lastAuthError =
          'An account or request with "$cleanEmail" already exists.';
      return null;
    }

    final safeRole = role == UserRole.proprietor ? UserRole.supervisor : role;

    String? resolvedCustomId;
    String? resolvedCustomName;
    Set<AppPermissionKey>? resolvedPermissions = customPermissions != null
        ? Set<AppPermissionKey>.from(customPermissions)
        : null;

    if (customRoleId != null) {
      final matches = _customRoles.where((r) => r.id == customRoleId).toList();
      if (matches.isNotEmpty) {
        resolvedCustomId = matches.first.id;
        resolvedCustomName = matches.first.name;
        resolvedPermissions ??= Set<AppPermissionKey>.from(
          matches.first.permissions,
        );
      }
    } else if (customRoleName != null &&
        customRoleName.trim().isNotEmpty &&
        !CustomRoleDefinition.isReservedRoleName(customRoleName)) {
      resolvedCustomName = customRoleName.trim();
    }

    final newUser = AppUser(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fullName: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      role: safeRole,
      status: UserAccountStatus.approved,
      createdAt: DateTime.now(),
      customRoleId: resolvedCustomId,
      customRoleName: resolvedCustomName,
      customPermissions: resolvedPermissions,
      seenByProprietor: true,
    );

    _approvedUsers.add(newUser);
    _saveUsersToStorage();
    notifyListeners();
    return newUser;
  }

  /// Marks pending sign-up requests as acknowledged by Proprietor.
  void markPendingRequestsSeen() {
    if (!canManageTeam) return;
    bool changed = false;
    for (int i = 0; i < _pendingUsers.length; i++) {
      if (!_pendingUsers[i].seenByProprietor) {
        _pendingUsers[i] = _pendingUsers[i].copyWith(seenByProprietor: true);
        changed = true;
      }
    }
    if (changed) {
      _saveUsersToStorage();
      notifyListeners();
    }
  }

  /// Creates and persists a custom reusable role with explicit checked permissions.
  /// Strictly restricted to Master Proprietor.
  CustomRoleDefinition? createCustomRole({
    required String name,
    required Set<AppPermissionKey> permissions,
  }) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can create custom roles.';
      return null;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty || CustomRoleDefinition.isReservedRoleName(cleanName)) {
      _lastAuthError =
          'Enter a valid non-reserved role name (cannot be Proprietor/Admin).';
      return null;
    }

    final duplicate = _customRoles.any(
      (r) => r.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (duplicate) {
      _lastAuthError = 'A custom role named "$cleanName" already exists.';
      return null;
    }

    final role = CustomRoleDefinition(
      id: 'ROLE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: cleanName,
      shortCode: CustomRoleDefinition.deriveShortCode(cleanName),
      permissions: Set<AppPermissionKey>.from(permissions),
      createdAt: DateTime.now(),
    );

    _customRoles.add(role);
    _saveCustomRolesToStorage();
    notifyListeners();
    return role;
  }

  /// Updates an existing reusable custom role and syncs permissions to active
  /// staff assigned to that role. Strictly restricted to Master Proprietor.
  bool updateCustomRole({
    required String roleId,
    required String name,
    required Set<AppPermissionKey> permissions,
  }) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can modify custom roles.';
      return false;
    }

    final idx = _customRoles.indexWhere((r) => r.id == roleId);
    if (idx == -1) return false;

    final cleanName = name.trim();
    if (cleanName.isEmpty || CustomRoleDefinition.isReservedRoleName(cleanName)) {
      _lastAuthError = 'Enter a valid non-reserved role name.';
      return false;
    }

    final duplicate = _customRoles.any(
      (r) => r.id != roleId && r.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (duplicate) {
      _lastAuthError = 'A custom role named "$cleanName" already exists.';
      return false;
    }

    final updatedRole = _customRoles[idx].copyWith(
      name: cleanName,
      shortCode: CustomRoleDefinition.deriveShortCode(cleanName),
      permissions: Set<AppPermissionKey>.from(permissions),
    );
    _customRoles[idx] = updatedRole;

    // Sync updated custom role definition to active staff assigned to it
    for (int i = 0; i < _approvedUsers.length; i++) {
      final u = _approvedUsers[i];
      if (u.customRoleId == roleId) {
        _approvedUsers[i] = u.copyWith(
          customRoleName: updatedRole.name,
          customPermissions: Set<AppPermissionKey>.from(updatedRole.permissions),
        );
        if (_currentUser?.id == u.id) {
          _currentUser = _approvedUsers[i];
        }
      }
    }

    _saveCustomRolesToStorage();
    _saveUsersToStorage();
    notifyListeners();
    return true;
  }

  /// Deletes a saved custom role definition. Existing users keep their snapshot
  /// permissions unless reassigned. Strictly restricted to Master Proprietor.
  bool deleteCustomRole(String roleId) {
    if (!canManageTeam) return false;
    final removed = _customRoles.where((r) => r.id == roleId).isNotEmpty;
    if (!removed) return false;
    _customRoles.removeWhere((r) => r.id == roleId);
    _saveCustomRolesToStorage();
    notifyListeners();
    return true;
  }

  /// Approves a pending team request with either a built-in role OR a named custom
  /// role and explicit checkbox permissions. Strictly restricted to Proprietor.
  bool approveUser(
    String userId, [
    UserRole? overrideRole,
    String? customRoleId,
    String? customRoleName,
    Set<AppPermissionKey>? customPermissions,
    bool saveAsReusableRole = false,
  ]) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can approve staff access.';
      return false;
    }

    final index = _pendingUsers.indexWhere((u) => u.id == userId);
    if (index == -1) return false;

    final pending = _pendingUsers[index];
    final targetBaseRole =
        (overrideRole == UserRole.proprietor ||
            (overrideRole == null && pending.role == UserRole.proprietor))
        ? UserRole.supervisor
        : (overrideRole ?? pending.role);

    String? resolvedCustomId = customRoleId;
    String? resolvedCustomName = customRoleName?.trim();
    Set<AppPermissionKey>? resolvedPerms = customPermissions != null
        ? Set<AppPermissionKey>.from(customPermissions)
        : null;

    if (resolvedCustomName != null && resolvedCustomName.isNotEmpty) {
      if (CustomRoleDefinition.isReservedRoleName(resolvedCustomName)) {
        _lastAuthError = 'Custom role name cannot use a reserved executive title.';
        return false;
      }
      if (saveAsReusableRole && resolvedPerms != null) {
        final existing = _customRoles.where(
          (r) => r.name.toLowerCase() == resolvedCustomName.toLowerCase(),
        );
        if (existing.isNotEmpty) {
          updateCustomRole(
            roleId: existing.first.id,
            name: resolvedCustomName,
            permissions: resolvedPerms,
          );
          resolvedCustomId = existing.first.id;
        } else {
          final created = createCustomRole(
            name: resolvedCustomName,
            permissions: resolvedPerms,
          );
          resolvedCustomId = created?.id;
        }
      }
    }

    _pendingUsers.removeAt(index);
    final bool applyCustom =
        (resolvedCustomName != null && resolvedCustomName.isNotEmpty) ||
        resolvedPerms != null;

    final approved = pending.copyWith(
      status: UserAccountStatus.approved,
      role: targetBaseRole,
      customRoleId: applyCustom ? resolvedCustomId : null,
      customRoleName: applyCustom ? resolvedCustomName : null,
      customPermissions: applyCustom ? (resolvedPerms ?? const {}) : null,
      clearCustomRole: !applyCustom,
      seenByProprietor: true,
    );

    _approvedUsers.add(approved);
    _saveUsersToStorage();
    notifyListeners();
    return true;
  }

  /// Updates the role or custom permissions of an existing approved team member.
  /// Strictly restricted to Master Proprietor; cannot modify Master Owner.
  bool updateApprovedUserAccess({
    required String userId,
    UserRole? presetRole,
    String? customRoleId,
    String? customRoleName,
    Set<AppPermissionKey>? customPermissions,
    bool saveAsReusableRole = false,
  }) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can update staff permissions.';
      return false;
    }

    final idx = _approvedUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return false;
    final target = _approvedUsers[idx];

    // Safeguard: Master Proprietor cannot be reassigned
    if (target.role == UserRole.proprietor && !target.hasCustomAccess) {
      return false;
    }

    String? resolvedCustomId = customRoleId;
    String? resolvedCustomName = customRoleName?.trim();
    Set<AppPermissionKey>? resolvedPerms = customPermissions != null
        ? Set<AppPermissionKey>.from(customPermissions)
        : null;

    final bool applyCustom =
        (resolvedCustomName != null && resolvedCustomName.isNotEmpty) ||
        resolvedPerms != null;

    if (applyCustom &&
        resolvedCustomName != null &&
        resolvedCustomName.isNotEmpty) {
      if (CustomRoleDefinition.isReservedRoleName(resolvedCustomName)) {
        _lastAuthError = 'Custom role name cannot use a reserved executive title.';
        return false;
      }
      if (saveAsReusableRole && resolvedPerms != null) {
        final existing = _customRoles.where(
          (r) => r.name.toLowerCase() == resolvedCustomName.toLowerCase(),
        );
        if (existing.isNotEmpty) {
          updateCustomRole(
            roleId: existing.first.id,
            name: resolvedCustomName,
            permissions: resolvedPerms,
          );
          resolvedCustomId = existing.first.id;
        } else {
          final created = createCustomRole(
            name: resolvedCustomName,
            permissions: resolvedPerms,
          );
          resolvedCustomId = created?.id;
        }
      }
    }

    final safePreset = (presetRole == UserRole.proprietor || presetRole == null)
        ? (target.role == UserRole.proprietor
              ? UserRole.supervisor
              : target.role)
        : presetRole;

    final updated = applyCustom
        ? target.copyWith(
            role: UserRole.supervisor,
            customRoleId: resolvedCustomId,
            customRoleName: resolvedCustomName,
            customPermissions: resolvedPerms ?? const {},
          )
        : target.copyWith(
            role: safePreset,
            clearCustomRole: true,
          );

    _approvedUsers[idx] = updated;
    if (_currentUser?.id == userId) {
      _currentUser = updated;
    }
    _saveUsersToStorage();
    notifyListeners();
    return true;
  }

  void rejectUser(String userId) {
    if (!canManageTeam) return;
    _pendingUsers.removeWhere((u) => u.id == userId);
    _saveUsersToStorage();
    BackendManager.instance.deleteDocument('users', userId);
    notifyListeners();
  }

  void dismissStaff(String userId) {
    if (!canManageTeam) return;
    final index = _approvedUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _approvedUsers[index];
      // Safeguard: Proprietor owner cannot be dismissed
      if (user.role == UserRole.proprietor && !user.hasCustomAccess) return;

      _approvedUsers.removeAt(index);
      _saveUsersToStorage();
      BackendManager.instance.deleteDocument('users', userId);

      if (_currentUser?.id == userId) {
        _currentUser = null;
      }
      notifyListeners();
    }
  }

  /// Allows the Master Proprietor to set a new temporary or permanent password
  /// for an approved staff member (resolving forgotten passwords without email links).
  bool resetStaffPassword({
    required String userId,
    required String newPassword,
  }) {
    _lastAuthError = null;
    if (!canManageTeam) {
      _lastAuthError =
          'Security restriction: Only the Proprietor can reset staff passwords.';
      return false;
    }
    final cleanPassword = newPassword.trim();
    if (cleanPassword.length < 6) {
      _lastAuthError = 'Password must be at least 6 characters long.';
      return false;
    }
    final idx = _approvedUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) {
      _lastAuthError = 'Staff member not found.';
      return false;
    }
    final salt = SecurityHash.generateSalt();
    final hash = SecurityHash.hashPassword(cleanPassword, salt);
    final updated = _approvedUsers[idx].copyWith(
      passwordHash: hash,
      passwordSalt: salt,
    );
    _approvedUsers[idx] = updated;
    if (_currentUser?.id == userId) {
      _currentUser = updated;
    }
    _saveUsersToStorage();
    notifyListeners();
    return true;
  }

  /// Sends a password reset email when Firebase Auth is connected.
  Future<String?> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Enter your email address first so we can send a reset link.';
    }
    if (Firebase.apps.isEmpty) {
      return 'Password reset emails require an active Firebase connection. Ask the Proprietor or use Quick Demo Login below.';
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send password reset email.';
    } catch (_) {
      return 'Could not send password reset email right now.';
    }
  }

  void logout() {
    _lastAuthError = null;
    _currentUser = null;
    StorageService.saveCurrentUserId(null);
    BackendManager.instance.stopRealtimeSync();
    if (Firebase.apps.isNotEmpty) {
      FirebaseAuth.instance.signOut().catchError((_) {});
    }
    notifyListeners();
  }

  AppFontTheme get fontTheme => _fontTheme;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setFontTheme(AppFontTheme theme) {
    _fontTheme = theme;
    AppTypography.activeTheme = theme;
    notifyListeners();
  }

  void setTextScaleFactor(double factor) {
    final clamped = factor.clamp(0.95, 1.4).toDouble();
    _textScaleFactor = clamped;
    StorageService.saveTextScaleFactor(clamped);
    notifyListeners();
  }

  Future<void> setPhotoRetentionMonths(int months) async {
    if (!StorageService.supportedPhotoRetentionMonths.contains(months)) return;
    _photoRetentionMonths = months;
    await StorageService.setPhotoRetentionMonths(months);
    notifyListeners();
  }

  Future<void> setCadRetentionMonths(int months) async {
    if (!StorageService.supportedCadRetentionMonths.contains(months)) return;
    _cadRetentionMonths = months;
    await StorageService.setCadRetentionMonths(months);
    notifyListeners();
  }
}
