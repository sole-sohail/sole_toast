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

/// Stage durations (milliseconds) for the toast choreography.
///
/// The defaults reproduce the original relaxed feel (~1.5 s until an
/// expanded toast is fully readable). For quick feedback after user
/// actions, use [fast] (~350–400 ms to readable content) or derive a
/// custom pace with [SoleToastTimings.scaled].
@immutable
class SoleToastTimings {
  const SoleToastTimings({
    this.enterMs = 260,
    this.expandDelayMs = 330,
    this.morphMs = 900,
    this.bodyFadeMs = 350,
    this.collapseMs = 900,
    this.lingerMs = 800,
    this.exitMs = 220,
    this.islandEnterMs = 150,
    this.islandIconHoldMs = 620,
  });

  /// The original, relaxed choreography.
  static const SoleToastTimings normal = SoleToastTimings();

  /// Snappy entrance for action feedback: the description is readable in
  /// roughly 350–400 ms while keeping the gooey morph style.
  static const SoleToastTimings fast = SoleToastTimings(
    enterMs: 130,
    expandDelayMs: 40,
    morphMs: 420,
    bodyFadeMs: 160,
    collapseMs: 480,
    lingerMs: 420,
    exitMs: 160,
    islandEnterMs: 90,
    islandIconHoldMs: 220,
  );

  /// Uniform pace control: every phase of [normal] divided by [speed]
  /// (`2.0` → twice as fast, `0.5` → half speed).
  factory SoleToastTimings.scaled(double speed) {
    assert(speed > 0);
    int s(int ms) => (ms / speed).round().clamp(1, 60000);
    const n = SoleToastTimings.normal;
    return SoleToastTimings(
      enterMs: s(n.enterMs),
      expandDelayMs: s(n.expandDelayMs),
      morphMs: s(n.morphMs),
      bodyFadeMs: s(n.bodyFadeMs),
      collapseMs: s(n.collapseMs),
      lingerMs: s(n.lingerMs),
      exitMs: s(n.exitMs),
      islandEnterMs: s(n.islandEnterMs),
      islandIconHoldMs: s(n.islandIconHoldMs),
    );
  }

  /// Pill slide/fade-in duration.
  final int enterMs;

  /// Pause on the compact pill before the body starts melting out.
  final int expandDelayMs;

  /// Nominal duration of the expand morph spring (also collapse spring
  /// when springs are enabled).
  final int morphMs;

  /// Description/action fade-in duration.
  final int bodyFadeMs;

  /// Fold-up duration back to the pill.
  final int collapseMs;

  /// How long the bare pill lingers after folding before it exits.
  final int lingerMs;

  /// Exit slide/fade duration.
  final int exitMs;

  /// Island capsule fade-in duration.
  final int islandEnterMs;

  /// How long the island holds the icon chin before the sheet continues.
  final int islandIconHoldMs;
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
    this.timings = SoleToastTimings.normal,
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

  /// Stage durations for the choreography. Use [SoleToastTimings.fast] for
  /// near-instant action feedback.
  final SoleToastTimings timings;

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
    SoleToastTimings? timings,
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
      timings: timings ?? this.timings,
    );
  }
}
