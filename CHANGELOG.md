# Changelog

## 0.3.0

- **Text effects** — `SoleTextEffect.typewriter()` reveals the description
  like live typing (soft per-character fade head, blinking accent caret,
  `charsPerSecond` + `maxDuration` controls) and `SoleTextEffect.fadeWords()`
  washes words in sequentially. Configurable globally
  (`SoleToastConfig.textEffect`) or per toast (`textEffect:`). The display
  timer is extended by the reveal duration; reduced motion shows text
  instantly. Full text is laid out from the first frame — no reflow, RTL
  safe. `SoleEffectText` is exported for standalone use.

## 0.2.0

- **Configurable timings** — new `SoleToastTimings` with per-phase durations,
  a `fast` preset (readable content in ~350–400 ms for action feedback), a
  `scaled()` factory for uniform pace control, and a
  `SoleToastConfig.timings` field.
- **Dynamic Island redesign** — the icon now melts out in a gooey chin
  *beneath* the cutout instead of a side lobe, so it can never collide with
  the status-bar clock, signal, or battery indicators. The sheet then
  continues downward through the title and description.
- `SoleToastIcon` gained crossfade reuse inside the island chin.

## 0.1.1

- README images now use absolute URLs so they render on pub.dev.
- Much smaller package archive: documentation media and the example's
  generated platform folders are excluded from publishing.

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
