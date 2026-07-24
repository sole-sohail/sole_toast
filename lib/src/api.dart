import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'host.dart';
import 'manager.dart';
import 'toast_data.dart';
import 'types.dart';

/// Sole Toast public API.
///
/// One-time setup:
/// ```dart
/// MaterialApp(builder: SoleToast.init());
/// ```
///
/// Then from anywhere:
/// ```dart
/// SoleToast.success('Saved', description: 'Your changes have been synced.');
/// ```
abstract final class SoleToast {
  static SoleToastManager get _manager => SoleToastManager.instance;

  /// Global configuration. Assign a new [SoleToastConfig] to change defaults.
  static SoleToastConfig get config => _manager.config;
  static set config(SoleToastConfig value) {
    _manager.config = value;
  }

  /// Returns a [TransitionBuilder] that mounts the toast layer above the
  /// app. Pass your existing builder through [builder] if you already use
  /// one.
  static TransitionBuilder init({TransitionBuilder? builder}) {
    return (BuildContext context, Widget? child) {
      final layer = SoleToastLayer(child: child ?? const SizedBox.shrink());
      return builder == null ? layer : builder(context, layer);
    };
  }

  /// Shows a toast. Returns its id (usable with [update] / [dismiss]).
  static Object show(
    String title, {
    SoleToastType type = SoleToastType.info,
    String? description,
    SoleToastAction? action,
    Duration? duration,
    SoleToastMode? mode,
    bool? showProgress,
    SoleTextEffect? textEffect,
    Object? id,
    VoidCallback? onDismiss,
  }) {
    assert(
      SoleToastLayer.mountedLayers > 0,
      'SoleToast has not been initialized. Add the toast layer to your app '
      'first:\n\n  MaterialApp(builder: SoleToast.init())\n\n'
      '(or mount a SoleToastLayer manually near the root of your tree).',
    );
    final data = SoleToastData(
      id: id ?? _manager.nextId(),
      type: type,
      title: title,
      description: description,
      action: action,
      duration: duration,
      modeOverride: mode,
      showProgressOverride: showProgress,
      textEffectOverride: textEffect,
      onDismiss: onDismiss,
    );
    _announce(title, description, type);
    return _manager.show(data);
  }

  /// Green success toast.
  static Object success(String title,
          {String? description,
          SoleToastAction? action,
          Duration? duration,
          SoleToastMode? mode,
          bool? showProgress,
          SoleTextEffect? textEffect,
          Object? id,
          VoidCallback? onDismiss}) =>
      show(title,
          type: SoleToastType.success,
          description: description,
          action: action,
          duration: duration,
          mode: mode,
          showProgress: showProgress,
          textEffect: textEffect,
          id: id,
          onDismiss: onDismiss);

  /// Red error toast (plays the shake when transitioning to error).
  static Object error(String title,
          {String? description,
          SoleToastAction? action,
          Duration? duration,
          SoleToastMode? mode,
          bool? showProgress,
          SoleTextEffect? textEffect,
          Object? id,
          VoidCallback? onDismiss}) =>
      show(title,
          type: SoleToastType.error,
          description: description,
          action: action,
          duration: duration,
          mode: mode,
          showProgress: showProgress,
          textEffect: textEffect,
          id: id,
          onDismiss: onDismiss);

  /// Amber warning toast.
  static Object warning(String title,
          {String? description,
          SoleToastAction? action,
          Duration? duration,
          SoleToastMode? mode,
          bool? showProgress,
          SoleTextEffect? textEffect,
          Object? id,
          VoidCallback? onDismiss}) =>
      show(title,
          type: SoleToastType.warning,
          description: description,
          action: action,
          duration: duration,
          mode: mode,
          showProgress: showProgress,
          textEffect: textEffect,
          id: id,
          onDismiss: onDismiss);

  /// Blue informational toast.
  static Object info(String title,
          {String? description,
          SoleToastAction? action,
          Duration? duration,
          SoleToastMode? mode,
          bool? showProgress,
          SoleTextEffect? textEffect,
          Object? id,
          VoidCallback? onDismiss}) =>
      show(title,
          type: SoleToastType.info,
          description: description,
          action: action,
          duration: duration,
          mode: mode,
          showProgress: showProgress,
          textEffect: textEffect,
          id: id,
          onDismiss: onDismiss);

  /// Shows a spinner toast for [future], morphing into a success or error
  /// toast when it settles. Returns the future's result (errors rethrow).
  static Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    required String Function(T value) success,
    required String Function(Object error) error,
    String? Function(T value)? successDescription,
    String? Function(Object error)? errorDescription,
    Duration? duration,
    SoleToastMode? mode,
  }) async {
    final id =
        show(loading, type: SoleToastType.info, duration: duration, mode: mode);
    // Flag the loading phase after creation so the spinner shows.
    _manager.update(id, loading: true);
    try {
      final value = await future;
      final desc = successDescription?.call(value);
      _manager.update(
        id,
        title: success(value),
        type: SoleToastType.success,
        description: desc,
        clearDescription: desc == null,
        loading: false,
      );
      return value;
    } catch (e) {
      final desc = errorDescription?.call(e);
      _manager.update(
        id,
        title: error(e),
        type: SoleToastType.error,
        description: desc,
        clearDescription: desc == null,
        loading: false,
      );
      rethrow;
    }
  }

  /// Updates a visible or queued toast in place.
  static void update(
    Object id, {
    String? title,
    String? description,
    bool clearDescription = false,
    SoleToastType? type,
    SoleToastAction? action,
    bool clearAction = false,
  }) {
    _manager.update(
      id,
      title: title,
      description: description,
      clearDescription: clearDescription,
      type: type,
      action: action,
      clearAction: clearAction,
    );
    if (title != null) {
      _announce(title, description, type ?? SoleToastType.info);
    }
  }

  /// Dismisses one toast by [id], or all toasts when omitted. The toast
  /// plays its fold-up choreography rather than vanishing.
  static void dismiss([Object? id]) => _manager.dismiss(id);

  /// Dismisses every toast of [type] (visible and queued).
  static void dismissByType(SoleToastType type) => _manager.dismissByType(type);

  /// Dismisses everything.
  static void dismissAll() => _manager.dismiss();

  static void _announce(String title, String? description, SoleToastType type) {
    final message = description == null ? title : '$title: $description';
    // Fire-and-forget; assertive channel for problems.
    // `sendAnnouncement` does not exist at this package's minimum Flutter
    // version, so the deprecated API is intentional.
    // ignore: deprecated_member_use
    SemanticsService.announce(
      message,
      TextDirection.ltr,
      assertiveness:
          type == SoleToastType.error || type == SoleToastType.warning
              ? Assertiveness.assertive
              : Assertiveness.polite,
    );
  }
}
