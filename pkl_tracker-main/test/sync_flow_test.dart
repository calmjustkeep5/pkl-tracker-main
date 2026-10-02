import 'package:apk_pkl_tracker/models/attendance_model.dart';
import 'package:apk_pkl_tracker/models/logbook_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shared sync payloads', () {
    test('attendance payload contains user and status fields', () {
      final attendance = AttendanceModel(
        uid: 'a1',
        userId: 'u1',
        tanggal: '2026-06-24',
        checkIn: '08:00',
        status: 'hadir',
      );

      final map = attendance.toMap();
      expect(map['user_id'], 'u1');
      expect(map['status'], 'hadir');
      expect(map['check_in'], '08:00');
    });

    test('logbook payload contains shared status and teacher fields', () {
      final logbook = LogbookModel(
        uid: 'l1',
        userId: 'u1',
        tanggal: '2026-06-24',
        kegiatan: 'Membuat laporan',
        status: 'menunggu',
        guruId: 'guru-1',
        createdAt: DateTime(2026, 6, 24),
      );

      final map = logbook.toMap();
      expect(map['user_id'], 'u1');
      expect(map['status'], 'menunggu');
      expect(map['guru_id'], 'guru-1');
    });
  });
}
