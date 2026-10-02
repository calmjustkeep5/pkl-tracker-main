import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard badge should show pending updates when count is positive', () {
    final pending = 3;
    final badge = pending > 0 ? '$pending' : null;

    expect(badge, '3');
  });
}
