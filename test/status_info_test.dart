import 'package:flutter_test/flutter_test.dart';
import 'package:homemate/core/constants/status_info.dart';
import 'package:homemate/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  group('StatusInfo.fromBookingStatus', () {
    test('returns correct label for pending', () {
      final info = StatusInfo.fromBookingStatus('pending');
      expect(info.label, 'قيد الانتظار');
      expect(info.color, AppTheme.warningColor);
      expect(info.icon, Icons.hourglass_top_rounded);
    });

    test('returns correct label for accepted', () {
      final info = StatusInfo.fromBookingStatus('accepted');
      expect(info.label, 'مقبول');
      expect(info.color, AppTheme.successColor);
    });

    test('returns correct label for rejected', () {
      final info = StatusInfo.fromBookingStatus('rejected');
      expect(info.label, 'مرفوض');
      expect(info.color, AppTheme.errorColor);
    });

    test('returns correct label for in_progress', () {
      final info = StatusInfo.fromBookingStatus('in_progress');
      expect(info.label, 'قيد التنفيذ');
    });

    test('returns correct label for completed', () {
      final info = StatusInfo.fromBookingStatus('completed');
      expect(info.label, 'مكتمل');
      expect(info.color, AppTheme.successColor);
    });

    test('returns raw status string for unknown status', () {
      final info = StatusInfo.fromBookingStatus('custom_status');
      expect(info.label, 'custom_status');
      expect(info.color, AppTheme.primaryColor);
    });
  });

  group('StatusInfo.fromApprovalStatus', () {
    test('returns correct label for pending', () {
      final info = StatusInfo.fromApprovalStatus('pending');
      expect(info.label, 'قيد المراجعة');
      expect(info.color, AppTheme.warningColor);
    });

    test('returns correct label for accepted', () {
      final info = StatusInfo.fromApprovalStatus('accepted');
      expect(info.label, 'مقبولة');
      expect(info.color, AppTheme.successColor);
    });

    test('returns correct label for rejected', () {
      final info = StatusInfo.fromApprovalStatus('rejected');
      expect(info.label, 'مرفوضة');
      expect(info.color, AppTheme.errorColor);
    });

    test('returns correct label for inactive', () {
      final info = StatusInfo.fromApprovalStatus('inactive');
      expect(info.label, 'غير نشطة');
      expect(info.color, Colors.grey);
    });

    test('returns raw status string for unknown status', () {
      final info = StatusInfo.fromApprovalStatus('archived');
      expect(info.label, 'archived');
      expect(info.color, AppTheme.primaryColor);
    });
  });

  group('StatusInfo.fromApprovalStatusDetailed', () {
    test('accepted shows detailed label', () {
      final info = StatusInfo.fromApprovalStatusDetailed('accepted');
      expect(info.label, 'مقبولة وفعالة');
      expect(info.color, AppTheme.successColor);
    });
  });
}
