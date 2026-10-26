import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/screens/app_screens.dart';
import 'package:stash_android/screens/tabs_screen.dart';
import 'package:stash_android/services/app_state.dart';

Future<AppState> _pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs,
) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'server_url': 'http://stash.test',
    'auto_update': false,
    ...prefs,
  });
  final app = AppState(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: app, child: const StashApp()),
  );
  await tester.pump();
  return app;
}

List<String> _barLabels(WidgetTester tester) => [
  for (final d in tester.widgetList<NavigationDestination>(
    find.byType(NavigationDestination),
  ))
    d.label,
];

void main() {
  test('chosen tabs: unknown names dropped, at most four', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    expect(AppScreen.tabsOf(app), AppScreen.defaultTabs);
    app.tabNames = ['tags', 'old', 'images', 'scenes', 'home', 'studios'];
    expect(AppScreen.tabsOf(app), [
      AppScreen.tags,
      AppScreen.images,
      AppScreen.scenes,
      AppScreen.home,
    ]);
    app.tabNames = ['old'];
    expect(AppScreen.tabsOf(app), AppScreen.defaultTabs);
  });

  testWidgets('the bar shows the chosen tabs; Plus lists the others', (
    tester,
  ) async {
    await _pumpApp(tester, {
      'tabs': ['images', 'scenes'],
    });
    expect(_barLabels(tester), ['Images', 'Scènes', 'Plus']);

    await tester.tap(find.text('Plus').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (final s in ['Accueil', 'Groupes', 'Performeurs', 'Galeries', 'Tags']) {
      expect(find.widgetWithText(ListTile, s), findsOneWidget, reason: s);
    }
    expect(find.widgetWithText(ListTile, 'Images'), findsNothing);
    expect(find.text('Images, Scènes, Plus'), findsOneWidget);
  });

  testWidgets('tabs page: four at most, one at least, applied at once', (
    tester,
  ) async {
    final app = await _pumpApp(tester, {});
    await tester.tap(find.text('Plus').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Onglets'));
    await tester.pumpAndSettle();
    expect(find.byType(TabsScreen), findsOneWidget);
    expect(find.textContaining('4 / 4 onglets'), findsOneWidget);

    Checkbox box(String label) => tester.widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(ListTile, label),
        matching: find.byType(Checkbox),
      ),
    );
    expect(box('Tags').onChanged, isNull, reason: 'already four tabs');

    await tester.tap(find.byWidget(box('Groupes')));
    await tester.pump();
    await tester.tap(find.byWidget(box('Tags')));
    await tester.pump();
    expect(app.tabNames, ['home', 'scenes', 'performers', 'tags']);

    for (final s in ['Accueil', 'Scènes', 'Performeurs']) {
      await tester.tap(find.byWidget(box(s)));
      await tester.pump();
    }
    expect(app.tabNames, ['tags']);
    expect(box('Tags').onChanged, isNull, reason: 'the last tab stays');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(_barLabels(tester), ['Tags', 'Plus']);
  });
}
