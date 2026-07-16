import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'types.dart';

/// Describes whether — and where — the Dynamic Island choreography applies.
@immutable
class SoleIslandSpec {
  const SoleIslandSpec({required this.active, required this.capsuleRect});

  /// Whether toasts should dock to the Dynamic Island.
  final bool active;

  /// The hardware cutout area in logical pixels (screen coordinates),
  /// already inflated by a 1.5 px bleed so the black capsule fully covers
  /// the cutout's anti-aliased edge.
  final Rect capsuleRect;

  static const SoleIslandSpec inactive =
      SoleIslandSpec(active: false, capsuleRect: Rect.zero);

  /// Dynamic Island devices report a 59 pt top view padding in portrait
  /// (notch devices report 44–50 pt).
  static const double _kIslandTopPadding = 59.0;

  // Logical geometry of the island cutout (iPhone 14 Pro → 16 family).
  static const double _kIslandWidth = 126.0;
  static const double _kIslandHeight = 37.0;
  static const double _kIslandTop = 11.6;
  static const double _kBleed = 1.5;

  /// Resolves the island spec for the current device.
  ///
  /// * [SoleIslandMode.never] — always inactive.
  /// * [SoleIslandMode.always] — active whenever the device is in portrait
  ///   (lets demos and simulators preview the choreography anywhere).
  /// * [SoleIslandMode.auto] — active only on portrait iOS devices whose top
  ///   view padding matches the Dynamic Island.
  static SoleIslandSpec resolve(
    MediaQueryData mq,
    TargetPlatform platform,
    SoleIslandMode mode,
  ) {
    if (mode == SoleIslandMode.never) return inactive;
    final portrait = mq.orientation == Orientation.portrait;
    if (!portrait) return inactive;
    if (mode == SoleIslandMode.auto) {
      final isIslandDevice = !kIsWeb &&
          platform == TargetPlatform.iOS &&
          mq.viewPadding.top >= _kIslandTopPadding;
      if (!isIslandDevice) return inactive;
    }
    final rect = Rect.fromLTWH(
      (mq.size.width - _kIslandWidth) / 2,
      _kIslandTop,
      _kIslandWidth,
      _kIslandHeight,
    ).inflate(_kBleed);
    return SoleIslandSpec(active: true, capsuleRect: rect);
  }
}
