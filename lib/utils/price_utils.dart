import 'package:flutter/material.dart';

double? parsePriceValue(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
  return null;
}

num toFirestorePriceNumber(double value) {
  return value == value.truncateToDouble() ? value.toInt() : value;
}

String readCurrencyCode(dynamic value, {String fallback = 'JOD'}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String formatPriceNumber(num value) {
  final normalized = value.toDouble();
  if (normalized == normalized.truncateToDouble()) {
    return normalized.toInt().toString();
  }

  return normalized
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

bool hasValidStartingPrice(double? price) {
  return price != null && price > 0;
}

String buildStartingPriceLabel(
  BuildContext _,
  double? price, {
  String currency = 'JOD',
}) {
  if (!hasValidStartingPrice(price)) {
    return 'السعر غير متوفر';
  }

  final amount = formatPriceNumber(price!);
  return currency == 'JOD'
      ? 'تبدأ من $amount دنانير'
      : 'تبدأ من $amount $currency';
}

String buildFinalPriceNote(BuildContext _) {
  return 'قد يختلف السعر النهائي حسب تفاصيل الطلب.';
}
