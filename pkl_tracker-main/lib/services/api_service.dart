import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../models/logbook_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Override for each environment with:
  // flutter run --dart-define=API_BASE_URL=https://your-host/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static Uri _uri(String path) {
    if (baseUrl.isEmpty || baseUrl.contains('URL-TUNNEL-BARU')) {
      throw StateError(
        'API belum dikonfigurasi. Gunakan --dart-define=API_BASE_URL=https://domain-railway/api',
      );
    }
    return Uri.parse('$baseUrl$path');
  }

  Future<bool> syncUser(UserModel user) async {
    try {
      final payload = {
        ...user.toMap(),
        'guru_uid': user.guruUid,
        'pkl_place_name': user.pklPlaceName,
        'pkl_place_address': user.pklPlaceAddress,
        'pkl_lat': user.pklLatitude,
        'pkl_lng': user.pklLongitude,
      };

      print("----------------------------------------");
      print("Mencoba kirim data user ke API: ${_uri('/users')}");

      final response = await http.post(
        _uri('/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("----------------------------------------");

      bool isSuccess = response.statusCode == 200 || response.statusCode == 201;
      if (isSuccess) {
        print("BERHASIL: Akun tersimpan di database Railway!");
      } else if (response.statusCode == 530) {
        print(
          "GAGAL: API tidak terhubung ke origin (Cloudflare 530/1033). "
          "Pastikan server dan tunnel aktif.",
        );
      } else {
        print("GAGAL: API menolak data dengan status ${response.statusCode}");
      }
      return isSuccess;
    } catch (e) {
      print('API syncUser error (Koneksi Gagal): $e');
      return false;
    }
  }

  // Fungsi Login
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final payload = {'email': email, 'password': password};

      print("----------------------------------------");
      print("Mencoba login ke API: $baseUrl/login");

      final response = await http.post(
        _uri('/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print("Login Status Code: ${response.statusCode}");
      print("Login Response Body: ${response.body}");
      print("----------------------------------------");

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("BERHASIL: Login sukses!");
        return decoded;
      } else {
        print("GAGAL: Login ditolak dengan status ${response.statusCode}");
        return decoded;
      }
    } catch (e) {
      print('API loginUser error (Koneksi Gagal): $e');
      return null;
    }
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      print("Mengambil data user dari Railway: $baseUrl/users");
      final response = await http.get(Uri.parse('$baseUrl/users'));

      print("Fetch Status Code: ${response.statusCode}");
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .map((item) => UserModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      print('API fetchUsers error: $e');
      return [];
    }
  }

  Future<List<LogbookModel>> fetchLogbooks({String? userId}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/logbook',
      ).replace(queryParameters: userId == null ? null : {'user_id': userId});
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .map((item) => LogbookModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('API fetchLogbooks error: $e');
      return [];
    }
  }

  Future<bool> submitLogbook(LogbookModel logbook) async {
    try {
      print("Mengirim logbook ke Railway: $baseUrl/logbook");
      final response = await http.post(
        Uri.parse('$baseUrl/logbook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logbook.toMap()),
      );

      print("Logbook Status Code: ${response.statusCode}");
      print("Logbook Response: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('API submitLogbook error: $e');
      return false;
    }
  }

  // Fungsi Pengiriman Multipart untuk Logbook beserta List Gambar
  static Future<bool> uploadLogbookWithImages({
    required LogbookModel logbook,
    required List<File> images,
  }) async {
    try {
      final uri = _uri('/logbook/upload');
      print("Mengirim Logbook dengan Gambar ke $uri");
      var request = http.MultipartRequest('POST', uri);

      request.fields['uid'] = logbook.uid;
      request.fields['userId'] = logbook.userId;
      request.fields['user_id'] = logbook.userId;
      request.fields['tanggal'] = logbook.tanggal;
      request.fields['activity'] = logbook.kegiatan;
      request.fields['kegiatan'] = logbook.kegiatan;
      request.fields['status'] = logbook.status;

      if (logbook.locationLat != null) {
        request.fields['location_lat'] = logbook.locationLat.toString();
      }
      if (logbook.locationLng != null) {
        request.fields['location_lng'] = logbook.locationLng.toString();
      }
      if (logbook.locationAddress != null) {
        request.fields['location_address'] = logbook.locationAddress!;
      }

      // Unggah List File Foto
      for (var file in images) {
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos', // Key array di backend Express / Multer
              file.path,
            ),
          );
        }
      }

      if (request.files.isEmpty) {
        print(
          'API uploadLogbookWithImages error: Tidak ada file foto yang valid',
        );
        return false;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Multipart Logbook Status Code: ${response.statusCode}");
      print("Multipart Logbook Response Body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }
      return true;
    } catch (e) {
      print('API uploadLogbookWithImages error: $e');
      return false;
    }
  }

  Future<bool> submitAttendance(AttendanceModel attendance) async {
    try {
      print("Mengirim presensi ke Railway: $baseUrl/presensi");
      final response = await http.post(
        Uri.parse('$baseUrl/presensi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(attendance.toMap()),
      );

      print("Attendance Status Code: ${response.statusCode}");
      print("Attendance Response: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('API submitAttendance error: $e');
      return false;
    }
  }
}
