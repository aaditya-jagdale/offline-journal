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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
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
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
