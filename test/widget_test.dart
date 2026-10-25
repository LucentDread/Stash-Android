import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/main.dart';
import 'package:stash_android/services/app_state.dart';

void main() {
  testWidgets('shows the setup screen when no server is configured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(prefs),
        child: const StashApp(),
      ),
    );
    expect(find.text('Adresse du serveur'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Saisissez l\'adresse du serveur.'), findsOneWidget);
  });

  testWidgets('each bottom tab opens its own screen', (tester) async {
    SharedPreferences.setMockInitialValues({'server_url': 'http://stash.test'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(prefs),
        child: const StashApp(),
      ),
    );

    final bar = find.byType(NavigationBar);
    String appBarTitle() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AppBar).hitTestable(),
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;

    for (final label in ['Scènes', 'Groupes', 'Performeurs', 'Plus']) {
      await tester.tap(find.descendant(of: bar, matching: find.text(label)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(appBarTitle(), label);
    }
    expect(
      find.descendant(of: bar, matching: find.text('Galeries')),
      findsNothing,
    );
  });

  testWidgets('tab labels stay on one line on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'server_url': 'http://stash.test'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: ChangeNotifierProvider(
          create: (_) => AppState(prefs),
          child: const StashApp(),
        ),
      ),
    );
    await tester.pump();

    final label = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Performeurs'),
    );
    final paragraph = tester.renderObject<RenderParagraph>(label);
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue);
  });
}
