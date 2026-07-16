import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';

void main() {
  group('SoleToastStyle.resolve', () {
    test('island override is pure black regardless of mode', () {
      for (final mode in SoleToastMode.values) {
        final style =
            SoleToastStyle.resolve(SoleToastType.success, mode, island: true);
        expect(style.surface, const Color(0xFF000000));
        expect(style.blurSigma, 0);
        expect(style.hasBorder, isTrue);
      }
    });

    test('glossy has blur and sheen; follows brightness', () {
      final light =
          SoleToastStyle.resolve(SoleToastType.info, SoleToastMode.glossy);
      final dark = SoleToastStyle.resolve(
          SoleToastType.info, SoleToastMode.glossy,
          brightness: Brightness.dark);
      expect(light.hasBlur, isTrue);
      expect(light.sheen, isNotNull);
      expect(light.surface.a, lessThan(1.0));
      expect(light.ink, isNot(equals(dark.ink)));
    });

    test('light and dark modes are solid with no blur', () {
      final light =
          SoleToastStyle.resolve(SoleToastType.warning, SoleToastMode.light);
      final dark =
          SoleToastStyle.resolve(SoleToastType.warning, SoleToastMode.dark);
      expect(light.surface.a, 1.0);
      expect(dark.surface.a, 1.0);
      expect(light.hasBlur, isFalse);
      expect(dark.hasBlur, isFalse);
      expect(light.sheen, isNull);
    });

    test('each type maps to a distinct accent', () {
      final accents = SoleToastType.values
          .map((t) => SoleToastStyle.resolve(t, SoleToastMode.light).accent)
          .toSet();
      expect(accents, hasLength(SoleToastType.values.length));
    });

    test('action button tints derive from type', () {
      final success =
          SoleToastStyle.resolve(SoleToastType.success, SoleToastMode.light);
      expect(success.actionBg, const Color(0xFFC8E6C9));
      expect(success.actionFg, const Color(0xFF4CAF50));
    });
  });

  group('SoleToastConfig', () {
    test('defaults match spec', () {
      const config = SoleToastConfig();
      expect(config.mode, SoleToastMode.glossy);
      expect(config.position, SoleToastPosition.topCenter);
      expect(config.islandMode, SoleIslandMode.auto);
      expect(config.bounce, 0.4);
      expect(config.displayDuration, const Duration(milliseconds: 4000));
      expect(config.maxVisible, 3);
    });

    test('preset factory maps bounce', () {
      expect(SoleToastConfig.preset(SoleToastPreset.bouncy).bounce, 0.6);
      expect(SoleToastConfig.preset(SoleToastPreset.subtle).bounce, 0.05);
    });

    test('copyWith preserves unset fields', () {
      const config = SoleToastConfig(gap: 20);
      final copy = config.copyWith(mode: SoleToastMode.dark);
      expect(copy.gap, 20);
      expect(copy.mode, SoleToastMode.dark);
    });
  });
}
