import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'package:tanza_store/models/code_item.dart';
import 'package:tanza_store/models/product_transaction.dart';

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
    await _ensureTransactionsTable(_database!);
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'codes.db');
    return await openDatabase(
      path,
      version: 4, // Incremented to trigger onUpgrade
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE codes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            price REAL,
            stock INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
        CREATE TABLE transactions(
          id TEXT PRIMARY KEY,
          createdAt TEXT NOT NULL,
          total REAL NOT NULL,
          paid REAL NOT NULL,
          change REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          itemsJson TEXT NOT NULL
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Upgrade from version 1 to 2: add price column
          try {
            await db.execute('ALTER TABLE codes ADD COLUMN price REAL');
            log('codes table has been altered and price column has been added.');
          } catch (e) {
            log('Error adding price column during upgrade: $e');
            log('Error adding price column during upgrade: $e');
            log('Error adding price column',
                error: e, stackTrace: StackTrace.current);
          }
        }

        if (oldVersion < 3) {
          try {
            await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            createdAt TEXT NOT NULL,
            total REAL NOT NULL,
            paid REAL NOT NULL,
            change REAL NOT NULL,
            paymentMethod TEXT NOT NULL,
            itemsJson TEXT NOT NULL
          )
        ''');
            log('tansaction table has been added.');
          } catch (e) {
            log('Error adding price column during upgrade: $e');
          }
        }

        if (oldVersion < 4) {
          try {
            await db.execute(
                'ALTER TABLE codes ADD COLUMN stock INTEGER DEFAULT 0');
            log('stock column is added successfully.');
          } catch (e) {
            log('Error adding stock column: $e');
          }
        }
        // Future upgrades can be added here
      },
    );
  }

  Future<void> updateStock(String code, int newStock) async {
    final db = await database;
    await db.update('codes', {'stock': newStock},
        where: 'code = ?', whereArgs: [code]);
  }

  Future<void> insertTransaction(ProductTransaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<ProductTransaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'createdAt DESC');
    return maps.map((map) => ProductTransaction.fromMap(map)).toList();
  }

  // Fallback safety: ensure transactions table exists after opening
  Future<void> _ensureTransactionsTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions(
          id TEXT PRIMARY KEY,
          createdAt TEXT NOT NULL,
          total REAL NOT NULL,
          paid REAL NOT NULL,
          change REAL NOT NULL,
          paymentMethod TEXT NOT NULL,
          itemsJson TEXT NOT NULL
        )
      ''');
    } catch (e) {
      debugPrint('Error ensuring transactions table: $e');
      log('Error ensuring transactions table: $e');
    }
  }

  // Ensure the price column exists (adds it if missing)
  Future<void> _ensurePriceColumn(Database db) async {
    try {
      final List<Map<String, dynamic>> columns =
          await db.rawQuery("PRAGMA table_info(codes)");
      bool hasPrice = columns.any((col) => col['name'] == 'price');
      if (!hasPrice) {
        await db.execute('ALTER TABLE codes ADD COLUMN price REAL');
        log('Price column added successfully.');
      }
    } catch (e) {
      log('Error ensuring price column: $e');
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
