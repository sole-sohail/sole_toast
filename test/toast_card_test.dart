import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';
import 'package:sole_toast/src/toast_card.dart';
import 'package:sole_toast/src/toast_data.dart';

Widget _harness(
  SoleToastData data, {
  SoleToastConfig config = const SoleToastConfig(enableHaptics: false),
  SoleIslandSpec island = SoleIslandSpec.inactive,
  required void Function(SoleToastData) onExited,
  bool reduced = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      disableAnimations: reduced,
    ),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: SoleToastCard(
          data: data,
          config: config,
          island: island,
          onExited: onExited,
        ),
      ),
    ),
  );
}

SoleToastCardState _state(WidgetTester tester) =>
    tester.state<SoleToastCardState>(find.byType(SoleToastCard));

/// Advances time in ~100 ms frames so springs tick like on a real device
/// (one giant pump would quantize the fake clock and stall simulations).
Future<void> _pumpFor(WidgetTester tester, int ms) async {
  var remaining = ms;
  while (remaining > 0) {
    final step = remaining < 100 ? remaining : 100;
    await tester.pump(Duration(milliseconds: step));
    remaining -= step;
  }
}

void main() {
  testWidgets('expanded toast walks the full lifecycle', (tester) async {
    var exited = false;
    final data = SoleToastData(
      id: 1,
      type: SoleToastType.success,
      title: 'Saved',
      description: 'Your changes have been synced.',
    );
    await tester.pumpWidget(_harness(data, onExited: (_) => exited = true));
    await tester.pump();
    await _pumpFor(tester, 100);
    expect(_state(tester).stage,
        anyOf(SoleCardStage.entering, SoleCardStage.compact));

    // Enter (260) + expand delay (330) + morph spring (~1000).
    await _pumpFor(tester, 800);
    expect(_state(tester).stage,
        anyOf(SoleCardStage.expanding, SoleCardStage.shown));
    await _pumpFor(tester, 1400);
    expect(_state(tester).stage, SoleCardStage.shown);

    // Display window (4000 − 330 − 900 = 2770) then collapse (900).
    await _pumpFor(tester, 2900);
    expect(_state(tester).stage, SoleCardStage.collapsing);
    await _pumpFor(tester, 1000);
    expect(_state(tester).stage, SoleCardStage.lingering);

    // Linger (800) + exit (220).
    await _pumpFor(tester, 1200);
    expect(exited, isTrue);
  });

  testWidgets('simple toast never expands and exits after its duration',
      (tester) async {
    var exited = false;
    final data =
        SoleToastData(id: 2, type: SoleToastType.info, title: 'Hello');
    await tester.pumpWidget(_harness(data, onExited: (_) => exited = true));
    await tester.pump();
    await _pumpFor(tester, 500);
    expect(_state(tester).stage, SoleCardStage.compact);

    await _pumpFor(tester, 4500);
    expect(exited, isTrue);
  });

  testWidgets('reduced motion fast-forwards the morph', (tester) async {
    final data = SoleToastData(
      id: 3,
      type: SoleToastType.warning,
      title: 'Careful',
      description: 'Something needs attention.',
    );
    await tester.pumpWidget(_harness(data, onExited: (_) {}, reduced: true));
    await tester.pump();
    // Several tiny frames: the 1 ms timers need sequential pumps to fire.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(_state(tester).stage, SoleCardStage.shown);
    // Cleanly unwind pending timers.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tap during collapse re-expands and restarts the timer',
      (tester) async {
    final data = SoleToastData(
      id: 4,
      type: SoleToastType.info,
      title: 'Update',
      description: 'Tap to keep me open.',
    );
    await tester.pumpWidget(_harness(data, onExited: (_) {}));
    await tester.pump();
    await _pumpFor(tester, 2300);
    expect(_state(tester).stage, SoleCardStage.shown);

    await _pumpFor(tester, 2900);
    expect(_state(tester).stage, SoleCardStage.collapsing);

    await tester.tap(find.byType(SoleToastCard), warnIfMissed: false);
    await _pumpFor(tester, 2000);
    expect(_state(tester).stage, SoleCardStage.shown);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('horizontal swipe past the threshold dismisses early',
      (tester) async {
    var exited = false;
    final data = SoleToastData(
      id: 5,
      type: SoleToastType.error,
      title: 'Oops',
      description: 'Swipe me away.',
    );
    await tester.pumpWidget(_harness(data, onExited: (_) => exited = true));
    await tester.pump();
    await _pumpFor(tester, 2300);
    expect(_state(tester).stage, SoleCardStage.shown);

    await tester.drag(find.byType(SoleToastCard), const Offset(140, 0),
        warnIfMissed: false);
    await _pumpFor(tester, 400);
    expect(exited, isTrue);
  });

  testWidgets('update() to error fires the shake and swaps content',
      (tester) async {
    final data =
        SoleToastData(id: 6, type: SoleToastType.info, title: 'Uploading…');
    await tester.pumpWidget(_harness(data, onExited: (_) {}));
    await tester.pump();
    await _pumpFor(tester, 500);
    expect(_state(tester).stage, SoleCardStage.compact);

    data.update(title: 'Upload failed', type: SoleToastType.error);
    await tester.pump();
    await _pumpFor(tester, 700);
    expect(find.text('Upload failed'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('island choreography reaches the expanded body', (tester) async {
    const mq = MediaQueryData(
      size: Size(390, 844),
      viewPadding: EdgeInsets.only(top: 59),
      padding: EdgeInsets.only(top: 59),
    );
    final island =
        SoleIslandSpec.resolve(mq, TargetPlatform.iOS, SoleIslandMode.always);
    expect(island.active, isTrue);

    final data = SoleToastData(
      id: 7,
      type: SoleToastType.success,
      title: 'Done',
      description: 'Everything synced.',
    );
    await tester.pumpWidget(_harness(data, island: island, onExited: (_) {}));
    await tester.pump();
    await _pumpFor(tester, 250);
    expect(
        _state(tester).stage,
        anyOf(SoleCardStage.entering, SoleCardStage.islandIcon,
            SoleCardStage.islandTitle));

    // Icon hold (420) + title hold (350) + expand delay + morph spring.
    await _pumpFor(tester, 3000);
    expect(_state(tester).stage, SoleCardStage.shown);
    await tester.pumpWidget(const SizedBox());
  });
}
