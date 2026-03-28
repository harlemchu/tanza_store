import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/code_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    // Ensure the price column exists (fix for missing column)
    await _ensurePriceColumn(_database!);
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'codes.db');
    return await openDatabase(
      path,
      version: 3, // Incremented to trigger onUpgrade
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE codes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            price REAL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Upgrade from version 1 to 2: add price column
          try {
            await db.execute('ALTER TABLE codes ADD COLUMN price REAL');
          } catch (e) {
            print('Error adding price column during upgrade: $e');
          }
        }
        // Future upgrades can be added here
      },
    );
  }

  // Ensure the price column exists (adds it if missing)
  Future<void> _ensurePriceColumn(Database db) async {
    try {
      final List<Map<String, dynamic>> columns =
          await db.rawQuery("PRAGMA table_info(codes)");
      bool hasPrice = columns.any((col) => col['name'] == 'price');
      if (!hasPrice) {
        await db.execute('ALTER TABLE codes ADD COLUMN price REAL');
        print('Price column added successfully.');
      }
    } catch (e) {
      print('Error ensuring price column: $e');
    }
  }

  // --- Existing CRUD methods (unchanged) ---
  Future<int> insertCode(CodeItem item) async {
    final db = await database;
    return await db.insert('codes', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CodeItem?> getCodeByCode(String code) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'codes',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (maps.isNotEmpty) {
      return CodeItem.fromMap(maps.first);
    }
    return null;
  }

  Future<List<CodeItem>> getAllCodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('codes');
    return maps.map((map) => CodeItem.fromMap(map)).toList();
  }

  Future<int> updateCode(CodeItem item) async {
    final db = await database;
    return await db.update(
      'codes',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCode(int id) async {
    final db = await database;
    return await db.delete(
      'codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
