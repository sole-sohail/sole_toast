import 'package:flutter/widgets.dart';

import 'blob_path.dart';
import 'theme.dart';

/// Animated blob dimensions — the channel between the toast card's animation
/// controllers and the painter/clipper. Mutating it repaints listeners
/// without rebuilding the widget tree.
class SoleBlobDims extends ChangeNotifier {
  double pillW = 0;
  double bodyW = 0;
  double totalH = 0;
  double morphT = 0;
  double pillH = 38;

  /// Pill offset within the body; `null` = centered.
  double? pillLeft;

  bool get ready => pillW > 0 && bodyW > 0 && totalH > 0;

  /// Morph progress clamped to 0–1 (spring overshoot must not flip the
  /// painter between geometry branches).
  double get t => morphT.clamp(0.0, 1.0);

  /// Current blob height for layout purposes.
  double get currentH => pillH + (totalH - pillH) * t;

  /// Current blob width (body portion) for clip purposes.
  double get currentW {
    final pw = pillW > bodyW ? bodyW : pillW;
    return pw + (bodyW - pw) * t;
  }

  void update({
    double? pillW,
    double? bodyW,
    double? totalH,
    double? morphT,
    double? pillH,
    double? pillLeft,
    bool clearPillLeft = false,
  }) {
    var changed = false;
    if (pillW != null && pillW != this.pillW) {
      this.pillW = pillW;
      changed = true;
    }
    if (bodyW != null && bodyW != this.bodyW) {
      this.bodyW = bodyW;
      changed = true;
    }
    if (totalH != null && totalH != this.totalH) {
      this.totalH = totalH;
      changed = true;
    }
    if (morphT != null && morphT != this.morphT) {
      this.morphT = morphT;
      changed = true;
    }
    if (pillH != null && pillH != this.pillH) {
      this.pillH = pillH;
      changed = true;
    }
    if (clearPillLeft) {
      if (this.pillLeft != null) {
        this.pillLeft = null;
        changed = true;
      }
    } else if (pillLeft != null && pillLeft != this.pillLeft) {
      this.pillLeft = pillLeft;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Path buildPath() => soleBlobPath(
        pillW: pillW,
        bodyW: bodyW,
        totalH: totalH,
        t: t,
        pillH: pillH,
        pillLeft: pillLeft,
      );
}

/// Paints the gooey blob: soft shadows, fill (with optional glossy sheen)
/// and a hairline border.
class SoleBlobPainter extends CustomPainter {
  SoleBlobPainter({required this.dims, required this.style})
      : super(repaint: dims);

  final SoleBlobDims dims;
  final SoleToastStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (!dims.ready) return;
    final path = dims.buildPath();

    for (final shadow in style.shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    canvas.drawPath(path, Paint()..color = style.surface);

    final sheen = style.sheen;
    if (sheen != null) {
      final bounds = path.getBounds();
      if (!bounds.isEmpty) {
        canvas.drawPath(
          path,
          Paint()..shader = sheen.createShader(bounds),
        );
      }
    }

    if (style.hasBorder) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = style.border,
      );
    }
  }

  @override
  bool shouldRepaint(SoleBlobPainter oldDelegate) =>
      oldDelegate.dims != dims || oldDelegate.style != style;
}

/// Clips a child (the backdrop blur in glossy mode) to the live blob path.
class SoleBlobClipper extends CustomClipper<Path> {
  SoleBlobClipper(this.dims) : super(reclip: dims);

  final SoleBlobDims dims;

  @override
  Path getClip(Size size) =>
      dims.ready ? dims.buildPath() : Path();

  @override
  bool shouldReclip(SoleBlobClipper oldClipper) => oldClipper.dims != dims;
}
