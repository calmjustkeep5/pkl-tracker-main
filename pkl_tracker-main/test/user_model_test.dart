import 'package:apk_pkl_tracker/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel shared sync fields', () {
    test('serializes guruUid and PKL fields to map', () {
      final user = UserModel(
        uid: 'u1',
        nama: 'Siswa A',
        email: 'siswa@example.com',
        password: '123456',
        role: 'siswa',
        guruUid: 'guru-1',
        pklPlaceName: 'PT ABC',
        pklPlaceAddress: 'Jl. Merdeka',
        pklLatitude: -6.2,
        pklLongitude: 106.8,
        createdAt: DateTime(2024, 1, 1),
      );

      final map = user.toMap();

      expect(map['guru_uid'], 'guru-1');
      expect(map['pkl_place_name'], 'PT ABC');
      expect(map['pkl_place_address'], 'Jl. Merdeka');
      expect(map['pkl_lat'], -6.2);
      expect(map['pkl_lng'], 106.8);
    });

    test('restores shared fields from map', () {
      final user = UserModel.fromMap({
        'uid': 'u2',
        'nama': 'Siswa B',
        'email': 'b@example.com',
        'password': '123456',
        'role': 'siswa',
        'guru_uid': 'guru-2',
        'pkl_place_name': 'PT XYZ',
        'pkl_place_address': 'Jl. Sudirman',
        'pkl_lat': -6.1,
        'pkl_lng': 106.7,
        'created_at': '2024-01-01T00:00:00.000',
      });

      expect(user.guruUid, 'guru-2');
      expect(user.pklPlaceName, 'PT XYZ');
      expect(user.pklPlaceAddress, 'Jl. Sudirman');
      expect(user.pklLatitude, -6.1);
      expect(user.pklLongitude, 106.7);
    });
  });
}
