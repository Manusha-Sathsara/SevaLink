import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ─── Notifier ────────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.light;
  }

  Future<void> toggleTheme() async {}

  Future<void> setTheme(ThemeMode mode) async {}
}

// ─── Provider ────────────────────────────────────────────────────────────────
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

// ─── Helper extension ────────────────────────────────────────────────────────
extension ThemeModeX on ThemeMode {
  bool get isDark => this == ThemeMode.dark;
}
