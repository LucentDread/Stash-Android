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
import 'package:stash_android/screens/browse_screens.dart';
import 'package:stash_android/screens/gallery_screen.dart';
import 'package:stash_android/screens/group_screen.dart';
import 'package:stash_android/screens/performer_screen.dart';
import 'package:stash_android/screens/scene_filter_screen.dart';
import 'package:stash_android/screens/studio_screen.dart';
import 'package:stash_android/screens/tag_screen.dart';
import 'package:stash_android/services/app_state.dart';

/// App state whose server creates items with id 7 and records requests.
Future<(AppState, List<Map<String, dynamic>>)> _app({
  Map<String, dynamic>? gallery,
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
        final Object data = switch (q) {
          _ when q.contains('Create(') => {
            RegExp(r'(\w+Create)\(').firstMatch(q)![1]!: {'id': '7'},
          },
          _ when q.contains('Destroy(') => {
            RegExp(r'(\w+Destroy)\(').firstMatch(q)![1]!: true,
          },
          _ when q.contains('findPerformers') => {
            'findPerformers': {'count': 0, 'performers': []},
          },
          _ when q.contains('findStudios') => {
            'findStudios': {'count': 0, 'studios': []},
          },
          _ when q.contains('findTags') => {
            'findTags': {'count': 0, 'tags': []},
          },
          _ when q.contains('findPerformer') => {
            'findPerformer': {'id': '7', 'name': 'Alice'},
          },
          _ when q.contains('findStudio') => {
            'findStudio': {'id': '7', 'name': 'Prod'},
          },
          _ when q.contains('findTag') => {
            'findTag': {'id': '7', 'name': 'Plage'},
          },
          _ when q.contains('findGallery') && gallery != null => {
            'findGallery': gallery,
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

  for (final (screen, title, page) in [
    (const PerformersScreen(), 'Nouveau performeur', PerformerScreen),
    (const StudiosScreen(), 'Nouveau studio', StudioScreen),
    (const TagsScreen(), 'Nouveau tag', TagScreen),
  ]) {
    testWidgets('$title from its list', (tester) async {
      final (app, sent) = await _app();
      await _create(tester, app, screen);
      expect(find.text(title), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Nom *'), 'X');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      final create = sent.singleWhere(
        (s) => '${s['query']}'.contains('Create('),
      );
      expect(((create['variables'] as Map)['input'] as Map)['name'], 'X');
      expect(find.byType(page), findsOneWidget);
      _dump(sent, 'create_$page');
    });
  }

  for (final (page, label) in [
    (const PerformerScreen(performerId: '7'), 'Supprimer le performeur'),
    (const StudioScreen(studioId: '7'), 'Supprimer le studio'),
    (const TagScreen(tagId: '7'), 'Supprimer le tag'),
    (const GroupScreen(groupId: '7'), 'Supprimer le groupe'),
    (const GalleryScreen(galleryId: '7'), 'Supprimer la galerie'),
  ]) {
    testWidgets('${page.runtimeType}: deleting closes the page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final (app, sent) = await _app();
      final version = app.dataVersion;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => page)),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      expect(find.text('$label ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(
        sent.where((s) => '${s['query']}'.contains('Destroy(')),
        hasLength(1),
      );
      expect(find.text('ouvrir'), findsOneWidget, reason: 'page closed');
      expect(app.dataVersion, greaterThan(version));
      _dump(sent, 'destroy_${page.runtimeType}');
    });
  }

  testWidgets('a gallery made of a folder cannot be deleted', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (app, _) = await _app(
      gallery: {
        'id': '7',
        'title': 'Album',
        'folder': {'path': '/photos/album'},
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GalleryScreen(galleryId: '7')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la galerie'), findsOneWidget);
    expect(find.byTooltip('Supprimer la galerie'), findsNothing);
  });

  testWidgets('a missing tag is created from the picker and selected', (
    tester,
  ) async {
    final (app, sent) = await _app();
    List<TagRef>? picked;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  picked = await Navigator.of(context).push<List<TagRef>>(
                    MaterialPageRoute(
                      builder: (_) => const RefPickerScreen(
                        title: 'Tags',
                        kind: RefKind.tags,
                        initial: [],
                        canCreate: true,
                      ),
                    ),
                  ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Créer'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Neige');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer « Neige »'));
    await tester.pumpAndSettle();
    final create = sent.singleWhere((s) => '${s['query']}'.contains('Create('));
    expect('${create['query']}', contains('tagCreate'));
    expect((create['variables'] as Map)['input'], {'name': 'Neige'});
    _dump(sent, 'picker_create');

    await tester.tap(find.text('Valider (1)'));
    await tester.pumpAndSettle();
    expect(picked!.single.id, '7');
    expect(picked!.single.name, 'Neige');
  });

  testWidgets('filters only pick existing items', (tester) async {
    final (app, _) = await _app();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: RefPickerScreen(title: 'Tags', kind: RefKind.tags, initial: []),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Neige');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('Créer'), findsNothing);
  });
}
