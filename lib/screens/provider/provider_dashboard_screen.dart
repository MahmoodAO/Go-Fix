import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/services/booking_service.dart';
import 'package:homemate/screens/provider/provider_services_screen.dart';
import 'package:homemate/screens/provider/new_requests_screen.dart';

/// لوحة تحكم مزوّد الخدمة – عرض ملخص سريع وأزرار إجراءات.
/// Provider Dashboard – summary stats and quick actions.
/// لوحة تحكم مزود الخدمة، وتعرض ملخص الإحصاءات وأزرار الوصول السريع.
class ProviderDashboardScreen extends StatefulWidget {
  /// Callback to switch to a tab in the parent ProviderTabsScreen
  final void Function(int tabIndex)? onSwitchTab;

  const ProviderDashboardScreen({super.key, this.onSwitchTab});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  /// إحصاءات الخدمات والطلبات المعروضة في البطاقات العلوية.
  int _totalServices = 0;
  int _pendingServices = 0;
  int _pendingBookings = 0;
  bool _isLoading = true;
  StreamSubscription? _bookingSub;
  StreamSubscription? _servicesSub;

  @override
  /// بدء تحميل الإحصاءات فور فتح لوحة التحكم.
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  /// إلغاء الاشتراكات المباشرة عند إغلاق الشاشة.
  void dispose() {
    _bookingSub?.cancel();
    _servicesSub?.cancel();
    super.dispose();
  }

  /// تحميل إحصاءات المزود بالاعتماد على بث مباشر للخدمات والحجوزات.
  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      _servicesSub?.cancel();
      _bookingSub?.cancel();

      // الاستماع لخدمات المزود لحساب الإجمالي وعدد الخدمات المعلقة.
      _servicesSub = ServiceService()
          .getProviderServicesStream(uid)
          .listen((services) {
        if (mounted) {
          setState(() {
            _totalServices = services.length;
            _pendingServices =
                services.where((s) => s.approvalStatus == 'pending').length;
            _isLoading = false;
          });
        }
      }, onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      });

      // الاستماع لحجوزات المزود لحساب عدد الطلبات الجديدة المعلقة.
      _bookingSub =
          BookingService().getProviderBookingsStream(uid).listen((bookings) {
        if (mounted) {
          setState(() {
            _pendingBookings =
                bookings.where((b) => b.bookingStatus == 'pending').length;
          });
        }
      }, onError: (_) {});
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  /// بناء لوحة التحكم مع الإحصاءات والإجراءات السريعة.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? '';

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              onRefresh: () async {
                // إعادة تحميل الإحصاءات يدويًا عند السحب للتحديث.
                setState(() => _isLoading = true);
                await _loadStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ────────────────────────────
                    Text(
                      'مرحباً، $userName',
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إليك ملخص نشاطك اليوم',
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 15,
                        color: AppTheme.getTextSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Stats Cards (clickable) ────────────
                    LayoutBuilder(builder: (context, constraints) {
                      final cardW = (constraints.maxWidth - 24) / 3;
                      return Row(
                        children: [
                          SizedBox(
                            width: cardW,
                            child: _StatCard(
                              icon: Icons.design_services_rounded,
                              label: 'خدماتي',
                              value: '$_totalServices',
                              color: primary,
                              isDark: isDark,
                              onTap: () => widget.onSwitchTab?.call(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: cardW,
                            child: _StatCard(
                              icon: Icons.hourglass_top_rounded,
                              label: 'بانتظار القبول',
                              value: '$_pendingServices',
                              color: AppTheme.warningColor,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProviderServicesScreen(
                                            showPendingOnly: true),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: cardW,
                            child: _StatCard(
                              icon: Icons.receipt_long_rounded,
                              label: 'طلبات جديدة',
                              value: '$_pendingBookings',
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NewRequestsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),

                    // ── Quick Action: Add Service ──────────
                    GestureDetector(
                      onTap: () async {
                        // فتح شاشة إضافة خدمة ثم تحديث الإحصاءات بعد العودة.
                        await Navigator.of(context).pushNamed('addservice');
                        // تحديث الإحصائيات بعد العودة
                        _loadStats();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.darkElevated,
                                    AppTheme.darkSurface,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppTheme.primaryDark,
                                    AppTheme.primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : primary.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: isDark
                              ? Border.all(
                                  color: AppTheme.darkDivider.withOpacity(0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(isDark ? 0.08 : 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إضافة خدمة جديدة',
                                    style: TextStyle(
                                      fontFamily: 'ElMessiri',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'قدّم خدمتك للآلاف من العملاء',
                                    style: TextStyle(
                                      fontFamily: 'ElMessiri',
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Clickable Stat Card
// ───────────────────────────────────────────────────────────────────
/// بطاقة إحصائية قابلة للنقر تعرض قيمة مختصرة ضمن لوحة التحكم.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  /// بناء بطاقة الإحصاء مع دعم الضغط للتنقل إلى الشاشة المرتبطة.
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(isDark),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.getPremiumShadow(isDark),
          border: Border.all(
            color: AppTheme.getDividerColor(isDark)
                .withOpacity(isDark ? 0.35 : 0.7),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 11,
                color: AppTheme.getTextSecondary(isDark),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
