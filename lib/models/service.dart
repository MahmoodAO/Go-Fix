import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/core/utils/price_utils.dart';

// enum : لتعريف أنواع ثابتة

/// نموذج الخدمة، ويمثل بيانات الخدمة المعروضة أو المُدارة داخل التطبيق.
/// نموذج الخدمة، ويمثل بيانات الخدمة المعروضة داخل التطبيق.
class Service {
  /// معرف الخدمة داخل Firestore.
  final String id;
  /// معرف التصنيف المرتبط بالخدمة.
  final String categoryId;
  /// عنوان الخدمة.
  final String title;
  /// وصف الخدمة المقدم من مزوّد الخدمة.
  final String description;
  /// رقم التواصل المرتبط بالخدمة.
  final String phone;
  /// موقع تنفيذ الخدمة أو المدينة.
  final String location;
  /// حالة موافقة الإدارة على الخدمة – 'pending', 'accepted', 'rejected', 'inactive'
  /// Admin approval status for this service listing.
  /// حالة اعتماد الإدارة للخدمة.
  final String approvalStatus;
  /// اسم مزوّد الخدمة الظاهر للمستخدمين.
  final String providerName;
  final String providerId; // معرّف مزوّد الخدمة – Provider's uid
  /// متوسط تقييمات المستخدمين للخدمة.
  final double averageRating;
  /// عدد التقييمات المسجلة للخدمة.
  final int totalRatings;
  /// السعر الابتدائي للخدمة إن وجد.
  final double? startingPrice;
  /// رمز العملة المستخدم مع السعر.
  final String currency;

  /// تهيئة كائن الخدمة بالقيم القادمة من التطبيق أو من قاعدة البيانات.
  /// تهيئة كائن الخدمة من البيانات المحلية أو القادمة من Firestore.
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
  /// إنشاء نموذج الخدمة من مستند Firestore مع دعم الحقول القديمة للحالة.
  /// إنشاء نموذج خدمة من مستند Firestore مع دعم الحقول القديمة للحالة.
  factory Service.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      throw Exception("Service document not found or empty");
    }
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // قراءة بيانات الخدمة مع توفير قيم افتراضية عند غياب بعض الحقول.
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
