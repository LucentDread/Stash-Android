import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/api/saved_filter.dart';
import 'package:stash_android/api/stash_client.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/screens/home_screen.dart';
import 'package:stash_android/screens/views_screen.dart';
import 'package:stash_android/services/app_state.dart';
import 'package:stash_android/widgets/cards.dart';

Map<String, dynamic> _named(String kind, String name) => {
  'kind': kind,
  'name': name,
  'ofType': null,
};
Map<String, dynamic> _nonNull(Map<String, dynamic> t) => {
  'kind': 'NON_NULL',
  'name': null,
  'ofType': t,
};
Map<String, dynamic> _list(Map<String, dynamic> t) => {
  'kind': 'LIST',
  'name': null,
  'ofType': t,
};

Map<String, dynamic> _input(String name, Map<String, Map<String, dynamic>> f) =>
    {
      'name': name,
      'kind': 'INPUT_OBJECT',
      'inputFields': [
        for (final MapEntry(:key, :value) in f.entries)
          {'name': key, 'type': value},
      ],
      'enumValues': null,
    };

Map<String, dynamic> _enum(String name, List<String> values) => {
  'name': name,
  'kind': 'ENUM',
  'inputFields': null,
  'enumValues': [
    for (final v in values) {'name': v},
  ],
};

final _modifier = _nonNull(_named('ENUM', 'CriterionModifier'));
final _id = _named('SCALAR', 'ID');

/// A small slice of Stash's schema, as introspection returns it.
final _schema = FilterSchema.fromIntrospection({
  '__schema': {
    'types': [
      _input('SceneFilterType', {
        'tags': _named('INPUT_OBJECT', 'HierarchicalMultiCriterionInput'),
        'performers': _named('INPUT_OBJECT', 'MultiCriterionInput'),
        'rating100': _named('INPUT_OBJECT', 'IntCriterionInput'),
        'resolution': _named('INPUT_OBJECT', 'ResolutionCriterionInput'),
        'organized': _named('SCALAR', 'Boolean'),
        'has_markers': _named('SCALAR', 'String'),
        'created_at': _named('INPUT_OBJECT', 'TimestampCriterionInput'),
        'orientation': _named('INPUT_OBJECT', 'OrientationCriterionInput'),
        'duplicated': _named('INPUT_OBJECT', 'DuplicationCriterionInput'),
        'stash_id_endpoint': _named('INPUT_OBJECT', 'StashIDCriterionInput'),
      }),
      _input('PerformerFilterType', {
        'gender': _named('INPUT_OBJECT', 'GenderCriterionInput'),
        'filter_favorites': _named('SCALAR', 'Boolean'),
      }),
      _input('HierarchicalMultiCriterionInput', {
        'value': _list(_nonNull(_id)),
        'modifier': _modifier,
        'depth': _named('SCALAR', 'Int'),
        'excludes': _list(_nonNull(_id)),
      }),
      _input('MultiCriterionInput', {
        'value': _list(_nonNull(_id)),
        'modifier': _modifier,
        'excludes': _list(_nonNull(_id)),
      }),
      _input('IntCriterionInput', {
        'value': _nonNull(_named('SCALAR', 'Int')),
        'value2': _named('SCALAR', 'Int'),
        'modifier': _modifier,
      }),
      _input('TimestampCriterionInput', {
        'value': _nonNull(_named('SCALAR', 'String')),
        'value2': _named('SCALAR', 'String'),
        'modifier': _modifier,
      }),
      _input('ResolutionCriterionInput', {
        'value': _nonNull(_named('ENUM', 'ResolutionEnum')),
        'modifier': _modifier,
      }),
      _input('OrientationCriterionInput', {
        'value': _nonNull(_list(_nonNull(_named('ENUM', 'OrientationEnum')))),
      }),
      _input('GenderCriterionInput', {
        'value': _named('ENUM', 'GenderEnum'),
        'value_list': _list(_nonNull(_named('ENUM', 'GenderEnum'))),
        'modifier': _modifier,
      }),
      _input('DuplicationCriterionInput', {
        'distance': _named('SCALAR', 'Int'),
        'phash': _named('SCALAR', 'Boolean'),
      }),
      _input('StashIDCriterionInput', {
        'endpoint': _named('SCALAR', 'String'),
        'stash_id': _named('SCALAR', 'String'),
        'modifier': _modifier,
      }),
      _enum('ResolutionEnum', ['STANDARD', 'FULL_HD', 'FOUR_K']),
      _enum('OrientationEnum', ['LANDSCAPE', 'PORTRAIT', 'SQUARE']),
      _enum('GenderEnum', ['MALE', 'FEMALE', 'TRANSGENDER_FEMALE']),
    ],
  },
});

