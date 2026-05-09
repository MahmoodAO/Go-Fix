import 'package:flutter/material.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/core/constants/status_info.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// شاشة تفاصيل الحجز – تعرض كل معلومات حجز واحد.
/// BookingDetailsScreen – shows full details of a single booking.
/// شاشة تفاصيل الحجز، وتعرض جميع معلومات الحجز المختار بشكل منظم.
class BookingDetailsScreen extends StatelessWidget {
  static const screenRoute = '/booking-details';

  const BookingDetailsScreen({super.key});

  @override
  /// بناء شاشة التفاصيل بعد قراءة الحجز المرسل عبر المسار.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // استلام كائن الحجز المرسل من الشاشة السابقة عبر المسار.
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final booking = args?['booking'] as Booking?;

    // عرض حالة بديلة إذا لم تصل بيانات الحجز بشكل صحيح.
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: const Center(child: Text('لم يتم العثور على بيانات الحجز')),
      );
    }

    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final statusInfo = _getStatusInfo(booking.bookingStatus);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Badge ────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: statusInfo.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, size: 18, color: statusInfo.color),
                    const SizedBox(width: 8),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: statusInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Service Info Card ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      booking.serviceTitle,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Booking Details Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل الموعد',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'التاريخ',
                    value:
                        '${booking.selectedDate.year}/${booking.selectedDate.month.toString().padLeft(2, '0')}/${booking.selectedDate.day.toString().padLeft(2, '0')}',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildDivider(dividerColor),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'الوقت',
                    value: booking.selectedTime,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildDivider(dividerColor),
                  _buildDetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'العنوان',
                    value: booking.address,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  if (booking.notes.isNotEmpty) ...[
                    _buildDivider(dividerColor),
                    _buildDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'ملاحظات',
                      value: booking.notes,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Timestamps Card ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.getPremiumShadow(isDark),
                border: Border.all(
                  color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات إضافية',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'تاريخ الإنشاء',
                    value: _formatDateTime(booking.createdAt),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  _buildDivider(dividerColor),
                  _buildDetailRow(
                    icon: Icons.update_rounded,
                    label: 'آخر تحديث',
                    value: _formatDateTime(booking.updatedAt),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  if (booking.categoryId.isNotEmpty) ...[
                    _buildDivider(dividerColor),
                    _buildDetailRow(
                      icon: Icons.category_rounded,
                      label: 'معرّف التصنيف',
                      value: booking.categoryId,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Placeholder for future actions (cancel, reorder) ─
            // يمكن إضافة أزرار إلغاء أو إعادة حجز هنا لاحقاً
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────
  /// بناء صف معلومات موحد لعرض أي قيمة ضمن تفاصيل الحجز.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء فاصل بصري بين عناصر التفاصيل.
  Widget _buildDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: color.withOpacity(0.5)),
    );
  }

  /// تنسيق التاريخ والوقت بشكل نصي مناسب للعرض.
  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// تحويل حالة الحجز إلى بيانات عرض موحدة من حيث النص واللون والأيقونة.
  StatusInfo _getStatusInfo(String status) {
    return StatusInfo.fromBookingStatus(status);
  }
}
