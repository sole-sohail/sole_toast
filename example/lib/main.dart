import 'package:flutter/material.dart';
import 'package:sole_toast/sole_toast.dart';

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
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        SoleToast.success('Welcome',
            description: 'The gooey toast with a Dynamic Island trick.');
      }
    });
  }

  SoleToastMode _mode = SoleToastMode.glossy;
  SoleIslandMode _islandMode = SoleIslandMode.auto;
  double _bounce = 0.4;
  bool _withDescription = true;
  bool _showProgress = false;

  void _applyConfig() {
    SoleToast.config = SoleToast.config.copyWith(
      mode: _mode,
      islandMode: _islandMode,
      bounce: _bounce,
      showProgress: _showProgress,
    );
  }

  String? get _desc => _withDescription
      ? 'This is the toast body. It melts out of the pill, then folds back up.'
      : null;

  @override
  Widget build(BuildContext context) {
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
