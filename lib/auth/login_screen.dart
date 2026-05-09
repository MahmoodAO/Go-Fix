import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/core/widgets/loading_overlay.dart';
import 'package:homemate/core/utils/local_storage_service.dart';
import 'package:homemate/services/auth_service.dart';
import 'package:homemate/services/user_service.dart';

/// شاشة تسجيل الدخول، مسؤولة عن إدخال بيانات المستخدم والتحقق منها عبر Firebase Auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  /// متحكمات حقول البريد الإلكتروني وكلمة المرور.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  /// خدمة المصادقة المستخدمة لتنفيذ عمليات الدخول واستعادة كلمة المرور.
  final AuthService _authService = AuthService();

  /// متغيرات التحكم في حالات التحميل وإظهار كلمة المرور.
  bool _isLoading = false;
  bool _isSuccessLoading = false;
  bool _obscurePassword = true;

  /// متحكمات الحركة الخاصة بظهور عناصر الشاشة.
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  /// تهيئة الحركات الافتتاحية عند فتح شاشة تسجيل الدخول.
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  /// تنفيذ عملية تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور.
  Future<bool> signIn() async {
    try {
      if (kDebugMode) {
        debugPrint('[LOGIN] Attempting sign in: ${_emailController.text.trim()}');
      }

      // تنفيذ المصادقة الفعلية عبر Firebase Auth.
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[LOGIN] FirebaseAuthException: ${e.code}');
      }

      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';

      if (e.code == 'user-not-found') {
        errorMessage = 'لا يوجد حساب بهذا البريد الإلكتروني';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'البريد الإلكتروني غير صالح';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'بيانات الاعتماد غير صحيحة';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }

      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }

      return false;
    }
  }

  /// الانتقال إلى شاشة إنشاء حساب جديد.
  void openSigupScreen() {
    Navigator.of(context).pushReplacementNamed('signup');
  }

  /// معالجة زر تسجيل الدخول مع التحقق الأولي ثم حفظ الجلسة محليًا.
  Future<void> _handleLogin() async {
    // التحقق من إدخال البيانات الأساسية قبل إرسال الطلب.
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await signIn();

    if (!success) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    try {
      // Save login state locally
      // حفظ حالة تسجيل الدخول ومعرّف المستخدم محليًا لتسريع الدخول لاحقًا.
      await LocalStorageService.setLoggedIn(true);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await LocalStorageService.setUserId(uid);

      // Read user role from Firestore and cache locally
      // جلب دور المستخدم من Firestore لتحديد الشاشة المناسبة بعد الدخول.
      final role = await UserService().getUserRole(uid);
      await LocalStorageService.setUserRole(role);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccessLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Route by role: admin → /admin, provider → provider_tabscreen, customer → tabscreen
        // التوجيه يعتمد على نوع المستخدم داخل النظام.
        String destination;
        if (role == 'admin') {
          destination = '/admin';
        } else if (role == 'provider') {
          destination = 'provider_tabscreen';
        } else {
          destination = 'tabscreen';
        }
        Navigator.of(context).pushReplacementNamed(destination);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الملف الشخصي: $e')),
        );
      }
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني المدخل.
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني أولاً'),
        ),
      );
      return;
    }

    try {
      // تنفيذ طلب إعادة التعيين عبر Firebase Auth.
      await _authService.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء إرسال رابط إعادة التعيين';
      if (e.code == 'user-not-found') {
        msg = 'لا يوجد حساب بهذا البريد الإلكتروني';
      } else if (e.code == 'invalid-email') {
        msg = 'البريد الإلكتروني غير صالح';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  @override
  /// التخلص من المتحكمات عند إغلاق الشاشة لتجنب تسرب الذاكرة.
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  /// بناء واجهة تسجيل الدخول مع دعم حالات التحميل والتنقل.
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topHeight = mq.size.height * 0.35;
    final primary = AppTheme.getPrimary(false);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppTheme.lightScaffoldBg,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight + 40,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.onboardingGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'مرحباً بك مجدداً',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'قم بتسجيل الدخول للوصول إلى خدماتك.',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: topHeight - 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.lightScaffoldBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        32,
                        24,
                        mq.padding.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
                              boxShadow: AppTheme.premiumShadow(false),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontFamily: 'ElMessiri',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                  decoration: AppTheme.inputDecoration(
                                    label: 'البريد الإلكتروني',
                                    isDark: false,
                                    prefixIcon: Icons.email_outlined,
                                  ).copyWith(
                                    hintText: 'أدخل بريدك الإلكتروني',
                                    hintTextDirection: TextDirection.rtl,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                  decoration: AppTheme.inputDecoration(
                                    label: 'كلمة المرور',
                                    isDark: false,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffix: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppTheme.lightTextSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ).copyWith(
                                    hintText: 'أدخل كلمة المرور',
                                    hintTextDirection: TextDirection.rtl,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _handleForgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      'نسيت كلمة المرور؟',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'تسجيل الدخول',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'ليس لديك حساب؟ ',
                                style: TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 15,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: openSigupScreen,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    'إنشاء حساب جديد',
                                    style: TextStyle(
                                      fontFamily: 'ElMessiri',
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // إظهار طبقة تحميل نجاح قصيرة قبل الانتقال النهائي.
            if (_isSuccessLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}
