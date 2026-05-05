import 'package:flutter/material.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/models/status_info.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/theme/app_theme.dart';

/// شاشة تفاصيل الحجز لمزوّد الخدمة – عرض تفاصيل الحجز مع أزرار قبول/رفض/إكمال.
/// Provider Booking Details Screen – view full booking details and manage status.
class ProviderBookingDetailsScreen extends StatefulWidget {
  static const screenRoute = '/provider_booking_details';

  const ProviderBookingDetailsScreen({super.key});

  @override
  State<ProviderBookingDetailsScreen> createState() =>
      _ProviderBookingDetailsScreenState();
}

class _ProviderBookingDetailsScreenState
    extends State<ProviderBookingDetailsScreen> {
  bool _isActioning = false;

  Future<void> _updateStatus(Booking booking, String newStatus) async {
    setState(() => _isActioning = true);
    try {
      final bookingService = BookingService();
      switch (newStatus) {
        case 'accepted':
          await bookingService.acceptBooking(booking.id);
          break;
        case 'rejected':
          await bookingService.rejectBooking(booking.id);
          break;
        case 'completed':
          await bookingService.updateBookingStatus(booking.id, 'completed');
          break;
        case 'in_progress':
          await bookingService.updateBookingStatus(booking.id, 'in_progress');
          break;
      }
      if (mounted) {
        final labels = {
          'accepted': 'تم قبول الطلب',
          'rejected': 'تم رفض الطلب',
          'completed': 'تم إكمال الطلب',
          'in_progress': 'بدأ التنفيذ',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              labels[newStatus] ?? 'تم التحديث',
              style: const TextStyle(fontFamily: 'ElMessiri'),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true); // pop with result to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking = ModalRoute.of(context)?.settings.arguments as Booking?;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: const Center(child: Text('لم يتم العثور على بيانات الحجز')),
      );
    }

    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final primary = AppTheme.getPrimary(isDark);
    final statusInfo = _getStatusInfo(booking.bookingStatus);

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      appBar: AppBar(
        title: const Text(
          'تفاصيل الطلب',
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppTheme.darkElevated, AppTheme.darkSurface],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20)),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Badge ─────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: statusInfo.color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                      color: statusInfo.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, color: statusInfo.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Service Info Card ────────────────────
            _buildCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('معلومات الخدمة', Icons.design_services_rounded, primary, textPrimary),
                  const SizedBox(height: 16),
                  _buildDetailRow('الخدمة', booking.serviceTitle, textPrimary, textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Booking Details Card ─────────────────
            _buildCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('تفاصيل الحجز', Icons.event_note_rounded, primary, textPrimary),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'التاريخ',
                    '${booking.selectedDate.year}/${booking.selectedDate.month.toString().padLeft(2, '0')}/${booking.selectedDate.day.toString().padLeft(2, '0')}',
                    textPrimary,
                    textSecondary,
                  ),
                  _buildDetailRow('الوقت', booking.selectedTime, textPrimary, textSecondary),
                  _buildDetailRow('العنوان', booking.address, textPrimary, textSecondary),
                  if (booking.notes.isNotEmpty)
                    _buildDetailRow('ملاحظات', booking.notes, textPrimary, textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Timestamps Card ──────────────────────
            _buildCard(
              isDark: isDark,
              surfaceColor: surfaceColor,
              dividerColor: dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('الأوقات', Icons.schedule_rounded, primary, textPrimary),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'تاريخ الإنشاء',
                    '${booking.createdAt.year}/${booking.createdAt.month.toString().padLeft(2, '0')}/${booking.createdAt.day.toString().padLeft(2, '0')} ${booking.createdAt.hour.toString().padLeft(2, '0')}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Action Buttons ───────────────────────
            ..._buildActionButtons(booking, isDark, primary),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(Booking booking, bool isDark, Color primary) {
    final status = booking.bookingStatus;
    final widgets = <Widget>[];

    if (status == 'pending') {
      widgets.addAll([
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isActioning ? null : () => _updateStatus(booking, 'accepted'),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('قبول الطلب', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isActioning ? null : () => _updateStatus(booking, 'rejected'),
            icon: const Icon(Icons.cancel_rounded, size: 20),
            label: const Text('رفض الطلب', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
      ]);
    } else if (status == 'accepted') {
      widgets.addAll([
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isActioning ? null : () => _updateStatus(booking, 'in_progress'),
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: const Text('بدء التنفيذ', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isActioning ? null : () => _updateStatus(booking, 'rejected'),
            icon: const Icon(Icons.cancel_rounded, size: 20),
            label: const Text('إلغاء', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
      ]);
    } else if (status == 'in_progress') {
      widgets.add(
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isActioning ? null : () => _updateStatus(booking, 'completed'),
            icon: const Icon(Icons.task_alt_rounded, size: 20),
            label: const Text('إكمال الطلب', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
      );
    }

    if (_isActioning) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCard({
    required bool isDark,
    required Color surfaceColor,
    required Color dividerColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.getPremiumShadow(isDark),
        border: Border.all(
          color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCardTitle(String title, IconData icon, Color primary, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 15,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    return StatusInfo.fromBookingStatus(status);
  }
}