void main() {
  group('web UI saved filters', () {
    test('criteria are converted to the API format', () {
      final skipped = <String>[];
      final f = _schema.convert('SceneFilterType', {
        'tags': {
          'value': {
            'items': [
              {'id': '1', 'label': 'Plage'},
            ],
            'excluded': [
              {'id': '2', 'label': 'Nuit'},
            ],
            'depth': -1,
          },
          'modifier': 'INCLUDES',
        },
        'performers': {
          'value': {
            'items': [
              {'id': '3', 'label': 'Alice'},
            ],
            'excluded': [],
          },
          'modifier': 'INCLUDES_ALL',
        },
        // Old format: a plain number.
        'rating100': {'value': 60, 'modifier': 'GREATER_THAN'},
        'resolution': {'value': '4k', 'modifier': 'EQUALS'},
        'organized': {'value': 'false', 'modifier': 'EQUALS'},
        'has_markers': {'value': 'true', 'modifier': 'EQUALS'},
        'created_at': {
          'value': {'value': '2024-01-01 10:00'},
          'modifier': 'GREATER_THAN',
        },
        'orientation': {
          'value': ['Landscape', 'Square'],
          'modifier': 'EQUALS',
        },
        'duplicated': {'value': 'true', 'modifier': 'EQUALS'},
        'stash_id_endpoint': {
          'value': {'endpoint': 'https://stashdb.org/graphql', 'stashID': ''},
          'modifier': 'NOT_NULL',
        },
        'folder': {'value': 'x', 'modifier': 'EQUALS'},
      }, skipped: skipped);

      expect(f, {
        'tags': {
          'modifier': 'INCLUDES',
          'value': ['1'],
          'excludes': ['2'],
          'depth': -1,
        },
        'performers': {
          'modifier': 'INCLUDES_ALL',
          'value': ['3'],
          'excludes': <String>[],
        },
        'rating100': {'modifier': 'GREATER_THAN', 'value': 60},
        'resolution': {'modifier': 'EQUALS', 'value': 'FOUR_K'},
        'organized': false,
        'has_markers': 'true',
        'created_at': {'modifier': 'GREATER_THAN', 'value': '2024-01-01T10:00'},
        'orientation': {
          'value': ['LANDSCAPE', 'SQUARE'],
        },
        'duplicated': {'phash': true},
        'stash_id_endpoint': {
          'modifier': 'NOT_NULL',
          'endpoint': 'https://stashdb.org/graphql',
          'stash_id': '',
        },
      });
      expect(skipped, ['folder'], reason: 'not a SceneFilterType field');
    });

    test('labels become enum values; "equals" has no sub-levels', () {
      expect(
        _schema.convert('PerformerFilterType', {
          'gender': {
            'value': ['Female', 'Transgender Female'],
            'modifier': 'INCLUDES',
          },
          'filter_favorites': {'value': 'true', 'modifier': 'EQUALS'},
        }),
        {
          'gender': {
            'modifier': 'INCLUDES',
            'value_list': ['FEMALE', 'TRANSGENDER_FEMALE'],
          },
          'filter_favorites': true,
        },
      );
      expect(
        _schema.convert('SceneFilterType', {
          'tags': {
            'value': {
              'items': [
                {'id': '1'},
              ],
              'depth': -1,
            },
            'modifier': 'EQUALS',
          },
        })['tags']['depth'],
        0,
      );
    });

    test('saved filters become views of the matching kind', () {
      final v = SavedView.fromServer({
        'id': 7,
        'mode': 'MOVIES',
        'name': 'Mes groupes',
        'find_filter': {'q': 'abc', 'sort': 'random_1234', 'direction': 'ASC'},
        'object_filter': {
          'rating100': {'value': 80, 'modifier': 'GREATER_THAN'},
        },
      })!;
      expect(v.id, 'web:7');
      expect(v.remote, isTrue);
      expect(v.kind, ViewKind.groups);
      expect(v.sort, 'random');
      expect(v.descending, isFalse);
      expect(v.query, 'abc');
      expect(SavedView.fromJson(v.toJson()).serverFilter, v.serverFilter);
      expect(
        SavedView.fromServer({'id': 1, 'mode': 'IMAGES'})!.kind,
        ViewKind.images,
      );
      expect(SavedView.fromServer({'id': 1, 'mode': 'FOO'}), isNull);
    });
  });

  test('app filters only send what the kind supports', () {
    final f = SceneFilter(
      tags: EntityCriterion(
        items: [TagRef(id: '1', name: 'a')],
      ),
      minStars: 4,
      minResolution: 'FULL_HD',
      favorite: true,
      played: true,
    );
    expect(f.toGraphQL(ViewKind.performers), {
      'tags': {
        'modifier': 'INCLUDES',
        'value': ['1'],
        'depth': 0,
      },
      'rating100': {'value': 79, 'modifier': 'GREATER_THAN'},
      'play_count': {'value': 0, 'modifier': 'GREATER_THAN'},
      'filter_favorites': true,
    });
    expect(f.toGraphQL(ViewKind.tags), {'favorite': true});
    expect(f.toGraphQL().containsKey('favorite'), isFalse);
    expect(f.describe(ViewKind.studios), ['Tags : a', '≥ 4 ★', 'Favoris']);
  });

  group('with a server', () {
    late List<Map<String, dynamic>> sent;

    Future<AppState> app({bool oldServer = false}) async {
      SharedPreferences.setMockInitialValues({});
      final app = AppState(await SharedPreferences.getInstance());
      sent = [];
      app.repoOverride = StashRepository(
        StashClient(
          serverUrl: 'http://stash.test',
          client: MockClient((req) async {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            sent.add(body);
            final query = body['query'] as String;
            Object? data;
            if (query.contains('findSavedFilters')) {
              data = {
                'findSavedFilters': [
                  {
                    'id': '3',
                    'mode': 'PERFORMERS',
                    'name': 'Favorites du web',
                    'find_filter': {'sort': 'name', 'direction': 'ASC'},
                    'object_filter': {
                      'filter_favorites': {
                        'value': 'true',
                        'modifier': 'EQUALS',
                      },
                    },
                  },
                  {
                    'id': '4',
                    'mode': 'IMAGES',
                    'name': 'Photos organisées',
                    'object_filter': {
                      'organized': {'value': 'true', 'modifier': 'EQUALS'},
                      'folder': {'value': 'x', 'modifier': 'INCLUDES'},
                    },
                  },
                  {'id': '5', 'mode': 'FOO', 'name': 'Inconnu'},
                ],
              };
            } else if (query.contains('__schema')) {
              data = {
                '__schema': {
                  'types': [
                    _input('PerformerFilterType', {
                      'filter_favorites': _named('SCALAR', 'Boolean'),
                    }),
                    _input('ImageFilterType', {
                      'organized': _named('SCALAR', 'Boolean'),
                    }),
                  ],
                },
              };
            } else if (query.contains('findPerformers')) {
              data = {
                'findPerformers': {
                  'count': 1,
                  'performers': [
                    {'id': '1', 'name': 'Alice'},
                  ],
                },
              };
            } else if (query.contains('findImages')) {
              data = {
                'findImages': {
                  'count': 1,
                  'images': [
                    {'id': '8', 'title': 'Photo', 'paths': <String, dynamic>{}},
                  ],
                },
              };
            } else if (query.contains('findScenes')) {
              data = {
                'findScenes': {
                  'count': 1,
                  'scenes': [
                    {'id': '1', 'title': 'Scène', 'paths': <String, dynamic>{}},
                  ],
                },
              };
            } else if (query.contains('sceneResetActivity') && oldServer) {
              return http.Response.bytes(
                utf8.encode(
                  '{"errors":[{"message":"Cannot query field '
                  '\\"sceneResetActivity\\""}]}',
                ),
                422,
              );
            } else {
              data = {'ok': true};
            }
            return http.Response.bytes(
              utf8.encode(jsonEncode({'data': data})),
              200,
            );
          }),
        ),
      );
      return app;
    }

    test('web filters join the views, in one order', () async {
      final a = await app();
      a.saveView(SavedView(id: 'l', name: 'Locale', filter: SceneFilter()));
      expect(await a.refreshWebViews(), 1, reason: 'unknown kind left out');
      expect([for (final v in a.allViews) v.id], ['l', 'web:3', 'web:4']);

      a.reorderViews(1, 0);
      a.setHomeView('l', true);
      a.setHomeView('web:3', true);
      expect(
        [for (final v in a.homeViews) v.name],
        ['Favorites du web', 'Locale'],
      );

      final page = await a.repo!.findForView(
        a.allViews.first,
        const ListQuery(),
      );
      expect((page.items.single as Performer).name, 'Alice');
      expect(sent.last['variables']['pf'], {'filter_favorites': true});
    });

    test('image views list images; unreadable criteria are reported', () async {
      final a = await app();
      await a.refreshWebViews();
      final photos = a.viewById('web:4')!;
      expect(photos.kind, ViewKind.images);
      final page = await a.repo!.findForView(photos, const ListQuery());
      expect((page.items.single as StashImage).id, '8');
      expect(sent.last['variables']['imf'], {'organized': true});
      expect(await a.repo!.skippedCriteria(photos), ['folder']);
      expect(await a.repo!.skippedCriteria(a.viewById('web:3')!), isEmpty);
    });

    testWidgets('saved views page warns about ignored criteria', (
      tester,
    ) async {
      final a = await app();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: a,
          child: const MaterialApp(home: ViewsScreen()),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(find.textContaining('Un filtre web utilise'), findsOneWidget);
      expect(find.textContaining('Ignoré : dossier'), findsOneWidget);
      expect(find.text('Photos organisées'), findsOneWidget);
      expect(find.text('Favorites du web'), findsOneWidget);
    });

    test('resume point reset, also on servers before 0.27', () async {
      final a = await app();
      await a.repo!.resetResume('9');
      expect(sent.single['query'], contains('reset_resume: true'));

      final old = await app(oldServer: true);
      await old.repo!.resetResume('9');
      expect(sent.length, 2);
      expect(sent.last['query'], contains('sceneSaveActivity'));
      expect(sent.last['variables'], {
        'id': '9',
        'resume': 0,
        'duration': null,
      });
    });

    testWidgets('home stacks views of different kinds', (tester) async {
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final a = await app();
      a.saveView(SavedView(id: 's', name: 'Scènes', filter: SceneFilter()));
      a.saveView(
        SavedView(
          id: 'p',
          name: 'Acteurs',
          kind: ViewKind.performers,
          filter: SceneFilter(),
        ),
      );
      a.setHomeView('s', true);
      a.setHomeView('p', true);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: a,
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(find.byType(SceneCard), findsOneWidget);
      expect(find.byType(PerformerCard), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('each stacked view of the home page sorts on its own', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final a = await app();
      a.saveView(SavedView(id: 's', name: 'Scènes', filter: SceneFilter()));
      a.saveView(
        SavedView(
          id: 'p',
          name: 'Acteurs',
          kind: ViewKind.performers,
          filter: SceneFilter(),
          sort: 'name',
          descending: false,
        ),
      );
      a.setHomeView('s', true);
      a.setHomeView('p', true);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: a,
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      List<Map<String, dynamic>> finds(String query) => [
        for (final r in sent)
          if ((r['query'] as String).contains(query))
            r['variables']['filter'] as Map<String, dynamic>,
      ];
      expect(find.byTooltip('Trier'), findsNWidgets(2));
      expect(find.text('Date d\'ajout'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);

      sent.clear();
      await tester.tap(find.byTooltip('Trier').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Titre').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(finds('findScenes').single['sort'], 'title');
      expect(finds('findScenes').single['direction'], 'DESC');
      expect(finds('findPerformers'), isEmpty, reason: 'other view untouched');

      sent.clear();
      await tester.tap(find.byTooltip('Croissant'));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(finds('findPerformers').single, containsPair('direction', 'DESC'));
      expect(finds('findPerformers').single, containsPair('sort', 'name'));
      expect(finds('findScenes'), isEmpty);
      // The saved views keep their own sort.
      expect(a.viewById('s')!.sort, 'created_at');
    });
  });
}
