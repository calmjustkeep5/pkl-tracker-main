class AttendanceModel {
  final int? id;
  final String uid;
  final String userId;
  final String tanggal;
  final String? checkIn;
  final String? checkOut;
  final String status; // 'hadir', 'terlambat', 'izin', 'sakit'
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? keterangan;
  
  // ✅ TAMBAHAN BARU UNTUK FITUR IZIN
  final String? alasanIzin;      
  final String? buktiFotoPath;   

  AttendanceModel({
    this.id,
    required this.uid,
    required this.userId,
    required this.tanggal,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.keterangan,
    this.alasanIzin,
    this.buktiFotoPath,
  });

  // ✅ GETTER: Menghubungkan variabel 'keterangan' bawaan dengan UI baru agar tidak error
  String? get keteranganTambahan => keterangan;

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      uid: map['uid'],
      userId: map['user_id'],
      tanggal: map['tanggal'],
      checkIn: map['check_in'],
      checkOut: map['check_out'],
      status: map['status'],
      checkInLat: map['check_in_lat']?.toDouble(),
      checkInLng: map['check_in_lng']?.toDouble(),
      checkOutLat: map['check_out_lat']?.toDouble(),
      checkOutLng: map['check_out_lng']?.toDouble(),
      keterangan: map['keterangan'],
      
      // ✅ Mapping dari database (pastikan nama kolom di database sesuai)
      alasanIzin: map['alasan_izin'],
      buktiFotoPath: map['bukti_foto_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'user_id': userId,
      'tanggal': tanggal,
      'check_in': checkIn,
      'check_out': checkOut,
      'status': status,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'keterangan': keterangan,
      
      // ✅ Menyimpan ke database
      'alasan_izin': alasanIzin,
      'bukti_foto_path': buktiFotoPath,
    };
  }

  AttendanceModel copyWith({
    String? checkOut,
    double? checkOutLat,
    double? checkOutLng,
    String? status,
    String? keterangan,
    String? alasanIzin,
    String? buktiFotoPath,
  }) {
    return AttendanceModel(
      id: id,
      uid: uid,
      userId: userId,
      tanggal: tanggal,
      checkIn: checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      checkInLat: checkInLat,
      checkInLng: checkInLng,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      keterangan: keterangan ?? this.keterangan,
      
      // ✅ Update data izin
      alasanIzin: alasanIzin ?? this.alasanIzin,
      buktiFotoPath: buktiFotoPath ?? this.buktiFotoPath,
    );
  }

  bool get sudahCheckIn => checkIn != null;
  bool get sudahCheckOut => checkOut != null;
}