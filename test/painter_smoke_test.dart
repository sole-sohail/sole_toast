import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';
import 'package:sole_toast/src/blob_painter.dart';
import 'package:sole_toast/src/icons.dart';

void main() {
  group('SoleBlobPainter', () {
    testWidgets('paints at t=0 / 0.5 / 1 without errors', (tester) async {
      final dims = SoleBlobDims()
        ..update(pillW: 140, bodyW: 340, totalH: 150, morphT: 0);
      final style = SoleToastStyle.resolve(
          SoleToastType.success, SoleToastMode.glossy);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CustomPaint(
              size: const Size(340, 150),
              painter: SoleBlobPainter(dims: dims, style: style),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      dims.update(morphT: 0.5);
      await tester.pump();
      expect(tester.takeException(), isNull);

      dims.update(morphT: 1.2); // overshoot must clamp, not throw
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(dims.t, 1.0);
    });

    test('currentH interpolates between pill and total height', () {
      final dims = SoleBlobDims()
        ..update(pillW: 100, bodyW: 300, totalH: 138, pillH: 38, morphT: 0.5);
      expect(dims.currentH, closeTo(88, 0.001));
    });

    test('pillLeft offsets the pill lobe', () {
      final dims = SoleBlobDims()
        ..update(pillW: 120, bodyW: 340, totalH: 150, morphT: 0, pillLeft: 20);
      expect(dims.buildPath().getBounds().left, closeTo(20, 0.6));
    });
  });

  group('SoleToastIcon', () {
    testWidgets('renders every phase', (tester) async {
      for (final phase in SoleToastPhase.values) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SoleToastIcon(
                  phase: phase, color: const Color(0xFF4CAF50)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull, reason: 'phase $phase');
      }
      // Let the spinner controller unwind before teardown.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('partial progress paints without errors', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SoleToastIcon(
                phase: SoleToastPhase.success,
                color: Color(0xFF4CAF50),
                progress: 0.4),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
