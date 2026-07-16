import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';
import 'package:sole_toast/src/manager.dart';

Widget _app() {
  return MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: SoleToastLayer(child: Container()),
    ),
  );
}

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  var remaining = ms;
  while (remaining > 0) {
    final step = remaining < 100 ? remaining : 100;
    await tester.pump(Duration(milliseconds: step));
    remaining -= step;
  }
}

void main() {
  setUp(SoleToastManager.instance.reset);

  testWidgets('success toast renders through the layer and auto-dismisses',
      (tester) async {
    await tester.pumpWidget(_app());
    SoleToast.config = const SoleToastConfig(enableHaptics: false);

    SoleToast.success('Saved');
    await tester.pump();
    await _pumpFor(tester, 600);
    expect(find.text('Saved'), findsWidgets);

    await _pumpFor(tester, 5000);
    expect(find.text('Saved'), findsNothing);
    expect(SoleToastManager.instance.active, isEmpty);
  });

  testWidgets('promise toast morphs into success and returns the value',
      (tester) async {
    await tester.pumpWidget(_app());
    SoleToast.config = const SoleToastConfig(enableHaptics: false);

    final completer = Completer<int>();
    final resultFuture = SoleToast.promise<int>(
      completer.future,
      loading: 'Working…',
      success: (v) => 'Got $v',
      error: (e) => 'Failed',
    );
    await tester.pump();
    await _pumpFor(tester, 400);
    expect(find.text('Working…'), findsWidgets);

    completer.complete(42);
    await tester.pump();
    await _pumpFor(tester, 400);
    expect(find.text('Got 42'), findsWidgets);
    expect(await resultFuture, 42);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('promise toast morphs into error and rethrows', (tester) async {
    await tester.pumpWidget(_app());
    SoleToast.config = const SoleToastConfig(enableHaptics: false);

    final completer = Completer<int>();
    final resultFuture = SoleToast.promise<int>(
      completer.future,
      loading: 'Working…',
      success: (v) => 'Got $v',
      error: (e) => 'Broke: $e',
    );
    await tester.pump();
    completer.completeError('boom');
    await expectLater(resultFuture, throwsA('boom'));
    await tester.pump();
    await _pumpFor(tester, 500);
    expect(find.text('Broke: boom'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dismissAll folds every visible toast away', (tester) async {
    await tester.pumpWidget(_app());
    SoleToast.config = const SoleToastConfig(enableHaptics: false);

    SoleToast.info('One');
    SoleToast.info('Two');
    await tester.pump();
    await _pumpFor(tester, 600);
    expect(SoleToastManager.instance.active, hasLength(2));

    SoleToast.dismissAll();
    await _pumpFor(tester, 1200);
    expect(SoleToastManager.instance.active, isEmpty);
  });

  testWidgets('config setter changes global defaults', (tester) async {
    SoleToast.config = const SoleToastConfig(
        mode: SoleToastMode.dark, maxVisible: 1, enableHaptics: false);
    expect(SoleToast.config.mode, SoleToastMode.dark);

    await tester.pumpWidget(_app());
    SoleToast.info('One');
    SoleToast.info('Two');
    await tester.pump();
    expect(SoleToastManager.instance.active, hasLength(1));
    expect(SoleToastManager.instance.queueLength, 1);
    SoleToast.dismissAll();
    await _pumpFor(tester, 1200);
  });
}
