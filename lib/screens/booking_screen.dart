import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// شاشة الحجز – تتيح للمستخدم اختيار التاريخ والوقت وإدخال العنوان وملاحظات.
/// BookingScreen – allows the user to pick date/time, enter address & notes,
/// then confirm the booking.
/// شاشة الحجز، وتسمح للمستخدم باختيار الموعد وإرسال طلب الحجز للخدمة.
class BookingScreen extends StatefulWidget {
  static const screenRoute = '/booking';

  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  /// مفتاح النموذج ومتحكمات الحقول النصية الخاصة بالعناوين والملاحظات.
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  /// خدمة الحجوزات المسؤولة عن إنشاء الحجز في Firestore.
  final BookingService _bookingService = BookingService();

  /// القيم المختارة للموعد وحالة إرسال الطلب.
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  /// التخلص من المتحكمات عند إغلاق الشاشة.
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Date Picker ──────────────────────────────────────────────────
  /// فتح منتقي التاريخ لتحديد موعد تنفيذ الخدمة.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ─── Time Picker ──────────────────────────────────────────────────
  /// فتح منتقي الوقت لاختيار ساعة الحجز.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // ─── Submit Booking ───────────────────────────────────────────────
  /// إنشاء طلب الحجز بعد التحقق من الموعد والبيانات المطلوبة.
  Future<void> _submitBooking(Service service, String? categoryName) async {
    // التحقق من اختيار التاريخ والوقت
    // التحقق من اختيار التاريخ والوقت قبل إنشاء الطلب.
    if (_selectedDate == null) {
      _showError('يرجى اختيار تاريخ الحجز');
      return;
    }
    if (_selectedTime == null) {
      _showError('يرجى اختيار وقت الحجز');
      return;
    }
    // التحقق من صحة الحقول النصية
    // التحقق من الحقول النصية مثل العنوان قبل الحفظ.
    if (!_formKey.currentState!.validate()) return;

    // التحقق من تسجيل الدخول
    // لا يمكن إنشاء الحجز بدون مستخدم مسجل الدخول.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('يرجى تسجيل الدخول أولاً لإتمام الحجز');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // تحويل الوقت إلى نص
      // تحويل الوقت المختار إلى صيغة نصية مناسبة للتخزين والعرض.
      final timeString =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      // تجهيز نموذج الحجز الكامل قبل حفظه في Firestore.
      final booking = Booking(
        userId: user.uid,
        userName: user.displayName ?? user.email?.split('@').first ?? 'عميل',
        serviceId: service.id,
        serviceTitle: service.title,
        categoryId: service.categoryId,
        providerId: service.providerId, // ربط الحجز بمزوّد الخدمة
        selectedDate: _selectedDate!,
        selectedTime: timeString,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        initialPrice: service.startingPrice,
        currency: service.currency,
      );

      // تنفيذ عملية الحفظ الفعلية لطلب الحجز.
      await _bookingService.createBooking(booking);

      if (!mounted) return;

      // عرض رسالة نجاح والعودة للشاشة السابقة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تأكيد الحجز بنجاح! 🎉',
            style: TextStyle(fontFamily: 'ElMessiri'),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showError('حدث خطأ أثناء الحجز. يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// عرض رسالة خطأ موحدة في أسفل الشاشة.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'ElMessiri')),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────
  @override
  /// بناء واجهة الحجز مع النموذج وحقول الموعد والتأكيد.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // استقبال الخدمة المختارة واسم التصنيف من الشاشة السابقة.
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final service = args?['service'] as Service?;
    final categoryName = args?['categoryName'] as String?;

    // إظهار حالة بديلة إذا لم تصل بيانات الخدمة بشكل صحيح.
    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('حجز الخدمة')),
        body: const Center(
          child: Text('لم يتم العثور على بيانات الخدمة'),
        ),
      );
    }

    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('حجز الخدمة'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Service Info Card ────────────────────────────────
              _buildServiceInfoCard(
                service: service,
                categoryName: categoryName,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                dividerColor: dividerColor,
              ),
              const SizedBox(height: 24),

              // ── Section Title: Booking Details ──────────────────
              Text(
                'تفاصيل الحجز',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Date Picker ─────────────────────────────────────
              _buildPickerTile(
                icon: Icons.calendar_today_rounded,
                label: 'تاريخ الحجز',
                value: _selectedDate != null
                    ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}'
                    : 'اختر التاريخ',
                onTap: _pickDate,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                dividerColor: dividerColor,
                isSelected: _selectedDate != null,
              ),
              const SizedBox(height: 12),

              // ── Time Picker ─────────────────────────────────────
              _buildPickerTile(
                icon: Icons.access_time_rounded,
                label: 'وقت الحجز',
                value: _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'اختر الوقت',
                onTap: _pickTime,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                dividerColor: dividerColor,
                isSelected: _selectedTime != null,
              ),
              const SizedBox(height: 16),

              // ── Address Field ───────────────────────────────────
              TextFormField(
                controller: _addressController,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  color: textPrimary,
                ),
                decoration: AppTheme.inputDecoration(
                  label: 'العنوان',
                  isDark: isDark,
                  prefixIcon: Icons.location_on_rounded,
                  hintText: 'أدخل عنوان الموقع',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال العنوان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Notes Field (optional) ──────────────────────────
              TextFormField(
                controller: _notesController,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  color: textPrimary,
                ),
                maxLines: 3,
                decoration: AppTheme.inputDecoration(
                  label: 'ملاحظات (اختياري)',
                  isDark: isDark,
                  prefixIcon: Icons.notes_rounded,
                  hintText: 'أي تفاصيل إضافية...',
                ),
              ),
              const SizedBox(height: 32),

              // ── Confirm Button ──────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitBooking(service, categoryName),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSubmitting ? 'جارٍ الحجز...' : 'تأكيد الحجز',
                    style: const TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor:
                        isDark ? AppTheme.darkScaffoldBg : Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Service Info Card ──────────────────────────────────────────
  /// بناء بطاقة مختصرة تعرض معلومات الخدمة قبل تأكيد الحجز.
  Widget _buildServiceInfoCard({
    required Service service,
    required String? categoryName,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.getPremiumShadow(isDark),
        border: Border.all(
          color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // أيقونة الخدمة
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          // بيانات الخدمة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (categoryName != null && categoryName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category_rounded,
                          size: 16, color: textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 16, color: textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        service.providerName,
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Picker Tile (reusable for date & time) ─────────────────────
  /// بناء عنصر قابل للنقر لاختيار التاريخ أو الوقت بصيغة موحدة.
  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.5)
                : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? textPrimary : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
