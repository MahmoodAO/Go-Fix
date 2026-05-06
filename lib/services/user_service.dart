import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ø®Ø¯Ù…Ø© Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… â€“ ØªØ¯ÙŠØ± Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… ÙˆØ£Ø¯ÙˆØ§Ø±Ù‡ ÙÙŠ Firestore.
/// UserService â€“ manages user profile and role data in Firestore.
class UserService {
  UserService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _usersCollection =
            (firestore ?? FirebaseFirestore.instance).collection('users');

  final FirebaseAuth _firebaseAuth;
  final CollectionReference<Map<String, dynamic>> _usersCollection;

  /// Ø¬Ù„Ø¨ Ø¯ÙˆØ± Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ù…Ù† Firestore (customer Ø£Ùˆ provider).
  /// Ø¥Ø°Ø§ Ù„Ù… ÙŠÙƒÙ† Ø§Ù„Ø­Ù‚Ù„ Ù…ÙˆØ¬ÙˆØ¯Ø§Ù‹ØŒ ÙŠØ±Ø¬Ø¹ "customer" ÙƒÙ‚ÙŠÙ…Ø© Ø§ÙØªØ±Ø§Ø¶ÙŠØ©.
  /// Fetches the user's role. Defaults to "customer" if missing.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['role'] as String? ?? 'customer';
      }
      return 'customer';
    } catch (e) {
      debugPrint('âš ï¸ Error fetching user role: $e');
      return 'customer';
    }
  }

  /// ØªØ¹ÙŠÙŠÙ† Ø£Ùˆ ØªØ­Ø¯ÙŠØ« Ø¯ÙˆØ± Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… ÙÙŠ Firestore.
  /// Sets or updates the user's role in Firestore.
  Future<void> setUserRole(String uid, String role) async {
    await _usersCollection.doc(uid).set(
      {'role': role, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Ø¬Ù„Ø¨ Ø¨ÙŠØ§Ù†Ø§Øª Ù…Ù„Ù Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ø§Ù„ÙƒØ§Ù…Ù„Ø©.
  /// Fetches the full user profile document.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      return null;
    } catch (e) {
      debugPrint('âš ï¸ Error fetching user profile: $e');
      return null;
    }
  }

  /// Fetches the current signed-in user's profile from the users collection.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  /// Creates a new user profile document using the existing users collection.
  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String role,
  }) async {
    await _usersCollection.doc(uid).set({
      'displayName': displayName,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the current signed-in user's profile fields.
  Future<void> updateCurrentUserProfile({
    String? displayName,
    String? email,
    String? role,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (email != null) updates['email'] = email;
    if (role != null) updates['role'] = role;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _usersCollection.doc(user.uid).set(
      updates,
      SetOptions(merge: true),
    );
  }

  /// Fetches only the displayName field for a given user.
  Future<String> getUserDisplayName(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['displayName'] as String? ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('âš ï¸ Error fetching user display name: $e');
      return '';
    }
  }
}
