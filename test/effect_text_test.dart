import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:sole_toast/src/effect_text.dart';
import 'package:sole_toast/src/types.dart';

Widget _wrap(Widget child) => Directionality(
    textDirection: TextDirection.ltr, child: Center(child: child));

SoleEffectTextState _state(WidgetTester t) =>
    t.state<SoleEffectTextState>(find.byType(SoleEffectText));

void main() {
  group('SoleTextEffect.revealDuration', () {
    test('none is instant', () {
      expect(const SoleTextEffect.none().revealDuration(500), Duration.zero);
    });

    test('typewriter scales with length and honors the cap', () {
      const e = SoleTextEffect.typewriter(charsPerSecond: 40);
      expect(e.revealDuration(40), const Duration(seconds: 1));
      // 400 chars @40cps = 10s → capped.
      expect(e.revealDuration(400), const Duration(milliseconds: 2200));
    });

    test('fadeWords uses its fixed duration', () {
      const e = SoleTextEffect.fadeWords();
      expect(e.revealDuration(10), const Duration(milliseconds: 1400));
    });
  });

  testWidgets('typewriter reveals progressively and completes', (tester) async {
    const text = 'Hello sole toast typing'; // 23 chars @35cps ≈ 657ms
    await tester.pumpWidget(_wrap(const SoleEffectText(
      text: text,
      style: TextStyle(color: Color(0xFF222222), fontSize: 14),
      effect: SoleTextEffect.typewriter(),
      play: true,
      caretColor: Color(0xFF16A34A),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final mid = _state(tester).visibleChars;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(text.length));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_state(tester).visibleChars, text.length);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('does not start until play flips true', (tester) async {
    const text = 'Waiting for the body to open';
    Widget build(bool play) => _wrap(SoleEffectText(
          text: text,
          style: const TextStyle(color: Color(0xFF222222)),
          effect: const SoleTextEffect.typewriter(),
          play: play,
          caretColor: const Color(0xFF16A34A),
        ));
    await tester.pumpWidget(build(false));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_state(tester).visibleChars, 0);
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_state(tester).visibleChars, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('new text re-runs the reveal (promise/update path)',
      (tester) async {
    Widget build(String text) => _wrap(SoleEffectText(
          text: text,
          style: const TextStyle(color: Color(0xFF222222)),
          effect: const SoleTextEffect.typewriter(),
          play: true,
          caretColor: const Color(0xFF16A34A),
        ));
    await tester.pumpWidget(build('First message body'));
    await tester.pump(const Duration(seconds: 2));
    expect(_state(tester).visibleChars, 'First message body'.length);
    await tester.pumpWidget(build('A completely different message'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_state(tester).visibleChars,
        lessThan('A completely different message'.length));
    await tester.pump(const Duration(seconds: 2));
    expect(
        _state(tester).visibleChars, 'A completely different message'.length);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion shows text instantly', (tester) async {
    await tester.pumpWidget(_wrap(const SoleEffectText(
      text: 'Accessibility first',
      style: TextStyle(color: Color(0xFF222222)),
      effect: SoleTextEffect.typewriter(),
      play: true,
      reduced: true,
      caretColor: Color(0xFF16A34A),
    )));
    await tester.pump();
    expect(_state(tester).visibleChars, 'Accessibility first'.length);
    expect(find.text('Accessibility first'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fadeWords completes to fully opaque text', (tester) async {
    await tester.pumpWidget(_wrap(const SoleEffectText(
      text: 'Words wash in softly',
      style: TextStyle(color: Color(0xFF222222)),
      effect: SoleTextEffect.fadeWords(),
      play: true,
      caretColor: Color(0xFF16A34A),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
        _state(tester).visibleChars, lessThan('Words wash in softly'.length));
    await tester.pump(const Duration(seconds: 2));
    expect(_state(tester).visibleChars, 'Words wash in softly'.length);
    await tester.pumpWidget(const SizedBox());
  });
}
