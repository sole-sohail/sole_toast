import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'blob_painter.dart';
import 'icons.dart';
import 'island.dart';
import 'measure.dart';
import 'springs.dart';
import 'theme.dart';
import 'toast_data.dart';
import 'types.dart';

/// Lifecycle stage of a [SoleToastCard].
enum SoleCardStage {
  measuring,
  entering,
  islandIcon,
  islandTitle,
  compact,
  expanding,
  shown,
  collapsing,
  lingering,
  exiting,
  gone,
}

// Timeline constants (ported from goey-toast v0.5.0).
const _kEnterMs = 260;
const _kExitMs = 220;
const _kExpandDelayMs = 330;
const _kMorphExpandSec = 0.9;
const _kMorphCollapseSec = 0.9;
const _kLingerMs = 800;
const _kBodyFadeMs = 350;
const _kActionSuccessLingerMs = 1200;
const _kIslandIconHoldMs = 420;
const _kIslandTitleHoldMs = 350;
const _kSwipeThreshold = 100.0;
const _kSmoothEase = Cubic(0.4, 0, 0.2, 1);

/// A single animated toast: pill entry, gooey expand, timed fold-up, exit —
/// plus the Dynamic Island choreography when [island] is active.
class SoleToastCard extends StatefulWidget {
  const SoleToastCard({
    super.key,
    required this.data,
    required this.config,
    required this.island,
    required this.onExited,
  });

  final SoleToastData data;
  final SoleToastConfig config;
  final SoleIslandSpec island;
  final void Function(SoleToastData data) onExited;

  @override
  State<SoleToastCard> createState() => SoleToastCardState();
}

