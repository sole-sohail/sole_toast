import 'package:flutter/foundation.dart';

/// Semantic type of a toast. Drives the accent color, icon, and
/// action-button tint.
enum SoleToastType { success, error, warning, info }

/// Visual mode of the toast surface.
///
/// * [light] — solid white surface, dark text.
/// * [dark] — solid near-black surface, light text.
/// * [glossy] — frosted glass: background blur, translucent tint that follows
///   the app's [Brightness], a specular sheen and a hairline border.
enum SoleToastMode { light, dark, glossy }

/// Where toasts enter and stack.
enum SoleToastPosition { topCenter, bottomCenter }

/// Controls the iPhone Dynamic Island choreography.
///
/// * [auto] — enabled only on iPhones with a Dynamic Island (detected from
///   the top view padding) in portrait orientation.
/// * [always] — force island rendering (useful for demos/simulators).
/// * [never] — always use the standard top-center drop.
enum SoleIslandMode { auto, always, never }

/// Lifecycle phase of a toast's content. [loading] is used by
/// `SoleToast.promise` before the future settles.
enum SoleToastPhase { loading, success, error, warning, info }

/// Converts a [SoleToastType] to its matching content phase.
SoleToastPhase phaseOf(SoleToastType type) => switch (type) {
      SoleToastType.success => SoleToastPhase.success,
      SoleToastType.error => SoleToastPhase.error,
      SoleToastType.warning => SoleToastPhase.warning,
      SoleToastType.info => SoleToastPhase.info,
    };

/// One-dial animation presets (ported from goey-toast).
enum SoleToastPreset {
  smooth(0.1),
  bouncy(0.6),
  subtle(0.05),
  snappy(0.4);

  const SoleToastPreset(this.bounce);

  /// Spring bounce intensity, `0.05` (barely there) to `0.8` (jelly).
  final double bounce;
}

/// An optional button rendered inside the expanded toast body.
@immutable
class SoleToastAction {
  const SoleToastAction({
    required this.label,
    required this.onPressed,
    this.successLabel,
  });

  /// Button text.
  final String label;

  /// Invoked when the button is tapped.
  final VoidCallback onPressed;

  /// When set, tapping the action morphs the toast back into a pill showing
  /// this label with a success accent, then dismisses.
  final String? successLabel;
}

/// Global configuration applied to every toast (individual toasts may
/// override `mode`, `duration` and `showProgress`).
@immutable
class SoleToastConfig {
  const SoleToastConfig({
    this.mode = SoleToastMode.glossy,
    this.position = SoleToastPosition.topCenter,
    this.islandMode = SoleIslandMode.auto,
    this.bounce = 0.4,
    this.spring = true,
    this.displayDuration = const Duration(milliseconds: 4000),
    this.maxVisible = 3,
    this.gap = 12.0,
    this.maxWidth = 380.0,
    this.minWidth = 300.0,
    this.pillHeight = 38.0,
    this.showProgress = false,
    this.showTimestamp = false,
    this.enableHaptics = true,
  })  : assert(bounce >= 0.0 && bounce <= 0.8, 'bounce must be 0.0–0.8'),
        assert(maxVisible > 0),
        assert(pillHeight >= 28);

  /// Builds a config from a [SoleToastPreset].
  factory SoleToastConfig.preset(SoleToastPreset preset) =>
      SoleToastConfig(bounce: preset.bounce);

  /// Default surface mode for all toasts.
  final SoleToastMode mode;

  /// Screen edge toasts drop from.
  final SoleToastPosition position;

  /// Dynamic Island behavior. See [SoleIslandMode].
  final SoleIslandMode islandMode;

  /// Spring intensity, `0.0`–`0.8`. Higher is bouncier.
  final double bounce;

  /// When `false`, springs are replaced with smooth ease curves.
  final bool spring;

  /// Total on-screen time for expanded toasts (includes expand + collapse).
  final Duration displayDuration;

  /// Maximum simultaneously visible toasts; extras queue FIFO.
  final int maxVisible;

  /// Vertical gap between stacked toasts, in logical pixels.
  final double gap;

  /// Maximum expanded body width (clamped to screen width − 32).
  final double maxWidth;

  /// Minimum expanded body width.
  final double minWidth;

  /// Height of the compact pill.
  final double pillHeight;

  /// Show a countdown progress bar in expanded toasts.
  final bool showProgress;

  /// Show a timestamp in the toast header/body.
  final bool showTimestamp;

  /// Fire light haptic feedback on show / error shake / action tap.
  final bool enableHaptics;

  SoleToastConfig copyWith({
    SoleToastMode? mode,
    SoleToastPosition? position,
    SoleIslandMode? islandMode,
    double? bounce,
    bool? spring,
    Duration? displayDuration,
    int? maxVisible,
    double? gap,
    double? maxWidth,
    double? minWidth,
    double? pillHeight,
    bool? showProgress,
    bool? showTimestamp,
    bool? enableHaptics,
  }) {
    return SoleToastConfig(
      mode: mode ?? this.mode,
      position: position ?? this.position,
      islandMode: islandMode ?? this.islandMode,
      bounce: bounce ?? this.bounce,
      spring: spring ?? this.spring,
      displayDuration: displayDuration ?? this.displayDuration,
      maxVisible: maxVisible ?? this.maxVisible,
      gap: gap ?? this.gap,
      maxWidth: maxWidth ?? this.maxWidth,
      minWidth: minWidth ?? this.minWidth,
      pillHeight: pillHeight ?? this.pillHeight,
      showProgress: showProgress ?? this.showProgress,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      enableHaptics: enableHaptics ?? this.enableHaptics,
    );
  }
}
