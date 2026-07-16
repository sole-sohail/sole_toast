import 'dart:math' as math;

import 'package:flutter/physics.dart';

/// Squish spring — verbatim port of goey-toast's `squishSpring`.
///
/// Maps `bounce` (0–0.8) to stiffness 200–550 and damping 24–8; mass scales
/// with the morph duration so the squish feel stays consistent.
SpringDescription squishSpring({
  required double duration,
  required double defaultDuration,
  double bounce = 0.4,
}) {
  final scale = duration / defaultDuration;
  return SpringDescription(
    mass: 0.7 * scale,
    stiffness: 200 + bounce * 437.5,
    damping: 24 - bounce * 20,
  );
}

/// Approximates framer-motion's duration+bounce spring.
///
/// `bounce` maps to a damping ratio `ζ = 1 − bounce` and the natural
/// frequency is chosen so the spring settles (to 0.1%) in roughly
/// [durationSeconds].
SpringDescription morphSpring({
  required double durationSeconds,
  required double bounce,
}) {
  final zeta = (1.0 - bounce).clamp(0.05, 1.0);
  // Settling time approximation: t_s ≈ -ln(tolerance) / (ζ·ω).
  final omega = -math.log(0.001) / (zeta * durationSeconds);
  return SpringDescription(
    mass: 1,
    stiffness: omega * omega,
    damping: 2 * zeta * omega,
  );
}

/// Convenience wrapper building a [SpringSimulation] from [from] → [to].
SpringSimulation springSimulation(
  SpringDescription description, {
  double from = 0,
  double to = 1,
  double velocity = 0,
}) =>
    SpringSimulation(description, from, to, velocity,
        tolerance: const Tolerance(distance: 0.0005, velocity: 0.005));
