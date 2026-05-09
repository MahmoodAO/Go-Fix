import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homemate/models/category.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/services/category_service.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/core/utils/price_utils.dart';

/// شاشة إضافة أو تعديل خدمة، وتدير إدخال بيانات الخدمة وحفظها في Firestore.
class AddService extends StatefulWidget {
  final Service? serviceToEdit;

  const AddService({super.key, this.serviceToEdit});

  @override
  State<AddService> createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  /// مفتاح النموذج للتحقق من صحة البيانات قبل الإرسال.
  final _formKey = GlobalKey<FormState>();
  /// خدمة الخدمات المسؤولة عن إنشاء الخدمة أو تحديثها.
  final ServiceService _serviceService = ServiceService();

  /// قائمة التصنيفات المحمّلة من Firestore والتصنيف المختار حاليًا.
  List<Category> _categories = [];
  Category? _selectedCategory;
  /// متغيرات حالة الإرسال وبيانات المزود الظاهرة في الواجهة.
  bool _isSubmitting = false;
  String _providerDisplayName = '';
  String _providerEmail = '';

  /// متحكمات حقول إدخال بيانات الخدمة.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startingPriceController =
      TextEditingController();

  @override
  /// تحميل التصنيفات وهوية مزود الخدمة وملء الحقول عند التعديل.
  void initState() {
    super.initState();
    _fetchCategories();
    _loadProviderIdentity();

    // عند تعديل خدمة موجودة يتم تعبئة الحقول الحالية لعرضها في النموذج.
    if (widget.serviceToEdit != null) {
      final service = widget.serviceToEdit!;
      _titleController.text = service.title;
      _descriptionController.text = service.description;
      _phoneController.text = service.phone;
      _locationController.text = service.location;
      if (service.startingPrice != null) {
        _startingPriceController.text =
            formatPriceNumber(service.startingPrice!);
      }
    }
  }

