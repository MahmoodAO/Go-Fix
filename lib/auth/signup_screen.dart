import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homemate/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String _selectedRole = 'customer'; // الدور المختار: customer أو provider

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
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

  Future<bool> signUp() async {
    try {
      if (passwordConfirmed() && _fieldsAreValid()) {
        // Create the user with Firebase Auth
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          try {
            // Save displayName to Firebase Auth profile
            await user.updateDisplayName(_nameController.text.trim());

            // Save user profile data to Firestore (including role)
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'displayName': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (firestoreError) {
            // Rollback: delete the orphaned Auth user
            await user.delete();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'فشل في إنشاء الملف الشخصي. يرجى المحاولة مرة أخرى'),
                ),
              );
            }
            return false;
          }
        }

        return true;
      }

      if (!_fieldsAreValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى ملء جميع الحقول')),
        );
      } else if (!passwordConfirmed()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
        );
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء إنشاء الحساب';

      if (e.code == 'weak-password') {
        errorMessage = 'كلمة المرور ضعيفة جداً';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'الحساب موجود بالفعل';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'البريد الإلكتروني غير صالح';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع')),
      );
      return false;
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() ==
        _confirmPasswordController.text.trim();
  }

  bool _fieldsAreValid() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty;
  }

  Future<void> _handleSignup() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الشروط والأحكام أولاً'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (await signUp() && mounted) {
      // Sign out the auto-signed-in user so they arrive at login
      // with a clean auth state (createUserWithEmailAndPassword auto-signs in).
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'login');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topHeight = mq.size.height * 0.28;
    final primary = AppTheme.getPrimary(false);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppTheme.lightScaffoldBg,
        body: Stack(
          children: [
            // ─── Gradient Header ──────────────────────────────
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
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, 'login'),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'حساب جديد',
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
                          'انضم إلينا اليوم لتجربة منزلية أذكى وأسهل.',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── White Card Form ──────────────────────────────
            Positioned.fill(
              top: topHeight - 20,
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
                                  'إنشاء حساب',
                                  style: TextStyle(
                                    fontFamily: 'ElMessiri',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ── Name Field ───────────────────
                                TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                  decoration: AppTheme.inputDecoration(
                                    label: 'الاسم الكامل',
                                    isDark: false,
                                    prefixIcon: Icons.person_outline_rounded,
                                  ).copyWith(
                                    hintText: 'أدخل اسمك الكامل',
                                    hintTextDirection: TextDirection.rtl,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Role Selection ────────────────
                                // اختيار الدور: عميل أو مزوّد خدمة
                                Text(
                                  'نوع الحساب',
                                  style: TextStyle(
                                    fontFamily: 'ElMessiri',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() =>
                                            _selectedRole = 'customer'),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedRole == 'customer'
                                                    ? primary
                                                        .withOpacity(0.10)
                                                    : AppTheme.lightScaffoldBg,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppTheme.radiusMd),
                                            border: Border.all(
                                              color: _selectedRole ==
                                                      'customer'
                                                  ? primary
                                                  : AppTheme.lightDivider,
                                              width: _selectedRole ==
                                                      'customer'
                                                  ? 2
                                                  : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.person_rounded,
                                                color: _selectedRole ==
                                                        'customer'
                                                    ? primary
                                                    : AppTheme
                                                        .lightTextSecondary,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'عميل',
                                                style: TextStyle(
                                                  fontFamily: 'ElMessiri',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: _selectedRole ==
                                                          'customer'
                                                      ? primary
                                                      : AppTheme
                                                          .lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() =>
                                            _selectedRole = 'provider'),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16),
                                          decoration: BoxDecoration(
                                            color: _selectedRole ==
                                                    'provider'
                                                ? primary
                                                    .withOpacity(0.10)
                                                : AppTheme.lightScaffoldBg,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppTheme.radiusMd),
                                            border: Border.all(
                                              color: _selectedRole ==
                                                      'provider'
                                                  ? primary
                                                  : AppTheme.lightDivider,
                                              width: _selectedRole ==
                                                      'provider'
                                                  ? 2
                                                  : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons
                                                    .home_repair_service_rounded,
                                                color: _selectedRole ==
                                                        'provider'
                                                    ? primary
                                                    : AppTheme
                                                        .lightTextSecondary,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'مزوّد خدمة',
                                                style: TextStyle(
                                                  fontFamily: 'ElMessiri',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: _selectedRole ==
                                                          'provider'
                                                      ? primary
                                                      : AppTheme
                                                          .lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ── Email Field ──────────────────
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
                                const SizedBox(height: 16),

                                // ── Password Field ───────────────
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

                                // ── Confirm Password Field ───────
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextPrimary,
                                  ),
                                  decoration: AppTheme.inputDecoration(
                                    label: 'تأكيد كلمة المرور',
                                    isDark: false,
                                    prefixIcon: Icons.lock_reset_rounded,
                                    suffix: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppTheme.lightTextSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ).copyWith(
                                    hintText: 'أعد إدخال كلمة المرور',
                                    hintTextDirection: TextDirection.rtl,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Terms Checkbox ───────────────
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _agreedToTerms = !_agreedToTerms;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        activeColor: primary,
                                        onChanged: (v) {
                                          setState(() {
                                            _agreedToTerms = v ?? false;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontFamily: 'ElMessiri',
                                              fontSize: 13,
                                              color:
                                                  AppTheme.lightTextSecondary,
                                            ),
                                            children: [
                                              const TextSpan(
                                                  text: 'أوافق على '),
                                              TextSpan(
                                                text: 'الشروط والأحكام',
                                                style: TextStyle(
                                                  color: primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // ── Sign Up Button ───────────────
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleSignup,
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
                                            'إنشاء حساب',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // ── Already have account ─────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'لديك حساب بالفعل؟ ',
                                style: TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 15,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(
                                    context, 'login'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    'تسجيل الدخول',
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
          ],
        ),
      ),
    );
  }
}