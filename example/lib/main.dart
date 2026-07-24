import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sole_toast/sole_toast.dart';

import 'banner.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sole Toast',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
          colorSchemeSeed: const Color(0xFF3E6DF5),
          brightness: Brightness.light),
      darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF3E6DF5),
          brightness: Brightness.dark),
      builder: SoleToast.init(),
      home: DemoPage(
        onToggleTheme: () => setState(() => _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        onSetTheme: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage(
      {super.key, required this.onToggleTheme, required this.onSetTheme});

  final VoidCallback onToggleTheme;
  final ValueChanged<ThemeMode> onSetTheme;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  /// Screenshot showcase mode — used to regenerate the README media:
  /// `flutter build ios --simulator --dart-define=SOLE_SHOWCASE=variant`
  static const _defineShowcase = String.fromEnvironment('SOLE_SHOWCASE');

  String? get _showcase => _defineShowcase.isEmpty ? null : _defineShowcase;

  bool _bannerMode = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final showcase = _showcase;
      if (showcase != null) {
        _runShowcase(showcase);
      } else {
        SoleToast.success('Welcome',
            description: 'The gooey toast with a Dynamic Island trick.');
      }
    });
  }

  /// Fires a single, deterministic variant for README screenshots.
  void _runShowcase(String variant) {
    const long = Duration(seconds: 60);
    SoleToastConfig base(SoleToastMode mode,
            {SoleIslandMode island = SoleIslandMode.never,
            bool progress = false}) =>
        SoleToastConfig(mode: mode, islandMode: island, showProgress: progress);
    switch (variant) {
      case 'demo':
        break; // just the settings screen
      case 'glossy_success':
        SoleToast.config = base(SoleToastMode.glossy);
        SoleToast.success('Saved',
            description: 'Your changes have been synced.', duration: long);
      case 'glossy_error_action':
        SoleToast.config = base(SoleToastMode.glossy);
        SoleToast.error('Payment failed',
            description: 'Your card was declined. Please try again.',
            action: SoleToastAction(label: 'Retry', onPressed: () {}),
            duration: long);
      case 'light_info':
        widget.onSetTheme(ThemeMode.light);
        SoleToast.config = base(SoleToastMode.light);
        SoleToast.info('New version available',
            description: 'Sole Toast 0.2.0 is ready to install.',
            duration: long);
      case 'dark_warning':
        widget.onSetTheme(ThemeMode.light);
        SoleToast.config = base(SoleToastMode.dark);
        SoleToast.warning('Storage almost full',
            description: 'Free up space to keep syncing.', duration: long);
      case 'loading':
        SoleToast.config = base(SoleToastMode.glossy);
        SoleToast.promise<void>(Completer<void>().future,
            loading: 'Uploading 3 files…',
            success: (_) => 'Done',
            error: (_) => 'Failed');
      case 'progress':
        SoleToast.config = base(SoleToastMode.glossy, progress: true);
        SoleToast.success('Report ready',
            description: 'Q2 attendance report has been generated.',
            duration: const Duration(seconds: 20));
      case 'island':
        SoleToast.config =
            base(SoleToastMode.glossy, island: SoleIslandMode.auto);
        SoleToast.success('Saved',
            description: 'Your changes have been synced.', duration: long);
      case 'typewriter':
        SoleToast.config = base(SoleToastMode.glossy);
        SoleToast.success('Report ready',
            description:
                'Q2 attendance report has been generated and shared with '
                'your manager for review.',
            textEffect: const SoleTextEffect.typewriter(),
            duration: long);
      case 'banner':
        setState(() => _bannerMode = true);
    }
  }

  SoleToastMode _mode = SoleToastMode.glossy;
  SoleIslandMode _islandMode = SoleIslandMode.auto;
  double _bounce = 0.4;
  bool _withDescription = true;
  bool _showProgress = false;
  bool _fastTimings = false;
  bool _typewriter = false;

  void _applyConfig() {
    SoleToast.config = SoleToast.config.copyWith(
      mode: _mode,
      islandMode: _islandMode,
      bounce: _bounce,
      showProgress: _showProgress,
      timings: _fastTimings ? SoleToastTimings.fast : SoleToastTimings.normal,
      textEffect: _typewriter
          ? const SoleTextEffect.typewriter()
          : const SoleTextEffect.none(),
    );
  }

  String? get _desc => _withDescription
      ? 'This is the toast body. It melts out of the pill, then folds back up.'
      : null;

  @override
  Widget build(BuildContext context) {
    if (_bannerMode) return const BannerCanvas();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sole Toast'),
        actions: [
          IconButton(
              onPressed: widget.onToggleTheme,
              icon: const Icon(Icons.brightness_6_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Surface mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<SoleToastMode>(
            segments: const [
              ButtonSegment(value: SoleToastMode.light, label: Text('Light')),
              ButtonSegment(value: SoleToastMode.dark, label: Text('Dark')),
              ButtonSegment(value: SoleToastMode.glossy, label: Text('Glossy')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) {
              setState(() => _mode = s.first);
              _applyConfig();
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Island preview (force Dynamic Island)'),
            value: _islandMode == SoleIslandMode.always,
            onChanged: (v) {
              setState(() => _islandMode =
                  v ? SoleIslandMode.always : SoleIslandMode.auto);
              _applyConfig();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Description body'),
            value: _withDescription,
            onChanged: (v) => setState(() => _withDescription = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Typewriter description'),
            value: _typewriter,
            onChanged: (v) {
              setState(() => _typewriter = v);
              _applyConfig();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fast timings (instant feedback)'),
            value: _fastTimings,
            onChanged: (v) {
              setState(() => _fastTimings = v);
              _applyConfig();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Countdown progress bar'),
            value: _showProgress,
            onChanged: (v) {
              setState(() => _showProgress = v);
              _applyConfig();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Bounce  ${_bounce.toStringAsFixed(2)}'),
            subtitle: Slider(
              value: _bounce,
              min: 0.05,
              max: 0.8,
              onChanged: (v) => setState(() => _bounce = v),
              onChangeEnd: (_) => _applyConfig(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: () => SoleToast.success('Saved', description: _desc),
                child: const Text('Success'),
              ),
              FilledButton.tonal(
                onPressed: () => SoleToast.error('Payment failed',
                    description: _withDescription
                        ? 'Your card was declined. Please try again.'
                        : null),
                child: const Text('Error'),
              ),
              FilledButton.tonal(
                onPressed: () => SoleToast.warning('Storage almost full',
                    description: _desc),
                child: const Text('Warning'),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    SoleToast.info('New version available', description: _desc),
                child: const Text('Info'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => SoleToast.info(
                  'Share link ready',
                  description: 'Your link has been generated.',
                  action: SoleToastAction(
                    label: 'Copy to clipboard',
                    successLabel: 'Copied!',
                    onPressed: () {},
                  ),
                ),
                child: const Text('Action + success label'),
              ),
              OutlinedButton(
                onPressed: () {
                  SoleToast.promise<String>(
                    Future.delayed(const Duration(seconds: 3), () => 'v2.4.1'),
                    loading: 'Deploying…',
                    success: (v) => 'Deployed $v',
                    error: (e) => 'Deploy failed',
                    successDescription: (v) =>
                        'Build $v is live in production.',
                  );
                },
                child: const Text('Promise'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final id = SoleToast.info('Uploading…');
                  await Future<void>.delayed(const Duration(seconds: 2));
                  SoleToast.update(id,
                      title: 'Upload complete',
                      type: SoleToastType.success,
                      description: '3 files uploaded.');
                },
                child: const Text('Update in place'),
              ),
              OutlinedButton(
                onPressed: SoleToast.dismissAll,
                child: const Text('Dismiss all'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Tips: long-press a toast to pause its timer, tap a folding toast '
            'to re-open it, swipe sideways to dismiss.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
