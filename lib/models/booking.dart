import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/core/utils/price_utils.dart';

/// نموذج الحجز – يمثّل حجز خدمة واحد في التطبيق.
/// Booking model – represents a single service booking.
/// نموذج الحجز، ويمثل بيانات حجز خدمة واحدة داخل التطبيق.
/// نموذج الحجز، ويمثل طلب حجز خدمة داخل التطبيق.
class Booking {
  /// معرف الحجز داخل Firestore.
  final String id;
  /// معرف المستخدم الذي أنشأ الحجز.
  final String userId;
  /// اسم المستخدم لعرضه داخل الشاشات.
  final String userName;
  /// معرف الخدمة المحجوزة.
  final String serviceId;
  /// عنوان الخدمة المحجوزة.
  final String serviceTitle;
  /// التصنيف الذي تنتمي إليه الخدمة.
  final String categoryId;
  /// معرف مزوّد الخدمة المسؤول عن تنفيذ الحجز.
  final String providerId;
  /// التاريخ المختار لتنفيذ الخدمة.
  final DateTime selectedDate;
  final String selectedTime; // e.g. "14:30"
  /// عنوان تنفيذ الخدمة الذي يدخله العميل.
  final String address;
  /// ملاحظات إضافية مرتبطة بالحجز.
  final String notes;
  /// حالة طلب الحجز — "pending", "accepted", "rejected", "in_progress", "completed"
  /// Booking request lifecycle status.
  /// حالة دورة حياة الحجز داخل النظام.
  final String bookingStatus;
  /// وقت إنشاء الحجز.
  final DateTime createdAt;
  /// وقت آخر تحديث على الحجز.
  final DateTime updatedAt;
  /// السعر الابتدائي المقترح إن وجد.
  final double? initialPrice;
  /// رمز العملة المستخدم مع السعر.
  final String currency;

  /// تهيئة كائن الحجز بالقيم الأساسية القادمة من التطبيق أو من Firestore.
  /// تهيئة كائن الحجز من البيانات المحلية أو القادمة من Firestore.
  Booking({
    this.id = '',
    required this.userId,
    this.userName = '',
    required this.serviceId,
    required this.serviceTitle,
    this.categoryId = '',
    this.providerId = '',
    required this.selectedDate,
    required this.selectedTime,
    required this.address,
    this.notes = '',
    this.bookingStatus = 'pending',
    this.initialPrice,
    this.currency = 'JOD',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// تحويل الحجز إلى Map لحفظه في Firestore
  /// تحويل كائن الحجز إلى Map قبل حفظه في Firestore.
  /// تحويل كائن الحجز إلى خريطة قبل حفظه في Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'categoryId': categoryId,
      'providerId': providerId,
      'selectedDate': Timestamp.fromDate(selectedDate),
      'selectedTime': selectedTime,
      'address': address,
      'notes': notes,
      'bookingStatus': bookingStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (initialPrice != null)
        'initialPrice': toFirestorePriceNumber(initialPrice!),
      'currency': currency,
    };
  }

  /// إنشاء نموذج حجز من مستند Firestore
  /// Reads `bookingStatus` first; falls back to legacy `status` field.
  /// إنشاء نموذج الحجز من مستند Firestore مع دعم الحقول القديمة عند الحاجة.
  /// إنشاء نموذج الحجز من مستند Firestore مع دعم الحقول القديمة للحالة.
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception("Booking document not found or empty");
    }
    final data = doc.data() as Map<String, dynamic>;

    // قراءة بيانات الحجز مع توفير قيم افتراضية لتفادي فشل العرض عند نقص البيانات.
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceTitle: data['serviceTitle'] ?? '',
      categoryId: data['categoryId'] ?? '',
      providerId: data['providerId'] ?? '',
      selectedDate: (data['selectedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedTime: data['selectedTime'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      // قراءة bookingStatus أولاً، أو العودة للحقل القديم status
      bookingStatus: data['bookingStatus'] ?? data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      initialPrice: parsePriceValue(data['initialPrice']),
      currency: readCurrencyCode(data['currency']),
    );
  }
}
