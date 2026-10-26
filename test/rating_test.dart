import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:stash_android/services/app_state.dart';
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
    // Nothing left to clear: the button hides, keeping its room.
    final button = tester.widget<Visibility>(
      find.ancestor(
        of: find.byTooltip('Supprimer la note'),
        matching: find.byType(Visibility),
      ),
    );
    expect(button.visible, isFalse);
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
