import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/screens/group_screen.dart';
import 'package:stash_android/screens/image_viewer_screen.dart';
import 'package:stash_android/screens/performer_screen.dart';
import 'package:stash_android/screens/scene_screen.dart';
import 'package:stash_android/screens/studio_screen.dart';
import 'package:stash_android/screens/edit/editors.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/services/system_bridge.dart';
import 'package:stash_android/widgets/download_button.dart';
import 'package:stash_android/widgets/tv_focus.dart';
import 'package:stash_android/widgets/detail_widgets.dart';

/// Server whose items are rated 3 stars; updates fail when [failUpdates].
Future<(AppState, List<Map<String, dynamic>>)> _app({
  bool failUpdates = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final app = AppState(await SharedPreferences.getInstance());
  final sent = <Map<String, dynamic>>[];
  app.repoOverride = StashRepository(
    StashClient(
      serverUrl: 'http://stash.test',
      client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        sent.add(body);
        final q = body['query'] as String;
        if (q.contains('Update(')) {
          if (failUpdates) {
            return http.Response(
              jsonEncode({
                'errors': [
                  {'message': 'refused'},
                ],
              }),
              200,
            );
          }
          final m = RegExp(r'(\w+Update)\(').firstMatch(q)![1]!;
          return http.Response(
            jsonEncode({
              'data': {
                m: {'id': '1'},
              },
            }),
            200,
          );
        }
        final item = {'id': '1', 'name': 'X', 'title': 'X', 'rating100': 60};
        final Object data = switch (q) {
          _ when q.contains('findScene(') => {
            'findScene': {...item, 'paths': <String, dynamic>{}},
          },
          _ when q.contains('findPerformer(') => {'findPerformer': item},
          _ when q.contains('findStudio(') => {'findStudio': item},
          _ when q.contains('findGroup(') => {'findGroup': item},
          _ => <String, dynamic>{},
        };
        return http.Response(jsonEncode({'data': data}), 200);
      }),
    ),
  );
  return (app, sent);
}

void _dump(List<Map<String, dynamic>> sent, String name) {
  final dir = Platform.environment['STASH_QUERIES'];
  if (dir != null) File('$dir/$name.json').writeAsStringSync(jsonEncode(sent));
}

Future<void> _show(WidgetTester tester, AppState app, Widget page) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _lastUpdate(List<Map<String, dynamic>> sent) =>
    (sent.lastWhere((s) => '${s['query']}'.contains('Update('))['variables']
            as Map)['input']
        as Map<String, dynamic>;

int _fullStars(WidgetTester tester) =>
    tester.widgetList(find.byIcon(Icons.star)).length;

