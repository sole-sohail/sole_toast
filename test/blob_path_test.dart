import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/src/blob_path.dart';

void main() {
  const pw = 140.0, bw = 340.0, th = 150.0, ph = 38.0;

  group('soleBlobPath (centered)', () {
    test('t=0 is a pure pill centered at final body width', () {
      final bounds = soleBlobPath(
              pillW: pw, bodyW: bw, totalH: th, t: 0, pillH: ph)
          .getBounds();
      expect(bounds.height, closeTo(ph, 0.6));
      expect(bounds.width, closeTo(pw, 0.6));
      expect(bounds.left, closeTo((bw - pw) / 2, 0.6));
    });

    test('t=1 fills the full body rect', () {
      final bounds = soleBlobPath(
              pillW: pw, bodyW: bw, totalH: th, t: 1, pillH: ph)
          .getBounds();
      expect(bounds.left, closeTo(0, 0.6));
      expect(bounds.top, closeTo(0, 0.6));
      expect(bounds.width, closeTo(bw, 0.6));
      expect(bounds.height, closeTo(th, 0.6));
    });

    test('t=0.5 interpolates height and stays centered', () {
      final bounds = soleBlobPath(
              pillW: pw, bodyW: bw, totalH: th, t: 0.5, pillH: ph)
          .getBounds();
      expect(bounds.height, closeTo(ph + (th - ph) * 0.5, 0.6));
      expect(bounds.center.dx, closeTo(bw / 2, 0.6));
    });

    test('width grows monotonically with t', () {
      var last = 0.0;
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        final w = soleBlobPath(
                pillW: pw, bodyW: bw, totalH: th, t: t, pillH: ph)
            .getBounds()
            .width;
        expect(w, greaterThanOrEqualTo(last - 0.001));
        last = w;
      }
    });

    test('tiny expansion (< 8px body) stays a pill', () {
      final bounds = soleBlobPath(
              pillW: pw, bodyW: bw, totalH: ph + 6, t: 1, pillH: ph)
          .getBounds();
      expect(bounds.height, closeTo(ph, 0.6));
    });
  });

  group('soleBlobPath (left anchored)', () {
    test('t=0 pill anchors to left edge', () {
      final bounds = soleBlobPath(
              pillW: pw,
              bodyW: bw,
              totalH: th,
              t: 0,
              pillH: ph,
              centered: false)
          .getBounds();
      expect(bounds.left, closeTo(0, 0.6));
      expect(bounds.width, closeTo(pw, 0.6));
    });

    test('t=1 fills full body rect from origin', () {
      final bounds = soleBlobPath(
              pillW: pw,
              bodyW: bw,
              totalH: th,
              t: 1,
              pillH: ph,
              centered: false)
          .getBounds();
      expect(bounds.width, closeTo(bw, 0.6));
      expect(bounds.height, closeTo(th, 0.6));
    });

    test('pill wider than body clamps to body width', () {
      final bounds = soleBlobPath(
              pillW: 500,
              bodyW: bw,
              totalH: th,
              t: 0,
              pillH: ph,
              centered: false)
          .getBounds();
      expect(bounds.width, closeTo(bw, 0.6));
    });
  });
}
