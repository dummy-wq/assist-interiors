import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/services/backend_manager.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/auth/views/login_screen.dart';
import 'features/dashboard/views/main_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Production-grade crash shield replacing default red/grey box with studio recovery tile
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0E1017),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.architecture_rounded, size: 40, color: Color(0xFFF3B9A8)),
              SizedBox(height: 12),
              Text(
                'Studio Layout Refreshing...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  await StorageService.init();
  await StorageService.seedFillerProjectsIfEmpty();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase not initialized or credentials missing: $e');
  }
  await BackendManager.instance.init();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const AssistInteriorsApp(),
    ),
  );
}

/// Custom fluid scroll behavior enabling multi-pointer dragging and iOS-style elastic overscroll
class StudioScrollBehavior extends MaterialScrollBehavior {
  const StudioScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class AssistInteriorsApp extends StatelessWidget {
  const AssistInteriorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = auth.isDarkMode;
    final overlay = isDark ? AppTheme.darkOverlay : AppTheme.lightOverlay;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: auth.themeMode,
        themeAnimationDuration: Duration.zero,
        scrollBehavior: const StudioScrollBehavior(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final scaledMediaQuery = mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0) * 1.10,
            ),
          );
          return MediaQuery(
            data: scaledMediaQuery,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: auth.isAuthenticated
            ? const MainDashboardScreen()
            : const LoginScreen(),
      ),
    );
  }
}
