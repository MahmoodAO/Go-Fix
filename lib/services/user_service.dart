import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// خدمة المستخدم – تدير بيانات المستخدم وأدواره في Firestore.
/// UserService – manages user profile and role data in Firestore.
class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// جلب دور المستخدم من Firestore (customer أو provider).
  /// إذا لم يكن الحقل موجوداً، يرجع "customer" كقيمة افتراضية.
  /// Fetches the user's role. Defaults to "customer" if missing.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String? ?? 'customer';
      }
      return 'customer';
    } catch (e) {
      debugPrint('⚠️ Error fetching user role: $e');
      return 'customer';
    }
  }

  /// تعيين أو تحديث دور المستخدم في Firestore.
  /// Sets or updates the user's role in Firestore.
  Future<void> setUserRole(String uid, String role) async {
    await _usersCollection.doc(uid).set(
      {'role': role, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// جلب بيانات ملف المستخدم الكاملة.
  /// Fetches the full user profile document.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
      return null;
    }
  }
}
