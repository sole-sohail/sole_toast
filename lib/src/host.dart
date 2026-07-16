import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'island.dart';
import 'manager.dart';
import 'toast_card.dart';
import 'types.dart';

/// Mounts the toast overlay above [child]. Installed once via
/// `MaterialApp(builder: SoleToast.init())`, or manually anywhere high in
/// the tree.
class SoleToastLayer extends StatefulWidget {
  const SoleToastLayer({super.key, required this.child});

  final Widget child;

  /// How many layers are currently mounted — used to give a friendly error
  /// when `SoleToast.show` is called without setup.
  static int mountedLayers = 0;

  @override
  State<SoleToastLayer> createState() => _SoleToastLayerState();
}

class _SoleToastLayerState extends State<SoleToastLayer> {
  final SoleToastManager _manager = SoleToastManager.instance;

  @override
  void initState() {
    super.initState();
    SoleToastLayer.mountedLayers++;
  }

  @override
  void dispose() {
    SoleToastLayer.mountedLayers--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _manager,
            builder: (context, _) => _buildOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final mq = MediaQuery.of(context);
    final config = _manager.config;
    final island =
        SoleIslandSpec.resolve(mq, defaultTargetPlatform, config.islandMode);
    // Inform the manager (single-slot show behavior); no notify — this runs
    // during build.
    _manager.islandActive = island.active;

    if (_manager.active.isEmpty) return const SizedBox.shrink();

    final cards = <Widget>[];
    for (var i = 0; i < _manager.active.length; i++) {
      final data = _manager.active[i];
      if (i > 0) cards.add(SizedBox(height: config.gap));
      cards.add(KeyedSubtree(
        key: ValueKey(data.id),
        child: SoleToastCard(
          data: data,
          config: config,
          island: island,
          onExited: _manager.onExited,
        ),
      ));
    }

    if (island.active) {
      return Positioned(
        top: island.capsuleRect.top,
        left: 0,
        right: 0,
        child: Column(mainAxisSize: MainAxisSize.min, children: cards),
      );
    }

    final top = config.position == SoleToastPosition.topCenter;
    final inset = top
        ? mq.viewPadding.top + 10
        : mq.viewPadding.bottom + mq.viewInsets.bottom + 16;
    return Positioned(
      top: top ? inset : null,
      bottom: top ? null : inset,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        verticalDirection: top ? VerticalDirection.down : VerticalDirection.up,
        children: cards,
      ),
    );
  }
}
