import 'dart:math' as math;
import 'dart:ui';

/// Builds the parametric pill → blob morph path.
///
/// Direct port of goey-toast's `morphPathRaw` / `morphPathCenterRaw` SVG
/// generators. The pill lobe keeps a constant height ([pillH]) while the body
/// grows underneath as [t] goes 0 → 1:
///
/// * `t = 0` — a pure capsule of width `min(pillW, bodyW)`.
/// * `t = 1` — the full blob: pill on top, body of size [bodyW]×[totalH]
///   below, joined by an organic quadratic curve.
///
/// [centered] grows the body symmetrically with the pill fixed at the
/// horizontal center (used for top-center drops and the Dynamic Island);
/// otherwise the pill anchors to the left edge. [pillLeft] overrides the
/// pill's horizontal offset within the body (centered mode only) — used by
/// the Dynamic Island capsule, which hugs the hardware cutout rather than
/// the body center.
Path soleBlobPath({
  required double pillW,
  required double bodyW,
  required double totalH,
  required double t,
  required double pillH,
  bool centered = true,
  double? pillLeft,
}) {
  return centered
      ? _centerAnchored(pillW, bodyW, totalH, t, pillH, pillLeft)
      : _leftAnchored(pillW, bodyW, totalH, t, pillH);
}

Path _purePill(double left, double pillW, double ph) {
  final pr = ph / 2;
  final r = Radius.circular(pr);
  return Path()
    ..moveTo(left, pr)
    ..arcToPoint(Offset(left + pr, 0), radius: r)
    ..lineTo(left + pillW - pr, 0)
    ..arcToPoint(Offset(left + pillW, pr), radius: r)
    ..arcToPoint(Offset(left + pillW - pr, ph), radius: r)
    ..lineTo(left + pr, ph)
    ..arcToPoint(Offset(left, pr), radius: r)
    ..close();
}

Path _leftAnchored(double pw, double bw, double th, double t, double ph) {
  final pr = ph / 2;
  final pillW = math.min(pw, bw);
  final bodyH = ph + (th - ph) * t;

  if (t <= 0 || bodyH - ph < 8) return _purePill(0, pillW, ph);

  final curve = 14.0 * t;
  final cr = math.min(16.0, (bodyH - ph) * 0.45);
  final bodyW = pillW + (bw - pillW) * t;
  final bodyTop = ph - curve;
  final qEndX = math.min(pillW + curve, bodyW - cr);
  final r = Radius.circular(pr);
  final rc = Radius.circular(cr);

  return Path()
    ..moveTo(0, pr)
    ..arcToPoint(Offset(pr, 0), radius: r)
    ..lineTo(pillW - pr, 0)
    ..arcToPoint(Offset(pillW, pr), radius: r)
    ..lineTo(pillW, bodyTop)
    ..quadraticBezierTo(pillW, bodyTop + curve, qEndX, bodyTop + curve)
    ..lineTo(bodyW - cr, bodyTop + curve)
    ..arcToPoint(Offset(bodyW, bodyTop + curve + cr), radius: rc)
    ..lineTo(bodyW, bodyH - cr)
    ..arcToPoint(Offset(bodyW - cr, bodyH), radius: rc)
    ..lineTo(cr, bodyH)
    ..arcToPoint(Offset(0, bodyH - cr), radius: rc)
    ..close();
}

Path _centerAnchored(
    double pw, double bw, double th, double t, double ph, double? pillLeft) {
  final pr = ph / 2;
  final pillW = math.min(pw, bw);
  // Pill is ALWAYS at its final-body-width position (centered by default).
  final pillOffset = pillLeft ?? (bw - pillW) / 2;
  final bodyH = ph + (th - ph) * t;

  if (t <= 0 || bodyH - ph < 8) return _purePill(pillOffset, pillW, ph);

  final curve = 14.0 * t;
  final cr = math.min(16.0, (bodyH - ph) * 0.45);
  final bodyTop = ph - curve;

  // Body grows symmetrically outward from the pill center.
  final bodyCenter = bw / 2;
  final halfBodyW = (pillW / 2) + ((bw - pillW) / 2) * t;
  final bodyLeft = bodyCenter - halfBodyW;
  final bodyRight = bodyCenter + halfBodyW;

  // Q-curve endpoints: body edges meet pill edges with organic curves.
  final qLeftX = math.max(bodyLeft + cr, pillOffset - curve);
  final qRightX = math.min(bodyRight - cr, pillOffset + pillW + curve);

  final r = Radius.circular(pr);
  final rc = Radius.circular(cr);

  return Path()
    ..moveTo(pillOffset, pr)
    ..arcToPoint(Offset(pillOffset + pr, 0), radius: r)
    ..lineTo(pillOffset + pillW - pr, 0)
    ..arcToPoint(Offset(pillOffset + pillW, pr), radius: r)
    ..lineTo(pillOffset + pillW, bodyTop)
    ..quadraticBezierTo(
        pillOffset + pillW, bodyTop + curve, qRightX, bodyTop + curve)
    ..lineTo(bodyRight - cr, bodyTop + curve)
    ..arcToPoint(Offset(bodyRight, bodyTop + curve + cr), radius: rc)
    ..lineTo(bodyRight, bodyH - cr)
    ..arcToPoint(Offset(bodyRight - cr, bodyH), radius: rc)
    ..lineTo(bodyLeft + cr, bodyH)
    ..arcToPoint(Offset(bodyLeft, bodyH - cr), radius: rc)
    ..lineTo(bodyLeft, bodyTop + curve + cr)
    ..arcToPoint(Offset(bodyLeft + cr, bodyTop + curve), radius: rc)
    ..lineTo(qLeftX, bodyTop + curve)
    ..quadraticBezierTo(pillOffset, bodyTop + curve, pillOffset, bodyTop)
    ..close();
}
