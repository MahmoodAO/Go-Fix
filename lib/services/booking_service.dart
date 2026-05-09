import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:homemate/models/booking.dart';

/// خدمة الحجز – تدير عمليات الحجز في Firestore.
/// BookingService – handles booking CRUD operations with Firestore.
/// خدمة الحجوزات، وتدير إنشاء الحجوزات وتحديث حالتها وجلبها من Firestore.
class BookingService {
  /// مرجع مجموعة الحجوزات المركزية داخل Firestore.
  final CollectionReference _bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');

  /// إنشاء حجز جديد وإرجاع معرّف المستند
  /// Creates a new booking document and returns the new document ID.
  /// إنشاء حجز جديد وحفظه في Firestore ثم إرجاع معرّف المستند.
  Future<String> createBooking(Booking booking) async {
    final docRef = await _bookingsCollection.add(booking.toMap());
    return docRef.id;
  }

  /// تحديث حالة طلب الحجز (bookingStatus)
  /// Updates the booking request status (e.g. pending → accepted).
  /// تحديث حالة الحجز مع تسجيل وقت آخر تعديل.
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsCollection.doc(bookingId).update({
      'bookingStatus': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  /// بث مباشر لحجوزات المستخدم
  /// الاستماع المباشر لحجوزات مستخدم محدد لعرضها مباشرة في الواجهة.
  Stream<List<Booking>> getUserBookingsStream(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // تجاهل أي مستند غير صالح حتى لا يتعطل تدفق البيانات في الواجهة.
      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        try {
          bookings.add(Booking.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ Skipping malformed booking doc ${doc.id}: $e');
        }
      }
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// بث مباشر لطلبات الحجز الخاصة بمزوّد خدمة معيّن.
  /// الاستماع المباشر لطلبات الحجز الخاصة بمزود خدمة معيّن مع إمكانية التصفية حسب الخدمة.
  Stream<List<Booking>> getProviderBookingsStream(String providerId, {String? serviceId}) {
    var query = _bookingsCollection.where('providerId', isEqualTo: providerId);
    
    // إضافة شرط إضافي عند الحاجة إلى عرض حجوزات خدمة واحدة فقط.
    if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }
    
    return query.snapshots().map((snapshot) {
      // تحويل المستندات إلى نماذج حجز صالحة مع تجاهل البيانات التالفة.
      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        try {
          bookings.add(Booking.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ Skipping malformed booking doc ${doc.id}: $e');
        }
      }
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// قبول طلب حجز (إجراء المزوّد).
  /// قبول طلب الحجز بعد التحقق من وجود الحجز والخدمة المرتبطة به.
  Future<void> acceptBooking(String bookingId) async {
    // قراءة الحجز الحالي قبل تعديل حالته لتجنب قبول حجوزات غير صالحة.
    final bookingDoc = await _bookingsCollection.doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('الحجز غير موجود');

    final data = bookingDoc.data() as Map<String, dynamic>;
    final serviceId = data['serviceId'] as String;
    final currentStatus = data['bookingStatus'] ?? data['status'] ?? 'pending';

    if (currentStatus == 'cancelled') throw Exception('تم إلغاء هذا الحجز لأن الخدمة تم حذفها');

    final serviceDoc = await FirebaseFirestore.instance.collection('services').doc(serviceId).get();
    if (!serviceDoc.exists) throw Exception('لا يمكن قبول الحجز، تم حذف هذه الخدمة مسبقاً');

    // تحديث حالة الحجز إلى مقبول وتسجيل وقت التعديل.
    await _bookingsCollection.doc(bookingId).update({
      'bookingStatus': 'accepted',
      'updatedAt': Timestamp.now(),
    });
  }

  /// رفض طلب حجز (إجراء المزوّد).
  /// رفض طلب الحجز بعد التأكد من أن الحجز ما زال صالحًا للتعديل.
  Future<void> rejectBooking(String bookingId) async {
    final bookingDoc = await _bookingsCollection.doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('الحجز غير موجود');

    final data = bookingDoc.data() as Map<String, dynamic>;
    final currentStatus = data['bookingStatus'] ?? data['status'] ?? 'pending';

    if (currentStatus == 'cancelled') throw Exception('لا يمكن التعديل لأن هذه الخدمة تم حذفها');

    // تحديث حالة الحجز إلى مرفوض مع حفظ وقت آخر تعديل.
    await _bookingsCollection.doc(bookingId).update({
      'bookingStatus': 'rejected',
      'updatedAt': Timestamp.now(),
    });
  }
}
