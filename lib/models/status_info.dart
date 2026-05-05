import 'package:flutter/material.dart';
import 'package:homemate/theme/app_theme.dart';

/// Shared status badge model used across booking and service screens.
/// Replaces the duplicated `_StatusInfo` classes found in multiple files.
class StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const StatusInfo(this.label, this.color, [this.icon = Icons.info_rounded]);

  // ── Booking status ─────────────────────────────────────────────
  static StatusInfo fromBookingStatus(String status) {
    switch (status) {
      case 'pending':
        return const StatusInfo(
            'قيد الانتظار', AppTheme.warningColor, Icons.hourglass_top_rounded);
      case 'accepted':
        return const StatusInfo(
            'مقبول', AppTheme.successColor, Icons.check_circle_rounded);
      case 'rejected':
        return const StatusInfo(
            'مرفوض', AppTheme.errorColor, Icons.cancel_rounded);
      case 'in_progress':
        return const StatusInfo(
            'قيد التنفيذ', Color(0xFF3B82F6), Icons.engineering_rounded);
      case 'completed':
        return const StatusInfo(
            'مكتمل', AppTheme.successColor, Icons.task_alt_rounded);
      case 'cancelled':
        return const StatusInfo(
            'ملغى (الخدمة غير متاحة)', Colors.grey, Icons.block_rounded);
      default:
        return StatusInfo(status, AppTheme.primaryColor, Icons.info_rounded);
    }
  }

  // ── Service approval status ────────────────────────────────────
  static StatusInfo fromApprovalStatus(String status) {
    switch (status) {
      case 'pending':
        return const StatusInfo(
            'قيد المراجعة', AppTheme.warningColor, Icons.hourglass_top_rounded);
      case 'accepted':
        return const StatusInfo(
            'مقبولة', AppTheme.successColor, Icons.check_circle_rounded);
      case 'rejected':
        return const StatusInfo(
            'مرفوضة', AppTheme.errorColor, Icons.cancel_rounded);
      case 'inactive':
        return const StatusInfo(
            'غير نشطة', Colors.grey, Icons.pause_circle_filled_rounded);
      default:
        return StatusInfo(status, AppTheme.primaryColor, Icons.info_rounded);
    }
  }

  // ── Variant with richer label for provider details ─────────────
  static StatusInfo fromApprovalStatusDetailed(String status) {
    switch (status) {
      case 'pending':
        return const StatusInfo(
            'قيد المراجعة', AppTheme.warningColor, Icons.hourglass_top_rounded);
      case 'accepted':
        return const StatusInfo('مقبولة وفعالة', AppTheme.successColor,
            Icons.check_circle_rounded);
      case 'rejected':
        return const StatusInfo(
            'مرفوضة', AppTheme.errorColor, Icons.cancel_rounded);
      case 'inactive':
        return const StatusInfo(
            'غير نشطة', Colors.grey, Icons.pause_circle_filled_rounded);
      default:
        return StatusInfo(status, AppTheme.primaryColor, Icons.info_rounded);
    }
  }
}
