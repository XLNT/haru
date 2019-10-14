import 'package:haru/haru.dart';
import 'package:test/test.dart';

void main() {
  group('Haru', () {
    test('produces a normal spring simulation', () {
      expect(Haru.normal(), isNotNull);
    });

    test('handles velocity', () {
      final slow = Haru.normal();
      final fast = Haru.normal(10);

      // initial velocity should be greater
      expect(fast.dx(0), greaterThan(slow.dx(0)));
    });

    // there's not much else to test, really...
  });
}