class SoleToastCardState extends State<SoleToastCard>
    with TickerProviderStateMixin {
  final SoleBlobDims _dims = SoleBlobDims();

  late final AnimationController _morph =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _resize =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _inOut = AnimationController(
      vsync: this, duration: const Duration(milliseconds: _kEnterMs));
  late final AnimationController _squish =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _headerSquish =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  late final AnimationController _drag =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _progress = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000), value: 1);

  SoleCardStage _stage = SoleCardStage.measuring;
  bool _bodyVisible = false;
  bool _exited = false;
  bool _squishIsCollapse = false;
  String? _actionSuccess;
  SoleToastPhase _lastPhase = SoleToastPhase.info;
  int _lastRevision = 0;

  // Measurement results.
  double _headerContentW = 0;
  double _measuredTotalH = 0;
  double _bodyW = 0;
  bool _reduced = false;

  // Display timer with pause support.
  Timer? _timer;
  int _remainingMs = 0;
  DateTime _timerStartedAt = DateTime.now();
  bool _paused = false;

  // Swipe state.
  double _dragDx = 0;
  bool _dragging = false;

  /// Current lifecycle stage — exposed for tests and the host.
  SoleCardStage get stage => _stage;

  SoleToastData get data => widget.data;
  SoleToastConfig get config => widget.config;
  bool get _isIsland => widget.island.active;
  double get _pillH =>
      _isIsland ? widget.island.capsuleRect.height : config.pillHeight;

  String get _title => _actionSuccess ?? data.title;
  SoleToastPhase get _phase =>
      _actionSuccess != null ? SoleToastPhase.success : data.phase;
  bool get _hasBody => _actionSuccess == null && data.hasBody;

  double get _islandW => widget.island.capsuleRect.width;
  double get _pillPadH => _isIsland ? 14.0 : 12.0;

  /// Outer pill width for the current stage/content.
  double get _pillOuterW {
    if (_isIsland) {
      switch (_stage) {
        case SoleCardStage.measuring:
        case SoleCardStage.entering:
          return _islandW;
        case SoleCardStage.islandIcon:
          return _islandW + 8 + 18 + 14;
        default:
          return _islandW + 8 + _headerContentW + _pillPadH;
      }
    }
    return _headerContentW + 2 * _pillPadH;
  }

  @override
  void initState() {
    super.initState();
    _lastPhase = data.phase;
    data.addListener(_onDataChanged);
    _morph.addListener(() {
      _dims.update(morphT: _morph.value);
    });
    _drag.addListener(() {
      if (!_dragging) setState(() => _dragDx = _drag.value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final screenW = MediaQuery.sizeOf(context).width;
    final maxW = math.min(config.maxWidth, screenW - 48);
    _bodyW = math.max(math.min(config.minWidth, screenW - 48), maxW);
  }

  @override
  void dispose() {
    data.removeListener(_onDataChanged);
    _timer?.cancel();
    _morph.dispose();
    _resize.dispose();
    _inOut.dispose();
    _squish.dispose();
    _headerSquish.dispose();
    _shake.dispose();
    _drag.dispose();
    _progress.dispose();
    _dims.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data changes
  // ---------------------------------------------------------------------

  void _onDataChanged() {
    if (!mounted) return;
    if (data.dismissRequested) {
      _gracefulDismiss();
      return;
    }
    if (data.phase == SoleToastPhase.error &&
        _lastPhase != SoleToastPhase.error &&
        !_reduced) {
      _shake.forward(from: 0);
      _haptic(HapticFeedback.mediumImpact);
    }
    _lastPhase = data.phase;
    if (data.revision != _lastRevision) {
      _lastRevision = data.revision;
      // Content changed → rebuild so offstage measurement re-reports; the
      // measurement callbacks animate the new dimensions in.
      setState(() {});
      // An update can add or remove the body → re-evaluate the timeline.
      if (_stage == SoleCardStage.compact && _hasBody) {
        _scheduleExpand();
      } else if (_stage == SoleCardStage.shown) {
        _restartTimer();
      }
    }
  }

  // ---------------------------------------------------------------------
  // Measurement plumbing
  // ---------------------------------------------------------------------

  void _onHeaderMeasured(Size size) {
    if (!mounted || size.width <= 0) return;
    // Clamp so an extreme title can never push the pill past the body width.
    final available =
        _bodyW - 2 * _pillPadH - (_isIsland ? _islandW + 8 : 0);
    final clamped = math.min(size.width, math.max(available, 40.0));
    final changed = (clamped - _headerContentW).abs() > 0.5;
    _headerContentW = clamped;
    _afterMeasure(changed);
  }

  void _onContentMeasured(Size size) {
    if (!mounted || size.height <= 0) return;
    final changed = (size.height - _measuredTotalH).abs() > 0.5;
    _measuredTotalH = math.max(size.height, _pillH);
    _afterMeasure(changed);
  }

  bool get _measured => _headerContentW > 0 && _measuredTotalH > 0;

  void _afterMeasure(bool changed) {
    if (!_measured) return;
    if (_stage == SoleCardStage.measuring) {
      _begin();
      return;
    }
    if (!changed) return;
    // Animate dimension changes in place (title/description updates).
    final targetPw = _pillOuterW;
    final targetTh = _measuredTotalH;
    if ((targetPw - _dims.pillW).abs() > 0.5 ||
        (targetTh - _dims.totalH).abs() > 0.5) {
      _animateDims(pw: targetPw, th: targetTh);
      if (_stage == SoleCardStage.compact && !_reduced && !_isIsland) {
        _triggerSquish(collapse: false);
      }
    }
  }

  /// Springs `dims.pillW`/`totalH` from their current to the given values.
  void _animateDims({double? pw, double? th}) {
    final fromPw = _dims.pillW;
    final fromTh = _dims.totalH;
    final toPw = pw ?? fromPw;
    final toTh = th ?? fromTh;
    if (_reduced) {
      _dims.update(pillW: toPw, totalH: toTh);
      return;
    }
    _resize.stop();
    _resize.value = 0;
    void tick() {
      final v = _resize.value.clamp(0.0, 1.2);
      _dims.update(
        pillW: fromPw + (toPw - fromPw) * v,
        totalH: fromTh + (toTh - fromTh) * v,
      );
    }

    _resize.addListener(tick);
    _resize
        .animateWith(springSimulation(config.spring
            ? morphSpring(durationSeconds: 0.5, bounce: config.bounce * 0.875)
            : morphSpring(durationSeconds: 0.5, bounce: 0)))
        .whenCompleteOrCancel(() => _resize.removeListener(tick));
  }

  // ---------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------

  void _begin() {
    _dims.update(
      pillW: _isIsland ? _islandW : _pillOuterW,
      bodyW: _bodyW,
      totalH: _measuredTotalH,
      morphT: 0,
      pillH: _pillH,
      pillLeft: _isIsland ? (_bodyW - _islandW) / 2 : null,
      clearPillLeft: !_isIsland,
    );
    _haptic(HapticFeedback.lightImpact);
    if (_isIsland) {
      _stage = SoleCardStage.entering;
      setState(() {});
      _inOut.duration = Duration(milliseconds: _ms(150));
      _inOut.forward().whenComplete(_islandIconStage);
    } else {
      setState(() => _stage = SoleCardStage.entering);
      _inOut.duration = Duration(milliseconds: _ms(_kEnterMs));
      _inOut.forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _stage = SoleCardStage.compact);
        if (!_hasBody) _triggerSquish(collapse: false, delayMs: 45);
        if (_hasBody) {
          _scheduleExpand();
        } else {
          _startTimer(_displayMsSimple, _exit);
        }
      });
    }
  }

  void _islandIconStage() {
    if (!mounted) return;
    setState(() => _stage = SoleCardStage.islandIcon);
    _animateDims(pw: _pillOuterW);
    Future<void>.delayed(Duration(milliseconds: _ms(_kIslandIconHoldMs)), () {
      if (!mounted || _stage != SoleCardStage.islandIcon) return;
      setState(() => _stage = SoleCardStage.islandTitle);
      _animateDims(pw: _pillOuterW);
      Future<void>.delayed(Duration(milliseconds: _ms(_kIslandTitleHoldMs)),
          () {
        if (!mounted || _stage != SoleCardStage.islandTitle) return;
        setState(() => _stage = SoleCardStage.compact);
        if (_hasBody) {
          _scheduleExpand(delayMs: 60);
        } else {
          _startTimer(_displayMsSimple, _exit);
        }
      });
    });
  }

  int get _displayMsSimple =>
      (data.duration ?? config.displayDuration).inMilliseconds;

  int get _displayMsExpanded {
    final total = (data.duration ?? config.displayDuration).inMilliseconds;
    final ms = total - _ms(_kExpandDelayMs) - (_kMorphCollapseSec * 1000).round();
    return math.max(ms, 800);
  }

  void _scheduleExpand({int? delayMs}) {
    Future<void>.delayed(Duration(milliseconds: _ms(delayMs ?? _kExpandDelayMs)),
        () {
      if (!mounted || !_hasBody) return;
      if (_stage != SoleCardStage.compact) return;
      _expand();
    });
  }

  void _expand({bool reExpand = false}) {
    setState(() {
      _stage = SoleCardStage.expanding;
      _bodyVisible = true;
    });
    _dims.update(totalH: _measuredTotalH, pillW: _pillOuterW);
    _morph.stop();
    if (_reduced) {
      _morph.value = 1;
      setState(() => _stage = SoleCardStage.shown);
      _startTimer(_displayMsExpanded, _collapse);
      _restartProgress();
      return;
    }
    final sim = config.spring
        ? springSimulation(
            morphSpring(durationSeconds: _kMorphExpandSec, bounce: config.bounce),
            from: _morph.value)
        : null;
    final future = sim != null
        ? _morph.animateWith(sim)
        : _morph.animateTo(1,
            duration: const Duration(milliseconds: 600), curve: _kSmoothEase);
    if (!reExpand) {
      _triggerSquish(collapse: false, delayMs: 80);
      _headerSquishTo(1);
    }
    future.whenComplete(() {
      if (!mounted || _stage != SoleCardStage.expanding) return;
      _morph.value = 1;
      setState(() => _stage = SoleCardStage.shown);
      _startTimer(_displayMsExpanded, _collapse);
      _restartProgress();
    });
  }

  void _collapse({bool preDismiss = true, VoidCallback? then}) {
    _timer?.cancel();
    _progress.stop();
    setState(() {
      _stage = SoleCardStage.collapsing;
      _bodyVisible = false;
    });
    // Collapse target pill may differ (action success label).
    _animateDims(pw: _pillOuterW);
    _headerSquishTo(0);
    _triggerSquish(collapse: true);
    _morph.stop();
    if (_reduced) {
      _morph.value = 0;
      _afterCollapse(then);
      return;
    }
    final future = (preDismiss || !config.spring)
        ? _morph.animateTo(0,
            duration:
                Duration(milliseconds: (_kMorphCollapseSec * 1000).round()),
            curve: _kSmoothEase)
        : _morph.animateWith(springSimulation(
            morphSpring(
                durationSeconds: _kMorphCollapseSec,
                bounce: config.bounce * 0.875),
            from: _morph.value,
            to: 0));
    future.whenComplete(() {
      if (!mounted || _stage != SoleCardStage.collapsing) return;
      _morph.value = 0;
      _afterCollapse(then);
    });
  }

  void _afterCollapse(VoidCallback? then) {
    if (then != null) {
      then();
      return;
    }
    setState(() => _stage = SoleCardStage.lingering);
    final linger =
        _actionSuccess != null ? _kActionSuccessLingerMs : _kLingerMs;
    _startTimer(_ms(linger), _exit);
  }

  void _exit() {
    if (_exited) return;
    _timer?.cancel();
    if (_isIsland) {
      _exitIsland();
      return;
    }
    setState(() => _stage = SoleCardStage.exiting);
    _inOut.reverseDuration = Duration(milliseconds: _ms(_kExitMs));
    _inOut.reverse().whenComplete(_finish);
  }

  void _exitIsland() {
    setState(() => _stage = SoleCardStage.exiting);
    // Shrink back to the bare capsule, then fade into the island.
    _animateDims(pw: _islandW);
    Future<void>.delayed(Duration(milliseconds: _ms(260)), () {
      if (!mounted) return;
      _inOut.reverseDuration = Duration(milliseconds: _ms(150));
      _inOut.reverse().whenComplete(_finish);
    });
  }

  void _finish() {
    if (_exited || !mounted) return;
    _exited = true;
    _stage = SoleCardStage.gone;
    widget.onExited(data);
  }

  void _gracefulDismiss() {
    switch (_stage) {
      case SoleCardStage.shown:
      case SoleCardStage.expanding:
        _collapse(then: () {
          setState(() => _stage = SoleCardStage.lingering);
          _startTimer(_ms(250), _exit);
        });
      case SoleCardStage.exiting:
      case SoleCardStage.gone:
        break;
      default:
        _exit();
    }
  }

  // ---------------------------------------------------------------------
  // Timer + progress
  // ---------------------------------------------------------------------

  void _startTimer(int ms, VoidCallback onFire) {
    _timer?.cancel();
    _remainingMs = ms;
    _timerStartedAt = DateTime.now();
    if (_paused) return;
    _timer = Timer(Duration(milliseconds: ms), () {
      if (mounted) onFire();
    });
  }

  void _restartTimer() {
    if (_stage == SoleCardStage.shown) {
      _startTimer(_displayMsExpanded, _collapse);
      _restartProgress();
    }
  }

  void _pauseTimer() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    final elapsed = DateTime.now().difference(_timerStartedAt).inMilliseconds;
    _remainingMs = math.max(0, _remainingMs - elapsed);
    _progress.stop();
  }

  void _resumeTimer() {
    if (!_paused) return;
    _paused = false;
    if (_remainingMs <= 0) return;
    _timerStartedAt = DateTime.now();
    final onFire = _stage == SoleCardStage.shown ? _collapse : _exit;
    _timer = Timer(Duration(milliseconds: _remainingMs), () {
      if (mounted) onFire();
    });
    if (_stage == SoleCardStage.shown && _showProgress) {
      _progress.animateTo(0,
          duration: Duration(milliseconds: _remainingMs),
          curve: Curves.linear);
    }
  }

  bool get _showProgress =>
      data.showProgressOverride ?? config.showProgress;

  void _restartProgress() {
    if (!_showProgress) return;
    _progress.value = 1;
    _progress.animateTo(0,
        duration: Duration(milliseconds: _remainingMs), curve: Curves.linear);
  }

  // ---------------------------------------------------------------------
  // Micro-motion
  // ---------------------------------------------------------------------

  int _ms(int standard) => _reduced ? 1 : standard;

  void _haptic(Future<void> Function() fn) {
    if (config.enableHaptics) fn();
  }

  DateTime _lastSquishAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _triggerSquish({required bool collapse, int delayMs = 0}) {
    if (_reduced || !config.spring) return;
    void run() {
      if (!mounted) return;
      final now = DateTime.now();
      if (now.difference(_lastSquishAt).inMilliseconds < 300) return;
      _lastSquishAt = now;
      _squishIsCollapse = collapse;
      _squish.stop();
      _squish.value = 0;
      _squish.animateWith(springSimulation(squishSpring(
        duration: collapse ? _kMorphCollapseSec : 0.6,
        defaultDuration: collapse ? _kMorphCollapseSec : 0.6,
        bounce: config.bounce,
      )));
    }

    if (delayMs > 0) {
      Future<void>.delayed(Duration(milliseconds: delayMs), run);
    } else {
      run();
    }
  }

  void _headerSquishTo(double target) {
    if (_reduced || !config.spring) return;
    _headerSquish.animateWith(springSimulation(
      squishSpring(duration: 0.6, defaultDuration: 0.6, bounce: config.bounce),
      from: _headerSquish.value,
      to: target,
    ));
  }

  // ---------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------

  void _onTap() {
    if (_stage == SoleCardStage.collapsing ||
        _stage == SoleCardStage.lingering) {
      if (!_hasBody) return;
      _timer?.cancel();
      _morph.stop();
      _expand(reExpand: true);
    }
  }

  void _onActionTap(SoleToastAction action) {
    _haptic(HapticFeedback.selectionClick);
    if (action.successLabel != null) {
      setState(() => _actionSuccess = action.successLabel);
      _collapse(preDismiss: false);
    }
    try {
      action.onPressed();
    } catch (_) {
      // Action errors must not break the toast lifecycle.
    }
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _drag.stop();
    _pauseTimer();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragDx += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (_dragDx.abs() >= _kSwipeThreshold || velocity.abs() > 800) {
      final direction = (_dragDx == 0 ? velocity : _dragDx).sign;
      _drag.value = _dragDx;
      _drag
          .animateTo(direction * _bodyW * 0.8,
              duration: Duration(milliseconds: _ms(180)),
              curve: Curves.easeIn)
          .whenComplete(_finish);
      // Track the fling on the card even though _dragging is false.
      _dragging = false;
    } else {
      _drag.value = _dragDx;
      _drag.animateWith(
          springSimulation(morphSpring(durationSeconds: 0.4, bounce: 0.2),
              from: _dragDx, to: 0));
      _resumeTimer();
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  SoleToastStyle get _style {
    final mode = data.modeOverride ?? config.mode;
    final brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    final type = _actionSuccess != null ? SoleToastType.success : data.type;
    return SoleToastStyle.resolve(type, mode,
        island: _isIsland, brightness: brightness);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final visible = _stage != SoleCardStage.measuring;

    final measurePass = _buildMeasurePass(style);
    if (!visible) {
      return Offstage(child: measurePass);
    }

    final card = AnimatedBuilder(
      animation: _dims,
      builder: (context, child) => SizedBox(
        width: _bodyW,
        height: math.max(_dims.currentH, _pillH),
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          if (style.hasBlur)
            ClipPath(
              clipper: SoleBlobClipper(_dims),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                    sigmaX: style.blurSigma, sigmaY: style.blurSigma),
                child: const SizedBox.expand(),
              ),
            ),
          CustomPaint(painter: SoleBlobPainter(dims: _dims, style: style)),
          ClipPath(
            clipper: _RevealClipper(_dims),
            child: _buildContent(style),
          ),
        ],
      ),
    );

    final withFx = AnimatedBuilder(
      animation: Listenable.merge([_inOut, _squish, _shake]),
      builder: (context, child) {
        final squishI =
            math.sin(_squish.value.clamp(-0.2, 1.4) * math.pi);
        final bScale = config.bounce / 0.4;
        final compressY =
            (_squishIsCollapse ? 0.035 : 0.12) * bScale * squishI;
        final expandX =
            (_squishIsCollapse ? 0.018 : 0.06) * bScale * squishI;
        final shakeV = _shake.isAnimating || _shake.value > 0
            ? math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 3
            : 0.0;
        final inV = Curves.easeOutCubic.transform(_inOut.value);
        final travel = _isIsland
            ? 0.0
            : (config.position == SoleToastPosition.topCenter ? -1.0 : 1.0) *
                (1 - inV) *
                (_pillH + 26);
        final dragOpacity = _dragDx == 0
            ? 1.0
            : (1 - _dragDx.abs() / (_kSwipeThreshold * 1.5))
                .clamp(0.0, 1.0);
        return Opacity(
          opacity: (_inOut.value * dragOpacity).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(_dragDx + shakeV, travel),
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.diagonal3Values(
                  1 + expandX, 1 - compressY, 1),
              child: child,
            ),
          ),
        );
      },
      child: card,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: data.description == null
          ? data.title
          : '${data.title}: ${data.description}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onLongPressStart: (_) => _pauseTimer(),
        onLongPressEnd: (_) => _resumeTimer(),
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Offstage(child: measurePass),
            withFx,
          ],
        ),
      ),
    );
  }

  // Offstage copies used purely for measurement.
  Widget _buildMeasurePass(SoleToastStyle style) {
    return Stack(
      children: [
        MeasureSize(
          onChange: _onHeaderMeasured,
          child: UnconstrainedBox(
            alignment: Alignment.topLeft,
            child: _headerRow(style, measuring: true),
          ),
        ),
        MeasureSize(
          onChange: _onContentMeasured,
          child: UnconstrainedBox(
            alignment: Alignment.topLeft,
            constrainedAxis: Axis.horizontal,
            child: SizedBox(
              width: _bodyW,
              child: _bodyColumn(style, measuring: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerRow(SoleToastStyle style, {bool measuring = false}) {
    final showTimestampInline = !_hasBody &&
        config.showTimestamp &&
        _actionSuccess == null &&
        !_isIsland;
    final iconVisible = !_isIsland ||
        measuring ||
        _stage.index >= SoleCardStage.islandIcon.index;
    final titleVisible = !_isIsland ||
        measuring ||
        _stage.index >= SoleCardStage.islandTitle.index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: iconVisible ? 1 : 0.4,
          duration: Duration(milliseconds: _ms(220)),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: iconVisible ? 1 : 0,
            duration: Duration(milliseconds: _ms(180)),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: _ms(200)),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: SoleToastIcon(
                key: ValueKey(_phase),
                phase: _phase,
                color: style.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        AnimatedOpacity(
          opacity: titleVisible ? 1 : 0,
          duration: Duration(milliseconds: _ms(240)),
          // Cap the title so an extreme string ellipsizes instead of pushing
          // the pill past the body width. Applied identically in the
          // measuring copy so measured and live layouts always agree.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(
                40,
                _bodyW -
                    2 * _pillPadH -
                    25 -
                    (_isIsland ? _islandW + 8 : 0) -
                    (showTimestampInline ? 70 : 0),
              ),
            ),
            child: Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        if (showTimestampInline) ...[
          const SizedBox(width: 8),
          Text(
            _fmtTime(data.createdAt),
            style: TextStyle(
              color: style.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }

  Widget _bodyColumn(SoleToastStyle style, {bool measuring = false}) {
    final description = _actionSuccess == null ? data.description : null;
    final action = _actionSuccess == null ? data.action : null;
    final bodyOn = measuring || _bodyVisible;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: _pillH),
        if (description != null || action != null || _showProgress)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (description != null)
                  AnimatedOpacity(
                    opacity: bodyOn ? 1 : 0,
                    duration: Duration(milliseconds: _ms(_kBodyFadeMs)),
                    curve: _kSmoothEase,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              color: style.ink,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        if (config.showTimestamp) ...[
                          const SizedBox(width: 10),
                          Text(
                            _fmtTime(data.createdAt),
                            style: TextStyle(
                              color: style.inkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (action != null) ...[
                  SizedBox(height: description != null ? 12 : 4),
                  AnimatedOpacity(
                    opacity: bodyOn ? 1 : 0,
                    duration: Duration(milliseconds: _ms(_kBodyFadeMs + 100)),
                    curve: const Interval(0.22, 1, curve: _kSmoothEase),
                    child: GestureDetector(
                      onTap: () => _onActionTap(action),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: style.actionBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          action.label,
                          style: TextStyle(
                            color: style.actionFg,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_showProgress) ...[
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: bodyOn ? 1 : 0,
                    duration: Duration(milliseconds: _ms(_kBodyFadeMs)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 3,
                        child: ColoredBox(
                          color: style.ink.withValues(alpha: 0.08),
                          child: AnimatedBuilder(
                            animation: _progress,
                            builder: (context, _) => FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: _progress.value,
                              child: ColoredBox(color: style.accent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent(SoleToastStyle style) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Body content laid out at its natural (full) height; the reveal
        // clipper crops it to the growing blob so nothing overflows.
        Positioned(top: 0, left: 0, right: 0, child: _bodyColumn(style)),
        // Header pinned to the pill lobe, horizontally tracking the pill.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _pillH,
          child: AnimatedBuilder(
            animation: Listenable.merge([_dims, _headerSquish]),
            builder: (context, child) {
              final pw = math.min(_dims.pillW, _dims.bodyW);
              double left;
              if (_isIsland) {
                left =
                    (_dims.pillLeft ?? 0) + _islandW + 8;
              } else {
                left = (_dims.bodyW - _headerContentW) / 2;
              }
              final squishV = _headerSquish.value.clamp(-0.3, 1.3);
              return Padding(
                padding: EdgeInsets.only(left: math.max(left, 0)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    child: SizedBox(
                      // +1.5 slack absorbs sub-pixel rounding; the blob path
                      // is the true visual boundary anyway.
                      width: math.max(
                            0,
                            _isIsland
                                ? pw - _islandW - 8 - _pillPadH / 2
                                : _headerContentW,
                          ) +
                          1.5,
                      height: _pillH,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.translationValues(0, squishV, 0)
                            ..multiply(Matrix4.diagonal3Values(
                                1 - 0.05 * squishV, 1 - 0.05 * squishV, 1)),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: _headerRow(style),
            ),
          ),
        ),
      ],
    );
  }

  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Clips content to the union of the pill lobe and the growing body so text
/// never paints outside the blob mid-morph.
class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper(this.dims) : super(reclip: dims);

  final SoleBlobDims dims;

  @override
  Path getClip(Size size) {
    if (!dims.ready) return Path()..addRect(Offset.zero & size);
    final path = Path();
    final pw = math.min(dims.pillW, dims.bodyW);
    final pillLeft = dims.pillLeft ?? (dims.bodyW - pw) / 2;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(pillLeft, 0, pw, dims.pillH),
      Radius.circular(dims.pillH / 2),
    ));
    final cw = dims.currentW;
    path.addRect(
        Rect.fromLTWH((dims.bodyW - cw) / 2, 0, cw, dims.currentH));
    return path;
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) => oldClipper.dims != dims;
}
