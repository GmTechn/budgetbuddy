import 'dart:async';
import 'dart:io';
import 'package:expenses_tracker/models/cardmodel.dart';
import 'package:expenses_tracker/models/notificationmodel.dart';
import 'package:expenses_tracker/models/transactionmodel.dart';
import 'package:expenses_tracker/models/usermodel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialisation();
    return _database!;
  }

  /// ✅ Initialise la base de données
  Future<void> initialisation() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'users_database.db'),
      version: 5, // ⬅️ nouvelle version pour inclure notifications + type
      onCreate: (db, version) async {
        // --- Users ---
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fname TEXT,
            lname TEXT,
            email TEXT UNIQUE,
            password TEXT,
            phone TEXT,
            photoPath TEXT
          )
        ''');

        // --- Transactions ---
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            place TEXT,
            amount REAL,
            date TEXT,
            logoPath TEXT,
            cardId INTEGER,
            type TEXT DEFAULT 'expense'
          )
        ''');

        // --- Cards ---
        await db.execute('''
          CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            amount TEXT,
            cardnumber TEXT,
            expirydate TEXT,
            username TEXT,
            colorOne INTEGER,
            colorTwo INTEGER,
            colorThree INTEGER,
            isDefault INTEGER DEFAULT 0
          )
        ''');

        // --- Notifications ---
        await db.execute('''
          CREATE TABLE notifications(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            date TEXT,
            read INTEGER DEFAULT 0,
            cardLast4 TEXT,
            type TEXT
          )
        ''');
      },

      // ✅ Migration
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE cards ADD COLUMN isDefault INTEGER DEFAULT 0');
          await db
              .execute('ALTER TABLE transactions ADD COLUMN cardId INTEGER');
          await db
              .execute('ALTER TABLE cards ADD COLUMN amount REAL DEFAULT 0');
          await db.execute(
              'ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "expense"');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications(
              id TEXT PRIMARY KEY,
              title TEXT,
              description TEXT,
              date TEXT,
              read INTEGER DEFAULT 0,
              cardLast4 TEXT,
              type TEXT
            )
          ''');
        }
      },
    );
  }

  /// ✅ Supprimer complètement la base de données (dev uniquement)
  Future<void> clearDatabase() async {
    final path = join(await getDatabasesPath(), 'users_database.db');
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }
    _database = null;
  }

  // ------------ USERS ------------- //

  Future<List<AppUser>> getAllAppUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => AppUser.fromMap(map)).toList();
  }

  Future<void> insertAppUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAppUser(AppUser user) async {
    final db = await database;
    final existing =
        await db.query('users', where: 'email = ?', whereArgs: [user.email]);
    if (existing.isEmpty) {
      await db.insert('users', user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update('users', user.toMap(),
          where: 'email = ?', whereArgs: [user.email]);
    }
  }

  Future<void> deleteAppUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return AppUser.fromMap(result.first);
    return null;
  }

  // ------------ TRANSACTIONS ------------ //

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions(String email) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'email = ?',
      whereArgs: [email],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getTransactionsByCard(
      String email, int cardId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'email = ? AND cardId = ?',
      whereArgs: [email, cardId],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // ------------ CARDS ------------ //

  Future<CardModel?> getDefaultCard(String email) async {
    final db = await database;
    final result = await db.query('cards',
        where: 'email = ? AND isDefault = 1', whereArgs: [email]);
    if (result.isNotEmpty) return CardModel.fromMap(result.first);
    return null;
  }

  Future<List<CardModel>> getCards(String email) async {
    final db = await database;
    final result =
        await db.query('cards', where: 'email = ?', whereArgs: [email]);
    return result.map((map) => CardModel.fromMap(map)).toList();
  }

  Future<int> insertCard(CardModel card) async {
    final db = await database;
    return await db.insert('cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCard(CardModel card) async {
    final db = await database;
    return await db.update('cards', card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCard(int id) async {
    final db = await database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultCard(String email, int cardID) async {
    final db = await database;
    await db.update('cards', {'isDefault': 0},
        where: 'email = ?', whereArgs: [email]);
    await db.update('cards', {'isDefault': 1},
        where: 'id = ?', whereArgs: [cardID]);
  }

  Future<CardModel?> getCardById(int id) async {
    final db = await database;
    final result = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return CardModel.fromMap(result.first);
    }
    return null;
  }

  // ------------ NOTIFICATIONS ------------ //

  Future<void> insertNotification(AppNotification notif) async {
    final db = await database;
    await db.insert('notifications', notif.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppNotification>> getNotifications() async {
    final db = await database;
    final maps = await db.query('notifications', orderBy: 'date DESC');
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<void> deleteNotification(String id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = await database;
    await db.update('notifications', {'read': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}
