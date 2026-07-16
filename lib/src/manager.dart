import 'package:flutter/foundation.dart';

import 'toast_data.dart';
import 'types.dart';

/// Singleton bookkeeping for live toasts: the visible list, the FIFO queue,
/// id allocation and dismiss routing. Pure Dart — fully unit-testable.
class SoleToastManager extends ChangeNotifier {
  SoleToastManager._();

  static final SoleToastManager instance = SoleToastManager._();

  SoleToastConfig config = const SoleToastConfig();

  final List<SoleToastData> active = <SoleToastData>[];
  final List<SoleToastData> _queue = <SoleToastData>[];

  /// Set by the host each build; single-slot behavior when docked to the
  /// Dynamic Island.
  bool islandActive = false;

  int _seq = 0;

  Object nextId() => 'sole-toast-${++_seq}';

  int get _maxVisible => islandActive ? 1 : config.maxVisible;

  /// Number of queued (not yet visible) toasts.
  int get queueLength => _queue.length;

  /// Shows [data], queueing it when the visible slots are full. In island
  /// mode a new toast morphs the existing capsule in place instead of
  /// stacking.
  Object show(SoleToastData data) {
    if (islandActive && active.isNotEmpty) {
      final current = active.first;
      current.update(
        title: data.title,
        type: data.type,
        description: data.description,
        clearDescription: data.description == null,
        action: data.action,
        clearAction: data.action == null,
        loading: data.phase == SoleToastPhase.loading,
      );
      return current.id;
    }
    if (active.length < _maxVisible) {
      active.add(data);
      notifyListeners();
    } else {
      _queue.add(data);
    }
    return data.id;
  }

  /// Called by the card once its exit animation finishes.
  void onExited(SoleToastData data) {
    if (!active.remove(data)) return;
    data.onDismiss?.call();
    data.dispose();
    _drainQueue();
    notifyListeners();
  }

  void _drainQueue() {
    while (_queue.isNotEmpty && active.length < _maxVisible) {
      active.add(_queue.removeAt(0));
    }
  }

  SoleToastData? _find(Object id) {
    for (final d in active) {
      if (d.id == id) return d;
    }
    for (final d in _queue) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// In-place update of an active or queued toast.
  void update(
    Object id, {
    String? title,
    String? description,
    bool clearDescription = false,
    SoleToastType? type,
    SoleToastAction? action,
    bool clearAction = false,
    bool? loading,
  }) {
    _find(id)?.update(
      title: title,
      description: description,
      clearDescription: clearDescription,
      type: type,
      action: action,
      clearAction: clearAction,
      loading: loading,
    );
  }

  /// Dismisses one toast by [id], or every toast when [id] is null.
  void dismiss([Object? id]) {
    if (id == null) {
      _queue.clear();
      for (final d in List<SoleToastData>.of(active)) {
        d.requestDismiss();
      }
      return;
    }
    _queue.removeWhere((d) => d.id == id);
    for (final d in active) {
      if (d.id == id) d.requestDismiss();
    }
  }

  /// Dismisses all queued and active toasts of [type].
  void dismissByType(SoleToastType type) {
    _queue.removeWhere((d) => d.type == type);
    for (final d in List<SoleToastData>.of(active)) {
      if (d.type == type) d.requestDismiss();
    }
  }

  /// Clears all state — tests only.
  @visibleForTesting
  void reset() {
    active.clear();
    _queue.clear();
    islandActive = false;
    config = const SoleToastConfig();
    notifyListeners();
  }
}
