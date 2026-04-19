import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modern NotifierProvider to manage the current ThemeMode.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to system theme
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
