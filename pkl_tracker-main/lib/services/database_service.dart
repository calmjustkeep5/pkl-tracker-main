import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/attendance_model.dart';
import '../models/logbook_model.dart';
import 'api_service.dart';

class DatabaseService {
  static Database? _db;
  static const _dbName = 'pkl_tracker.db';
  static const _dbVersion = 8;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // TABEL USERS
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            no_induk TEXT,
            sekolah TEXT,
            jurusan TEXT,
            alamat TEXT, 
            photo_url TEXT,
            phone TEXT,
            guru_uid TEXT,
            pkl_place_name TEXT,
            pkl_place_address TEXT,
            pkl_lat REAL,
            pkl_lng REAL,
            created_at TEXT NOT NULL
          )
        ''');

        // TABEL ATTENDANCE
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT UNIQUE NOT NULL,
            user_id TEXT NOT NULL,
            tanggal TEXT NOT NULL,
            check_in TEXT,
            check_out TEXT,
            status TEXT NOT NULL,
            check_in_lat REAL,
            check_in_lng REAL,
            check_out_lat REAL,
            check_out_lng REAL,
            keterangan TEXT,
            alasan_izin TEXT,
            bukti_foto_path TEXT
          )
        ''');

        // TABEL LOGBOOK
        await db.execute('''
          CREATE TABLE logbook (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT UNIQUE NOT NULL,
            user_id TEXT NOT NULL,
            tanggal TEXT NOT NULL,
            kegiatan TEXT NOT NULL,
            foto_bukti TEXT,
            status TEXT NOT NULL,
            catatan_guru TEXT,
            guru_id TEXT,
            location_lat REAL,
            location_lng REAL,
            location_address TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // TABEL ACTIVITIES
        await db.execute('''
          CREATE TABLE activities (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE logbook ADD COLUMN location_lat REAL');
          await db.execute('ALTER TABLE logbook ADD COLUMN location_lng REAL');
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE logbook ADD COLUMN location_address TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE attendance ADD COLUMN alasan_izin TEXT',
          );
          await db.execute(
            'ALTER TABLE attendance ADD COLUMN bukti_foto_path TEXT',
          );
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE users ADD COLUMN pkl_place_name TEXT');
          await db.execute(
            'ALTER TABLE users ADD COLUMN pkl_place_address TEXT',
          );
          await db.execute('ALTER TABLE users ADD COLUMN pkl_lat REAL');
          await db.execute('ALTER TABLE users ADD COLUMN pkl_lng REAL');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE users ADD COLUMN guru_uid TEXT');
        }
        if (oldVersion < 8) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
          } catch (_) {
            // Kolom mungkin sudah ada
          }
        }
      },
    );
  }

  // ======================== ACTIVITIES (Local) ========================

  static Future<void> addActivity(ActivityModel activity) async {
    final db = await database;
    await db.insert('activities', {
      'id': activity.id,
      'user_id': activity.userId,
      'title': activity.title,
      'date': activity.date.toIso8601String(),
    });
  }

  static Future<List<ActivityModel>> getUserActivities(String userId) async {
    final db = await database;
    final res = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return res
        .map(
          (e) => ActivityModel(
            id: e['id'] as String,
            userId: e['user_id'] as String,
            title: e['title'] as String,
            date: DateTime.parse(e['date'] as String),
          ),
        )
        .toList();
  }

  // ======================== AUTH & USER ========================

  static Future<bool> registerUser(UserModel user) async {
    try {
      final db = await database;
      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      print("ERROR REGISTER: $e");
      return false;
    }
  }

  static Future<UserModel?> getUserById(String uid) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }

  static Future<UserModel?> getActivePklLocation() async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'role = ? AND pkl_lat IS NOT NULL AND pkl_lng IS NOT NULL',
      whereArgs: ['guru'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }

  static Future<UserModel?> getFirstGuru() async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['guru'],
      limit: 1,
    );
    return res.isNotEmpty ? UserModel.fromMap(res.first) : null;
  }

  static Future<void> syncUsersFromServer() async {
    try {
      final remoteUsers = await ApiService().fetchUsers();
      final db = await database;
      final batch = db.batch();
      for (final user in remoteUsers) {
        batch.insert(
          'users',
          user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('ERROR SYNC USERS FROM SERVER: $e');
    }
  }

  static Future<List<UserModel>> getAllSiswa({String? guruUid}) async {
    final db = await database;
    late final List<Map<String, Object?>> res;
    if (guruUid != null && guruUid.isNotEmpty) {
      res = await db.query(
        'users',
        where: 'role = ? AND (guru_uid IS NULL OR guru_uid = ?)',
        whereArgs: ['siswa', guruUid],
      );
    } else {
      res = await db.query('users', where: 'role = ?', whereArgs: ['siswa']);
    }
    return res.map((e) => UserModel.fromMap(e)).toList();
  }

  static Future<List<UserModel>> getSiswaByGuru(String guruUid) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'role = ? AND guru_uid = ?',
      whereArgs: ['siswa', guruUid],
    );
    return res.map((e) => UserModel.fromMap(e)).toList();
  }

  static Future<int> updateUser(UserModel user) async {
    try {
      final db = await database;
      final data = user.toMap();
      data.remove('id');
      return await db.update(
        'users',
        data,
        where: 'uid = ?',
        whereArgs: [user.uid],
      );
    } catch (e) {
      print("ERROR UPDATE USER: $e");
      rethrow;
    }
  }

  static Future<void> upsertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ======================== ATTENDANCE (PRESENSI) ========================

  static Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final db = await database;
    final now = DateTime.now();
    final tgl =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final res = await db.query(
      'attendance',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, tgl],
      limit: 1,
    );
    return res.isNotEmpty ? AttendanceModel.fromMap(res.first) : null;
  }

  static Future<bool> checkIn({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final tgl =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final existing = await db.query(
        'attendance',
        where: 'user_id = ? AND tanggal = ?',
        whereArgs: [userId, tgl],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return false;
      }
      final jam =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final attendance = AttendanceModel(
        uid: const Uuid().v4(),
        userId: userId,
        tanggal: tgl,
        checkIn: jam,
        status: now.hour < 8 ? 'hadir' : 'terlambat',
        checkInLat: lat,
        checkInLng: lng,
      );

      await db.insert('attendance', attendance.toMap());
      await ApiService().submitAttendance(attendance);
      return true;
    } catch (e) {
      print("ERROR CHECK IN: $e");
      return false;
    }
  }

  static Future<bool> checkOut({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final tgl =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final jam =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final existing = await db.query(
        'attendance',
        where: 'user_id = ? AND tanggal = ?',
        whereArgs: [userId, tgl],
        limit: 1,
      );
      if (existing.isEmpty) {
        return false;
      }

      final current = AttendanceModel.fromMap(existing.first);
      final updated = current.copyWith(
        checkOut: jam,
        checkOutLat: lat,
        checkOutLng: lng,
      );

      final count = await db.update(
        'attendance',
        updated.toMap(),
        where: 'user_id = ? AND tanggal = ?',
        whereArgs: [userId, tgl],
      );
      if (count > 0) {
        await ApiService().submitAttendance(updated);
      }
      return count > 0;
    } catch (e) {
      print("ERROR CHECK OUT: $e");
      return false;
    }
  }

  static Future<bool> submitIzin({
    required String userId,
    required String alasanIzin,
    required String keterangan,
    required String buktiFotoPath,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final tgl =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final existing = await db.query(
        'attendance',
        where: 'user_id = ? AND tanggal = ? AND status = ?',
        whereArgs: [userId, tgl, 'izin'],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return false;
      }

      final uid = const Uuid().v4();

      final attendance = AttendanceModel(
        uid: uid,
        userId: userId,
        tanggal: tgl,
        status: 'izin',
        keterangan: keterangan,
        alasanIzin: alasanIzin,
        buktiFotoPath: buktiFotoPath,
      );
      await db.insert('attendance', attendance.toMap());
      await ApiService().submitAttendance(attendance);
      return true;
    } catch (e) {
      print('ERROR SUBMIT IZIN: $e');
      return false;
    }
  }

  static Future<List<AttendanceModel>> getUserAttendance(String userId) async {
    final db = await database;
    final res = await db.query(
      'attendance',
      where: 'user_id = ?',
      orderBy: 'tanggal DESC',
    );
    return res.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  static Future<Map<String, int>> getAttendanceStats(String userId) async {
    final db = await database;
    final res = await db.query(
      'attendance',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    int hadir = 0, terlambat = 0, izin = 0;
    for (var row in res) {
      if (row['status'] == 'hadir') {
        hadir++;
      } else if (row['status'] == 'terlambat') {
        terlambat++;
      } else if (row['status'] == 'izin') {
        izin++;
      }
    }
    return {
      'total': res.length,
      'hadir': hadir,
      'terlambat': terlambat,
      'izin': izin,
    };
  }

  // ======================== LOGBOOK ========================

  static Future<bool> addLogbook(
    LogbookModel logbook, {
    File? imageFile,
    List<File>? images,
  }) async {
    try {
      final db = await database;
      final mapData = Map<String, dynamic>.from(logbook.toMap());

      if (mapData['uid'] == null || mapData['uid'].toString().isEmpty) {
        mapData['uid'] = const Uuid().v4();
      }
      if (mapData['created_at'] == null) {
        mapData['created_at'] = DateTime.now().toIso8601String();
      }
      if (mapData['status'] == null || mapData['status'].toString().isEmpty) {
        mapData['status'] = 'menunggu';
      }

      // Gabungkan imageFile parsial jika dikirim via parameter tungsten tunggal
      final List<File> uploadImages = [];
      if (images != null && images.isNotEmpty) {
        uploadImages.addAll(images);
      } else if (imageFile != null) {
        uploadImages.add(imageFile);
      }

      // 1. Simpan ke database lokal SQLite
      await db.insert('logbook', mapData);

      // 2. Kirim/Sync ke backend Express + Cloudinary via ApiService
      try {
        final syncResult = await ApiService.uploadLogbookWithImages(
          logbook: logbook,
          images: uploadImages,
        );

        if (syncResult) {
          print("SUCCESS SYNC LOGBOOK TO EXPRESS & CLOUDINARY");
        } else {
          print("FAILED SYNC TO BACKEND: Respon server gagal atau error.");
        }
      } catch (apiErr) {
        print("API SYNC ERROR (Saved locally): $apiErr");
      }

      return true;
    } catch (e) {
      print('ERROR ADD LOGBOOK: $e');
      return false;
    }
  }

  static Future<List<LogbookModel>> getUserLogbooks(String userId) async {
    final db = await database;
    final res = await db.query(
      'logbook',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
    return res.map((e) => LogbookModel.fromMap(e)).toList();
  }

  static Future<void> syncLogbooksFromServer({String? userId}) async {
    try {
      final remoteLogbooks = await ApiService().fetchLogbooks(userId: userId);
      final db = await database;
      final batch = db.batch();
      for (final logbook in remoteLogbooks) {
        batch.insert(
          'logbook',
          logbook.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('ERROR SYNC LOGBOOKS FROM SERVER: $e');
    }
  }

  static Future<List<LogbookModel>> getLogbooksForValidation() async {
    final db = await database;
    final res = await db.query('logbook', orderBy: 'tanggal DESC');
    return res.map((e) => LogbookModel.fromMap(e)).toList();
  }

  static Future<void> validateLogbook({
    required String uid,
    required String status,
    required String catatan,
    required String guruId,
  }) async {
    try {
      final db = await database;
      await db.update(
        'logbook',
        {'status': status, 'catatan_guru': catatan, 'guru_id': guruId},
        where: 'uid = ?',
        whereArgs: [uid],
      );
      final updated = await db.query(
        'logbook',
        where: 'uid = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (updated.isNotEmpty) {
        await ApiService().submitLogbook(LogbookModel.fromMap(updated.first));
      }
    } catch (e) {
      print('ERROR VALIDATE LOGBOOK: $e');
      rethrow;
    }
  }

  static Future<Map<String, int>> getLogbookStats(String userId) async {
    final db = await database;
    final res = await db.query(
      'logbook',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    int p = 0, o = 0, r = 0;
    for (var row in res) {
      if (row['status'] == 'disetujui') {
        o++;
      } else if (row['status'] == 'ditolak') {
        r++;
      } else {
        p++;
      }
    }
    return {'menunggu': p, 'disetujui': o, 'ditolak': r, 'total': res.length};
  }

  // ======================== GLOBAL STATS ========================

  static Future<Map<String, int>> getGuruDashboardStats() async {
    final db = await database;
    final s = await db.query('users', where: 'role = ?', whereArgs: ['siswa']);
    final l = await db.query(
      'logbook',
      where: 'status = ?',
      whereArgs: ['menunggu'],
    );
    return {'total_siswa': s.length, 'belum_validasi': l.length};
  }
}
