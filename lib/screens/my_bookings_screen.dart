import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/core/constants/status_info.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/screens/booking_details_screen.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// شاشة حجوزاتي – تعرض جميع حجوزات المستخدم الحالي من Firestore.
/// MyBookingsScreen – shows all bookings for the current user in real-time.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // إذا المستخدم غير مسجل دخول
    if (user == null) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.login_rounded,
        message: 'يرجى تسجيل الدخول لعرض حجوزاتك',
      );
    }

    final bookingService = BookingService();

    return StreamBuilder<List<Booking>>(
      stream: bookingService.getUserBookingsStream(user.uid),
      builder: (context, snapshot) {
        // حالة التحميل الأولى فقط (لا توجد بيانات سابقة)
        // Show loading only on initial load with no prior data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.getPrimary(isDark),
            ),
          );
        }

        // استخدام البيانات الموجودة حتى لو حدث خطأ في البث
        // Prefer showing existing data even if the stream has an error
        // (e.g. first snapshot from cache succeeds, server response fails
        //  due to missing composite index — we still show the cached data)
        if (snapshot.hasError) {
          debugPrint('⚠️ Bookings stream error: ${snapshot.error}');
        }

        final bookings = snapshot.data ?? [];

        // حالة عدم وجود حجوزات
        if (bookings.isEmpty && !snapshot.hasError) {
          return _buildEmptyState(
            isDark: isDark,
            icon: Icons.calendar_today_rounded,
            message: 'لا توجد حجوزات بعد',
          );
        }

        // حالة الخطأ فقط عندما لا توجد بيانات إطلاقاً
        if (bookings.isEmpty && snapshot.hasError) {
          return _buildEmptyState(
            isDark: isDark,
            icon: Icons.error_outline_rounded,
            message: 'حدث خطأ أثناء تحميل الحجوزات',
          );
        }

        // عرض قائمة الحجوزات
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _BookingCard(
              booking: bookings[index],
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 44,
              color: AppTheme.getPrimary(isDark),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Booking Card Widget
// ───────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isDark;

  const _BookingCard({required this.booking, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final statusInfo = _getStatusInfo(booking.bookingStatus);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          BookingDetailsScreen.screenRoute,
          arguments: {'booking': booking},
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Title + Status ──────────────────────────
            Row(
              children: [
                // أيقونة الخدمة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                // عنوان الخدمة
                Expanded(
                  child: Text(
                    booking.serviceTitle,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // شارة الحالة
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusInfo.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: dividerColor.withOpacity(0.5)),
            const SizedBox(height: 14),
            // ── Details Row ─────────────────────────────────────
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${booking.selectedDate.year}/${booking.selectedDate.month.toString().padLeft(2, '0')}/${booking.selectedDate.day.toString().padLeft(2, '0')}',
                  textSecondary: textSecondary,
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  text: booking.selectedTime,
                  textSecondary: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoChip(
              icon: Icons.location_on_rounded,
              text: booking.address,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryColor.withOpacity(0.7)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 13,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  StatusInfo _getStatusInfo(String status) {
    return StatusInfo.fromBookingStatus(status);
  }
}
