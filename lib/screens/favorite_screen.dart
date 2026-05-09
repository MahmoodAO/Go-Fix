import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homemate/core/widgets/services_item.dart';
import 'package:homemate/services/favorites_services.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:homemate/core/theme/theme_provider.dart';
import 'package:homemate/core/utils/price_utils.dart';

/// شاشة المفضلة، وتعرض الخدمات التي حفظها المستخدم في قائمته الخاصة.
class FavoriteServicesScreen extends StatefulWidget {
  const FavoriteServicesScreen({super.key});

  @override
  State<FavoriteServicesScreen> createState() => _FavoriteServicesScreenState();
}

class _FavoriteServicesScreenState extends State<FavoriteServicesScreen> {
  /// آخر قائمة معرّفات مفضلة تم تحميلها لتجنب إعادة الجلب دون داعٍ.
  List<String>? _lastFavoriteIds;
  /// المستقبل الذي يحمل تفاصيل الخدمات المفضلة بعد جلب معرّفاتها.
  Future<List<QueryDocumentSnapshot>>? _servicesFuture;

  /// Fetch only the services whose IDs are in [ids], batching by 10 (Firestore whereIn limit).
  /// جلب الخدمات المفضلة على دفعات بما يتوافق مع حد whereIn في Firestore.
  Future<List<QueryDocumentSnapshot>> _fetchFavoriteServices(List<String> ids) async {
    final List<QueryDocumentSnapshot> results = [];
    final batches = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      batches.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }
    // قراءة مستندات الخدمات المطابقة لمعرّفات المفضلة فقط.
    for (final batch in batches) {
      final snap = await FirebaseFirestore.instance
          .collection('services')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(snap.docs);
    }
    return results;
  }

  /// Returns true if the two ID lists contain the same set of IDs.
  /// مقارنة قائمتين من المعرّفات لتحديد الحاجة إلى إعادة التحميل.
  bool _idsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = Set<String>.from(a);
    final setB = Set<String>.from(b);
    return setA.containsAll(setB) && setB.containsAll(setA);
  }

  @override
  /// بناء شاشة المفضلة مع StreamBuilder للمعرّفات وFutureBuilder لتفاصيل الخدمات.
  Widget build(BuildContext context) {
    final FavoritesService favoritesService = FavoritesService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // الاستماع المباشر لتغييرات المفضلة الخاصة بالمستخدم الحالي.
      body: StreamBuilder<List<String>>(
        stream: favoritesService.getFavoriteServiceIdsStream(),
        builder: (context, favSnapshot) {
          if (favSnapshot.connectionState == ConnectionState.waiting && !favSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          if (favSnapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل المفضلة',
                style: TextStyle(fontFamily: 'ElMessiri', fontSize: 16),
              ),
            );
          }

          final favoriteIds = favSnapshot.data ?? [];

          if (favoriteIds.isEmpty) {
            _lastFavoriteIds = [];
            _servicesFuture = null;
            return _buildEmptyState(context);
          }

          // Only re-fetch when the set of IDs actually changes
          // إعادة جلب تفاصيل الخدمات فقط عند تغير مجموعة المعرّفات فعليًا.
          if (_lastFavoriteIds == null || !_idsEqual(_lastFavoriteIds!, favoriteIds)) {
            _lastFavoriteIds = List<String>.from(favoriteIds);
            _servicesFuture = _fetchFavoriteServices(favoriteIds);
          }

          // بعد وصول المعرّفات يتم جلب بيانات الخدمات الكاملة لعرضها في القائمة.
          return FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _servicesFuture,
            builder: (context, servicesSnapshot) {
              if (servicesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
              }

              if (servicesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل الخدمات',
                    style: TextStyle(fontFamily: 'ElMessiri', fontSize: 16),
                  ),
                );
              }

              // استبعاد الخدمات غير المقبولة حتى لا تظهر عناصر غير متاحة للمستخدم.
              final favoriteServices = (servicesSnapshot.data ?? [])
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['approvalStatus'] ?? data['status'] ?? 'inactive';
                    return status == 'accepted';
                  })
                  .toList();

              if (favoriteServices.isEmpty) {
                return _buildEmptyState(context);
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final service = favoriteServices[index];
                          final serviceId = service.id;
                          final data = service.data() as Map<String, dynamic>;

                          return ServicesItem(
                            id: serviceId,
                            title: data['title'] ?? 'No Title',
                            phone: data['phone'] ?? 'N/A',
                            location: data['location'] ?? 'Unknown',
                            providerName: data['providerName'] ?? '',
                            averageRating: data.containsKey('averageRating')
                                ? (data['averageRating'] as num).toDouble()
                                : 0.0,
                            totalRatings: data.containsKey('totalRatings')
                                ? (data['totalRatings'] as num).toInt()
                                : 0,
                            startingPrice: parsePriceValue(data['startingPrice']),
                            currency: readCurrencyCode(data['currency']),
                            isFavorite: true,
                            onToggleFavorite: () async {
                              await favoritesService.removeFromFavorites(serviceId);
                            },
                          );
                        },
                        childCount: favoriteServices.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// بناء واجهة بديلة عندما لا توجد خدمات مفضلة محفوظة.
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              shape: BoxShape.circle,
              boxShadow: AppTheme.premiumShadow(isDark),
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'لا توجد خدمات مفضلة',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'تصفح الخدمات وأضف ما يعجبك إلى المفضلة للعودة إليها لاحقاً بكل سهولة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
