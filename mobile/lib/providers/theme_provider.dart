import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "theme_mode";
  // On force une valeur par défaut (Light) pour éviter l'ambiguïté du Système au démarrage
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // On expose ThemeMode pour le MaterialApp
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    print("ThemeProvider: Manual toggle to ${_isDarkMode ? 'DARK' : 'LIGHT'}");
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      print("ThemeProvider: Loaded theme from storage: $savedTheme");
      
      if (savedTheme != null) {
        _isDarkMode = savedTheme == 'dark';
        notifyListeners();
      }
    } catch (e) {
      print("ThemeProvider: Error loading theme: $e");
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _isDarkMode ? 'dark' : 'light');
    } catch (e) {
      print("ThemeProvider: Error saving theme: $e");
    }
  }
}
