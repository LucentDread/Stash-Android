import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/system_bridge.dart';
import 'package:stash_android/widgets/remote_keys.dart';

/// Presses OK on the remote: a short press, or held (the remote repeats
/// the key) for a long press.
Future<void> _ok(WidgetTester tester, {bool hold = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
  if (hold) {
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
  await tester.pump();
}

void main() {
  testWidgets('remote: OK taps, held OK long presses', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => RemoteKeys(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              InkWell(
                autofocus: true,
                onTap: () => events.add('tap'),
                onLongPress: () => events.add('long'),
                onTapCancel: () => events.add('cancel'),
                child: const SizedBox(width: 100, height: 50),
              ),
              InkWell(
                onTap: () => events.add('tap2'),
                child: const SizedBox(width: 100, height: 50),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await _ok(tester);
    expect(events, ['tap']);
    events.clear();

    await _ok(tester, hold: true);
    expect(events, ['long', 'cancel'], reason: 'once, then released');
    events.clear();

    // An item without a long press activates as usual.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await _ok(tester);
    expect(events, ['tap2']);
  });

  group('on a TV', () {
    setUp(() => SystemBridge.instance.isTv = true);
    tearDown(() => SystemBridge.instance.isTv = false);

    Widget app(Widget home) => MaterialApp(
      builder: (_, child) => FocusRing(child: RemoteKeys(child: child!)),
      home: Scaffold(body: home),
    );

    /// The frame drawn around the focus, if any.
    Rect? ring(WidgetTester tester) {
      final f = find.descendant(
        of: find.byType(FocusRing),
        matching: find.byType(Positioned),
      );
      return f.evaluate().isEmpty ? null : tester.getRect(f.first);
    }

    testWidgets('a frame around the focused item, following it', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              for (final k in ['a', 'b'])
                InkWell(
                  key: ValueKey(k),
                  onTap: () {},
                  child: const SizedBox(width: 100, height: 50),
                ),
            ],
          ),
        ),
      );
      expect(ring(tester), isNull, reason: 'nothing focused');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();
      final a = tester.getRect(find.byKey(const ValueKey('a')));
      expect(ring(tester), a.inflate(4));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();
      final b = tester.getRect(find.byKey(const ValueKey('b')));
      expect(ring(tester), b.inflate(4));
      // Let the frame stop following.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('items that do nothing never take the focus', (tester) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              const ListTile(title: Text('info')), // no onTap
              const TextButton(onPressed: null, child: Text('off')),
              InkWell(
                key: const ValueKey('on'),
                onTap: () {},
                child: const SizedBox(width: 100, height: 50),
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<InkWell>()?.key,
        const ValueKey('on'),
      );
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Up/Down leave a text field', (tester) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('above')),
              const TextField(autofocus: true),
              const TextField(maxLines: 3),
              TextButton(onPressed: () {}, child: const Text('below')),
            ],
          ),
        ),
      );
      await tester.pump();
      String? focusedText() => FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<TextButton>()
          ?.child
          .toString();
      bool inField(int i) => tester
          .widget<EditableText>(find.byType(EditableText).at(i))
          .focusNode
          .hasPrimaryFocus;
      expect(inField(0), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedText(), contains('above'));

      // Back down, then into the multi-line field: Down moves between its
      // lines before leaving it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(inField(0), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(inField(1), isTrue);
      await tester.enterText(find.byType(EditableText).at(1), 'one\ntwo');
      final multi = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      multi.controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(inField(1), isTrue, reason: 'a line below');
      multi.controller.selection = const TextSelection.collapsed(offset: 7);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedText(), contains('below'));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Up/Down leave a slider, Left/Right change it', (tester) async {
      var value = 0.5;
      final focus = remoteSliderFocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextButton(onPressed: () {}, child: const Text('above')),
                Slider(
                  focusNode: focus,
                  autofocus: true,
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(focus.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, greaterThan(0.5));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  testWidgets('on a TV, the tabs are in a rail on the left', (tester) async {
    SystemBridge.instance.isTv = true;
    addTearDown(() => SystemBridge.instance.isTv = false);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://stash.test',
      'auto_update': false,
      'tabs': ['images', 'scenes'],
    });
    final app = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: app, child: const StashApp()),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(
      [for (final d in rail.destinations) (d.label as Text).data],
      ['Images', 'Scènes', 'Plus'],
    );

    // Choosing a tab in the rail opens it.
    await tester.tap(find.text('Plus'));
    await tester.pump();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
  });
}
