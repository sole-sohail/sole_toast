import 'package:flutter_test/flutter_test.dart';
import 'package:sole_toast/sole_toast.dart';
import 'package:sole_toast/src/manager.dart';
import 'package:sole_toast/src/toast_data.dart';

SoleToastData _toast(Object id,
        {SoleToastType type = SoleToastType.info, String title = 't'}) =>
    SoleToastData(id: id, type: type, title: title);

void main() {
  final manager = SoleToastManager.instance;

  setUp(manager.reset);

  test('respects maxVisible and drains the FIFO queue', () {
    for (var i = 0; i < 5; i++) {
      manager.show(_toast(i));
    }
    expect(manager.active, hasLength(3));
    expect(manager.queueLength, 2);

    manager.onExited(manager.active.first);
    expect(manager.active, hasLength(3));
    expect(manager.active.map((d) => d.id), [1, 2, 3]);
    expect(manager.queueLength, 1);
  });

  test('update mutates active and queued toasts', () {
    for (var i = 0; i < 4; i++) {
      manager.show(_toast(i));
    }
    manager.update(0, title: 'updated-active');
    manager.update(3, title: 'updated-queued', type: SoleToastType.error);
    expect(manager.active.first.title, 'updated-active');
    // Drain the queue and verify the queued toast carried the update.
    manager.onExited(manager.active.first);
    final drained = manager.active.last;
    expect(drained.id, 3);
    expect(drained.title, 'updated-queued');
    expect(drained.type, SoleToastType.error);
  });

  test('dismiss by id removes queued toasts and flags active ones', () {
    for (var i = 0; i < 4; i++) {
      manager.show(_toast(i));
    }
    manager.dismiss(3); // queued → silently dropped
    expect(manager.queueLength, 0);
    manager.dismiss(1); // active → graceful dismiss requested
    expect(manager.active.firstWhere((d) => d.id == 1).dismissRequested,
        isTrue);
  });

  test('dismissByType clears matching queued and active toasts', () {
    manager.show(_toast(0, type: SoleToastType.error));
    manager.show(_toast(1, type: SoleToastType.success));
    manager.show(_toast(2, type: SoleToastType.error));
    manager.show(_toast(3, type: SoleToastType.error)); // queued
    manager.dismissByType(SoleToastType.error);
    expect(manager.queueLength, 0);
    expect(
        manager.active.where((d) => d.type == SoleToastType.error).every(
            (d) => d.dismissRequested),
        isTrue);
    expect(
        manager.active
            .firstWhere((d) => d.type == SoleToastType.success)
            .dismissRequested,
        isFalse);
  });

  test('dismiss() clears everything', () {
    for (var i = 0; i < 5; i++) {
      manager.show(_toast(i));
    }
    manager.dismiss();
    expect(manager.queueLength, 0);
    expect(manager.active.every((d) => d.dismissRequested), isTrue);
  });

  test('island mode is single-slot: a second show morphs the first', () {
    manager.islandActive = true;
    final firstId = manager.show(_toast('a', title: 'first'));
    final secondId = manager.show(
        _toast('b', type: SoleToastType.error, title: 'second'));
    expect(secondId, firstId);
    expect(manager.active, hasLength(1));
    expect(manager.active.first.title, 'second');
    expect(manager.active.first.type, SoleToastType.error);
  });

  test('onDismiss fires when the toast exits', () {
    var dismissed = false;
    final data = SoleToastData(
        id: 'x',
        type: SoleToastType.info,
        title: 't',
        onDismiss: () => dismissed = true);
    manager.show(data);
    manager.onExited(data);
    expect(dismissed, isTrue);
    expect(manager.active, isEmpty);
  });
}
