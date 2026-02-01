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

      // 1. Check Preferences
      final prefs = ref.read(preferencesProvider).value;
      if (prefs?.isAutoBackupEnabled != true) return false;

      // 2. Identify Deltas
      // If lastSyncTime is null, we sync everything (since Epoch 0)
      final lastSync =
          prefs?.lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);

      final updates = await DatabaseService.getEntriesModifiedSince(lastSync);
      final deletedIds = await DatabaseService.getDeletionQueue();

      // 3. Early Exit if No Changes
      if (updates.isEmpty && deletedIds.isEmpty) {
        debugPrint('SyncService: No changes to sync (0 writes).');
        return false;
      }

      debugPrint(
        'SyncService: Syncing ${updates.length} updates and ${deletedIds.length} deletions...',
      );

      // 4. Push to Cloud
      await FirebaseFirestoreService.syncChanges(updates, deletedIds);

      // 5. Commit Success (Update Local State)
      // Capture timestamp BEFORE the sync started ideally, but effectively 'now' is fine
      // provided we handle slight drifts. Using 'now' is safer to avoid missed windows.
      await ref
          .read(preferencesProvider.notifier)
          .setLastSyncTime(DateTime.now());

      if (deletedIds.isNotEmpty) {
        await DatabaseService.clearDeletionQueue(deletedIds);
      }

      debugPrint('SyncService: Sync complete.');
      return true;
    } catch (e) {
      debugPrint('SyncService: Error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
