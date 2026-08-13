import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _fontFamilyKey = 'font_family';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<double> loadFontSize({double fallback = 18}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? fallback;
  }

  Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<String> loadFontFamily({String fallback = 'Inter'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontFamilyKey) ?? fallback;
  }

  Future<void> saveFontFamily(String family) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, family);
  }
}
