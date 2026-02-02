import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'journal.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isDeleted INTEGER DEFAULT 0,
            hasImage INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE deleted_entries (
              id TEXT PRIMARY KEY
            )
          ''');
        }
        if (oldVersion < 3) {
          // Add isDeleted column
          await db.execute(
            'ALTER TABLE entries ADD COLUMN isDeleted INTEGER DEFAULT 0',
          );
          // Migrate old deleted_entries to soft deletes if needed
          try {
            await db.query('deleted_entries');
            await db.execute('DROP TABLE IF EXISTS deleted_entries');
          } catch (_) {
            // Table might not exist
          }
        }
        if (oldVersion < 4) {
          // Add hasImage column
          await db.execute(
            'ALTER TABLE entries ADD COLUMN hasImage INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  static Future<List<EntryModel>> getAllEntries() async {
    final db = await database;
    // Filter out soft-deleted entries for UI
    final maps = await db.query(
      'entries',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return maps
        .map(
          (map) => EntryModel(
            id: map['id'] as String,
            body: map['body'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
            isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
            hasImage: (map['hasImage'] as int? ?? 0) == 1,
          ),
        )
        .toList();
  }

  static Future<void> deleteAllEntries() async {
    final db = await database;
    await db.delete('entries');
  }

  static Future<List<EntryModel>> getEntriesModifiedSince(DateTime date) async {
    final db = await database;
    // FETCH ALL (including deleted) for sync
    final maps = await db.query(
      'entries',
      where: 'updatedAt > ?',
      whereArgs: [date.toIso8601String()],
    );
    return maps
        .map(
          (map) => EntryModel(
            id: map['id'] as String,
            body: map['body'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
            isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
            hasImage: (map['hasImage'] as int? ?? 0) == 1,
          ),
        )
        .toList();
  }

  static Future<void> insertEntry(EntryModel entry) async {
    final db = await database;
    await db.insert('entries', {
      'id': entry.id,
      'body': entry.body,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
      'isDeleted': entry.isDeleted ? 1 : 0,
      'hasImage': entry.hasImage ? 1 : 0,
    });
  }

  static Future<void> updateEntry(EntryModel entry) async {
    final db = await database;
    await db.update(
      'entries',
      {
        'body': entry.body,
        'updatedAt': entry.updatedAt.toIso8601String(),
        'isDeleted': entry.isDeleted ? 1 : 0,
        'hasImage': entry.hasImage ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  static Future<void> deleteEntry(String id) async {
    final db = await database;
    // Soft delete: Mark isDeleted = 1 and update timestamp
    await db.update(
      'entries',
      {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Bulk insert entries (used for restoring from Firebase)
  /// Efficiently inserts multiple entries in a batch transaction
  static Future<void> bulkInsertEntries(List<EntryModel> entries) async {
    if (entries.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (final entry in entries) {
      batch.insert('entries', {
        'id': entry.id,
        'body': entry.body,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
        'isDeleted': entry.isDeleted ? 1 : 0,
        'hasImage': entry.hasImage ? 1 : 0,
      });
    }

    await batch.commit(noResult: true);
  }
}
