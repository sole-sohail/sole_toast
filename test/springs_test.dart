import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/src/springs.dart';

void main() {
  group('squishSpring', () {
    test('verbatim port of goey-toast formula', () {
      final s = squishSpring(duration: 0.6, defaultDuration: 0.6);
      expect(s.stiffness, closeTo(200 + 0.4 * 437.5, 0.001)); // 375
      expect(s.damping, closeTo(24 - 0.4 * 20, 0.001)); // 16
      expect(s.mass, closeTo(0.7, 0.001));
    });

    test('mass scales with duration ratio', () {
      final s = squishSpring(duration: 0.9, defaultDuration: 0.6, bounce: 0.8);
      expect(s.mass, closeTo(0.7 * 1.5, 0.001));
      expect(s.stiffness, closeTo(550, 0.001));
      expect(s.damping, closeTo(8, 0.001));
    });
  });

  group('morphSpring', () {
    test('settles near target within ~1.5x duration', () {
      for (final bounce in [0.05, 0.4, 0.8]) {
        final sim = springSimulation(
            morphSpring(durationSeconds: 0.9, bounce: bounce));
        expect(sim.x(1.35), closeTo(1.0, 0.02),
            reason: 'bounce $bounce should settle');
      }
    });

    test('high bounce overshoots, low bounce does not', () {
      final bouncy = springSimulation(
          morphSpring(durationSeconds: 0.9, bounce: 0.8));
      final subtle = springSimulation(
          morphSpring(durationSeconds: 0.9, bounce: 0.05));
      double maxOf(SpringSimulation sim) {
        var max = 0.0;
        for (var t = 0.0; t < 2.0; t += 0.008) {
          if (sim.x(t) > max) max = sim.x(t);
        }
        return max;
      }

      expect(maxOf(bouncy), greaterThan(1.02));
      expect(maxOf(subtle), lessThan(1.02));
    });
  });
}
