import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

/// Manages application-wide theme mode (Dark forest green vs White theme).
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    AppColors.setThemeMode(ThemeMode.dark);
  }

  bool get isDark => state != ThemeMode.light;

  void toggleTheme() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    AppColors.setThemeMode(next);
    state = next;
  }

  void setTheme(ThemeMode mode) {
    AppColors.setThemeMode(mode);
    state = mode;
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
