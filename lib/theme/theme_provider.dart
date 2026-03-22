import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum AppThemeMode { neon, classic }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.neon;
  static const String _prefKey = 'app_theme_mode';

  AppThemeMode get themeMode => _themeMode;
  bool get isNeonMode => _themeMode == AppThemeMode.neon;
  bool get isClassicMode => _themeMode == AppThemeMode.classic;

  ThemeData get currentTheme =>
      _themeMode == AppThemeMode.neon ? AppTheme.darkTheme : AppTheme.classicTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_prefKey);
    if (savedMode == 'classic') {
      _themeMode = AppThemeMode.classic;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode == AppThemeMode.classic ? 'classic' : 'neon');
  }

  Future<void> toggleTheme() async {
    await setTheme(
      _themeMode == AppThemeMode.neon ? AppThemeMode.classic : AppThemeMode.neon,
    );
  }
}
