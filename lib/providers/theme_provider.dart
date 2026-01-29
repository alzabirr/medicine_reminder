import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medi/core/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = AppTheme.primaryColor;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadPreferences();
  }

  void _loadPreferences() {
    final box = Hive.box('settings');
    final colorValue = box.get('accentColor', defaultValue: AppTheme.primaryColor.value);
    _accentColor = Color(colorValue);
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    Hive.box('settings').put('accentColor', color.value);
    notifyListeners();
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
