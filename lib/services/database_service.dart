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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        // Initialize deleted_entries table on fresh install
        await db.execute('''
          CREATE TABLE deleted_entries (
            id TEXT PRIMARY KEY
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
      },
    );
  }

  static Future<List<EntryModel>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('entries', orderBy: 'createdAt DESC');
    return maps
        .map(
          (map) => EntryModel(
            id: map['id'] as String,
            body: map['body'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
          ),
        )
        .toList();
  }

  static Future<List<EntryModel>> getEntriesModifiedSince(DateTime date) async {
    final db = await database;
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
    });
  }

  static Future<void> updateEntry(EntryModel entry) async {
    final db = await database;
    await db.update(
      'entries',
      {'body': entry.body, 'updatedAt': entry.updatedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  static Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('entries', where: 'id = ?', whereArgs: [id]);
      await txn.insert('deleted_entries', {
        'id': id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  static Future<List<String>> getDeletionQueue() async {
    final db = await database;
    final result = await db.query('deleted_entries');
    return result.map((e) => e['id'] as String).toList();
  }

  static Future<void> clearDeletionQueue(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    await db.delete(
      'deleted_entries',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
}
