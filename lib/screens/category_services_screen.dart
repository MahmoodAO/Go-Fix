import 'package:flutter/material.dart';
import 'package:homemate/screens/services_item.dart';
import 'package:homemate/theme/app_theme.dart';
import '../models/service.dart';
import '../services/favorites_services.dart';
import '../services/service_service.dart';

class CategoryServicesScreen extends StatefulWidget {
  static const screenRoute = '/category-servicse';
  final Map<String, bool>? filters;

  const CategoryServicesScreen({this.filters, super.key});

  @override
  State<CategoryServicesScreen> createState() =>
      CategoryServicesScreenState();
}

class CategoryServicesScreenState extends State<CategoryServicesScreen> {
  late String categoryTitle;
  late String categoryId;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final routeArgument =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    categoryId = routeArgument?['id'] ?? '';
    categoryTitle = routeArgument?['title'] ?? 'الخدمات';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scaffoldColor = theme.scaffoldBackgroundColor;
    final textPrimary =
        theme.textTheme.titleLarge?.color ??
        theme.textTheme.bodyLarge?.color ??
        Colors.black;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: StreamBuilder<List<String>>(
        stream: _favoritesService.getFavoriteServiceIdsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final favoriteServiceIds = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: scaffoldColor,
                foregroundColor: textPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  title: Text(
                    categoryTitle,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: false,
                ),
              ),
              StreamBuilder<List<Service>>(
                stream: ServiceService().getAcceptedCategoryServicesStream(categoryId),
                builder: (context, serviceSnapshot) {
                  if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (serviceSnapshot.hasError) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('حدث خطأ أثناء تحميل الخدمات')),
                    );
                  }

                  var services = serviceSnapshot.data ?? [];
                  
                  // Apply location filters
                  final Map<String, bool> activeFilters = widget.filters ?? {};
                  final anyFilterActive = activeFilters.values.any((v) => v == true);
                  if (anyFilterActive) {
                    services = services.where((service) {
                      if (activeFilters['Irbid'] == true && service.location == 'Irbid') return true;
                      if (activeFilters['Amman'] == true && service.location == 'Amman') return true;
                      if (activeFilters['Aqaba'] == true && service.location == 'Aqaba') return true;
                      return false;
                    }).toList();
                  }

                  if (services.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service = services[index];
                          final isFav = favoriteServiceIds.contains(service.id);
                          return ServicesItem(
                            id: service.id,
                            title: service.title,
                            phone: service.phone,
                            location: service.location,
                            providerName: service.providerName,
                            averageRating: service.averageRating,
                            totalRatings: service.totalRatings,
                            startingPrice: service.startingPrice,
                            currency: service.currency,
                            isFavorite: isFav,
                            onToggleFavorite: () async {
                              if (isFav) {
                                await _favoritesService.removeFromFavorites(service.id);
                              } else {
                                await _favoritesService.addToFavorites(service.id);
                              }
                            },
                          );
                        },
                        childCount: services.length,
                      ),
                    ),
                  );
                }
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    final textPrimary =
        theme.textTheme.titleLarge?.color ??
        theme.textTheme.bodyLarge?.color ??
        Colors.black;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد خدمات متاحة',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 18,
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على خدمات لهذا التصنيف حالياً',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
