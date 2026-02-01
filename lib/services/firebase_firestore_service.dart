import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';

class FirebaseFirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Backs up all entries to Firestore for the current user.
  /// Robustly handles empty lists and large datasets via chunked batches.
  static Future<void> backupAllEntries(List<EntryModel> entries) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);

    userDoc.set({
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final entriesCol = userDoc.collection('entries');

    // 1. Clear old backup (if any)
    final existing = await entriesCol.get();
    await _commitInBatches(existing.docs.map((d) => d.reference).toList(), (
      batch,
      ref,
    ) {
      batch.delete(ref as DocumentReference);
    });

    // 2. Upload new backup
    await _commitInBatches(entries, (batch, entry) {
      batch.set(entriesCol.doc(entry.id), {
        'id': entry.id,
        'body': entry.body,
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'updatedAt': Timestamp.fromDate(entry.updatedAt),
      });
    });

    // 3. Update "lastBackUp" timestamp on user document
    await userDoc.set({
      'lastBackUp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Syncs only the changes (updates/inserts and deletions) to Firestore.
  static Future<void> syncChanges(
    List<EntryModel> updates,
    List<String> deletedIds,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);
    final entriesCol = userDoc.collection('entries');

    // 1. Process Updates
    if (updates.isNotEmpty) {
      await _commitInBatches(updates, (batch, entry) {
        batch.set(entriesCol.doc(entry.id), {
          'id': entry.id,
          'body': entry.body,
          'createdAt': Timestamp.fromDate(entry.createdAt),
          'updatedAt': Timestamp.fromDate(entry.updatedAt),
        }, SetOptions(merge: true));
      });
    }

    // 2. Process Deletions
    if (deletedIds.isNotEmpty) {
      await _commitInBatches(deletedIds, (batch, id) {
        batch.delete(entriesCol.doc(id));
      });
    }

    // 3. Update Metadata
    await userDoc.set({
      'lastBackUp': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Helper to run Firestore operations in batches of 500 (Firestore limit).
  static Future<void> _commitInBatches<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) action,
  ) async {
    for (var i = 0; i < items.length; i += 500) {
      final batch = _db.batch();
      final chunk = items.skip(i).take(500);
      for (final item in chunk) {
        action(batch, item);
      }
      await batch.commit();
    }
  }

  /// Retrieves the last successful backup time.
  static Future<DateTime?> getLastBackupTime() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['lastBackUp'] as Timestamp?)?.toDate();
  }
}
