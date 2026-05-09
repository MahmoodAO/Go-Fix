import 'package:firebase_auth/firebase_auth.dart';

/// خدمة المصادقة، وتغلف عمليات Firebase Auth الأساسية المستخدمة داخل التطبيق.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// مرجع Firebase Auth المستخدم لتنفيذ عمليات الدخول والتسجيل والخروج.
  final FirebaseAuth _firebaseAuth;

  /// تنفيذ تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// إنشاء حساب جديد عبر Firebase Auth.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// إرسال رسالة إعادة تعيين كلمة المرور إلى البريد الإلكتروني المحدد.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// تسجيل خروج المستخدم الحالي من التطبيق.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  /// تحديث الاسم الظاهر للمستخدم داخل ملفه في Firebase Auth.
  Future<void> updateDisplayName({
    required User user,
    required String displayName,
  }) {
    return user.updateDisplayName(displayName);
  }
}
