import 'package:flutter/material.dart';

class LogbookModel {
  final int? id;
  final String uid;
  final String userId;
  final String tanggal;
  final String kegiatan;
  final String? fotoBukti;
  final String status; // 'menunggu', 'disetujui', 'ditolak'
  final String? catatanGuru;
  final String? guruId;
  final double? locationLat;
  final double? locationLng;
  final String? locationAddress;
  final DateTime createdAt;

  LogbookModel({
    this.id,
    required this.uid,
    required this.userId,
    required this.tanggal,
    required this.kegiatan,
    this.fotoBukti,
    this.status = 'menunggu',
    this.catatanGuru,
    this.guruId,
    this.locationLat,
    this.locationLng,
    this.locationAddress,
    required this.createdAt,
  });

  factory LogbookModel.fromMap(Map<String, dynamic> map) {
    return LogbookModel(
      id: map['id'],
      uid: map['uid'],
      userId: map['user_id'],
      tanggal: map['tanggal'],
      kegiatan: map['kegiatan'],
      fotoBukti: map['foto_bukti'],
      status: map['status'] ?? 'menunggu',
      catatanGuru: map['catatan_guru'],
      guruId: map['guru_id'],
      locationLat: map['location_lat'] != null ? (map['location_lat'] as num).toDouble() : null,
      locationLng: map['location_lng'] != null ? (map['location_lng'] as num).toDouble() : null,
      locationAddress: map['location_address'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'user_id': userId,
      'tanggal': tanggal,
      'kegiatan': kegiatan,
      'foto_bukti': fotoBukti,
      'status': status,
      'catatan_guru': catatanGuru,
      'guru_id': guruId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_address': locationAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LogbookModel copyWith({
    String? status,
    String? catatanGuru,
    String? guruId,
    String? fotoBukti,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) {
    return LogbookModel(
      id: id,
      uid: uid,
      userId: userId,
      tanggal: tanggal,
      kegiatan: kegiatan,
      fotoBukti: fotoBukti ?? this.fotoBukti,
      status: status ?? this.status,
      catatanGuru: catatanGuru ?? this.catatanGuru,
      guruId: guruId ?? this.guruId,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
      createdAt: createdAt,
    );
  }

  Color get statusColor {
    switch (status) {
      case 'disetujui': return const Color(0xFF22C55E);
      case 'ditolak':   return const Color(0xFFEF4444);
      default:          return const Color(0xFFF59E0B);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'disetujui': return 'Disetujui';
      case 'ditolak':   return 'Ditolak';
      default:          return 'Menunggu';
    }
  }
}