/// One-time Firestore migration script.
/// Copies the legacy `status` field to `approvalStatus` for any service
/// that has `status` but not `approvalStatus`.
///
/// HOW TO RUN:
/// 1. Add this as a Cloud Function or run it from a Dart script with
///    firebase_admin or cloud_firestore configured.
/// 2. Alternatively, call `migrateStatusToApprovalStatus()` from a
///    temporary admin button in the app.
///
/// This is safe to run multiple times (idempotent).

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateStatusToApprovalStatus() async {
  final db = FirebaseFirestore.instance;
  final servicesSnap = await db.collection('services').get();

  int migratedCount = 0;
  final WriteBatch batch = db.batch();

  for (final doc in servicesSnap.docs) {
    final data = doc.data();

    // Only migrate docs that have legacy `status` but no `approvalStatus`
    if (data.containsKey('status') && !data.containsKey('approvalStatus')) {
      batch.update(doc.reference, {
        'approvalStatus': data['status'],
      });
      migratedCount++;
    }

    // Commit in batches of 400 (Firestore limit is 500)
    if (migratedCount > 0 && migratedCount % 400 == 0) {
      await batch.commit();
    }
  }

  // Final commit
  if (migratedCount % 400 != 0) {
    await batch.commit();
  }

  // ignore: avoid_print
  print('Migration complete: $migratedCount services updated.');
}
