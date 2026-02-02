import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/riverpod/preferences_rvpd.dart';
import 'package:jrnl/services/database_service.dart';
import 'package:jrnl/services/firebase_firestore_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _isSyncing = false;

  /// Orchestrates the Delta Sync process.
  /// Returns [true] if a sync was performed, [false] if skipped or failed.
  Future<bool> syncIfNeeded(WidgetRef ref) async {
    if (_isSyncing) return false;

    try {
      _isSyncing = true;

      final prefs = ref.read(preferencesProvider).value;
      if (prefs?.isAutoBackupEnabled != true) return false;

      final lastSync =
          prefs?.lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);

      final updates = await DatabaseService.getEntriesModifiedSince(lastSync);

      if (updates.isEmpty) {
        debugPrint('SyncService: No changes to sync (0 writes).');
        return false;
      }

      debugPrint(
        'SyncService: Syncing ${updates.length} changes (includes soft deletes)...',
      );

      await FirebaseFirestoreService.syncChanges(updates);
      await ref
          .read(preferencesProvider.notifier)
          .setLastSyncTime(DateTime.now());

      debugPrint('SyncService: Sync complete.');
      return true;
    } catch (e) {
      debugPrint('SyncService: Error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Restore all data from Firebase, replacing local data completely
  /// This deletes ALL local entries and replaces with Firebase data
  /// Returns [true] if successful, [false] if failed
  Future<bool> restoreFromFirebase() async {
    if (_isSyncing) return false;

    try {
      _isSyncing = true;
      debugPrint('SyncService: Starting Firebase restore...');

      // 1. Fetch all entries from Firebase
      debugPrint('SyncService: Fetching all entries from Firebase...');
      final firebaseEntries =
          await FirebaseFirestoreService.getAllEntriesFromFirebase();
      debugPrint(
        'SyncService: Found ${firebaseEntries.length} entries in Firebase',
      );

      // 2. Delete all local entries
      debugPrint('SyncService: Deleting all local entries...');
      await DatabaseService.deleteAllEntries();

      // 3. Insert Firebase entries into local database
      if (firebaseEntries.isNotEmpty) {
        debugPrint(
          'SyncService: Inserting ${firebaseEntries.length} entries into local database...',
        );
        await DatabaseService.bulkInsertEntries(firebaseEntries);
      }

      debugPrint('SyncService: Firebase restore complete!');
      return true;
    } catch (e, stack) {
      debugPrint('SyncService: Error during Firebase restore: $e');
      debugPrint('SyncService: Stack trace: $stack');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
