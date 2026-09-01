import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const String _keyThemeMode = 'theme_mode';

  var isDarkMode = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_keyThemeMode);
      isDarkMode.value = savedMode == 'dark';
    } catch (_) {
      isDarkMode.value = false;
    }
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, isDarkMode.value ? 'dark' : 'light');
    } catch (_) {}
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
