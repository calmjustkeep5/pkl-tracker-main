import 'package:hive/hive.dart';

part 'user_model.g.dart';

class UserModel {
  final int? id;
  final String uid;
  final String nama;
  final String email;
  final String password;
  final String role; // 'siswa' atau 'guru'
  final String? noInduk; // NIS/NIP
  final String? sekolah;
  final String? jurusan;
  final String? alamat;
  final String? photoUrl;
  final String? phone;
  final String? guruUid;
  final String? pklPlaceName;
  final String? pklPlaceAddress;
  final double? pklLatitude;
  final double? pklLongitude;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.uid,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.noInduk,
    this.sekolah,
    this.jurusan,
    this.alamat,
    this.photoUrl,
    this.phone,
    this.guruUid,
    this.pklPlaceName,
    this.pklPlaceAddress,
    this.pklLatitude,
    this.pklLongitude,
    required this.createdAt,
  });

  // Mengubah data dari Map (Database SQLite / API) ke Object (Dart)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      uid: map['uid'] ?? '',
      // Membaca dari 'name' (API/DB baru) atau fallback ke 'nama' (DB lama), dan berikan default '' jika null
      nama: map['name'] ?? map['nama'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      noInduk: map['no_induk'],
      sekolah: map['sekolah'],
      jurusan: map['jurusan'],
      alamat: map['alamat'],
      photoUrl: map['photo_url'],
      phone: map['phone'],
      guruUid: map['guru_uid'],
      pklPlaceName: map['pkl_place_name'],
      pklPlaceAddress: map['pkl_place_address'],
      pklLatitude: map['pkl_lat'] != null ? (map['pkl_lat'] as num).toDouble() : null,
      pklLongitude: map['pkl_lng'] != null ? (map['pkl_lng'] as num).toDouble() : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  // Mengubah data dari Object (Dart) ke Map (Untuk disimpan ke Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'uid': uid,
      'name': nama, // Disinkronkan dengan API/Database sebagai 'name'
      'email': email,
      'password': password,
      'role': role,
      'no_induk': noInduk,
      'sekolah': sekolah,
      'jurusan': jurusan,
      'alamat': alamat,
      'photo_url': photoUrl,
      'phone': phone,
      'guru_uid': guruUid,
      'pkl_place_name': pklPlaceName,
      'pkl_place_address': pklPlaceAddress,
      'pkl_lat': pklLatitude,
      'pkl_lng': pklLongitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper untuk update data tertentu
  UserModel copyWith({
    int? id,
    String? uid,
    String? nama,
    String? email,
    String? password,
    String? role,
    String? noInduk,
    String? sekolah,
    String? jurusan,
    String? alamat,
    String? photoUrl,
    String? phone,
    String? guruUid,
    String? pklPlaceName,
    String? pklPlaceAddress,
    double? pklLatitude,
    double? pklLongitude,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      noInduk: noInduk ?? this.noInduk,
      sekolah: sekolah ?? this.sekolah,
      jurusan: jurusan ?? this.jurusan,
      alamat: alamat ?? this.alamat,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      guruUid: guruUid ?? this.guruUid,
      pklPlaceName: pklPlaceName ?? this.pklPlaceName,
      pklPlaceAddress: pklPlaceAddress ?? this.pklPlaceAddress,
      pklLatitude: pklLatitude ?? this.pklLatitude,
      pklLongitude: pklLongitude ?? this.pklLongitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}