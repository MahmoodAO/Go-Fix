import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local login persistence using SharedPreferences.
/// Does NOT rely on FirebaseAuth.currentUser.
/// خدمة التخزين المحلي، وتدير حفظ حالة الدخول وبعض الإعدادات البسيطة عبر SharedPreferences.
class LocalStorageService {
  /// المفاتيح المستخدمة لتخزين بيانات الجلسة والإعدادات محليًا.
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserRole = 'userRole';
  static const String _keyOnboardingCompleted = 'onboardingCompleted';

  /// Save login state as logged in.
  /// حفظ حالة تسجيل الدخول محليًا.
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  /// Save the user ID.
  /// حفظ معرف المستخدم للاستفادة منه عند استعادة الجلسة.
  static Future<void> setUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
  }

  /// Save the user role ("customer" or "provider").
  /// حفظ دور المستخدم محليًا لتسهيل التوجيه داخل التطبيق.
  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  /// Get the stored user role. Defaults to "customer" if not set.
  /// قراءة دور المستخدم المخزن محليًا مع قيمة افتراضية عند غيابه.
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'customer';
  }

  /// Check if user is logged in.
  /// التحقق من وجود جلسة دخول محفوظة محليًا.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clear all login-related data (used on logout).
  /// حذف بيانات الجلسة المحلية عند تسجيل الخروج.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }

  /// Mark onboarding as completed.
  /// حفظ حالة إكمال شاشة التعريف الأولية.
  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, value);
  }

  /// Check if onboarding is completed.
  /// التحقق مما إذا كان المستخدم أنهى شاشة التعريف من قبل.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }
}
