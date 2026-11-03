import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/system_bridge.dart';
import 'package:stash_android/widgets/remote_keys.dart';
import 'package:stash_android/widgets/tv_focus.dart';

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
      theme: tvTheme(ThemeData.dark()),
      builder: (_, child) => RemoteKeys(child: child!),
      home: Scaffold(body: home),
    );

    testWidgets('buttons are outlined in their own shape when focused', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              FilledButton(onPressed: () {}, child: const Text('play')),
              IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
            ],
          ),
        ),
      );
      BorderSide side(Type button) {
        final m = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(button),
                matching: find.byType(Material),
              )
              .first,
        );
        return (m.shape! as OutlinedBorder).side;
      }

      expect(side(FilledButton), BorderSide.none);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(side(FilledButton).width, 3);
      expect(side(FilledButton).color, Colors.white);
      // The filled button keeps its stadium shape, the icon button its
      // circle: the outline follows them.
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(FilledButton),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .shape,
        isA<StadiumBorder>(),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(side(FilledButton), BorderSide.none);
      expect(side(IconButton).width, 3);
    });

    testWidgets('pictures are framed when focused', (tester) async {
      await tester.pumpWidget(
        app(
          FocusFrame(
            child: Card(
              child: InkWell(
                onTap: () {},
                child: const SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        ),
      );
      Decoration frame() => tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(FocusFrame),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration;
      expect((frame() as BoxDecoration).border, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect((frame() as BoxDecoration).border, isNotNull);
    });

    testWidgets('Left at the start of a field reaches what is on its left', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('rail')),
              const Expanded(child: TextField(autofocus: true)),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ab');
      final field = tester.widget<EditableText>(find.byType(EditableText));
      field.controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();
      // Inside the text, Left moves the cursor.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(field.focusNode.hasPrimaryFocus, isTrue);
      expect(field.controller.selection.baseOffset, 0);
      // At its start, it leaves.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(field.focusNode.hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<TextButton>(),
        isNotNull,
      );
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
