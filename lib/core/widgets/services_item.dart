import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homemate/core/theme/theme_provider.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:homemate/core/utils/price_utils.dart';

/// بطاقة خدمة مختصرة، وتعرض بيانات الخدمة الأساسية مع زر المفضلة والتنقل للتفاصيل.
class ServicesItem extends StatelessWidget {
  /// البيانات الأساسية المستخدمة في عرض الخدمة داخل القوائم.
  final String id;
  final String title;
  final String phone;
  final String providerName;
  final String location;
  final bool isFavorite;
  final double averageRating;
  final int totalRatings;
  final double? startingPrice;
  final String currency;
  final VoidCallback onToggleFavorite;

  const ServicesItem({
    super.key,
    required this.id,
    required this.title,
    required this.phone,
    required this.location,
    required this.providerName,
    required this.isFavorite,
    required this.averageRating,
    required this.totalRatings,
    this.startingPrice,
    this.currency = 'JOD',
    required this.onToggleFavorite,
  });

  @override
  /// بناء بطاقة الخدمة مع السعر والتقييم والموقع وإجراءات التنقل.
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final titleColor =
        Theme.of(context).textTheme.titleLarge?.color ??
        AppTheme.getTextPrimary(isDark);
    final bodyColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8) ??
        AppTheme.getTextSecondary(isDark);
    final priceText = buildStartingPriceLabel(
      context,
      startingPrice,
      currency: currency,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppTheme.getSurface(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow(isDark),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // فتح شاشة تفاصيل الخدمة عند الضغط على البطاقة.
            Navigator.of(context).pushNamed(
              '/service-details',
              arguments: {'id': id},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
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
                          providerName.isNotEmpty
                              ? providerName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 24,
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
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: titleColor,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: bodyColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : (isDark
                                      ? AppTheme.darkDivider
                                      : AppTheme.lightDivider)
                                  .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppTheme.errorColor
                              : (isDark ? Colors.white70 : Colors.black45),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // عرض معلومات مختصرة عن التقييم والسعر الابتدائي.
                    _InfoChip(
                      icon: Icons.star_rounded,
                      label: '${averageRating.toStringAsFixed(1)} ($totalRatings)',
                      foregroundColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      borderColor: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: priceText,
                      foregroundColor: AppTheme.successColor,
                      backgroundColor: AppTheme.successColor.withOpacity(0.10),
                      borderColor: AppTheme.successColor.withOpacity(0.18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider)
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkDivider
                          : AppTheme.lightDivider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'ElMessiri',
                            fontWeight: FontWeight.w600,
                            color: bodyColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'ElMessiri',
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // الانتقال المباشر إلى شاشة تفاصيل الخدمة قبل متابعة الحجز.
                      Navigator.of(context).pushNamed(
                        '/service-details',
                        arguments: {'id': id},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'احجز الآن',
                      style: TextStyle(
                        fontFamily: 'ElMessiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عنصر بصري صغير لعرض معلومة سريعة مثل السعر أو التقييم.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  /// بناء شارة معلومات موحدة الشكل.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
