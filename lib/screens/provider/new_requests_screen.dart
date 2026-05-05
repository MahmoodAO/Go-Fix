import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/models/booking.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/widgets/provider_booking_card.dart';
import 'package:homemate/theme/app_theme.dart';

/// شاشة الطلبات الجديدة – تعرض فقط الحجوزات بحالة "pending".
/// New Requests Screen – shows ONLY pending bookings for the current provider.
class NewRequestsScreen extends StatelessWidget {
  const NewRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      appBar: AppBar(
        title: const Text(
          'طلبات جديدة',
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppTheme.darkElevated, AppTheme.darkSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: user == null
          ? _buildEmptyState(isDark, Icons.login_rounded,
              'يرجى تسجيل الدخول لعرض الطلبات')
          : StreamBuilder<List<Booking>>(
              stream:
                  BookingService().getProviderBookingsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                      '⚠️ New requests stream error: ${snapshot.error}');
                }

                // Filter to pending only
                final pendingBookings = (snapshot.data ?? [])
                    .where((b) => b.bookingStatus == 'pending')
                    .toList();

                if (pendingBookings.isEmpty) {
                  return _buildEmptyState(
                    isDark,
                    Icons.inbox_rounded,
                    'لا يوجد طلبات جديدة',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: pendingBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return ProviderBookingCard(
                      booking: pendingBookings[index],
                      isDark: isDark,
                    );
                  },
                );
              },
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
