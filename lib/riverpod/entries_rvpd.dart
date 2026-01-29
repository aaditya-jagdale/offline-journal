import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/services/database_service.dart';
import 'package:uuid/uuid.dart';

final entriesProvider =
    AsyncNotifierProvider<EntriesNotifier, List<EntryModel>>(
      () => EntriesNotifier(),
    );

class EntriesNotifier extends AsyncNotifier<List<EntryModel>> {
  @override
  Future<List<EntryModel>> build() async {
    return DatabaseService.getAllEntries();
  }

  Future<EntryModel> createEntry() async {
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
