import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/core/constants/status_info.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/core/theme/app_theme.dart';

/// شاشة خدماتي – تعرض جميع خدمات مزوّد الخدمة الحالي.
/// Provider Services Screen – lists all services owned by the current provider.
class ProviderServicesScreen extends StatefulWidget {
  final bool showPendingOnly;

  const ProviderServicesScreen({
    super.key,
    this.showPendingOnly = false,
  });

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  late Stream<List<Service>> _servicesStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _servicesStream = ServiceService().getProviderServicesStream(uid);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      appBar: widget.showPendingOnly
          ? AppBar(
              title: Text(
                'بانتظار القبول',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextPrimary(isDark),
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: IconThemeData(
                color: AppTheme.getTextPrimary(isDark),
              ),
            )
          : null,
      body: StreamBuilder<List<Service>>(
        stream: _servicesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (snapshot.hasError) {
            return _buildEmptyState(isDark, Icons.error_outline_rounded,
                'حدث خطأ أثناء تحميل الخدمات');
          }

          final allServices = snapshot.data ?? [];
          
          final services = allServices.where((s) {
            final st = s.approvalStatus;
            if (widget.showPendingOnly) {
              return st == 'pending' || st == 'awaiting_approval';
            } else {
              return st == 'accepted';
            }
          }).toList();

          if (services.isEmpty) {
            if (widget.showPendingOnly) {
              return _buildEmptyState(
                isDark, 
                Icons.hourglass_empty_rounded,
                'لا توجد خدمات قيد الانتظار\nالخدمات التي ترسلها وتنتظر موافقة الإدارة ستظهر هنا',
              );
            }
            return _buildEmptyState(isDark, Icons.design_services_rounded,
                'لا توجد خدمات موافق عليها بعد');
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Now uses stream, so no manual reload required
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ServiceCard(
                  service: services[index],
                  isDark: isDark,
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      '/provider-service-details',
                      arguments: {'id': services[index].id},
                    );
                    // Stream will automatically auto-refresh
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.showPendingOnly ? 0 : 90.0),
        child: FloatingActionButton.extended(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة خدمة',
            style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            await Navigator.of(context).pushNamed('addservice');
            // Stream auto-updates
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: AppTheme.getPrimary(isDark)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Service Card for Provider — tappable
// ───────────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isDark;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.service,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);
    final statusInfo = _getStatusInfo(service.approvalStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.getPremiumShadow(isDark),
          border: Border.all(
            color: dividerColor.withOpacity(isDark ? 0.35 : 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.design_services_rounded,
                    size: 22,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service.title,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    statusInfo.label,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusInfo.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              service.description,
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 15, color: AppTheme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  service.location,
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.phone_outlined,
                    size: 15, color: AppTheme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  service.phone,
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    return StatusInfo.fromApprovalStatus(status);
  }
}
