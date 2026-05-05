import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/core/theme/app_theme.dart';

class StarRating extends StatefulWidget {
  final String serviceId;
  final double averageRating;
  final int totalRatings;
  final double iconSize;

  const StarRating({
    super.key,
    required this.serviceId,
    required this.averageRating,
    required this.totalRatings,
    this.iconSize = 24.0,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  bool _isSubmitting = false;

  void _rateService(int rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لتقييم الخدمة')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ServiceService().rateService(widget.serviceId, user.uid, rating.toDouble());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تقييم الخدمة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التقييم')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showRatingDialog() {
    int selectedRating = 5;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              title: const Text(
                'تقييم الخدمة',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Flexible(
                    child: IconButton(
                      iconSize: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = index + 1;
                        });
                      },
                    ),
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _rateService(selectedRating);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  child: const Text('تقييم', style: TextStyle(fontFamily: 'ElMessiri', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('services').doc(widget.serviceId).snapshots(),
      builder: (context, snapshot) {
        double displayAvg = widget.averageRating;
        int displayTotal = widget.totalRatings;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            displayAvg = (data['averageRating'] as num?)?.toDouble() ?? widget.averageRating;
            displayTotal = data['totalRatings'] as int? ?? widget.totalRatings;
          }
        }

        return GestureDetector(
          onTap: _isSubmitting ? null : _showRatingDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isSubmitting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                else
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  displayAvg.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($displayTotal)',
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