  /// جلب التصنيفات من Firestore لإتاحتها داخل قائمة الاختيار.
  Future<void> _fetchCategories() async {
    try {
      final fetched = await CategoryService().getCategories();
      if (!mounted) return;

      // حفظ التصنيفات محليًا مع إعادة تحديد التصنيف إذا كانت الشاشة في وضع التعديل.
      setState(() {
        _categories = fetched;
        if (widget.serviceToEdit != null) {
          try {
            _selectedCategory = _categories.firstWhere(
              (category) => category.id == widget.serviceToEdit!.categoryId,
            );
          } catch (_) {}
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching categories: $e');
      }
    }
  }

  /// تحميل هوية مزود الخدمة الحالية من Auth وFirestore لعرضها أعلى النموذج.
  Future<void> _loadProviderIdentity() async {
    final user = FirebaseAuth.instance.currentUser;

    // عرض بيانات بديلة مباشرة حتى قبل اكتمال قراءة الهوية النهائية.
    if (mounted) {
      setState(() {
        _providerDisplayName = _buildLocalProviderFallback(user);
        _providerEmail = user?.email?.trim() ?? '';
      });
    }

    if (user == null) return;

    try {
      // قراءة الاسم النهائي من Firestore إن توفر لإظهاره بشكل معتمد في الخدمة.
      final identity = await _serviceService.resolveCurrentProviderIdentity();
      if (!mounted) return;

      setState(() {
        _providerDisplayName = identity.displayName;
        _providerEmail = identity.email;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resolving provider identity: $e');
      }
    }
  }

  /// إنشاء اسم بديل محلي للمزوّد عند غياب الاسم المخزن في الملف الشخصي.
  String _buildLocalProviderFallback(User? user) {
    final authName = user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Service Provider';
  }

  @override
  /// التخلص من المتحكمات عند إغلاق الشاشة.
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _startingPriceController.dispose();
    super.dispose();
  }

  /// حفظ النموذج بعد التحقق من البيانات وإنشاء الخدمة أو تحديثها.
  Future<void> _saveForm() async {
    // التحقق من صحة جميع الحقول قبل بدء الحفظ.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // التحقق من وجود مستخدم مسجل قبل السماح بإضافة خدمة.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول لإضافة خدمة')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      // تحليل السعر كنص وتحويله إلى قيمة رقمية صالحة للحفظ.
      final startingPrice = parsePriceValue(_startingPriceController.text.trim());

      // منع الحفظ إذا لم يتم اختيار تصنيف للخدمة.
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار تصنيف الخدمة')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (phone.length < 7 || phone.length > 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الهاتف غير صالح')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (startingPrice == null || startingPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال سعر ابتدائي صالح')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // التمييز بين إنشاء خدمة جديدة وتحديث خدمة موجودة.
      if (widget.serviceToEdit != null) {
        await _serviceService.updateProviderService(
          serviceId: widget.serviceToEdit!.id,
          categoryId: _selectedCategory!.id,
          title: title,
          description: description,
          phone: phone,
          location: location,
          startingPrice: startingPrice,
        );
      } else {
        await _serviceService.createProviderService(
          categoryId: _selectedCategory!.id,
          title: title,
          description: description,
          phone: phone,
          location: location,
          startingPrice: startingPrice,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.serviceToEdit != null
                ? 'تم تعديل الخدمة بنجاح'
                : 'تم طلب إضافة الخدمة بنجاح',
          ),
        ),
      );
      // إرجاع نتيجة نجاح للشاشة السابقة بعد اكتمال العملية.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في الإضافة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// بناء عنوان موحد للأقسام الرئيسية داخل النموذج.
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.getPrimary(isDark), size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة تعرض هوية مزود الخدمة التي ستربط بالخدمة عند الحفظ.
  Widget _buildProviderIdentityCard(bool isDark) {
    final providerName = _providerDisplayName.trim().isNotEmpty
        ? _providerDisplayName.trim()
        : 'غير متوفر حالياً';
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final textHint = AppTheme.getTextHint(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getElevatedSurface(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.getDividerColor(isDark).withOpacity(
            isDark ? 0.5 : 0.9,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مزود الخدمة',
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 13,
                        color: textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerName,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (_providerEmail.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _providerEmail,
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'يتم استخدام اسم حسابك تلقائيًا',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  /// بناء واجهة إضافة الخدمة مع حالات التحميل والتحقق والإرسال.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      appBar: AppBar(
        title: Text(
          widget.serviceToEdit != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة',
          style: const TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // عرض مؤشر تحميل حتى تكتمل قراءة التصنيفات المطلوبة للنموذج.
      body: _categories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(isDark),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.premiumShadow(isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'المعلومات الأساسية',
                            Icons.info_outline_rounded,
                            isDark,
                          ),
                          DropdownButtonFormField<Category>(
                            dropdownColor: AppTheme.getSurface(isDark),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.getTextHint(isDark),
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'الفئة',
                              isDark: isDark,
                              prefixIcon: Icons.category_outlined,
                            ),
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              color: AppTheme.getTextPrimary(isDark),
                            ),
                            value: _selectedCategory,
                            hint: Text(
                              'اختر الفئة المناسبة',
                              style: TextStyle(
                                fontFamily: 'ElMessiri',
                                color: AppTheme.getTextHint(isDark),
                              ),
                            ),
                            items: _categories.map((Category category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontFamily: 'ElMessiri',
                                    color: AppTheme.getTextPrimary(isDark),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            }).toList(),
                            onChanged: (Category? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'يرجى اختيار الفئة' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildProviderIdentityCard(isDark),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _startingPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: AppTheme.inputDecoration(
                              label: 'السعر الابتدائي',
                              isDark: isDark,
                              prefixIcon: Icons.payments_outlined,
                            ).copyWith(
                              hintText: 'مثال: 10',
                              suffixText: 'دنانير',
                              suffixStyle: TextStyle(
                                fontFamily: 'ElMessiri',
                                color: AppTheme.getTextHint(isDark),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // التحقق من صحة السعر الابتدائي قبل الإرسال إلى Firestore.
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'أدخل السعر الابتدائي';
                              }

                              final parsed = parsePriceValue(trimmed);
                              if (parsed == null) {
                                return 'أدخل رقماً صالحاً';
                              }

                              if (parsed <= 0) {
                                return 'يجب أن يكون السعر أكبر من صفر';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(isDark),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.premiumShadow(isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'تفاصيل الخدمة',
                            Icons.design_services_outlined,
                            isDark,
                          ),
                          TextFormField(
                            controller: _titleController,
                            textAlign: TextAlign.right,
                            decoration: AppTheme.inputDecoration(
                              label: 'عنوان الخدمة',
                              isDark: isDark,
                              prefixIcon: Icons.title_rounded,
                            ).copyWith(
                              hintText: 'مثال: أعمال صيانة وسباكة عامة',
                            ),
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'ادخل عنوان الخدمة'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            textAlign: TextAlign.right,
                            maxLines: 4,
                            decoration: AppTheme.inputDecoration(
                              label: 'الوصف الشامل',
                              isDark: isDark,
                            ).copyWith(
                              hintText:
                                  'اكتب تفاصيل الخدمة والمهام التي تقدمها...',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'ادخل وصف الخدمة'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurface(isDark),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.premiumShadow(isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'التواصل والموقع',
                            Icons.contact_phone_outlined,
                            isDark,
                          ),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: AppTheme.inputDecoration(
                              label: 'رقم الهاتف',
                              isDark: isDark,
                              prefixIcon: Icons.phone_in_talk_outlined,
                            ).copyWith(
                              hintText: '05xxxxxxxx',
                              hintTextDirection: TextDirection.ltr,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'ادخل رقم الهاتف';
                              }
                              if (value.length < 7) {
                                return 'رقم الهاتف يجب أن يكون 7 أرقام على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _locationController,
                            textAlign: TextAlign.right,
                            decoration: AppTheme.inputDecoration(
                              label: 'الموقع',
                              isDark: isDark,
                              prefixIcon: Icons.location_on_outlined,
                            ).copyWith(
                              hintText: 'مثال: الرياض، حي الياسمين',
                            ),
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'يرجى اختيار موقعك'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _categories.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                decoration: BoxDecoration(
                  color: AppTheme.getScaffoldBg(isDark),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getScaffoldBg(isDark).withOpacity(0.9),
                      blurRadius: 24,
                      spreadRadius: 24,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _saveForm,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'إرسال الطلب',
                                style: TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: AppTheme.getTextHint(isDark),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'سيتم مراجعة الطلب من قبل الإدارة لضمان الجودة',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 12,
                            color: AppTheme.getTextHint(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
