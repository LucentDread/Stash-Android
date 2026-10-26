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
import 'package:stash_android/screens/browse_screens.dart';
import 'package:stash_android/screens/gallery_screen.dart';
import 'package:stash_android/screens/group_screen.dart';
import 'package:stash_android/services/app_state.dart';

/// App state whose server creates items with id 7 and records requests.
Future<(AppState, List<Map<String, dynamic>>)> _app() async {
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
        final Object data = switch (q) {
          _ when q.contains('groupCreate') => {
            'groupCreate': {'id': '7'},
          },
          _ when q.contains('galleryCreate') => {
            'galleryCreate': {'id': '7'},
          },
          _ when q.contains('findGroups') => {
            'findGroups': {'count': 0, 'groups': []},
          },
          _ when q.contains('findGalleries') => {
            'findGalleries': {'count': 0, 'galleries': []},
          },
          _ when q.contains('findGroup') => {
            'findGroup': {'id': '7', 'name': 'Vacances'},
          },
          _ when q.contains('findGallery') => {
            'findGallery': {'id': '7', 'title': 'Album'},
          },
          _ when q.contains('findScenes') => {
            'findScenes': {'count': 0, 'scenes': []},
          },
          _ when q.contains('findImages') => {
            'findImages': {'count': 0, 'images': []},
          },
          _ => <String, dynamic>{},
        };
        return http.Response(jsonEncode({'data': data}), 200);
      }),
    ),
  );
  return (app, sent);
}

/// Saves the requests for schema validation when STASH_QUERIES is set.
void _dump(List<Map<String, dynamic>> sent, String name) {
  final dir = Platform.environment['STASH_QUERIES'];
  if (dir != null) File('$dir/$name.json').writeAsStringSync(jsonEncode(sent));
}

Future<void> _create(WidgetTester tester, AppState app, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new group is created from the Groups screen, then opened', (
    tester,
  ) async {
    final (app, sent) = await _app();
    await _create(tester, app, const GroupsScreen());
    expect(find.text('Nouveau groupe'), findsOneWidget);

    // The name is required.
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Nom est obligatoire'), findsOneWidget);
    expect(sent.where((s) => '${s['query']}'.contains('groupCreate')), isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Nom *'), 'Vacances');
    await tester.enterText(
      find.widgetWithText(TextField, 'Réalisateur'),
      'Ann',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final create = sent.singleWhere(
      (s) => '${s['query']}'.contains('groupCreate'),
    );
    final input = (create['variables'] as Map)['input'] as Map;
    expect(input['name'], 'Vacances');
    expect(input['director'], 'Ann');
    expect(input.containsKey('id'), isFalse);
    expect(find.byType(GroupScreen), findsOneWidget);
    _dump(sent, 'create_group');
  });

  testWidgets('a new gallery is created from the Galleries screen', (
    tester,
  ) async {
    final (app, sent) = await _app();
    await _create(tester, app, const GalleriesScreen());
    expect(find.text('Nouvelle galerie'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Titre est obligatoire'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Titre *'), 'Album');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final create = sent.singleWhere(
      (s) => '${s['query']}'.contains('galleryCreate'),
    );
    final input = (create['variables'] as Map)['input'] as Map;
    expect(input['title'], 'Album');
    expect(input['organized'], false);
    expect(find.byType(GalleryScreen), findsOneWidget);
    _dump(sent, 'create_gallery');
  });
}
