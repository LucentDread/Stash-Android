import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/screens/home_layout_screen.dart';
import 'package:stash_android/screens/home_screen.dart';
import 'package:stash_android/services/app_state.dart';

/// App state whose server answers every list, counting the requests by
/// kind ("resume" for the scenes to resume).
Future<(AppState, Map<String, int>)> _app() async {
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await SharedPreferences.getInstance());
  final counts = <String, int>{};
  Map<String, dynamic> scenes(int n) => {
    'count': n,
    'scenes': [
      for (var i = 0; i < n; i++)
        {'id': '$i', 'title': 'Plage $i', 'paths': <String, dynamic>{}},
    ],
  };
  app.repoOverride = StashRepository(
    StashClient(
      serverUrl: 'http://stash.test',
      client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        final vars = body['variables'] as Map<String, dynamic>?;
        final String kind;
        final Object data;
        if (query.contains('stats')) {
          kind = 'stats';
          data = {
            'stats': {
              'scene_count': 1,
              'scenes_size': 1,
              'scenes_duration': 1,
              'image_count': 1,
              'gallery_count': 1,
              'performer_count': 1,
              'studio_count': 1,
              'tag_count': 1,
            },
          };
        } else if (query.contains('findScenes')) {
          final resume =
              (vars?['scene_filter'] as Map?)?.containsKey('resume_time') ??
              false;
          kind = resume ? 'resume' : 'scenes';
          // Nothing to resume: that row hides once loaded.
          data = {'findScenes': scenes(resume ? 0 : 6)};
        } else if (query.contains('findPerformers')) {
          kind = 'performers';
          data = {
            'findPerformers': {'count': 0, 'performers': []},
          };
        } else if (query.contains('findGalleries')) {
          kind = 'galleries';
          data = {
            'findGalleries': {'count': 0, 'galleries': []},
          };
        } else {
          kind = 'other';
          data = {};
        }
        counts[kind] = (counts[kind] ?? 0) + 1;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'data': data})),
          200,
        );
      }),
    ),
  );
  return (app, counts);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('default home: back to the top after scrolling to the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, counts) = await _app();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await _settle(tester);
    expect(counts['resume'], 1);

    final scrollable = find.byType(Scrollable).first;
    ScrollPosition position() =>
        tester.state<ScrollableState>(scrollable).position;
    for (var i = 0; i < 10; i++) {
      await tester.drag(scrollable, const Offset(0, -600));
      await _settle(tester);
    }
    expect(position().pixels, position().maxScrollExtent);

    // Up by the distance left (more would pull to refresh), in steps.
    for (var i = 0; i < 20 && position().pixels > 0; i++) {
      final step = position().pixels.clamp(0, 300).toDouble();
      await tester.drag(scrollable, Offset(0, step + 20));
      await _settle(tester);
    }
    expect(position().pixels, 0, reason: 'nothing pushes the page down');
    // Rows scrolled away were kept, not loaded again.
    expect(counts['resume'], 1);
    expect(counts['stats'], 1);
  });

  testWidgets('custom home stacks dashboard sections with views', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, counts) = await _app();
    app.saveView(SavedView(id: 'v', name: 'Ma vue', filter: SceneFilter()));
    app.homeLayout = ['section:stats', 'v', 'section:recent'];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: HomeTab()),
      ),
    );
    await _settle(tester);
    expect(find.text('Accueil'), findsOneWidget, reason: 'not one view');
    expect(find.textContaining('Ma vue'), findsOneWidget);
    expect(find.text('Ajoutées récemment'), findsOneWidget);
    expect(find.text('Sorties récentes'), findsNothing);
    expect(counts['stats'], 1);
    expect(counts['scenes'], 2);

    // A single view still fills the page and names it.
    app.homeLayout = ['v'];
    await _settle(tester);
    expect(find.text('Ma vue'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
  });

  testWidgets('default home shows the chosen rows, in order', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, _) = await _app();
    app.saveView(SavedView(id: 'v', name: 'Ma vue', filter: SceneFilter()));
    app.saveView(SavedView(id: 'w', name: 'Autre vue', filter: SceneFilter()));
    app.dashboardLayout = ['section:random', 'w'];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await _settle(tester);
    expect(find.text('Au hasard'), findsOneWidget);
    expect(find.text('Autre vue'), findsOneWidget);
    expect(find.text('Ma vue'), findsNothing);
    expect(find.text('Ajoutées récemment'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Au hasard')).dy,
      lessThan(tester.getTopLeft(find.text('Autre vue')).dy),
    );
  });

  testWidgets('layout screen: checked items, in order, make each page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, _) = await _app();
    app.saveView(SavedView(id: 'v', name: 'Ma vue', filter: SceneFilter()));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: HomeLayoutScreen()),
      ),
    );
    Future<void> check(String label) async {
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, label),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pump();
    }

    await check('Ma vue');
    await check('Reprendre la lecture');
    expect(app.homeLayout, ['v', 'section:resume']);

    await tester.tap(find.text('Accueil par défaut'));
    await tester.pumpAndSettle();
    await check('Statistiques');
    expect(app.dashboardLayout.first, 'section:resume');
    expect(app.dashboardLayout, isNot(contains('section:stats')));
    await tester.tap(find.text('Lignes par défaut'));
    await tester.pump();
    expect(app.dashboardLayout.first, 'section:stats');
  });
}
