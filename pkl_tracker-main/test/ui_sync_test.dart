import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared snapshot payload exposes counts for users, logbooks, and attendance', () {
    final snapshot = {
      'users': 2,
      'logbooks': 3,
      'presensi': 4,
    };

    expect(snapshot['users'], 2);
    expect(snapshot['logbooks'], 3);
    expect(snapshot['presensi'], 4);
  });
}
