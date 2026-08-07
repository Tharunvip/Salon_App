import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_styles.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  ThemeData get lightTheme => AppTheme.theme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _mode == ThemeMode.dark);
    notifyListeners();
  }
}
