import 'package:harusaki/harusaki.dart';
import 'package:test/test.dart';

void main() {
  group('harusaki', () {
    test('produces a normal spring description', () {
      expect(Harusaki.normal, isNotNull);
    });

    test('handles velocity', () {
      final slow = Harusaki.spring(Harusaki.normal, velocity: 0);
      final fast = Harusaki.spring(Harusaki.normal, velocity: 1);

      expect(fast.dx(0), greaterThan(slow.dx(0)));
    });

    // there's not much else to test, really...
  });
}
