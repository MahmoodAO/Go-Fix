import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/core/utils/price_utils.dart';

// enum : لتعريف أنواع ثابتة

class Service {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String phone;
  final String location;
  /// حالة موافقة الإدارة على الخدمة – 'pending', 'accepted', 'rejected', 'inactive'
  /// Admin approval status for this service listing.
  final String approvalStatus;
  final String providerName;
  final String providerId; // معرّف مزوّد الخدمة – Provider's uid
  final double averageRating;
  final int totalRatings;
  final double? startingPrice;
  final String currency;

  Service({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.phone,
    required this.location,
    required this.approvalStatus,
    required this.providerName,
    this.providerId = '',
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.startingPrice,
    this.currency = 'JOD',
  });

  //  factory: يحوّل (document) من Firestore إلى  Service.
  //  Reads `approvalStatus` first; falls back to legacy `status` field.
  factory Service.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception("Service document not found or empty");
    }
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Service(
      id: doc.id,
      categoryId: data.containsKey('categoryId') ? data['categoryId'] : '',
      title: data.containsKey('title') ? data['title'] : 'No Title',
      description:
          data.containsKey('description')
              ? data['description']
              : 'No Description',
      phone: data.containsKey('phone') ? data['phone'] : 'N/A',
      location: data.containsKey('location') ? data['location'] : 'Unknown',
      // قراءة approvalStatus أولاً، أو العودة للحقل القديم status
      approvalStatus: data['approvalStatus'] ?? data['status'] ?? 'inactive',
      providerName:
          data.containsKey('providerName') ? data['providerName'] : '',
      providerId:
          data.containsKey('providerId') ? data['providerId'] ?? '' : '',
      averageRating: (data['averageRating'] != null) ? (data['averageRating'] as num).toDouble() : 0.0,
      totalRatings: (data['totalRatings'] != null) ? (data['totalRatings'] as num).toInt() : 0,
      startingPrice: parsePriceValue(data['startingPrice']),
      currency: readCurrencyCode(data['currency']),
    );
  }
}
