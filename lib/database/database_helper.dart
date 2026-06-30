import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';

/// Helper untuk mengelola database SQLite lokal.
/// Tabel `users` menyimpan: id, name, emailOrPhone, passwordHash.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auth_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            emailOrPhone TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Hash password sebelum disimpan (jangan simpan plain text).
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Daftarkan user baru. Return null jika sukses,
  /// atau pesan error (mis. email/phone sudah terdaftar).
  Future<String?> registerUser({
    required String name,
    required String emailOrPhone,
    required String password,
  }) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'emailOrPhone = ?',
      whereArgs: [emailOrPhone],
    );
    if (existing.isNotEmpty) {
      return 'Email/No HP sudah terdaftar';
    }

    final user = UserModel(
      name: name,
      emailOrPhone: emailOrPhone,
      passwordHash: hashPassword(password),
    );

    await db.insert(
      'users',
      user.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return null; // sukses
  }

  /// Cek login. Return UserModel jika cocok, null jika gagal.
  Future<UserModel?> loginUser({
    required String emailOrPhone,
    required String password,
  }) async {
    final db = await database;
    final hashed = hashPassword(password);

    final result = await db.query(
      'users',
      where: 'emailOrPhone = ? AND passwordHash = ?',
      whereArgs: [emailOrPhone, hashed],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
