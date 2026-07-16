import 'package:flutter/foundation.dart';

import 'types.dart';

/// Live, mutable state of a single toast. The card listens and animates in
/// place when the manager applies `SoleToast.update(...)` or a promise
/// settles.
class SoleToastData extends ChangeNotifier {
  SoleToastData({
    required this.id,
    required SoleToastType type,
    required String title,
    String? description,
    SoleToastAction? action,
    this.duration,
    this.modeOverride,
    this.showProgressOverride,
    this.onDismiss,
    bool loading = false,
  })  : _type = type,
        _phase = loading ? SoleToastPhase.loading : phaseOf(type),
        _title = title,
        _description = description,
        _action = action;

  final Object id;

  /// Per-toast display duration override (null → config default).
  final Duration? duration;

  /// Per-toast surface mode override (null → config default).
  final SoleToastMode? modeOverride;

  /// Per-toast progress bar override (null → config default).
  final bool? showProgressOverride;

  /// Invoked once when the toast leaves the screen (any reason).
  VoidCallback? onDismiss;

  final DateTime createdAt = DateTime.now();

  SoleToastType _type;
  SoleToastPhase _phase;
  String _title;
  String? _description;
  SoleToastAction? _action;
  bool _dismissRequested = false;

  /// Incremented on every content mutation; the card re-measures when it
  /// changes.
  int revision = 0;

  SoleToastType get type => _type;
  SoleToastPhase get phase => _phase;
  String get title => _title;
  String? get description => _description;
  SoleToastAction? get action => _action;
  bool get dismissRequested => _dismissRequested;
  bool get hasBody => _description != null || _action != null;

  /// Applies an in-place update. Null arguments leave fields untouched;
  /// use the `clear*` flags to remove content.
  void update({
    String? title,
    String? description,
    bool clearDescription = false,
    SoleToastType? type,
    SoleToastAction? action,
    bool clearAction = false,
    bool? loading,
  }) {
    if (title != null) _title = title;
    if (clearDescription) {
      _description = null;
    } else if (description != null) {
      _description = description;
    }
    if (clearAction) {
      _action = null;
    } else if (action != null) {
      _action = action;
    }
    if (type != null) {
      _type = type;
      _phase = phaseOf(type);
    }
    if (loading == true) {
      _phase = SoleToastPhase.loading;
    } else if (loading == false && _phase == SoleToastPhase.loading) {
      _phase = phaseOf(_type);
    }
    revision++;
    notifyListeners();
  }

  /// Asks the card to play its collapse + exit choreography.
  void requestDismiss() {
    if (_dismissRequested) return;
    _dismissRequested = true;
    notifyListeners();
  }
}
