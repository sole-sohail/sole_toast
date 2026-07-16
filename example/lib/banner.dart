import 'package:flutter/material.dart';
import 'package:sole_toast/sole_toast.dart';

/// README hero banner, rendered by the library's own blob engine.
///
/// Shown when the app is built with `--dart-define=SOLE_SHOWCASE=banner`.
/// The composition is drawn rotated 90° so a portrait device screenshot
/// yields a wide landscape banner after rotation.
class BannerCanvas extends StatelessWidget {
  const BannerCanvas({super.key});

  static const _bg = Color(0xFF0E1116);
  static const _ink = Color(0xFFF2F5F9);
  static const _inkMuted = Color(0xFF9AA6B8);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Landscape canvas: height = screen width, width = screen height.
    final w = size.height;
    final h = size.width;
    return ColoredBox(
      color: _bg,
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Subtle sheen sweep.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.012),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.4, 0.8],
                      ),
                    ),
                  ),
                ),
                // Soft glow behind the toast cluster.
                Positioned(
                  left: w * 0.40,
                  top: -h * 0.2,
                  width: w * 0.64,
                  height: h * 1.4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Title block.
                Positioned(
                  left: w * 0.075,
                  top: h * 0.28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sole Toast',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1.0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'A gooey, morphing toast for Flutter',
                        style: TextStyle(
                          color: _inkMuted,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          for (final (type, phase) in [
                            (SoleToastType.success, SoleToastPhase.success),
                            (SoleToastType.error, SoleToastPhase.error),
                            (SoleToastType.warning, SoleToastPhase.warning),
                            (SoleToastType.info, SoleToastPhase.info),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: SoleToastIcon(
                                phase: phase,
                                color: SoleToastStyle.resolve(
                                        type, SoleToastMode.dark)
                                    .accent,
                                size: 26,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Real toasts, rendered by the engine, floating tilted.
                Positioned(
                  left: w * 0.505,
                  top: h * 0.14,
                  child: _ToastMock(
                    tilt: -0.045,
                    style: SoleToastStyle.resolve(
                        SoleToastType.success, SoleToastMode.light),
                    phase: SoleToastPhase.success,
                    title: 'Saved',
                    description: 'Your changes have been synced.',
                    pillW: 168,
                    bodyW: 330,
                    totalH: 126,
                    t: 0.93,
                  ),
                ),
                Positioned(
                  left: w * 0.455,
                  top: h * 0.68,
                  child: _ToastMock(
                    tilt: 0.035,
                    style: SoleToastStyle.resolve(
                        SoleToastType.info, SoleToastMode.dark),
                    phase: SoleToastPhase.loading,
                    title: 'Uploading 3 files…',
                    pillW: 236,
                    bodyW: 236,
                    totalH: 44,
                    t: 0,
                  ),
                ),
                Positioned(
                  left: w * 0.715,
                  top: h * 0.76,
                  child: _ToastMock(
                    tilt: -0.03,
                    style: SoleToastStyle.resolve(
                        SoleToastType.warning, SoleToastMode.dark),
                    phase: SoleToastPhase.warning,
                    title: 'Storage almost full',
                    pillW: 246,
                    bodyW: 246,
                    totalH: 44,
                    t: 0,
                  ),
                ),
                // Accent droplets near the cluster.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _DropletsPainter()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A static, engine-drawn toast used purely for the banner composition.
class _ToastMock extends StatelessWidget {
  const _ToastMock({
    required this.style,
    required this.phase,
    required this.title,
    this.description,
    required this.pillW,
    required this.bodyW,
    required this.totalH,
    required this.t,
    required this.tilt,
  });

  final SoleToastStyle style;
  final SoleToastPhase phase;
  final String title;
  final String? description;
  final double pillW;
  final double bodyW;
  final double totalH;
  final double t;
  final double tilt;

  static const double _pillH = 44;

  @override
  Widget build(BuildContext context) {
    final height = _pillH + (totalH - _pillH) * t.clamp(0.0, 1.0);
    return Transform.rotate(
      angle: tilt,
      child: SizedBox(
        width: bodyW,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MockBlobPainter(
                  style: style,
                  pillW: pillW,
                  bodyW: bodyW,
                  totalH: totalH,
                  t: t,
                  pillH: _pillH,
                ),
              ),
            ),
            // Header centered in the pill lobe.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _pillH,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoleToastIcon(phase: phase, color: style.accent, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (description != null)
              Positioned(
                top: _pillH + 10,
                left: 18,
                right: 18,
                child: Text(
                  description!,
                  style: TextStyle(
                    color: style.ink,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MockBlobPainter extends CustomPainter {
  const _MockBlobPainter({
    required this.style,
    required this.pillW,
    required this.bodyW,
    required this.totalH,
    required this.t,
    required this.pillH,
  });

  final SoleToastStyle style;
  final double pillW;
  final double bodyW;
  final double totalH;
  final double t;
  final double pillH;

  @override
  void paint(Canvas canvas, Size size) {
    final path = soleBlobPath(
        pillW: pillW, bodyW: bodyW, totalH: totalH, t: t, pillH: pillH);
    // Deep soft shadow lifts the card off the dark banner.
    canvas.drawPath(
      path.shift(const Offset(0, 14)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawPath(path, Paint()..color = style.surface);
    final sheen = style.sheen;
    if (sheen != null) {
      canvas.drawPath(
          path, Paint()..shader = sheen.createShader(path.getBounds()));
    }
    // Hairline keeps dark cards readable on the dark background.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = style.hasBorder
            ? style.border
            : Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _MockBlobPainter oldDelegate) => false;
}

class _DropletsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void droplet(Offset c, double r, Color color) {
      canvas.drawCircle(
        c.translate(0, 4),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(c, r, Paint()..color = color);
      canvas.drawCircle(
        c.translate(-r * 0.3, -r * 0.35),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
    }

    droplet(Offset(w * 0.475, h * 0.30), 11, const Color(0xFF4ADE80));
    droplet(Offset(w * 0.955, h * 0.24), 8, const Color(0xFFF87171));
    droplet(Offset(w * 0.665, h * 0.585), 7, const Color(0xFFFBBF24));
    droplet(Offset(w * 0.975, h * 0.60), 9, const Color(0xFF60A5FA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
