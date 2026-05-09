import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/core/utils/local_storage_service.dart';
import 'package:homemate/core/utils/price_utils.dart';
import 'package:homemate/services/auth_service.dart';

/// شاشة الإدارة، وتتيح مراجعة الخدمات المعلقة وقبولها أو رفضها وإصدار التقارير.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  /// خدمة المصادقة المستخدمة لتسجيل خروج المشرف.
  final AuthService _authService = AuthService();

  /// تحديث حالة اعتماد الخدمة داخل Firestore بحسب قرار الإدارة.
  Future<void> _updateServiceStatus(String serviceId, String status) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('services').doc(serviceId);

      // تجهيز التعديلات الأساسية على حالة اعتماد الخدمة.
      final updates = <String, dynamic>{'approvalStatus': status};

      // عند القبول يتم التأكد من وجود حقول التقييم الافتراضية اللازمة لاحقًا.
      if (status == 'accepted') {
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data() as Map<String, dynamic>?;
          if (data != null) {
            if (!data.containsKey('averageRating')) {
              updates['averageRating'] = 0.0;
            }
            if (!data.containsKey('totalRatings')) {
              updates['totalRatings'] = 0;
            }
          }
        }
      }

      await docRef.update(updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'تم قبول الخدمة بنجاح'
                : 'تم رفض الخدمة',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating service: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في تحديث حالة الخدمة'),
        ),
      );
    }
  }

  /// تسجيل خروج المشرف ومسح حالة الجلسة المحلية.
  Future<void> _logout() async {
    await _authService.signOut();
    await LocalStorageService.setLoggedIn(false);
    await LocalStorageService.setUserRole('customer');
    if (mounted) Navigator.pushReplacementNamed(context, 'login');
  }

  /// عرض نافذة تأكيد قبل الانتقال إلى شاشة التقارير.
  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text(
          'إصدار تقرير',
          style: TextStyle(fontFamily: 'ElMessiri'),
        ),
        content: const Text(
          'هل تود الانتقال لصفحة التقارير؟',
          style: TextStyle(fontFamily: 'ElMessiri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, 'generate_report');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            child: const Text(
              'عرض التقرير',
              style: TextStyle(fontFamily: 'ElMessiri'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  /// بناء واجهة الإدارة مع بث مباشر للخدمات المعلقة.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الخدمات المعلقة',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'قم بمراجعة الطلبات وقبولها أو رفضها',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // الاستماع المباشر للخدمات التي ما زالت بانتظار قرار الإدارة.
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('approvalStatus', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                final services = snapshot.data!.docs;

                if (services.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final doc = services[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildServiceCard(doc.id, data, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReport,
        icon: const Icon(Icons.assessment_rounded),
        label: const Text(
          'إصدار تقرير',
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// بناء بطاقة خدمة معلقة مع أزرار القبول والرفض.
  Widget _buildServiceCard(
    String docId,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.premiumShadow(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppTheme.warningColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['providerName'] ?? 'مقدم الخدمة غير معروف',
                        style: const TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'قيد المراجعة',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['title'] ?? 'خدمة بدون عنوان',
              style: const TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      buildStartingPriceLabel(
                        context,
                        parsePriceValue(data['startingPrice']),
                        currency: readCurrencyCode(data['currency']),
                      ),
                      style: const TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data['description'] ?? 'بدون وصف',
              style: const TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _updateServiceStatus(docId, 'rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'رفض',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateServiceStatus(docId, 'accepted'),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'قبول',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء حالة فارغة عندما لا توجد خدمات بانتظار المراجعة.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد طلبات معلقة',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'جميع الطلبات تمت مراجعتها',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 14,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
