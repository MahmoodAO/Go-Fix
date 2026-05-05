import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/widgets/provider_booking_card.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// Provider Bookings Screen – shows ONLY accepted/rejected bookings (no pending).
class ProviderBookingsScreen extends StatefulWidget {
  final String? serviceId;
  const ProviderBookingsScreen({super.key, this.serviceId});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  // 'all' now means accepted + rejected (no pending)
  String _selectedFilter = 'all'; // 'all', 'accepted', 'rejected'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyState(isDark, Icons.login_rounded,
          'يرجى تسجيل الدخول لعرض الطلبات');
    }

    return StreamBuilder<List<Booking>>(
      stream: BookingService()
          .getProviderBookingsStream(user.uid, serviceId: widget.serviceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.getPrimary(isDark),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('⚠️ Provider bookings stream error: ${snapshot.error}');
        }

        // Exclude pending bookings entirely from this screen
        final allBookings = (snapshot.data ?? [])
            .where((b) => b.bookingStatus != 'pending')
            .toList();

        var bookings = allBookings;

        // Filter logic
        if (_selectedFilter != 'all') {
          bookings = allBookings
              .where((b) => b.bookingStatus == _selectedFilter)
              .toList();
        }

        return Column(
          children: [
            _buildFilterStrip(isDark),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (bookings.isEmpty && !snapshot.hasError) {
                    return _buildEmptyState(isDark, Icons.inbox_rounded,
                        'لا توجد طلبات حجز حالياً');
                  }

                  if (bookings.isEmpty && snapshot.hasError) {
                    return _buildEmptyState(isDark,
                        Icons.error_outline_rounded, 'حدث خطأ أثناء تحميل الطلبات');
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ProviderBookingCard(
                        booking: bookings[index],
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterStrip(bool isDark) {
    final filters = [
      {'value': 'all', 'label': 'الكل'},
      {'value': 'accepted', 'label': 'مقبولة'},
      {'value': 'rejected', 'label': 'مرفوضة'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                filter['label']!,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.getTextSecondary(isDark),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppTheme.getPrimary(isDark),
              backgroundColor:
                  isDark ? AppTheme.darkSurface : Colors.grey[200],
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['value']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, IconData icon, String message) {
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
            child: Icon(icon, size: 44, color: AppTheme.getPrimary(isDark)),
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
