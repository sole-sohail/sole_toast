# Changelog

## 0.1.0

Initial release.

- Organic pill → blob morph animation (gooey expand, fold-up collapse).
- Semantic types: `success`, `error`, `warning`, `info` — accent, icon, and
  content colors derive from the type.
- Three visual modes: `light`, `dark`, and `glossy` (frosted blur + sheen).
- iPhone Dynamic Island choreography: the icon docks beside the island, then
  a sheet slides down beneath it revealing the title and content —
  auto-detected, with manual override.
- Physics-based springs with a single `bounce` dial and animation presets.
- Promise toasts (`loading → success/error`), in-place `update()`,
  `dismiss()` by id / type / all.
- Stacking with FIFO queue, swipe-to-dismiss, tap-to-re-expand,
  long-press-to-pause, optional countdown progress bar.
- Reduced-motion support, semantic announcements, optional haptics.
- Zero runtime dependencies. No assets, no icon fonts — everything painted.
