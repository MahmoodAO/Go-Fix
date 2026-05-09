import 'dart:async';
import 'package:flutter/material.dart';
import 'package:homemate/models/category.dart';
import 'package:homemate/core/widgets/category_item.dart';
import 'package:homemate/services/category_service.dart';
import 'package:homemate/core/utils/local_storage_service.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/core/widgets/services_item.dart';
import 'package:homemate/services/favorites_services.dart';
import 'package:homemate/core/utils/price_utils.dart';
import 'package:homemate/services/user_service.dart';

/// شاشة التصنيفات، وتعرض الفئات الرئيسية والخدمات المقترحة للمستخدم.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// المستقبل الخاص بتحميل التصنيفات وخدمة المستخدم لجلب البيانات المساندة.
  late Future<List<Category>> _categoriesFuture;
  final UserService _userService = UserService();
  /// اسم المستخدم الحالي ودوره لتخصيص الواجهة والصلاحيات.
  String _userName = '';
  String _userRole = 'customer'; // دور المستخدم الحالي

  @override
  /// تحميل التصنيفات وبيانات المستخدم الأولية عند فتح الشاشة.
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService().getCategories();
    _loadUserName();
    _loadUserRole();
  }

  /// تحديد اسم العرض الأنسب للمستخدم من Auth ثم Firestore ثم البريد الإلكتروني.
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // AuthWrapperScreen handles unauthenticated routing.
      // Just return without setting a name.
      return;
    }

    // تفضيل اسم العرض من Firebase Auth لأنه الأسرع والأكثر مباشرة.
    // 1. Prefer Firebase Auth displayName
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (mounted) setState(() => _userName = user.displayName!);
      return;
    }

    // محاولة قراءة الاسم من Firestore في حال غيابه من المصادقة.
    // 2. Try fetching from Firestore users collection
    try {
      final name = await _userService.getUserDisplayName(user.uid);
      if (name.isNotEmpty) {
        if (mounted) setState(() => _userName = name);
        return;
      }
    } catch (_) {}

    // استخدام بادئة البريد الإلكتروني كحل بديل أخير.
    // 3. Fallback to email prefix
    final email = user.email;
    if (email != null && email.contains('@')) {
      if (mounted) setState(() => _userName = email.split('@').first);
    } else {
      if (mounted) setState(() => _userName = 'ضيف');
    }
  }

  /// جلب دور المستخدم من التخزين المحلي
  /// جلب دور المستخدم من التخزين المحلي لتحديد الصلاحيات داخل الواجهة.
  Future<void> _loadUserRole() async {
    final role = await LocalStorageService.getUserRole();
    if (mounted) setState(() => _userRole = role);
  }

  @override
  /// بناء شاشة التصنيفات مع FutureBuilder والخدمات المقترحة والزر الخاص بالمزوّد.
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // انتظار التصنيفات من Firestore ثم عرض الشبكة أو حالات الخطأ والفراغ.
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final categories = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Greeting Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً، $_userName',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.headlineSmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ما الخدمة التي تبحث عنها اليوم؟',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Categories Grid
              if (categories.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return CategoryItem(
                          category.id,
                          category.name,
                          category.image,
                        );
                      },
                      childCount: categories.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                  ),
                ),

              // Recommended Services Section
              SliverToBoxAdapter(
                child: _buildRecommendedServices(context, isDark, primary),
              ),

              // Add Service CTA (Hero Banner)
              if (_userRole == 'provider')
                SliverToBoxAdapter(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: Container(
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
                              colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
                              color: AppTheme.darkDivider.withOpacity(0.5),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Decorative BG pattern
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.home_repair_service,
                            size: 140,
                            color: isDark
                                ? primary.withOpacity(0.08)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'هل تقدم خدمة احترافية؟',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : Colors.white,
                                  fontFamily: 'ElMessiri',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'انضم إلى منصتنا وقدم خدماتك للآلاف من العملاء في منطقتك.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : Colors.white70,
                                  fontFamily: 'ElMessiri',
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  // السماح بإضافة الخدمات لمزود الخدمة فقط.
                                  if (_userRole == 'provider') {
                                    Navigator.of(context).pushNamed('addservice');
                                  } else {
                                    // العميل لا يمكنه إضافة خدمات
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'هذه الميزة متاحة لمزودي الخدمات فقط',
                                          style: TextStyle(fontFamily: 'ElMessiri'),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? primary
                                      : Colors.white,
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : AppTheme.primaryDark,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'طلب إضافة خدمة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'ElMessiri',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// بناء واجهة فارغة عند عدم توفر تصنيفات للعرض.
  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 40,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تصنيفات حالياً',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء واجهة خطأ عند فشل تحميل التصنيفات.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء التحميل',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تضمين قسم الخدمات المقترحة في نهاية الشاشة الرئيسية.
  Widget _buildRecommendedServices(BuildContext context, bool isDark, Color primary) {
    return RecommendedServicesSection(isDark: isDark, primary: primary);
  }
}

/// قسم الخدمات المقترحة، ويعرض أفضل الخدمات المقبولة حسب التقييم.
class RecommendedServicesSection extends StatefulWidget {
  final bool isDark;
  final Color primary;
  const RecommendedServicesSection({super.key, required this.isDark, required this.primary});

  @override
  State<RecommendedServicesSection> createState() => _RecommendedServicesSectionState();
}

class _RecommendedServicesSectionState extends State<RecommendedServicesSection> {
  /// حالة التحميل والقائمة النهائية للخدمات المقترحة مع مخزن بيانات المزودين.
  bool _isLoading = true;
  List<Map<String, dynamic>> _topServices = [];
  StreamSubscription? _servicesSub;
  final Map<String, Map<String, dynamic>> _providerCache = {};

  @override
  /// بدء الاستماع للخدمات المقترحة فور إنشاء القسم.
  void initState() {
    super.initState();
    _listenRecommendedServices();
  }

  @override
  /// إلغاء الاشتراك في البث المباشر عند إزالة القسم من الواجهة.
  void dispose() {
    _servicesSub?.cancel();
    super.dispose();
  }

  /// الاستماع للخدمات المقبولة ثم فلترتها بحسب مزودين صالحين وترتيبها بالتقييم.
  void _listenRecommendedServices() {
    _servicesSub = FirebaseFirestore.instance
        .collection('services')
        .where('approvalStatus', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) async {
      try {

      // تجميع معرّفات المزودين المطلوبة لتقليل عدد طلبات القراءة.
      // 1. Collect unique provider IDs
      final Set<String> providerIds = {};
      for (var doc in snapshot.docs) {
        final providerId = doc.data()['providerId'] as String?;
        if (providerId != null && providerId.isNotEmpty) {
          providerIds.add(providerId);
        }
      }

      // جلب بيانات المزودين غير المخزنة مسبقًا فقط لتقليل الاستهلاك.
      // 2. Batch-fetch only missing providers
      final List<String> missingIds = providerIds.where((id) => !_providerCache.containsKey(id)).toList();
      if (missingIds.isNotEmpty) {
        for (var i = 0; i < missingIds.length; i += 10) {
          final batch = missingIds.sublist(i, i + 10 > missingIds.length ? missingIds.length : i + 10);
          final provSnap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (var doc in provSnap.docs) {
            _providerCache[doc.id] = doc.data();
          }
        }
      }

      // تصفية الخدمات الصالحة وترتيبها تنازليًا حسب متوسط التقييم.
      // 3. Filter valid provider services and sort
      final List<Map<String, dynamic>> validServices = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final providerId = data['providerId'] as String?;
        if (providerId == null || !_providerCache.containsKey(providerId)) continue;

        final userData = _providerCache[providerId]!;
        final role = userData['role'] as String?;
        final isProvider = userData['isProvider'] as bool? ?? false;

        if (role == 'provider' || isProvider) {
          final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          validServices.add({
            'id': doc.id,
            'data': data,
            'averageRating': averageRating,
          });
        }
      }

      validServices.sort((a, b) => (b['averageRating'] as double).compareTo(a['averageRating'] as double));

      if (mounted) {
        setState(() {
          _topServices = validServices.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    });
  }

  @override
  /// بناء قسم الخدمات المقترحة مع حالات التحميل والفراغ.
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_topServices.isEmpty) {
      return const SizedBox.shrink();
    }

    final textPrimary = Theme.of(context).textTheme.titleLarge?.color ?? AppTheme.getTextPrimary(widget.isDark);
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.getTextSecondary(widget.isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'خدمات مقترحة لك',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 154,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _topServices.length,
            itemBuilder: (context, index) {
              final item = _topServices[index];
              final id = item['id'] as String;
              final data = item['data'] as Map<String, dynamic>;
              final title = data['title'] ?? 'بدون عنوان';
              final providerName = data['providerName'] ?? '';
              final averageRating = item['averageRating'] as double;
              final totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;
              final priceText = buildStartingPriceLabel(
                context,
                parsePriceValue(data['startingPrice']),
                currency: readCurrencyCode(data['currency']),
              );

              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? AppTheme.getSurface(widget.isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.premiumShadow(widget.isDark),
                  border: Border.all(
                    color: widget.isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/service-details',
                        arguments: {'id': id},
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                providerName.isNotEmpty ? providerName[0].toUpperCase() : 'M',
                                style: const TextStyle(
                                  fontFamily: 'ElMessiri',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'ElMessiri',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        providerName,
                                        style: TextStyle(
                                          fontFamily: 'ElMessiri',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${averageRating.toStringAsFixed(1)} ($totalRatings)',
                                      style: const TextStyle(
                                        fontFamily: 'ElMessiri',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.payments_outlined,
                                      color: AppTheme.successColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        priceText,
                                        style: const TextStyle(
                                          fontFamily: 'ElMessiri',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.successColor,
                                        ),
                                        maxLines: 2,
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
