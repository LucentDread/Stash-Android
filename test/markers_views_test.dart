import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/screens/browse_screens.dart';
import 'package:stash_android/screens/scene_screen.dart';
import 'package:stash_android/screens/edit/edit_form.dart';
import 'package:stash_android/screens/edit/editors.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/widgets/cards.dart';
import 'package:stash_android/widgets/view_list.dart';

/// App state whose repository talks to a fake server recording requests.
Future<(AppState, List<Map<String, dynamic>>)> _app(String reply) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await SharedPreferences.getInstance());
  final sent = <Map<String, dynamic>>[];
  app.repoOverride = StashRepository(
    StashClient(
      serverUrl: 'http://stash.test',
      client: MockClient((req) async {
        sent.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(reply, 200);
      }),
    ),
  );
  return (app, sent);
}

void main() {
  test('time field parsing', () {
    expect(TimeEditField.parse('1:02:03'), 3723);
    expect(TimeEditField.parse('2:30'), 150);
    expect(TimeEditField.parse('45.5'), 45.5);
    expect(TimeEditField.parse(''), isNull);
    expect(TimeEditField.parse('a:10'), isNull);
    expect(TimeEditField.parse('1:2:3:4'), isNull);
    expect(TimeEditField('seconds', 'Début', 754).controller.text, '12:34');
  });

  test('image field sends only a new image', () {
    final f = ImageEditField('image', 'Photo', 'http://stash.test/p.jpg');
    expect(f.changed, isFalse);
    f.value = 'data:image/png;base64,AAAA';
    expect(f.toInput(), {'image': 'data:image/png;base64,AAAA'});
  });

  testWidgets('creating a marker sends every field with the scene id', (
    tester,
  ) async {
    final (app, sent) = await _app('{"data":{"sceneMarkerCreate":{"id":"1"}}}');
    late BuildContext ctx;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final result = createMarker(ctx, '42', at: 75);
    await tester.pumpAndSettle();
    expect(find.text('1:15'), findsOneWidget);

    // The primary tag is required.
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pump();
    expect(find.text('Tag principal est obligatoire'), findsOneWidget);
    expect(sent, isEmpty);

    // Fill the primary tag directly in the form's field.
    final screen = tester.widget<EditScreen>(find.byType(EditScreen));
    (screen.fields.whereType<RefEditField>().single).value = TagRef(
      id: '5',
      name: 'Intro',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(sent.single['variables']['input'], {
      'scene_id': '42',
      'title': '',
      'seconds': 75.0,
      'end_seconds': null,
      'primary_tag_id': '5',
      'tag_ids': <String>[],
    });
  });

  testWidgets('scene cards show the rating as five stars', (tester) async {
    final (app, _) = await _app('{}');
    final scene = Scene.fromJson({
      'id': '1',
      'title': 'Note',
      'rating100': 70,
      'paths': <String, dynamic>{},
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: SizedBox(
                width: 200,
                height: SceneCard.heightFor(context, 200),
                child: SceneCard(scene: scene),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    // Unrated: no empty stars.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: SizedBox(
                width: 200,
                height: SceneCard.heightFor(context, 200),
                child: SceneCard(
                  scene: Scene.fromJson({
                    'id': '2',
                    'title': 'Sans note',
                    'paths': <String, dynamic>{},
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_border), findsNothing);
  });

  testWidgets('a saved view cannot change its filter while browsing', (
    tester,
  ) async {
    final (app, _) = await _app(
      '{"data":{"findScenes":{"count":0,"scenes":[]}}}',
    );
    Widget wrap(Widget child) => ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(home: Scaffold(body: child)),
    );

    await tester.pumpWidget(wrap(const ScenesBrowser()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_list), findsOneWidget);

    final view = SavedView(
      id: 'v',
      name: 'Hors groupe',
      filter: SceneFilter(groups: EntityCriterion(mode: EntityMode.none)),
    );
    await tester.pumpWidget(wrap(ViewBrowser(view: view)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_list), findsNothing);
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
    expect(find.text('Sans groupe'), findsNothing);
  });

  testWidgets('scene page shows the studio logo, only when it has one', (
    tester,
  ) async {
    Future<void> open(String imagePath) async {
      await tester.pumpWidget(const SizedBox()); // fresh page state
      final (app, _) = await _app(
        jsonEncode({
          'data': {
            'findScene': {
              'id': '1',
              'title': 'Plage',
              'paths': <String, dynamic>{},
              'studio': {'id': '2', 'name': 'Studio', 'image_path': imagePath},
            },
          },
        }),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: const MaterialApp(home: SceneScreen(sceneId: '1')),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    await open('http://stash.test/studio/2/image');
    expect(find.byType(StudioWatermark), findsOneWidget);
    await open('http://stash.test/studio/2/image?default=true');
    expect(find.byType(StudioWatermark), findsNothing);
  });

  testWidgets('the end of the scene page clears the system navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    // Android's gesture/button bar, drawn over the app (edge to edge).
    tester.view.padding = const FakeViewPadding(bottom: 96);
    addTearDown(tester.view.reset);
    final (app, _) = await _app(
      jsonEncode({
        'data': {
          'findScene': {
            'id': '1',
            'title': 'Plage',
            'paths': <String, dynamic>{},
            'details': 'Une longue description.\n' * 30,
            'urls': ['https://example.com/scene'],
          },
        },
      }),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: SceneScreen(sceneId: '1')),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final link = find.text('https://example.com/scene');
    expect(link, findsOneWidget);
    // 800 logical pixels tall, the bar covering the last 48.
    expect(tester.getBottomLeft(link).dy, lessThanOrEqualTo(800 - 48));
  });

  testWidgets('the scene title fades from the page into the app bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, _) = await _app(
      jsonEncode({
        'data': {
          'findScene': {
            'id': '1',
            'title': 'Plage',
            'paths': <String, dynamic>{},
            'details': 'Une longue description.\n' * 40,
          },
        },
      }),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: SceneScreen(sceneId: '1')),
      ),
    );
    await tester.pump();
    await tester.pump();

    double opacity(Finder within) => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.descendant(of: within, matching: find.text('Plage')),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    final bar = find.byType(AppBar);
    final page = find.byType(SliverList);
    expect(opacity(bar), 0);
    expect(opacity(page), 1);

    // Small steps until the page title has slid under the bar.
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final seen = <double>[];
    for (var i = 0; i < 200 && opacity(bar) < 1; i++) {
      position.jumpTo(position.pixels + 3);
      await tester.pump();
      seen.add(opacity(bar));
      expect(opacity(bar) + opacity(page), closeTo(1, 1e-9));
    }
    expect(seen.where((o) => o > 0 && o < 1).length, greaterThan(3));
    expect(opacity(bar), 1);

    // Far down, then back to the top.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(opacity(bar), 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 6000));
    await tester.pumpAndSettle();
    expect(opacity(bar), 0);
  });
}