void main() {
  testWidgets('a landscape tablet gets the wide scene page, touch-ready', (
    tester,
  ) async {
    final (app, _) = await _app();
    Future<void> show(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: const MaterialApp(home: SceneScreen(sceneId: '1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.reset);
    await show(const Size(1280, 800));
    expect(find.byType(SliverAppBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget, reason: 'no remote');
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    expect(find.byType(DownloadButton), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<FilledButton>(),
      isNull,
      reason: 'no focus to show on a touch screen',
    );

    // Portrait: the phone page.
    await show(const Size(800, 1280));
    expect(find.byType(SliverAppBar), findsOneWidget);
  });

  testWidgets('on a TV, the scene page is laid out for the remote', (
    tester,
  ) async {
    SystemBridge.instance.isTv = true;
    addTearDown(() => SystemBridge.instance.isTv = false);
    final (app, _) = await _app();
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: tvTheme(ThemeData.dark()),
          home: const SceneScreen(sceneId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No app bar: the title and buttons are on the left, over the picture.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(SliverAppBar), findsNothing);
    final title = tester.getRect(find.text('X').first);
    expect(title.left, lessThan(1920 / 2));

    // Play has the focus at once; Right goes on to download and edit.
    Element focused() =>
        FocusManager.instance.primaryFocus!.context! as Element;
    expect(focused().findAncestorWidgetOfExactType<FilledButton>(), isNotNull);
    final reached = <Type>{};
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      if (focused().findAncestorWidgetOfExactType<DownloadButton>() != null) {
        reached.add(DownloadButton);
      }
      if (focused().findAncestorWidgetOfExactType<EditButton>() != null) {
        reached.add(EditButton);
      }
    }
    expect(reached, {DownloadButton, EditButton});
  });

  testWidgets('the scene rating can be cleared with its button', (
    tester,
  ) async {
    final (app, sent) = await _app();
    await _show(tester, app, const SceneScreen(sceneId: '1'));
    expect(_fullStars(tester), 3);
    await tester.tap(find.byTooltip('Supprimer la note'));
    await tester.pumpAndSettle();
    expect(_lastUpdate(sent), {'id': '1', 'rating100': null});
    expect(_fullStars(tester), 0);
    // Unrated: a "Not rated" button instead of empty stars.
    expect(find.text('Non noté'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    // It shows the stars to pick from; ✕ goes back without saving.
    await tester.tap(find.text('Non noté'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    final count = sent.length;
    await tester.tap(find.byTooltip('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Non noté'), findsOneWidget);
    expect(sent, hasLength(count));

    await tester.tap(find.text('Non noté'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).at(3)); // 4 stars
    await tester.pumpAndSettle();
    expect(_lastUpdate(sent), {'id': '1', 'rating100': 80});
    expect(_fullStars(tester), 4);
    _dump(sent, 'rate_scene');
  });

  for (final (page, mutation) in [
    (const PerformerScreen(performerId: '1'), 'performerUpdate'),
    (const StudioScreen(studioId: '1'), 'studioUpdate'),
    (const GroupScreen(groupId: '1'), 'groupUpdate'),
  ]) {
    testWidgets('${page.runtimeType}: the rating is shown and editable', (
      tester,
    ) async {
      final (app, sent) = await _app();
      await _show(tester, app, page);
      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();
      expect(find.byType(LiveRating), findsOneWidget);
      expect(_fullStars(tester), 3);

      await tester.tap(find.byIcon(Icons.star_border).last); // 5th star
      await tester.pumpAndSettle();
      expect(_fullStars(tester), 5);
      expect('${sent.last['query']}', contains(mutation));
      expect(_lastUpdate(sent), {'id': '1', 'rating100': 100});

      await tester.tap(find.byTooltip('Supprimer la note'));
      await tester.pumpAndSettle();
      expect(_lastUpdate(sent), {'id': '1', 'rating100': null});
      _dump(sent, 'rate_${page.runtimeType}');
    });
  }

  testWidgets('a refused rating comes back to the previous one', (
    tester,
  ) async {
    final (app, _) = await _app(failUpdates: true);
    await _show(tester, app, const PerformerScreen(performerId: '1'));
    await tester.tap(find.text('Infos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Supprimer la note'));
    await tester.pumpAndSettle();
    expect(_fullStars(tester), 3);
    expect(find.textContaining('refused'), findsOneWidget);
  });

  testWidgets('images are rated in the viewer, not offline copies', (
    tester,
  ) async {
    final (app, sent) = await _app();
    final images = [StashImage(id: '1', rating100: 40), StashImage(id: '2')];
    await _show(
      tester,
      app,
      ImageViewerScreen(images: images, initialIndex: 0),
    );
    expect(_fullStars(tester), 2);
    // A bar at the bottom only: the top buttons stay reachable.
    expect(find.byTooltip('Télécharger').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LiveRating)).dy,
      greaterThan(tester.view.physicalSize.height / 2 / 2),
    );
    await tester.tap(find.byIcon(Icons.star_border).first); // 3rd star
    await tester.pumpAndSettle();
    expect('${sent.last['query']}', contains('imageUpdate'));
    expect(_lastUpdate(sent), {'id': '1', 'rating100': 60});
    _dump(sent, 'rate_image');

    // Swiping away and back keeps the new rating.
    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    pages.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(_fullStars(tester), 0);
    pages.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(_fullStars(tester), 3);

    await _show(
      tester,
      app,
      ImageViewerScreen(images: images, initialIndex: 0, downloadable: false),
    );
    expect(find.byType(LiveRating), findsNothing);
  });
}
