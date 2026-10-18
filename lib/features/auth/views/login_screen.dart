import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/widgets/instant_press_feedback.dart';
import '../../../core/widgets/quick_fade_dropdown.dart';
import '../models/user_model.dart';
import '../state/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.supervisor;

  bool _obscurePassword = true;
  String? _errorMessage;
  AppUser? _justRegisteredUser;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    if (_isSignUp) {
      final newUser = auth.signUp(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        requestedRole: _selectedRole,
      );

      setState(() {
        _justRegisteredUser = newUser;
      });
    } else {
      final success = auth.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!success) {
        setState(() {
          _errorMessage = 'This account is pending approval by the Proprietor. Please wait for authorization.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Selector Button
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language (${auth.language.shortCode})',
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
              side: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.8),
                width: 0.8,
              ),
            ),
            position: PopupMenuPosition.under,
            onSelected: (AppLanguage selected) {
              auth.setLanguage(selected);
              AppNotification.show(
                context,
                message: 'Language set to ${selected.nativeName}',
              );
            },
            itemBuilder: (context) {
              return AppLanguage.values.map((lang) {
                final isSelected = auth.language == lang;
                return PopupMenuItem<AppLanguage>(
                  value: lang,
                  height: 38,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPeach.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          lang.shortCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.brandPeach : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? AppColors.brandPeach : null,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.brandPeach,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InstantPressFeedback(
                child: Material(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
                  child: Container(
                    width: AppSizes.topActionButtonSize,
                    height: AppSizes.topActionButtonSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.topActionRadius,
                      ),
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      auth.language.shortCode,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPeach,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Tooltip(
              message: 'Toggle Theme',
              child: Material(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
                child: InkWell(
                  onTap: () => auth.toggleTheme(),
                  borderRadius: BorderRadius.circular(AppSizes.topActionRadius),
                  child: Container(
                    width: AppSizes.topActionButtonSize,
                    height: AppSizes.topActionButtonSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.topActionRadius,
                      ),
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                .withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.82,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Icon(
                        auth.isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        key: ValueKey<bool>(auth.isDarkMode),
                        size: AppSizes.topActionIconSize,
                        color: isDark
                            ? AppColors.textLightPrimary
                            : AppColors.textDarkPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _justRegisteredUser != null
                ? _buildPendingApprovalCard(isDark, _justRegisteredUser!)
                : _buildAuthCard(context, isDark, auth),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, bool isDark, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Logo & Header
            Center(
              child: Image.asset(
                AppConstants.logoPath,
                height: 56,
                errorBuilder: (context, error, stackTrace) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPeach,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text(
                        'ASSIST',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'INTERIORS',
                      style: TextStyle(fontSize: 18, letterSpacing: 2.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'ENTERPRISE ARCHITECTURE SUITE',
                style: AppTypography.bodySmall(isDark).copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPeach,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Mode Selector Tabs (Sign In / Register)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isSignUp = false;
                        _errorMessage = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isSignUp
                              ? AppColors.brandPeach
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Staff Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: !_isSignUp
                                ? Colors.black
                                : (isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isSignUp = true;
                        _errorMessage = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isSignUp
                              ? AppColors.brandPeach
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Request Access',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _isSignUp
                                ? Colors.black
                                : (isDark
                                      ? AppColors.textLightMuted
                                      : AppColors.textDarkMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sign Up Fields
            if (_isSignUp) ...[
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter your phone number'
                    : null,
              ),
              const SizedBox(height: 14),
              QuickFadeDropdown<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Requested Department / Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: UserRole.values
                    .where((r) => r != UserRole.proprietor)
                    .map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.title),
                      );
                    })
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 14),
            ],

            // Common Fields (Email & Password)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: _isSignUp ? 'Work Email' : 'Email Address',
                hintText: _isSignUp
                    ? 'name@assistinteriors.in'
                    : 'rajesh@assistinteriors.in',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (val) => val == null || !val.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _obscurePassword,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) => val == null || val.length < 4
                  ? 'Password must be at least 4 characters'
                  : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text(
                _isSignUp
                    ? 'Submit Request to Proprietor'
                    : 'Sign In to Dashboard',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 28),

            // One-Click Demo Logins Section
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR QUICK DEMO LOGIN AS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark
                          ? AppColors.textLightMuted
                          : AppColors.textDarkMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: UserRole.values.map((role) {
                return InkWell(
                  onTap: () => auth.quickLoginAs(role),
                  borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                  child: Container(
                    height: AppSizes.chipHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.chipRadius),
                      border: Border.all(
                        color: role.color.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          role.icon,
                          size: AppSizes.chipIconSize,
                          color: role.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          role.shortCode,
                          style: TextStyle(
                            fontSize: AppSizes.chipFontSize,
                            fontWeight: FontWeight.w700,
                            color: role.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalCard(bool isDark, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.warning,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text('Request Submitted!', style: AppTypography.displaySmall(isDark)),
          const SizedBox(height: 10),
          Text(
            'Your account for ${user.fullName} (${user.role.title}) has been created.',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium(isDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Security Policy Notice: To protect client financials and site operations, all staff accounts must be verified and approved by the Proprietor before login permissions are activated.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _justRegisteredUser = null;
                _isSignUp = false;
              });
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }
}
