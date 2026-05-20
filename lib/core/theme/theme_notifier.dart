import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.dark);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'light') {
      super.value = ThemeMode.light;
    } else if (value == 'dark') {
      super.value = ThemeMode.dark;
    }
  }

  bool get isDark => value == ThemeMode.dark;

  Future<void> toggle() async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeNotifier = ThemeNotifier();
