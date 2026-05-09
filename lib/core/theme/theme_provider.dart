import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزود السمة، ويتولى حفظ وضع الإضاءة وإشعار الواجهة عند تغييره.
class ThemeProvider with ChangeNotifier {
  /// المفتاح المستخدم لتخزين وضع السمة محليًا.
  static const String _themeKey = 'theme_mode';
  /// الوضع الحالي للسمة داخل التطبيق.
  ThemeMode _themeMode = ThemeMode.light;

  /// تحميل وضع السمة المحفوظ عند إنشاء المزود.
  ThemeProvider() {
    _loadTheme();
  }

  /// قراءة وضع السمة الحالي لاستخدامه في MaterialApp.
  ThemeMode get themeMode => _themeMode;

  /// التحقق مما إذا كان التطبيق يعمل في الوضع الداكن.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// التبديل بين الوضع الفاتح والداكن مع حفظ النتيجة محليًا.
  void toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _saveTheme();
  }

  /// استعادة وضع السمة المخزن داخل SharedPreferences.
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false; // Default to Light
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// حفظ وضع السمة الحالي لاستخدامه في المرات القادمة.
  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }
}
