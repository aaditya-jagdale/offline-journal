import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';

class FirebaseFirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> backupAllEntries(List<EntryModel> entries) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);

    userDoc.set({
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final entriesCol = userDoc.collection('entries');

    final existing = await entriesCol.get();
    await _commitInBatches(existing.docs.map((d) => d.reference).toList(), (
      batch,
      ref,
    ) {
      batch.delete(ref as DocumentReference);
    });

    await _commitInBatches(entries, (batch, entry) {
      batch.set(entriesCol.doc(entry.id), {
        'id': entry.id,
        'body': entry.body,
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'updatedAt': Timestamp.fromDate(entry.updatedAt),
      });
    });

    await userDoc.set({
      'lastBackUp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> syncChanges(List<EntryModel> updates) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);
    final entriesCol = userDoc.collection('entries');

    // 1. Process Updates (Active & Soft Deleted)
    if (updates.isNotEmpty) {
      await _commitInBatches(updates, (batch, entry) {
        batch.set(entriesCol.doc(entry.id), {
          'id': entry.id,
          'body': entry.body,
          'createdAt': Timestamp.fromDate(entry.createdAt),
          'updatedAt': Timestamp.fromDate(entry.updatedAt),
          'isDeleted': entry.isDeleted,
        }, SetOptions(merge: true));
      });
    }

    // 2. Update Metadata
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

  static Future<DateTime?> getLastBackupTime() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['lastBackUp'] as Timestamp?)?.toDate();
  }
}
