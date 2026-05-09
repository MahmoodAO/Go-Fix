import 'package:flutter/material.dart';

/// تحويل قيمة السعر إلى رقم عشري موحد بغض النظر عن نوعها الأصلي.
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

/// تجهيز السعر قبل حفظه في Firestore مع الحفاظ على الصيغة الأنسب.
num toFirestorePriceNumber(double value) {
  return value == value.truncateToDouble() ? value.toInt() : value;
}

/// قراءة رمز العملة مع إرجاع قيمة افتراضية عند غياب البيانات.
String readCurrencyCode(dynamic value, {String fallback = 'JOD'}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

/// تنسيق السعر للعرض بطريقة مختصرة وواضحة للمستخدم.
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

/// التحقق من أن السعر الابتدائي صالح للعرض والاستخدام.
bool hasValidStartingPrice(double? price) {
  return price != null && price > 0;
}

/// بناء النص المناسب لعرض السعر الابتدائي مع العملة.
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

/// بناء ملاحظة توضيحية بأن السعر النهائي يعتمد على تفاصيل الطلب.
String buildFinalPriceNote(BuildContext _) {
  return 'قد يختلف السعر النهائي حسب تفاصيل الطلب.';
}
