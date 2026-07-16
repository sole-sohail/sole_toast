/// Sole Toast — a gooey, morphing toast for Flutter.
///
/// An organic pill → blob toast notification with light/dark/glossy modes,
/// semantic types (success / error / warning / info), physics-based springs,
/// and an iPhone Dynamic Island choreography. Zero runtime dependencies.
///
/// Setup:
/// ```dart
/// MaterialApp(builder: SoleToast.init());
/// ```
///
/// Usage:
/// ```dart
/// SoleToast.success('Saved', description: 'Your changes have been synced.');
/// ```
library;

export 'src/api.dart';
export 'src/blob_path.dart' show soleBlobPath;
export 'src/host.dart' show SoleToastLayer;
export 'src/icons.dart' show SoleToastIcon;
export 'src/island.dart' show SoleIslandSpec;
export 'src/theme.dart';
export 'src/types.dart';
