# Sole Toast

A gooey, morphing toast for Flutter. A compact pill lands on screen, the body
**melts** out of it with an organic blob morph, and after a few seconds it
folds itself back up and slips away — with physics-based springs, a landing
squish, and an iPhone **Dynamic Island** choreography.

**Zero runtime dependencies.** No assets, no icon fonts — every shape and
icon is painted.

## Highlights

- **Organic pill → blob morph** driven by a parametric path regenerated every
  frame, so text never reflows mid-animation.
- **Semantic types** — `success`, `error`, `warning`, `info` — accent color,
  stroke-drawn icon, and action tint all derive from the type.
- **Three surface modes** — `light`, `dark`, and `glossy` (frosted backdrop
  blur + specular sheen that adapts to the app's brightness).
- **Dynamic Island choreography** — on island iPhones the toast docks to the
  hardware cutout: the icon appears beside the island, the title expands,
  then the content slides down beneath. Auto-detected; can be forced or
  disabled.
- **Promise toasts** — spinner → success/error morph, in-place `update()`,
  action buttons with a success-label morph-back.
- **One bounce dial** — a single `bounce` value (0.05–0.8) tunes every
  spring, plus `smooth / bouncy / subtle / snappy` presets.
- Stacking with a FIFO queue, swipe-to-dismiss, tap-to-re-open while a toast
  folds up, long-press-to-pause, optional countdown progress bar and
  timestamps, reduced-motion support, screen-reader announcements, optional
  haptics.

## Setup

```dart
import 'package:sole_toast/sole_toast.dart';

MaterialApp(
  builder: SoleToast.init(),   // mounts the toast layer once
  home: ...,
);
```

Already using `builder`? Chain it: `SoleToast.init(builder: yourBuilder)`.

## Usage

```dart
SoleToast.success('Saved', description: 'Your changes have been synced.');

SoleToast.error('Payment failed',
    description: 'Your card was declined. Please try again.');

SoleToast.info('Share link ready',
    description: 'Your link has been generated.',
    action: SoleToastAction(
      label: 'Copy to clipboard',
      successLabel: 'Copied!',
      onPressed: copyLink,
    ));

// Loading → success/error:
await SoleToast.promise<Report>(
  fetchReport(),
  loading: 'Generating report…',
  success: (r) => 'Report ready',
  error: (e) => 'Generation failed',
);

// Update a live toast in place:
final id = SoleToast.info('Uploading…');
SoleToast.update(id, title: 'Upload complete', type: SoleToastType.success);

// Dismissal (plays the fold-up, never just vanishes):
SoleToast.dismiss(id);
SoleToast.dismissByType(SoleToastType.error);
SoleToast.dismissAll();
```

## Configuration

```dart
SoleToast.config = const SoleToastConfig(
  mode: SoleToastMode.glossy,          // light | dark | glossy
  position: SoleToastPosition.topCenter,
  islandMode: SoleIslandMode.auto,     // auto | always | never
  bounce: 0.4,                         // 0.05 subtle … 0.8 jelly
  displayDuration: Duration(seconds: 4),
  maxVisible: 3,
  showProgress: false,
  showTimestamp: false,
  enableHaptics: true,
);

// Or start from a preset:
SoleToast.config = SoleToastConfig.preset(SoleToastPreset.bouncy);
```

Per-toast overrides: `duration`, `mode`, `showProgress`, `id`, `onDismiss`.

## Dynamic Island

On iPhones with a Dynamic Island (auto-detected in portrait), toasts dock to
the cutout instead of dropping from the top: a black capsule hugs the island,
grows a lobe with the type icon, widens to reveal the title, then the body
morphs down beneath it — and folds back into the island on dismiss. New
toasts shown while one is docked morph the capsule in place rather than
stacking.

- Preview anywhere (simulator, Android): `islandMode: SoleIslandMode.always`.
- Opt out entirely: `SoleIslandMode.never`.

## Interactions & accessibility

Swipe a toast sideways to dismiss it. Tap a toast while it is folding up to
re-open it. Long-press to hold it on screen; release to resume. When the
platform requests reduced motion, springs and squishes are replaced with
near-instant transitions. Every toast is announced to screen readers
(assertively for errors and warnings).

## Modes

| Mode | Surface | Best for |
| --- | --- | --- |
| `light` | solid white, soft shadow | light apps, faithful goey-toast look |
| `dark` | solid near-black | dark apps |
| `glossy` | backdrop blur + translucent tint + sheen + hairline border, follows app brightness | apps that want the frosted-glass look over any content |

(The Dynamic Island always renders pure black to blend with the hardware.)

## Credits

The morph geometry and animation feel are a Flutter port of
[goey-toast](https://github.com/anl331/goey-toast) (React), rebuilt on
Flutter primitives — `CustomPainter`, `SpringSimulation`, and a manual
overlay — with a mobile-first interaction model.

## License

[MIT](LICENSE)
