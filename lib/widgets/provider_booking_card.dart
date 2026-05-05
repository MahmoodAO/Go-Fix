import 'package:flutter/material.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/core/constants/status_info.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/screens/provider/provider_booking_details_screen.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// Shared booking card widget used by both NewRequestsScreen and ProviderBookingsScreen.
class ProviderBookingCard extends StatefulWidget {
  final Booking booking;
  final bool isDark;
  final VoidCallback? onTap;

  const ProviderBookingCard({
    super.key,
    required this.booking,
    required this.isDark,
    this.onTap,
  });

  @override
  State<ProviderBookingCard> createState() => _ProviderBookingCardState();
}

class _ProviderBookingCardState extends State<ProviderBookingCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final s = BookingService();
      if (newStatus == 'accepted') {
        await s.acceptBooking(widget.booking.id);
      } else if (newStatus == 'rejected') {
        await s.rejectBooking(widget.booking.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(widget.isDark);
    final textPrimary = AppTheme.getTextPrimary(widget.isDark);
    final textSecondary = AppTheme.getTextSecondary(widget.isDark);
    final dividerColor = AppTheme.getDividerColor(widget.isDark);
    final statusInfo = StatusInfo.fromBookingStatus(widget.booking.bookingStatus);

    final displayName = (widget.booking.userName.isNotEmpty)
        ? widget.booking.userName
        : 'عميل';

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProviderBookingDetailsScreen(),
                settings: RouteSettings(arguments: widget.booking),
              ),
            );
          },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.getPremiumShadow(widget.isDark),
          border: Border.all(
            color: dividerColor.withOpacity(widget.isDark ? 0.35 : 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.serviceTitle,
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'من: $displayName',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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

            // ── Booking Details ─────────────────────────
            _buildInfoRow(
              Icons.calendar_today_rounded,
              '${widget.booking.selectedDate.year}/${widget.booking.selectedDate.month.toString().padLeft(2, '0')}/${widget.booking.selectedDate.day.toString().padLeft(2, '0')}',
              textSecondary,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              widget.booking.selectedTime,
              textSecondary,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on_rounded,
              widget.booking.address,
              textSecondary,
            ),
            if (widget.booking.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note_rounded,
                widget.booking.notes,
                textSecondary,
              ),
            ],

            // ── Action Buttons (if pending) ──────────────
            if (widget.booking.bookingStatus == 'pending') ...[
              const SizedBox(height: 16),
              if (_isUpdating)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('accepted'),
                        icon:
                            const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('قبول',
                            style: TextStyle(
                                fontFamily: 'ElMessiri',
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus('rejected'),
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        label: const Text('رفض',
                            style: TextStyle(
                                fontFamily: 'ElMessiri',
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            // ── Tap hint ─────────────────────────────────
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimary(widget.isDark),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.getPrimary(widget.isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 13,
              color: textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
