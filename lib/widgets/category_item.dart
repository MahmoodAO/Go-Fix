import 'package:flutter/material.dart';
import 'package:homemate/screens/category_services_screen.dart';
import 'package:homemate/theme/app_theme.dart';

class CategoryItem extends StatelessWidget {
  final String id;
  final String title;
  final String image;

  const CategoryItem(this.id, this.title, this.image, {super.key});

  String get _mappedImage {
    final lowerId = id.toLowerCase();
    final lowerTitle = title.toLowerCase();
    
    if (lowerId.contains('cleaning') || lowerTitle.contains('تنظيف')) {
      return 'images/m1.png';
    } else if (lowerId.contains('fixing') || lowerTitle.contains('صيانة')) {
      return 'images/m4.png';
    } else if (lowerId.contains('gardening') || lowerTitle.contains('حديقة')) {
      return 'images/m3.png';
    } else if (lowerId.contains('moving') || lowerTitle.contains('نقل')) {
      return 'images/m2.png';
    }
    
    return image.isNotEmpty ? image : 'images/m1.png';
  }

  void selectCategory(BuildContext ctx) {
    Navigator.of(ctx).pushNamed(
      CategoryServicesScreen.screenRoute,
      arguments: {'id': id, 'title': title},
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => selectCategory(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.asset(
                _mappedImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppTheme.dividerColor);
                },
              ),
              // Soft radial gradient + bottom gradient for depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
              // Title at the bottom
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right, // RTL standard
                        style: const TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Ripple effect overlay
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () => selectCategory(context),
                    highlightColor: Colors.white.withOpacity(0.1),
                    splashColor: Colors.white.withOpacity(0.2),
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
