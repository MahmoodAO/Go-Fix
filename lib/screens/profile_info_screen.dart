import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/services/auth_service.dart';
import 'package:homemate/services/user_service.dart';

/// شاشة الملف الشخصي، وتعرض بيانات المستخدم الحالية وتسمح بتحديثها.
class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  /// مفتاح النموذج ومتحكمات الحقول القابلة للتعديل.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  /// خدمات المصادقة والمستخدم لتحديث البيانات محليًا وفي Firestore.
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  /// حالات التحميل والبيانات الثابتة للملف الشخصي.
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String _email = '';
  String _photoUrl = '';

  @override
  /// بدء تحميل بيانات المستخدم الحالي عند فتح الشاشة.
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  /// التخلص من المتحكمات عند إغلاق الشاشة.
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// تحميل بيانات المستخدم من Firebase Auth ثم استكمالها من Firestore عند توفرها.
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _email = user.email ?? '';
    _nameController.text = user.displayName ?? '';
    _photoUrl = user.photoURL ?? '';

    // محاولة قراءة البيانات الإضافية المخزنة في Firestore مثل الهاتف والصورة.
    // Try to load extended profile from Firestore
    try {
      final data = await _userService.getCurrentUserProfile();

      if (data != null) {
        if (data.containsKey('displayName') &&
            _nameController.text.isEmpty) {
          _nameController.text = data['displayName'] ?? '';
        }
        if (data.containsKey('phone')) {
          _phoneController.text = data['phone'] ?? '';
        }
        if (data.containsKey('photoUrl') && _photoUrl.isEmpty) {
          _photoUrl = data['photoUrl'] ?? '';
        }
      }
    } catch (_) {
      // Firestore doc may not exist yet – that's fine
    }

    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  /// حفظ تعديلات الملف الشخصي في Firebase Auth وFirestore.
  Future<void> _saveProfile() async {
    // التحقق من صحة الحقول قبل تنفيذ الحفظ.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // تحديث اسم العرض في ملف المستخدم داخل Firebase Auth.
      // Update Firebase Auth profile
      await _authService.updateDisplayName(
        user: user,
        displayName: _nameController.text.trim(),
      );

      // حفظ الحقول الإضافية داخل مستند المستخدم في Firestore.
      // Save extended profile to Firestore
      await _userService.updateCurrentUserProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _email,
        photoUrl: _photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم حفظ المعلومات بنجاح',
              style: TextStyle(fontFamily: 'ElMessiri'),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ أثناء حفظ المعلومات',
              style: TextStyle(fontFamily: 'ElMessiri'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  /// بناء واجهة الملف الشخصي مع حالات التحميل والتحقق والحفظ.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final primary = AppTheme.getPrimary(isDark);

    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (_email.isNotEmpty ? _email.split('@').first : '');

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // عرض مؤشر تحميل حتى تكتمل قراءة بيانات المستخدم الأولية.
      body: _isInitialLoading
          ? Center(
              child: CircularProgressIndicator(color: primary),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ─── Profile Avatar Section ───────────────────
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.getPremiumShadow(isDark),
                        border: Border.all(
                          color:
                              dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.30),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          _photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildAvatarText(userName),
                                        ),
                                      )
                                    : _buildAvatarText(userName),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: surfaceColor,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName.isNotEmpty ? userName : 'مستخدم',
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 14,
                              color: textSecondary,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Form Fields Section ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.getPremiumShadow(isDark),
                        border: Border.all(
                          color:
                              dividerColor.withOpacity(isDark ? 0.25 : 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المعلومات الشخصية',
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Display Name
                          _buildFieldLabel('الاسم', isDark),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              color: textPrimary,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'أدخل اسمك',
                              isDark: isDark,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الاسم';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email (read-only)
                          _buildFieldLabel('البريد الإلكتروني', isDark),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              color: textSecondary,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'البريد الإلكتروني',
                              isDark: isDark,
                              prefixIcon: Icons.email_outlined,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 20),

                          // Phone
                          _buildFieldLabel('رقم الهاتف', isDark),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              color: textPrimary,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'أدخل رقم الهاتف',
                              isDark: isDark,
                              prefixIcon: Icons.phone_outlined,
                            ),
                            textDirection: TextDirection.ltr,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (value.trim().length < 7) {
                                  return 'رقم الهاتف غير صالح';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── Save Button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primary.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
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
                                'حفظ المعلومات',
                                style: TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// إنشاء الحرف الأول من الاسم كبديل عند غياب الصورة الشخصية.
  Widget _buildAvatarText(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
          fontFamily: 'ElMessiri',
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// بناء عنوان صغير موحد لكل حقل داخل النموذج.
  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'ElMessiri',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.getTextSecondary(isDark),
      ),
    );
  }
}
