import 'package:flutter/widgets.dart';

import 'types.dart';

/// Resolved visual tokens for a single toast — computed once per
/// (type, mode, island, brightness) combination.
@immutable
class SoleToastStyle {
  const SoleToastStyle({
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.actionBg,
    required this.actionFg,
    required this.border,
    required this.blurSigma,
    required this.shadows,
    this.sheen,
  });

  /// Blob fill color. Translucent in glossy mode.
  final Color surface;

  /// Primary content color (description text).
  final Color ink;

  /// Secondary content color (timestamps).
  final Color inkMuted;

  /// Type accent — title, icon, progress bar.
  final Color accent;

  /// Action button background.
  final Color actionBg;

  /// Action button foreground.
  final Color actionFg;

  /// Hairline border color ([Color(0x00000000)] disables the border).
  final Color border;

  /// Backdrop blur sigma; `0` disables the blur pass entirely.
  final double blurSigma;

  /// Soft drop shadows painted under the blob.
  final List<BoxShadow> shadows;

  /// Optional specular highlight painted over the fill (glossy mode).
  final Gradient? sheen;

  bool get hasBlur => blurSigma > 0;
  bool get hasBorder => border.a > 0;

  // Accent palettes — high-saturation so types read sharply.
  // Light surfaces get deep vivid tones; dark surfaces get luminous ones.
  static const _accentLight = <SoleToastType, Color>{
    SoleToastType.success: Color(0xFF16A34A),
    SoleToastType.error: Color(0xFFDC2626),
    SoleToastType.warning: Color(0xFFD97706),
    SoleToastType.info: Color(0xFF2563EB),
  };
  static const _accentDark = <SoleToastType, Color>{
    SoleToastType.success: Color(0xFF4ADE80),
    SoleToastType.error: Color(0xFFF87171),
    SoleToastType.warning: Color(0xFFFBBF24),
    SoleToastType.info: Color(0xFF60A5FA),
  };

  static const _shadowsLight = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 12),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 4),
  ];
  static const _shadowsDark = <BoxShadow>[
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4), blurRadius: 12),
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 4),
  ];

  /// Resolves the style for a toast.
  ///
  /// [island] forces the pure-black Dynamic-Island look regardless of [mode].
  /// [brightness] only affects [SoleToastMode.glossy], whose tint and ink
  /// follow the surrounding app theme ("a combination of light and dark").
  static SoleToastStyle resolve(
    SoleToastType type,
    SoleToastMode mode, {
    bool island = false,
    Brightness brightness = Brightness.light,
  }) {
    if (island) {
      final accent = _accentDark[type]!;
      return SoleToastStyle(
        surface: const Color(0xFF000000),
        ink: const Color(0xFFF5F5F7),
        inkMuted: const Color(0xFF98989E),
        accent: accent,
        actionBg: accent.withValues(alpha: 0.22),
        actionFg: accent,
        border: const Color(0x1FFFFFFF),
        blurSigma: 0,
        shadows: _shadowsDark,
      );
    }

    switch (mode) {
      case SoleToastMode.light:
        final accent = _accentLight[type]!;
        return SoleToastStyle(
          surface: const Color(0xFFFFFFFF),
          ink: const Color(0xFF444444),
          inkMuted: const Color(0xFF999999),
          accent: accent,
          actionBg: accent.withValues(alpha: 0.13),
          actionFg: accent,
          border: const Color(0x00000000),
          blurSigma: 0,
          shadows: _shadowsLight,
        );
      case SoleToastMode.dark:
        final accent = _accentDark[type]!;
        return SoleToastStyle(
          surface: const Color(0xFF1A1A1A),
          ink: const Color(0xFFE0E0E0),
          inkMuted: const Color(0xFF8A8A8A),
          accent: accent,
          actionBg: accent.withValues(alpha: 0.22),
          actionFg: accent,
          border: const Color(0x00000000),
          blurSigma: 0,
          shadows: _shadowsDark,
        );
      case SoleToastMode.glossy:
        final dark = brightness == Brightness.dark;
        final accent = dark ? _accentDark[type]! : _accentLight[type]!;
        return SoleToastStyle(
          surface: dark
              ? const Color(0xFF16181D).withValues(alpha: 0.58)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.55),
          ink: dark ? const Color(0xFFF2F5F9) : const Color(0xFF2A3240),
          inkMuted: dark ? const Color(0xFF9AA6B8) : const Color(0xFF7B8494),
          accent: accent,
          actionBg: accent.withValues(alpha: dark ? 0.24 : 0.16),
          actionFg: accent,
          border: dark ? const Color(0x2EFFFFFF) : const Color(0x99FFFFFF),
          blurSigma: 18,
          shadows: dark ? _shadowsDark : _shadowsLight,
          sheen: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    Color(0x2EFFFFFF),
                    Color(0x0AFFFFFF),
                    Color(0x05FFFFFF)
                  ]
                : const [
                    Color(0xA6FFFFFF),
                    Color(0x26FFFFFF),
                    Color(0x14FFFFFF)
                  ],
            stops: const [0.0, 0.55, 1.0],
          ),
        );
    }
  }
}
