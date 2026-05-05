// services/service_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:homemate/models/service.dart';
import 'package:homemate/core/utils/price_utils.dart';

class ResolvedProviderIdentity {
  final String uid;
  final String displayName;
  final String email;

  const ResolvedProviderIdentity({
    required this.uid,
    required this.displayName,
    required this.email,
  });
}

class ServiceService {
  final CollectionReference _serviceCollection = FirebaseFirestore.instance
      .collection('services');
  // متغير خاص بالسيرفس الموجودة بالفير ستور بحيث نقدر نسحب منها او نعدل عليها

  Future<List<Service>> getServices() async {
    final querySnapshot = await _serviceCollection.get();
    final services = querySnapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return services;
  }

  Future<ResolvedProviderIdentity> resolveCurrentProviderIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول لإضافة خدمة');
    }

    String? profileName;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          profileName = _readFirstNonEmptyString(data, const [
            'name',
            'fullName',
            'username',
            'displayName',
          ]);
        }
      }
    } catch (e) {
      debugPrint('Error loading provider profile: $e');
    }

    final resolvedName =
        profileName ??
        _cleanString(user.displayName) ??
        _emailPrefix(user.email) ??
        'Service Provider';

    return ResolvedProviderIdentity(
      uid: user.uid,
      displayName: resolvedName,
      email: user.email ?? '',
    );
  }

  Future<void> createProviderService({
    required String categoryId,
    required String title,
    required String description,
    required String phone,
    required String location,
    required double startingPrice,
  }) async {
    final identity = await resolveCurrentProviderIdentity();
    final serviceData = _buildProviderServiceData(
      identity: identity,
      categoryId: categoryId,
      title: title,
      description: description,
      phone: phone,
      location: location,
      startingPrice: startingPrice,
      isNewService: true,
    );

    await _serviceCollection.add(serviceData);
  }

  Future<void> updateProviderService({
    required String serviceId,
    required String categoryId,
    required String title,
    required String description,
    required String phone,
    required String location,
    required double startingPrice,
  }) async {
    final identity = await resolveCurrentProviderIdentity();
    final serviceData = _buildProviderServiceData(
      identity: identity,
      categoryId: categoryId,
      title: title,
      description: description,
      phone: phone,
      location: location,
      startingPrice: startingPrice,
      isNewService: false,
    );

    await _serviceCollection.doc(serviceId).update(serviceData);
  }

  // جلب الخدمات المقبولة فقط (التي وافق عليها الأدمن)
  Future<List<Service>> getAcceptedServices() async {
    final querySnapshot = await _serviceCollection
        .where('approvalStatus', isEqualTo: 'accepted')
        .get();

    final services = querySnapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return services;
  }

  // بسترجع خدمة بالاعتماد على  ال id
  Future<Service> getServiceById(String id) async {
    final doc = await _serviceCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception("Service with ID $id not found");
    }
    return Service.fromFirestore(doc);
  }

  // بجيب كل الخدمات التي تنتمي إلى تصنيف معيّن
  Future<List<Service>> getServicesByCategoryId(String categoryId) async {
    final query =
        await FirebaseFirestore.instance
            .collection('services')
            .where('categoryId', isEqualTo: categoryId)
            .get();
    final services = query.docs.map((doc) => Service.fromFirestore(doc)).toList();
    services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return services;
  }

  Future<List<Service>> getPendingServices({String? categoryId}) async {
    Query query = _serviceCollection
        .where('approvalStatus', isEqualTo: 'pending');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    final snapshot = await query.get();
    final services = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return services;
  }

  /// جلب خدمات مزوّد خدمة معيّن بناءً على providerId.
  /// Retrieves a stream of all accepted services
  Stream<List<Service>> getAcceptedServicesStream() {
    return _serviceCollection
        .where('approvalStatus', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList());
  }

  /// Retrieves a stream of accepted services belonging to a category
  Stream<List<Service>> getAcceptedCategoryServicesStream(String categoryId) {
    return _serviceCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('approvalStatus', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      final services = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
      services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      return services;
    });
  }

  /// Fetches all services belonging to a specific provider.
  Future<List<Service>> getProviderServices(String providerId) async {
    final query = await _serviceCollection
        .where('providerId', isEqualTo: providerId)
        .get();
    final services = query.docs.map((doc) => Service.fromFirestore(doc)).toList();
    return services;
  }

  /// Real-time stream of services for a provider.
  Stream<List<Service>> getProviderServicesStream(String providerId) {
    return _serviceCollection
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList());
  }

  Future<List<Service>> getInActiveServices() async {
    final query = await _serviceCollection
        .where('approvalStatus', isEqualTo: 'inactive')
        .get();

    final services = query.docs.map((doc) => Service.fromFirestore(doc)).toList();
    services.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return services;
  }

  /// تحديث حالة الموافقة على الخدمة (يستخدمها الأدمن)
  /// Updates the admin approval status of a service.
  Future<void> updateApprovalStatus(String serviceId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .update({'approvalStatus': newStatus});
  }

  /// Legacy: reject (delegates to updateApprovalStatus)
  Future<void> updateStatusToRejected(String serviceId) async {
    await updateApprovalStatus(serviceId, 'rejected');
  }

  // Transaction based rating
  Future<void> rateService(String serviceId, String userId, double rating) async {
    final serviceDocRef = _serviceCollection.doc(serviceId);
    final ratingDocRef = serviceDocRef.collection('ratings').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final serviceSnapshot = await transaction.get(serviceDocRef);
      if (!serviceSnapshot.exists) {
        throw Exception("Service does not exist!");
      }

      final ratingSnapshot = await transaction.get(ratingDocRef);
      
      final Map<String, dynamic>? data = serviceSnapshot.data() as Map<String, dynamic>?;
      int currentTotalRatings = data != null && data.containsKey('totalRatings') ? data['totalRatings'] as int : 0;
      double currentAverage = data != null && data.containsKey('averageRating') ? (data['averageRating'] as num).toDouble() : 0.0;

      if (ratingSnapshot.exists) {
        final oldRatingData = ratingSnapshot.data() as Map<String, dynamic>?;
        double oldRating = oldRatingData != null && oldRatingData.containsKey('rating') 
             ? (oldRatingData['rating'] as num).toDouble() : 0.0;

        if (currentTotalRatings > 0) {
          double oldSum = currentAverage * currentTotalRatings;
          double newSum = oldSum - oldRating + rating;
          double newAverage = newSum / currentTotalRatings;

          transaction.update(serviceDocRef, {
            'averageRating': newAverage,
          });
        } else {
          // Data inconsistency: rating doc exists but totalRatings is 0.
          // Rebuild from this single rating.
          transaction.update(serviceDocRef, {
            'averageRating': rating,
            'totalRatings': 1,
          });
        }
        transaction.update(ratingDocRef, {'rating': rating});
      } else {
        double newSum = (currentAverage * currentTotalRatings) + rating;
        int newTotal = currentTotalRatings + 1;
        double newAverage = newSum / newTotal;

        transaction.update(serviceDocRef, {
          'averageRating': newAverage,
          'totalRatings': newTotal,
        });

        transaction.set(ratingDocRef, {
          'userId': userId,
          'rating': rating,
        });
      }
    });
  }

  /// Safely deletes a service and its ratings subcollection.
  /// Favorites referencing this service are also removed.
  Future<void> deleteService(String serviceId) async {
    final serviceDocRef = _serviceCollection.doc(serviceId);

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int ops = 0;

    Future<void> commitBatchIfNeeded() async {
      if (ops >= 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        ops = 0;
      }
    }

    try {
      // 1. Delete ratings subcollection (Firestore does not cascade)
      final ratingsSnap = await serviceDocRef.collection('ratings').get();
      for (final doc in ratingsSnap.docs) {
        batch.delete(doc.reference);
        ops++;
        await commitBatchIfNeeded();
      }

      // 2. Remove from all users' favorites reliably
      try {
        final usersSnap = await FirebaseFirestore.instance.collection('users').get();
        for (final userDoc in usersSnap.docs) {
          final favDocRef = userDoc.reference.collection('favorite_services').doc(serviceId);
          batch.delete(favDocRef);
          ops++;
          await commitBatchIfNeeded();
        }
      } catch (e) {
        debugPrint('Error cleaning up favorite_services: $e');
      }

      // 3. Cancel all associated bookings safely
      try {
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('serviceId', isEqualTo: serviceId)
            .get();
        for (final bookingDoc in bookingsSnap.docs) {
          final data = bookingDoc.data();
          final String status = data['bookingStatus'] ?? data['status'] ?? 'pending';
          if (status == 'pending' || status == 'accepted' || status == 'in_progress') {
            batch.update(bookingDoc.reference, {
              'bookingStatus': 'cancelled',
              'updatedAt': Timestamp.now(),
            });
            ops++;
            await commitBatchIfNeeded();
          }
        }
      } catch (e) {
        debugPrint('Error cancelling bookings: $e');
      }

      // 4. Delete the service document itself
      batch.delete(serviceDocRef);
      ops++;
    } finally {
      // Always commit remaining operations, even if an earlier section threw
      if (ops > 0) {
        await batch.commit();
      }
    }
  }

  Map<String, dynamic> _buildProviderServiceData({
    required ResolvedProviderIdentity identity,
    required String categoryId,
    required String title,
    required String description,
    required String phone,
    required String location,
    required double startingPrice,
    required bool isNewService,
  }) {
    return {
      'categoryId': categoryId,
      'title': title,
      'providerId': identity.uid,
      'providerName': identity.displayName,
      'providerEmail': identity.email,
      'description': description,
      'phone': phone,
      'location': location,
      'startingPrice': toFirestorePriceNumber(startingPrice),
      'currency': 'JOD',
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNewService) 'approvalStatus': 'pending',
      if (isNewService) 'averageRating': 0.0,
      if (isNewService) 'totalRatings': 0,
      if (isNewService) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String? _readFirstNonEmptyString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _cleanString(data[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _emailPrefix(String? email) {
    final cleanedEmail = _cleanString(email);
    if (cleanedEmail == null || !cleanedEmail.contains('@')) return null;
    return cleanedEmail.split('@').first;
  }
}
