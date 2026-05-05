import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/utils/price_utils.dart';

/// نموذج الحجز – يمثّل حجز خدمة واحد في التطبيق.
/// Booking model – represents a single service booking.
class Booking {
  final String id;
  final String userId;
  final String userName;
  final String serviceId;
  final String serviceTitle;
  final String categoryId;
  final String providerId;
  final DateTime selectedDate;
  final String selectedTime; // e.g. "14:30"
  final String address;
  final String notes;
  /// حالة طلب الحجز — "pending", "accepted", "rejected", "in_progress", "completed"
  /// Booking request lifecycle status.
  final String bookingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? initialPrice;
  final String currency;

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
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception("Booking document not found or empty");
    }
    final data = doc.data() as Map<String, dynamic>;

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
