import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';

void main() {
  group('SoleToastTimings', () {
    test('fast preset is faster than normal in every phase', () {
      const n = SoleToastTimings.normal;
      const f = SoleToastTimings.fast;
      expect(f.enterMs, lessThan(n.enterMs));
      expect(f.expandDelayMs, lessThan(n.expandDelayMs));
      expect(f.morphMs, lessThan(n.morphMs));
      expect(f.bodyFadeMs, lessThan(n.bodyFadeMs));
      expect(f.collapseMs, lessThan(n.collapseMs));
      expect(f.lingerMs, lessThan(n.lingerMs));
      expect(f.exitMs, lessThan(n.exitMs));
      expect(f.islandEnterMs, lessThan(n.islandEnterMs));
      expect(f.islandIconHoldMs, lessThan(n.islandIconHoldMs));
    });

    test('fast entrance sums to roughly 400 ms of blocking time', () {
      const f = SoleToastTimings.fast;
      // Enter + expand delay + half the morph (content is readable well
      // before the spring fully settles).
      final readableAt = f.enterMs + f.expandDelayMs + f.morphMs ~/ 2;
      expect(readableAt, lessThanOrEqualTo(400));
    });

    test('scaled(2.0) halves every phase of normal', () {
      final s = SoleToastTimings.scaled(2.0);
      const n = SoleToastTimings.normal;
      expect(s.enterMs, n.enterMs ~/ 2);
      expect(s.morphMs, n.morphMs ~/ 2);
      expect(s.collapseMs, n.collapseMs ~/ 2);
      expect(s.islandIconHoldMs, n.islandIconHoldMs ~/ 2);
    });

    test('config carries timings through copyWith', () {
      const config = SoleToastConfig(timings: SoleToastTimings.fast);
      expect(config.copyWith(gap: 20).timings, SoleToastTimings.fast);
    });
  });
}
