import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';

MediaQueryData _mq({
  double top = 0,
  Size size = const Size(390, 844),
}) =>
    MediaQueryData(size: size, viewPadding: EdgeInsets.only(top: top));

void main() {
  group('SoleIslandSpec.resolve', () {
    test('active on iOS with Dynamic Island padding (59pt)', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 59), TargetPlatform.iOS, SoleIslandMode.auto);
      expect(spec.active, isTrue);
    });

    test('inactive on notch iPhones (47pt)', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 47), TargetPlatform.iOS, SoleIslandMode.auto);
      expect(spec.active, isFalse);
    });

    test('inactive on Android even with 59pt padding', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 59), TargetPlatform.android, SoleIslandMode.auto);
      expect(spec.active, isFalse);
    });

    test('always-mode forces island on any platform in portrait', () {
      final spec = SoleIslandSpec.resolve(
          _mq(), TargetPlatform.android, SoleIslandMode.always);
      expect(spec.active, isTrue);
    });

    test('inactive in landscape regardless of mode', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 59, size: const Size(844, 390)),
          TargetPlatform.iOS,
          SoleIslandMode.always);
      expect(spec.active, isFalse);
    });

    test('never-mode wins over island hardware', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 59), TargetPlatform.iOS, SoleIslandMode.never);
      expect(spec.active, isFalse);
    });

    test('capsule rect is centered with the island geometry (plus bleed)', () {
      final spec = SoleIslandSpec.resolve(
          _mq(top: 59), TargetPlatform.iOS, SoleIslandMode.auto);
      expect(spec.capsuleRect.center.dx, closeTo(390 / 2, 0.001));
      expect(spec.capsuleRect.width, closeTo(126 + 3, 0.001));
      expect(spec.capsuleRect.height, closeTo(37 + 3, 0.001));
      expect(spec.capsuleRect.top, closeTo(11.6 - 1.5, 0.001));
    });
  });
}
