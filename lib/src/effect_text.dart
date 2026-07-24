import 'package:flutter/widgets.dart';

import 'types.dart';

/// Renders the description with an optional reveal effect.
///
/// Smoothness strategy: the **full text is laid out from the first frame**
/// and only per-glyph opacity animates. Nothing reflows, line wraps never
/// shift, and BiDi/RTL text behaves exactly like the settled state. The
/// reveal is driven by a single [AnimationController]; each character (or
/// word) fades over a soft window as the head passes it, which reads as
/// fluid motion instead of discrete pops.
class SoleEffectText extends StatefulWidget {
  const SoleEffectText({
    super.key,
    required this.text,
    required this.style,
    required this.effect,
    required this.play,
    required this.caretColor,
    this.reduced = false,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final SoleTextEffect effect;

  /// The reveal starts when this first becomes true (typically when the
  /// body begins melting out). Until then the text is fully transparent —
  /// but already laid out, so the blob geometry never changes.
  final bool play;

  /// Caret accent color (typewriter only).
  final Color caretColor;

  /// When true (reduced motion), text appears instantly.
  final bool reduced;

  final TextAlign textAlign;

  @override
  State<SoleEffectText> createState() => SoleEffectTextState();
}

class SoleEffectTextState extends State<SoleEffectText>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState — a lazy `late` controller would be first
  // instantiated inside dispose() (vsync lookup on a deactivated element).
  late final AnimationController _reveal;

  bool get _active =>
      widget.effect.kind != SoleTextEffectKind.none && !widget.reduced;

  Duration get _duration {
    final d = widget.effect.revealDuration(widget.text.length);
    return d.inMilliseconds < 1 ? const Duration(milliseconds: 1) : d;
  }

  /// Number of fully revealed characters — exposed for tests.
  int get visibleChars {
    if (!_active) return widget.text.length;
    return (_reveal.value * widget.text.length)
        .floor()
        .clamp(0, widget.text.length);
  }

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _duration);
    if (widget.play) _start();
  }

  @override
  void didUpdateWidget(SoleEffectText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text ||
        widget.effect.kind != oldWidget.effect.kind) {
      // New content (e.g. promise settled or update()) → re-run the reveal.
      _reveal.duration = _duration;
      if (widget.play && _active) {
        _reveal.forward(from: 0);
      } else {
        _reveal.value = 1;
      }
    } else if (widget.play && !oldWidget.play) {
      _start();
    }
  }

  void _start() {
    if (!_active) {
      _reveal.value = 1;
      return;
    }
    _reveal.duration = _duration;
    _reveal.forward(from: 0);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return Text(widget.text,
          style: widget.style, textAlign: widget.textAlign);
    }
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final t = widget.play ? _reveal.value : 0.0;
        switch (widget.effect.kind) {
          case SoleTextEffectKind.typewriter:
            return _typewriter(t);
          case SoleTextEffectKind.fadeWords:
            return _fadeWords(t);
          case SoleTextEffectKind.none:
            return Text(widget.text,
                style: widget.style, textAlign: widget.textAlign);
        }
      },
    );
  }

  /// Per-character opacity behind a soft head (~1.6 characters wide), plus
  /// a caret that rides the head while typing and blinks out at the end.
  Widget _typewriter(double t) {
    final text = widget.text;
    final n = text.length;
    final head = t * n;
    const soft = 1.6;
    final base = widget.style.color ?? const Color(0xFFFFFFFF);
    final spans = <TextSpan>[];

    var i = 0;
    while (i < n) {
      // Group consecutive characters with the same (quantized) opacity into
      // one span so the span count stays tiny once typing has passed.
      final o0 = _charOpacity(i, head, soft);
      var j = i + 1;
      while (j < n && _charOpacity(j, head, soft) == o0) {
        j++;
      }
      if (o0 > 0) {
        spans.add(TextSpan(
          text: text.substring(i, j),
          style: TextStyle(color: base.withValues(alpha: base.a * o0)),
        ));
      } else {
        // Invisible tail keeps layout identical to the settled state.
        spans.add(TextSpan(
          text: text.substring(i, j),
          style: TextStyle(color: base.withValues(alpha: 0)),
        ));
      }
      i = j;
    }

    // A thin accent caret rides the typing head; it vanishes on the final
    // character so the settled text is exactly the plain string.
    if (widget.effect.showCaret && t < 1.0) {
      final at = head.floor().clamp(0, n);
      spans.insert(
        _spanIndexForChar(spans, at),
        TextSpan(
          text: '▏',
          style: TextStyle(
            color: widget.caretColor.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(style: widget.style, children: spans),
        textAlign: widget.textAlign);
  }

  static double _charOpacity(int index, double head, double soft) {
    final v = ((head - index) / soft).clamp(0.0, 1.0);
    // Quantize to 1/12 steps: imperceptible visually, but lets neighbouring
    // characters merge into a single span.
    return (v * 12).round() / 12;
  }

  /// Finds the span-list insertion index corresponding to character [at].
  static int _spanIndexForChar(List<TextSpan> spans, int at) {
    var count = 0;
    for (var s = 0; s < spans.length; s++) {
      count += spans[s].text!.length;
      if (count >= at) return s + 1;
    }
    return spans.length;
  }

  /// Words wash in sequentially, each fading over an overlapping window.
  Widget _fadeWords(double t) {
    final base = widget.style.color ?? const Color(0xFFFFFFFF);
    // Split keeping separators attached so layout matches the plain string.
    final words = <String>[];
    final re = RegExp(r'\S+\s*');
    for (final m in re.allMatches(widget.text)) {
      words.add(m.group(0)!);
    }
    if (words.isEmpty) {
      return Text(widget.text,
          style: widget.style, textAlign: widget.textAlign);
    }
    final n = words.length;
    // Each word fades over a window of 2 word-slots; head sweeps n+2 slots.
    final head = t * (n + 2);
    final spans = <TextSpan>[
      for (var i = 0; i < n; i++)
        TextSpan(
          text: words[i],
          style: TextStyle(
            color: base.withValues(
                alpha: base.a * ((head - i) / 2).clamp(0.0, 1.0)),
          ),
        ),
    ];
    return Text.rich(TextSpan(style: widget.style, children: spans),
        textAlign: widget.textAlign);
  }
}
