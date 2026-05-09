import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة المفضلة، وتدير إضافة الخدمات وإزالتها للمستخدم الحالي.
class FavoritesService {
  /// مرجع Firestore للوصول إلى بيانات المفضلة.
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance; // عشان نتعامل مع المستخدم الحالي

  /// إرجاع المجموعة الفرعية الخاصة بمفضلة المستخدم الحالي إن كان مسجل الدخول.
  /// Returns the user's favorites subcollection, or null if not authenticated.
  CollectionReference? get _favoritesRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorite_services');
  }

  /// إضافة خدمة إلى مفضلة المستخدم مع حفظ وقت الإضافة.
  /// Add service to favorites using serviceId
  Future<void> addToFavorites(String serviceId) async {
    final ref = _favoritesRef;
    if (ref == null) return;
    try {
      // استخدام معرّف الخدمة كمفتاح للمستند لتسهيل التحقق من وجودها في المفضلة.
      await ref.doc(serviceId).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  /// إزالة خدمة من قائمة المفضلة للمستخدم الحالي.
  /// Remove service from favorites
  Future<void> removeFromFavorites(String serviceId) async {
    final ref = _favoritesRef;
    if (ref == null) return;
    try {
      await ref.doc(serviceId).delete();
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  /// جلب معرّفات الخدمات المفضلة مرة واحدة للاستخدام غير المباشر.
  /// Get all favorite service IDs once (non-realtime)
  Future<List<String>> getFavoriteServiceIdsOnce() async {
    final ref = _favoritesRef;
    if (ref == null) return [];
    try {
      final snapshot = await ref.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting favorite services: $e');
      return [];
    }
  }

  /// الاستماع المباشر لتغييرات المفضلة وعرضها فورًا في الواجهة.
  /// Listen to favorite services (real-time stream)
  Stream<List<String>> getFavoriteServiceIdsStream() {
    final ref = _favoritesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
    );
  }

}
