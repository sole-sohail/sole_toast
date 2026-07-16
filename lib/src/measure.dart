import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports the laid-out size of its child after each layout pass.
///
/// Used by the toast card's offstage measurement pass: the pill width comes
/// from the header row's natural size and the blob's total height from the
/// content column laid out at the final body width.
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderMeasureSize).onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_reported == newSize) return;
    _reported = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChange(newSize);
    });
  }
}
