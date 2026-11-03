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

  testWidgets('remote: the focused card is framed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusCard(
            child: InkWell(
              onTap: () {},
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      ),
    );
    BorderSide side() =>
        ((tester.widget<Card>(find.byType(Card)).shape
                as RoundedRectangleBorder?)
            ?.side) ??
        BorderSide.none;
    expect(side(), BorderSide.none);

    // A key press switches to the keyboard / remote highlight.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(side().width, 3);
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
    expect(
      MediaQuery.of(tester.element(find.byType(NavigationRail))).navigationMode,
      NavigationMode.directional,
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
