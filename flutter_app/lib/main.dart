import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_toast.dart';
import 'ui/features/auth/view_models/auth_notifier.dart';
import 'ui/features/auth/views/login_screen.dart';
import 'ui/features/pos/views/pos_screen.dart';

import 'core/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted Cloud Server API Base URL if configured
  await AppConstants.loadSavedBaseUrl();

  // Lock to landscape — tablet POS only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive fullscreen for kiosk-style POS UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    // Riverpod ProviderScope wraps entire app
    const ProviderScope(child: SitePyoeApp()),
  );
}

class SitePyoeApp extends ConsumerWidget {
  const SitePyoeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    if (authState.isAuthenticated) {
      ref.read(syncServiceProvider).startPeriodicSync();
    }

    return MaterialApp(
      key: ValueKey(themeMode),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'SitePyoe POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isAuthenticated ? const PosScreen() : const LoginScreen(),
    );
  }
}
