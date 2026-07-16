import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'types.dart';

/// A custom-painted, stroke-drawn toast icon — no icon fonts, no assets.
///
/// [progress] trims the strokes so the icon "draws itself in" (outline first,
/// then the inner mark). The loading phase renders a self-rotating spinner
/// arc.
class SoleToastIcon extends StatefulWidget {
  const SoleToastIcon({
    super.key,
    required this.phase,
    required this.color,
    this.size = 18,
    this.progress = 1.0,
  });

  final SoleToastPhase phase;
  final Color color;
  final double size;
  final double progress;

  @override
  State<SoleToastIcon> createState() => _SoleToastIconState();
}

class _SoleToastIconState extends State<SoleToastIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(SoleToastIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _syncSpin();
  }

  void _syncSpin() {
    if (widget.phase == SoleToastPhase.loading) {
      _spin ??= AnimationController(
          vsync: this, duration: const Duration(seconds: 1));
      if (MediaQuery.maybeDisableAnimationsOf(context) != true) {
        _spin!.repeat();
      }
    } else {
      _spin?.stop();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = CustomPaint(
      size: Size.square(widget.size),
      painter: _SoleIconPainter(
        phase: widget.phase,
        color: widget.color,
        progress: widget.progress.clamp(0.0, 1.0),
      ),
    );
    final spin = _spin;
    if (widget.phase == SoleToastPhase.loading && spin != null) {
      icon = RotationTransition(turns: spin, child: icon);
    }
    return icon;
  }
}

class _SoleIconPainter extends CustomPainter {
  const _SoleIconPainter({
    required this.phase,
    required this.color,
    required this.progress,
  });

  final SoleToastPhase phase;
  final Color color;
  final double progress;

  // All geometry lives in a 24-unit viewBox (Lucide-style), scaled to size.
  static const _box = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final scale = size.shortestSide / _box;
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outline draws over the first 60% of progress, mark over the last 40%.
    final outlineT = (progress / 0.6).clamp(0.0, 1.0);
    final markT = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);

    switch (phase) {
      case SoleToastPhase.loading:
        // 300° arc; rotation is applied by the widget.
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 12), radius: 9),
            -math.pi / 2, math.pi * 5 / 3 * progress, false, stroke);
      case SoleToastPhase.success:
        _trimmed(canvas, _circle(), outlineT, stroke);
        _trimmed(
            canvas,
            Path()
              ..moveTo(9, 12)
              ..lineTo(11, 14)
              ..lineTo(15, 10),
            markT,
            stroke);
      case SoleToastPhase.error:
        _trimmed(canvas, _circle(), outlineT, stroke);
        _trimmed(
            canvas,
            Path()
              ..moveTo(15, 9)
              ..lineTo(9, 15),
            markT,
            stroke);
        _trimmed(
            canvas,
            Path()
              ..moveTo(9, 9)
              ..lineTo(15, 15),
            markT,
            stroke);
      case SoleToastPhase.warning:
        _trimmed(
            canvas,
            Path()
              ..moveTo(12, 3.5)
              ..lineTo(21, 19.5)
              ..lineTo(3, 19.5)
              ..close(),
            outlineT,
            stroke);
        _trimmed(
            canvas,
            Path()
              ..moveTo(12, 9.5)
              ..lineTo(12, 13.5),
            markT,
            stroke);
        if (markT > 0.5) {
          canvas.drawCircle(const Offset(12, 16.6), 0.4, stroke);
        }
      case SoleToastPhase.info:
        _trimmed(canvas, _circle(), outlineT, stroke);
        _trimmed(
            canvas,
            Path()
              ..moveTo(12, 11.5)
              ..lineTo(12, 16),
            markT,
            stroke);
        if (markT > 0.5) {
          canvas.drawCircle(const Offset(12, 8.2), 0.4, stroke);
        }
    }
  }

  Path _circle() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 10));

  /// Draws [path] trimmed to the first [t] fraction of its length.
  void _trimmed(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(_SoleIconPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
}
