import 'package:harusaki/harusaki.dart';
import 'package:test/test.dart';

void main() {
  group('harusaki', () {
    test('produces a normal spring simulation', () {
      expect(Harusaki.normal(), isNotNull);
    });

    test('handles velocity', () {
      final slow = Harusaki.normal();
      final fast = Harusaki.normal(10);

      // initial velocity should be greater
      expect(fast.dx(0), greaterThan(slow.dx(0)));
    });

    // there's not much else to test, really...
  });
}
