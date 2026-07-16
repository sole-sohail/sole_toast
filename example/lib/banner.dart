import 'package:flutter/material.dart';
import 'package:sole_toast/sole_toast.dart';

/// README hero banner, rendered by the library's own blob engine.
///
/// Shown when the app is built with `--dart-define=SOLE_SHOWCASE=banner`.
/// The composition is drawn rotated 90° so a portrait device screenshot
/// yields a wide landscape banner after rotation (`sips -r -90`).
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
                // Gooey blobs drawn with the real engine geometry.
                Positioned.fill(
                  child: CustomPaint(painter: _GooeyArtPainter()),
                ),
                // Title block.
                Positioned(
                  left: w * 0.075,
                  top: h * 0.30,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a large glossy pill→blob morph plus accent droplets using
/// [soleBlobPath] — the same parametric geometry the toasts use.
class _GooeyArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void blob({
      required Offset origin,
      required double pillW,
      required double bodyW,
      required double totalH,
      required double t,
      required double pillH,
      double opacity = 1,
    }) {
      final path = soleBlobPath(
        pillW: pillW,
        bodyW: bodyW,
        totalH: totalH,
        t: t,
        pillH: pillH,
      ).shift(origin);
      // Soft shadow.
      canvas.drawPath(
        path.shift(const Offset(0, 10)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
      // Glossy black fill.
      canvas.drawPath(path,
          Paint()..color = const Color(0xFF07080A).withValues(alpha: opacity));
      // Specular sheen.
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.30 * opacity),
              Colors.white.withValues(alpha: 0.05 * opacity),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ).createShader(path.getBounds()),
      );
      // Hairline border.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.22 * opacity),
      );
    }

    // Main morph: pill melting into a body — mid-morph so the gooey
    // junction is visible.
    blob(
      origin: Offset(w * 0.56, h * 0.16),
      pillW: w * 0.16,
      bodyW: w * 0.34,
      totalH: h * 0.52,
      t: 0.82,
      pillH: h * 0.115,
    );
    // Companion pill higher up, barely morphing.
    blob(
      origin: Offset(w * 0.80, h * 0.60),
      pillW: w * 0.10,
      bodyW: w * 0.16,
      totalH: h * 0.24,
      t: 0.45,
      pillH: h * 0.085,
      opacity: 0.85,
    );

    // Accent droplets.
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

    droplet(Offset(w * 0.525, h * 0.78), h * 0.030, const Color(0xFF4ADE80));
    droplet(Offset(w * 0.93, h * 0.28), h * 0.024, const Color(0xFFF87171));
    droplet(Offset(w * 0.62, h * 0.86), h * 0.019, const Color(0xFFFBBF24));
    droplet(Offset(w * 0.965, h * 0.52), h * 0.027, const Color(0xFF60A5FA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
