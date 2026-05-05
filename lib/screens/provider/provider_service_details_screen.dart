import 'package:flutter/material.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/theme/app_theme.dart';
import 'package:homemate/services/service_service.dart';
import 'package:homemate/widgets/star_rating.dart';

import 'package:homemate/screens/add_service.dart';
import 'package:homemate/models/status_info.dart';

class ProviderServiceDetailsScreen extends StatefulWidget {
  static const screenRoute = '/provider-service-details';

  const ProviderServiceDetailsScreen({super.key});

  @override
  State<ProviderServiceDetailsScreen> createState() =>
      _ProviderServiceDetailsScreenState();
}

class _ProviderServiceDetailsScreenState
    extends State<ProviderServiceDetailsScreen> {
  late String _serviceId;
  Service? _service;
  bool _isLoading = true;
  bool _isDeleting = false;
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
      if (mounted) {
        setState(() {
          _service = service;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldBg(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);
    final dividerColor = AppTheme.getDividerColor(isDark);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.getPrimary(isDark)),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
        ),
        body: Center(
          child: Text(
            'لم يتم العثور على الخدمة',
            style: TextStyle(
              fontFamily: 'ElMessiri',
              fontSize: 18,
              color: textPrimary,
            ),
          ),
        ),
      );
    }

    final statusInfo = _getStatusInfo(_service!.approvalStatus);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar Area ─────────────────────────
          SliverAppBar(
            backgroundColor: scaffoldBg,
            foregroundColor: textPrimary,
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              title: Text(
                'تفاصيل الخدمة',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Rating ─────────────────────────
                  Text(
                    _service!.title,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StarRating(
                        serviceId: _service!.id,
                        averageRating: _service!.averageRating,
                        totalRatings: _service!.totalRatings,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_service!.averageRating.toStringAsFixed(1)})',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${_service!.totalRatings} تقييم)',
                        style: TextStyle(
                          fontFamily: 'ElMessiri',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // ── Approval Status Pill (Read-only) ───────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: statusInfo.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo.icon,
                            size: 20, color: statusInfo.color),
                        const SizedBox(width: 10),
                        Text(
                          'موافقة الإدارة: ${statusInfo.label}',
                          style: TextStyle(
                            fontFamily: 'ElMessiri',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Description ─────────────────────────
                  Text(
                    'وصف الخدمة',
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _service!.description,
                    style: TextStyle(
                      fontFamily: 'ElMessiri',
                      fontSize: 15,
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Info Cards ─────────────────────────────
                  _buildInfoCard(
                    icon: Icons.location_on_rounded,
                    title: 'المنطقة',
                    value: _service!.location,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.phone_rounded,
                    title: 'رقم الهاتف',
                    value: _service!.phone,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 48),

                  // ── Provider Actions ─────────────────────
                  _buildActionButtons(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.getDividerColor(isDark).withOpacity(isDark ? 0.35 : 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textDirection: title == 'رقم الهاتف'
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        // Edit Service Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddService(serviceToEdit: _service),
                ),
              );
              // if it returned true, it means it saved
              if (result == true && mounted) {
                _loadServiceDetails();
              }
            },
            icon: Icon(Icons.edit_rounded, color: AppTheme.getTextPrimary(isDark)),
            label: Text(
              'تعديل الخدمة',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.getDividerColor(isDark)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Delete Service Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: _isDeleting 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.errorColor))
            : OutlinedButton.icon(
                onPressed: _showDeleteDialog,
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                label: const Text(
                  'حذف الخدمة',
                  style: TextStyle(
                    fontFamily: 'ElMessiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'ElMessiri', fontWeight: FontWeight.bold)),
          content: const Text(
            'هل أنت متأكد أنك تريد حذف هذه الخدمة؟ لا يمكن التراجع عن هذا الإجراء',
            style: TextStyle(fontFamily: 'ElMessiri', fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'ElMessiri')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف', style: TextStyle(fontFamily: 'ElMessiri')),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isDeleting = true);
        await ServiceService().deleteService(_serviceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الخدمة بنجاح', style: TextStyle(fontFamily: 'ElMessiri'))),
          );
          Navigator.of(context).pop(true); // Back to My Services list
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر مسح الخدمة. حاول مرة أخرى', style: TextStyle(fontFamily: 'ElMessiri'))),
          );
        }
      }
    }
  }

  StatusInfo _getStatusInfo(String status) {
    return StatusInfo.fromApprovalStatusDetailed(status);
  }
}
