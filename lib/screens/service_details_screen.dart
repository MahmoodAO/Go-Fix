import 'package:flutter/material.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/services/favorites_services.dart';
import 'package:homemate/widgets/star_rating.dart';
import 'package:homemate/screens/booking_screen.dart';
import 'package:homemate/core/utils/price_utils.dart';

class ServiceDetailsScreen extends StatefulWidget {
  static const screenRoute = '/service-details';

  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  late String _serviceId;
  Service? _service;
  bool _isLoading = true;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      final routeArgs =
          ModalRoute.of(context)?.settings.arguments as Map?;
      if (routeArgs != null && routeArgs.containsKey('id')) {
        _serviceId = routeArgs['id'] as String;
        _loadServiceDetails();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadServiceDetails() async {
    try {
      final service = await ServiceService().getServiceById(_serviceId);
      setState(() {
        _service = service;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite(bool isFav) async {
    if (isFav) {
      await _favoritesService.removeFromFavorites(_serviceId);
    } else {
      await _favoritesService.addToFavorites(_serviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: const Text('تفاصيل الخدمة'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: const Text('تفاصيل الخدمة'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'لم يتم العثور على الخدمة',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              color: textPrimary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(_service!.title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          StreamBuilder<List<String>>(
            stream: _favoritesService.getFavoriteServiceIdsStream(),
            builder: (context, snapshot) {
              final isFav = snapshot.data?.contains(_serviceId) ?? false;
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                color: isFav ? AppTheme.errorColor : Colors.white,
                onPressed: () => _toggleFavorite(isFav),
              );
            }
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.10),
              ),
              child: const Icon(
                Icons.home_repair_service_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _service!.title,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _service!.providerName,
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StarRating(
                    serviceId: _service!.id,
                    averageRating: _service!.averageRating,
                    totalRatings: _service!.totalRatings,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildStartingPriceLabel(
                            context,
                            _service!.startingPrice,
                            currency: _service!.currency,
                          ),
                          style: const TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                        if (hasValidStartingPrice(_service!.startingPrice)) ...[
                          const SizedBox(height: 6),
                          Text(
                            buildFinalPriceNote(context),
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 13,
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'الوصف',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _service!.description,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 15,
                      height: 1.6,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
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
                        Text(
                          'معلومات التواصل',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContactRow(
                          context: context,
                          icon: Icons.phone_rounded,
                          label: 'رقم الهاتف',
                          value: _service!.phone,
                        ),
                        Divider(
                          height: 24,
                          color: dividerColor,
                        ),
                        _buildContactRow(
                          context: context,
                          icon: Icons.location_on_rounded,
                          label: 'الموقع',
                          value: _service!.location,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── Book Now Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          BookingScreen.screenRoute,
                          arguments: {
                            'service': _service!,
                            'categoryName': null, // يمكن تمريره لاحقاً
                          },
                        );
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text(
                        'احجز الآن',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: isDark
                            ? AppTheme.darkScaffoldBg
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Contact Provider Button ─────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'قم بالتواصل مع مقدم الخدمة مباشرة للتنسيق معه.',
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.phone_forwarded_rounded,
                        color: AppTheme.getPrimary(isDark),
                      ),
                      label: Text(
                        'تواصل الآن',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getPrimary(isDark),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.getPrimary(isDark),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textHint = AppTheme.getTextHint(isDark);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 13,
                  color: textHint,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 16,
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
}
