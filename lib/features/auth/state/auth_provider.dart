import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_typography.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  ThemeMode _themeMode = ThemeMode.dark;
  AppFontTheme _fontTheme = AppFontTheme.plusJakartaSans;
  AppLanguage _language = AppLanguage.english;

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
    ),
    AppUser(
      id: 'USR-002',
      fullName: 'Kavita Reddy',
      email: 'kavita.sales@assistinteriors.in',
      phone: '+91 98711 23456',
      role: UserRole.sales,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 3, 15),
    ),
    AppUser(
      id: 'USR-003',
      fullName: 'Ananya Sen',
      email: 'ananya.pm@assistinteriors.in',
      phone: '+91 99102 34567',
      role: UserRole.projectManager,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 2, 10),
    ),
    AppUser(
      id: 'USR-004',
      fullName: 'Vikram Malhotra',
      email: 'vikram.design@assistinteriors.in',
      phone: '+91 98203 45678',
      role: UserRole.designer,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 4, 1),
    ),
    AppUser(
      id: 'USR-005',
      fullName: 'Pooja Iyer',
      email: 'pooja.accounts@assistinteriors.in',
      phone: '+91 98304 56789',
      role: UserRole.accounts,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 1, 20),
    ),
    AppUser(
      id: 'USR-006',
      fullName: 'Suresh Kumar',
      email: 'suresh.site@assistinteriors.in',
      phone: '+91 98405 67890',
      role: UserRole.supervisor,
      status: UserAccountStatus.approved,
      createdAt: DateTime(2025, 5, 12),
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
    ),
    AppUser(
      id: 'PEND-102',
      fullName: 'Tanvi Mehra',
      email: 'tanvi.m@gmail.com',
      phone: '+91 98112 99423',
      role: UserRole.designer,
      status: UserAccountStatus.pendingApproval,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
  ];

  final List<AppUser> _approvedUsers = [];
  final List<AppUser> _pendingUsers = [];

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole get currentRole => _currentUser?.role ?? UserRole.proprietor;
  String get userName => _currentUser?.fullName ?? 'Guest';
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppLanguage get language => _language;
  List<AppUser> get pendingUsers => List.unmodifiable(_pendingUsers);
  List<AppUser> get approvedUsers => List.unmodifiable(_approvedUsers);

  // Initialize with persisted or default users; Proprietor logged in by default for smooth demoing
  AuthProvider() {
    _loadPersistedLanguage();
    _loadPersistedUsers();
    _currentUser = _approvedUsers.isNotEmpty ? _approvedUsers.first : null;
  }

  void _loadPersistedLanguage() {
    final code = StorageService.getLanguage();
    final lang = AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
    _language = lang;
    AppStrings.setLanguage(lang);
  }

  void _loadPersistedUsers() {
    final storedApproved = StorageService.getApprovedUsers();
    if (storedApproved.isNotEmpty) {
      _approvedUsers.clear();
      _approvedUsers.addAll(storedApproved.map(AppUser.fromMap));
    } else {
      _approvedUsers.clear();
      _approvedUsers.addAll(_defaultApprovedUsers);
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
      _pendingUsers.addAll(_defaultPendingUsers);
      StorageService.savePendingUsers(
        _pendingUsers.map((u) => u.toMap()).toList(),
      );
    }
  }

  void _saveUsersToStorage() {
    StorageService.saveApprovedUsers(
      _approvedUsers.map((u) => u.toMap()).toList(),
    );
    StorageService.savePendingUsers(
      _pendingUsers.map((u) => u.toMap()).toList(),
    );
  }

  bool login(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final user = _approvedUsers.firstWhere(
      (u) => u.email.toLowerCase() == normalized,
      orElse: () => AppUser(
        id: '',
        fullName: '',
        email: '',
        phone: '',
        role: UserRole.proprietor,
        status: UserAccountStatus.rejected,
        createdAt: DateTime.now(),
      ),
    );

    if (user.id.isNotEmpty) {
      _currentUser = user;
      notifyListeners();
      return true;
    }

    // Check if account is in pending state
    final pending = _pendingUsers.where(
      (u) => u.email.toLowerCase() == normalized,
    );
    if (pending.isNotEmpty) {
      return false; // Triggers pending approval message
    }

    return false; // Unknown or dismissed account
  }

  void quickLoginAs(UserRole role) {
    _currentUser = _approvedUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => _approvedUsers.first,
    );
    notifyListeners();
  }

  void switchRole(UserRole role) {
    quickLoginAs(role);
  }

  AppUser signUp({
    required String fullName,
    required String email,
    required String phone,
    required UserRole requestedRole,
  }) {
    final newUser = AppUser(
      id: 'PEND-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: requestedRole,
      status: UserAccountStatus.pendingApproval,
      createdAt: DateTime.now(),
    );

    _pendingUsers.insert(0, newUser);
    _saveUsersToStorage();
    notifyListeners();
    return newUser;
  }

  void approveUser(String userId, [UserRole? overrideRole]) {
    final index = _pendingUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _pendingUsers.removeAt(index);
      final approved = user.copyWith(
        status: UserAccountStatus.approved,
        role: overrideRole ?? user.role,
      );
      _approvedUsers.add(approved);
      _saveUsersToStorage();
      notifyListeners();
    }
  }

  void rejectUser(String userId) {
    _pendingUsers.removeWhere((u) => u.id == userId);
    _saveUsersToStorage();
    notifyListeners();
  }

  void dismissStaff(String userId) {
    final index = _approvedUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _approvedUsers[index];
      // Safeguard: Proprietor owner cannot be dismissed
      if (user.role == UserRole.proprietor) return;

      _approvedUsers.removeAt(index);
      _saveUsersToStorage();

      if (_currentUser?.id == userId) {
        _currentUser = null;
      }
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
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

  void setLanguage(AppLanguage lang) {
    _language = lang;
    AppStrings.setLanguage(lang);
    StorageService.saveLanguage(lang.code);
    notifyListeners();
  }
}
