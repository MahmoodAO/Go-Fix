import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/theme/app_theme.dart';

class GenerateReportScreen extends StatelessWidget {
  const GenerateReportScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('services').get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'providerName': data['providerName'] ?? 'مجهول',
        'description': data['description'] ?? 'بدون وصف',
        'status': data['status'] ?? 'unknown',
      };
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return AppTheme.textHint;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      case 'pending':
        return 'معلقة';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الخدمات'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      backgroundColor: AppTheme.scaffoldBg,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ: ${snapshot.error}',
                    style: const TextStyle(
                      fontFamily: 'ElMessiri',
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد خدمات مخزنة حالياً',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.assessment_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إجمالي الخدمات',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${services.length}',
                          style: const TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Service list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final status = service['status'] ?? 'unknown';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(
                            Icons.build_rounded,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          service['providerName']!,
                          style: const TextStyle(
                            fontFamily: 'ElMessiri',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            service['description']!,
                            style: const TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 13,
                              color: AppTheme.textHint,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              fontFamily: 'ElMessiri',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
