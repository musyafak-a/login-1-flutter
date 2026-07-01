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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            emailOrPhone TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            sportType TEXT NOT NULL,
            date TEXT NOT NULL,
            distanceKm REAL NOT NULL,
            durationSeconds INTEGER NOT NULL,
            paceSecondsPerKm REAL NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activities (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              distanceKm REAL NOT NULL,
              durationSeconds INTEGER NOT NULL,
              paceSecondsPerKm REAL NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE activities ADD COLUMN userId INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE activities ADD COLUMN sportType TEXT NOT NULL DEFAULT 'Lari'");
        }
      },
    );
  }

  /// Hash password sebelum disimpan (jangan simpan plain text).
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Daftarkan user baru. Return UserModel jika sukses,
  /// atau pesan error (String) jika gagal.
  Future<dynamic> registerUser({
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

    final id = await db.insert(
      'users',
      user.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return UserModel(
      id: id,
      name: user.name,
      emailOrPhone: user.emailOrPhone,
      passwordHash: user.passwordHash,
    );
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

  // ====================== ACTIVITIES (data lari) ======================

  /// Simpan satu sesi lari yang baru selesai.
  Future<int> insertActivity({
    required int userId,
    required String sportType,
    required DateTime date,
    required double distanceKm,
    required int durationSeconds,
  }) async {
    final db = await database;
    final pace = distanceKm > 0 ? durationSeconds / distanceKm : 0.0;

    return await db.insert('activities', {
      'userId': userId,
      'sportType': sportType,
      'date': date.toIso8601String(),
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'paceSecondsPerKm': pace,
    });
  }

  /// Ambil semua activity dalam rentang tanggal [start, end] (inklusif).
  Future<List<Map<String, dynamic>>> getActivitiesBetween(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day)
        .toIso8601String();
    final endStr =
        DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    return await db.query(
      'activities',
      where: 'userId = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startStr, endStr],
      orderBy: 'date ASC',
    );
  }

  /// Ambil semua activity dalam 1 bulan tertentu (untuk tabel absen).
  Future<List<Map<String, dynamic>>> getActivitiesForMonth(
    int userId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0); // hari terakhir bulan itu
    return getActivitiesBetween(userId, start, end);
  }

  /// Statistik 7 hari terakhir (untuk grafik mingguan).
  /// Return list 7 item berurutan dari hari tertua -> terbaru,
  /// masing-masing berisi {date, distanceKm, durationSeconds}.
  Future<List<Map<String, dynamic>>> getWeeklyStats(int userId, DateTime referenceDate) async {
    final today = DateTime(
        referenceDate.year, referenceDate.month, referenceDate.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final activities = await getActivitiesBetween(userId, startOfWeek, endOfWeek);

    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      double totalDistance = 0;
      int totalDuration = 0;

      for (final a in activities) {
        final aDate = DateTime.parse(a['date'] as String);
        if (aDate.year == day.year &&
            aDate.month == day.month &&
            aDate.day == day.day) {
          totalDistance += (a['distanceKm'] as num).toDouble();
          totalDuration += (a['durationSeconds'] as num).toInt();
        }
      }

      result.add({
        'date': day,
        'distanceKm': totalDistance,
        'durationSeconds': totalDuration,
      });
    }
    return result;
  }

  /// Get user overview: records today, streak, and favorite sport
  Future<Map<String, dynamic>> getUserOverview(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = today.toIso8601String();
    
    // 1. Jumlah record hari ini
    final todayRecords = await db.query(
      'activities',
      where: 'userId = ? AND date >= ?',
      whereArgs: [userId, todayStr],
    );
    final todayCount = todayRecords.length;

    // 2. Streak hari olahraga & Olahraga Favorit
    final allActivities = await db.query(
      'activities',
      columns: ['date', 'sportType'],
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    
    Set<String> uniqueDays = {};
    Map<String, int> sportCounts = {};
    for (var a in allActivities) {
       final d = DateTime.parse(a['date'] as String);
       uniqueDays.add(DateTime(d.year, d.month, d.day).toIso8601String());
       
       final sport = a['sportType'] as String? ?? 'Lari';
       sportCounts[sport] = (sportCounts[sport] ?? 0) + 1;
    }
    
    int streak = 0;
    DateTime checkDate = today;
    
    if (!uniqueDays.contains(checkDate.toIso8601String())) {
      if (uniqueDays.contains(checkDate.subtract(const Duration(days: 1)).toIso8601String())) {
         checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }
    
    while(uniqueDays.contains(checkDate.toIso8601String())) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    String favorite = 'Lari';
    int maxCount = 0;
    sportCounts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        favorite = key;
      }
    });

    return {
      'todayCount': todayCount,
      'streak': streak,
      'favorite': favorite, 
    };
  }
}
