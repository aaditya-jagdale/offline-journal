import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/modules/shared/exceptions/entry_limit_exception.dart';
import 'package:jrnl/services/database_service.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:uuid/uuid.dart';

final entriesProvider =
    AsyncNotifierProvider<EntriesNotifier, List<EntryModel>>(
      () => EntriesNotifier(),
    );

/// Provider for the current entry count from the database.
final entryCountProvider = FutureProvider<int>((ref) async {
  final entries = await ref.watch(entriesProvider.future);
  return entries.length;
});

class EntriesNotifier extends AsyncNotifier<List<EntryModel>> {
  @override
  Future<List<EntryModel>> build() async {
    return DatabaseService.getAllEntries();
  }

  Future<void> getEntries() async {
    state = AsyncValue.data(await DatabaseService.getAllEntries());
  }

  Future<EntryModel> createEntry({required bool isPro}) async {
    final currentCount = state.value?.length ?? 0;

    // Defense layer 3: Final check at creation time
    if (!isPro && currentCount >= RevenueCatService.freeEntryLimit) {
      throw EntryLimitException(limit: RevenueCatService.freeEntryLimit);
    }

    final now = DateTime.now();
    final entry = EntryModel(
      id: const Uuid().v4(),
      body: '',
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.insertEntry(entry);
    state = AsyncValue.data([entry, ...state.value!]);
    return entry;
  }

  Future<void> updateEntry(EntryModel entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await DatabaseService.updateEntry(updated);
    state = AsyncValue.data(
      state.value!.map((e) => e.id == entry.id ? updated : e).toList(),
    );
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.deleteEntry(id);
    state = AsyncValue.data(state.value!.where((e) => e.id != id).toList());
  }
}
