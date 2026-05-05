import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance; // عشان نتعامل مع المستخدم الحالي

  /// Returns the user's favorites subcollection, or null if not authenticated.
  CollectionReference? get _favoritesRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorite_services');
  }

  /// Add service to favorites using serviceId
  Future<void> addToFavorites(String serviceId) async {
    final ref = _favoritesRef;
    if (ref == null) return;
    try {
      await ref.doc(serviceId).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

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

  /// Listen to favorite services (real-time stream)
  Stream<List<String>> getFavoriteServiceIdsStream() {
    final ref = _favoritesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
    );
  }

}
