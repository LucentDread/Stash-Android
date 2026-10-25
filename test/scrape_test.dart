import 'package:flutter_test/flutter_test.dart';
import 'package:stash_android/api/stash_repository.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/screens/edit/edit_form.dart';
import 'package:stash_android/screens/edit/editors.dart';
import 'package:stash_android/screens/edit/scrape.dart';

T _field<T extends EditField>(List<EditField> fields, String key) =>
    fields.whereType<T>().singleWhere((f) => f.key == key);

void _applyChecked(List<MergeItem> items) {
  for (final i in items) {
    if (i.checked) i.apply();
  }
}

Map<String, dynamic> _changes(List<EditField> fields) => {
  for (final f in fields)
    if (f.changed) ...f.toInput(),
};

void main() {
  group('scene', () {
    final scene = Scene.fromJson({
      'id': '1',
      'title': 'Titre local',
      'paths': <String, dynamic>{},
      'performers': [
        {'id': '1', 'name': 'Alice'},
      ],
      'tags': <dynamic>[],
      'urls': ['https://a'],
    });
    final scraped = toScraped(ScrapeKind.scene, {
      'title': 'Titre officiel',
      'date': '2024-02-03',
      'details': 'Résumé',
      'image': 'data:image/png;base64,iVBORw0KGgo=',
      'urls': ['https://a', 'https://b'],
      'studio': {'stored_id': '7', 'name': 'Studio'},
      'performers': [
        {'stored_id': '1', 'name': 'Alice'},
        {'stored_id': '2', 'name': 'Bob'},
        {'stored_id': null, 'name': 'Inconnue'},
      ],
      'tags': [
        {'stored_id': '9', 'name': 'Plage'},
      ],
      'groups': <dynamic>[],
    });

    test('proposes only new values, with sensible defaults', () {
      final (items, missing) = mergeItems(scraped, sceneFields(scene));
      final byLabel = {for (final i in items) i.label: i};
      expect(
        byLabel.keys,
        containsAll([
          'Titre',
          'Date',
          'Description',
          'Studio',
          'Performeurs',
          'Tags',
          'Liens',
          'Couverture',
        ]),
      );
      // Replacing an existing value is opt-in, filling an empty one is not.
      expect(byLabel['Titre']!.checked, isFalse);
      expect(byLabel['Date']!.checked, isTrue);
      expect(byLabel['Couverture']!.checked, isFalse);
      // Alice is already linked: only Bob is proposed.
      expect(byLabel['Performeurs']!.proposed, '+ Bob');
      expect(missing.map((m) => '${m.label} : ${m.proposed}'), [
        'Performeurs : Inconnue',
      ]);
    });

    test('applying the checked items fills the form', () {
      final fields = sceneFields(scene);
      _applyChecked(mergeItems(scraped, fields).$1);
      expect(
        _field<TextEditField>(fields, 'title').controller.text,
        'Titre local',
      );
      expect(_field<RefEditField>(fields, 'studio_id').value?.id, '7');
      expect(
        _field<RefsEditField>(fields, 'performer_ids').items.map((r) => r.id),
        ['1', '2'],
      );
      expect(_field<StringListEditField>(fields, 'urls').items, [
        'https://a',
        'https://b',
      ]);
      expect(
        _changes(fields).keys,
        unorderedEquals([
          'date',
          'details',
          'studio_id',
          'performer_ids',
          'tag_ids',
          'urls',
        ]),
      );
    });
  });

  test('performer: gender, height, aliases, photo', () {
    final p = Performer.fromJson({'id': '3', 'name': 'Alice'});
    final fields = performerFields(p);
    final scraped = toScraped(ScrapeKind.performer, {
      'name': 'Alice',
      'gender': 'Transgender Female',
      'height': '170 cm',
      'weight': '55',
      'aliases': 'Ali, A. Lice',
      'birthdate': '1995-04-01',
      'country': 'FR',
      'images': ['https://img/alice.jpg'],
      'tags': [
        {'stored_id': '4', 'name': 'Blonde'},
      ],
    });
    final (items, missing) = mergeItems(scraped, fields);
    expect(missing, isEmpty);
    expect(items.map((i) => i.label), isNot(contains('Nom')));
    final gender = items.singleWhere((i) => i.label == 'Genre');
    expect(gender.proposed, 'Femme trans');

    _applyChecked(items);
    expect(_changes(fields), {
      'alias_list': ['Ali', 'A. Lice'],
      'gender': 'TRANSGENDER_FEMALE',
      'birthdate': '1995-04-01',
      'country': 'FR',
      'height_cm': 170,
      'weight': 55,
      'tag_ids': ['4'],
    });
    // The photo is proposed but not ticked.
    expect(items.singleWhere((i) => i.label == 'Photo').checked, isFalse);
  });

  test('group: duration in minutes and covers', () {
    final g = Group.fromJson({'id': '5', 'name': 'Saga'});
    final fields = groupFields(g);
    final scraped = toScraped(ScrapeKind.group, {
      'name': 'Saga',
      'duration': '1:30:00',
      'director': 'Réal',
      'front_image': 'https://img/front.jpg',
      'studio': {'stored_id': null, 'name': 'Nouveau studio'},
    });
    final (items, missing) = mergeItems(scraped, fields);
    expect(missing.single.proposed, 'Nouveau studio');
    expect(items.singleWhere((i) => i.label == 'Durée').proposed, '90 min');
    _applyChecked(items);
    expect(_changes(fields), {'duration': 5400, 'director': 'Réal'});
  });

  test('gallery and studio', () {
    final gallery = Gallery.fromJson({'id': '8', 'paths': <String, dynamic>{}});
    final gFields = galleryFields(gallery);
    _applyChecked(
      mergeItems(
        toScraped(ScrapeKind.gallery, {
          'title': 'Vacances',
          'photographer': 'Jo',
          'performers': [
            {'stored_id': '2', 'name': 'Bob'},
          ],
        }),
        gFields,
      ).$1,
    );
    expect(_changes(gFields), {
      'title': 'Vacances',
      'photographer': 'Jo',
      'performer_ids': ['2'],
    });

    final studio = Studio.fromJson({'id': '1', 'name': 'Studio'});
    final sFields = studioFields(studio);
    _applyChecked(
      mergeItems(
        toScraped(ScrapeKind.studio, {
          'name': 'Studio',
          'details': 'À propos',
          'urls': ['https://studio'],
          'parent': {'stored_id': '9', 'name': 'Réseau'},
        }),
        sFields,
      ).$1,
    );
    expect(_changes(sFields), {
      'parent_id': '9',
      'urls': ['https://studio'],
      'details': 'À propos',
    });
  });

  group('creating missing items', () {
    final scene = Scene.fromJson({
      'id': '1',
      'paths': <String, dynamic>{},
      'performers': <dynamic>[],
      'tags': [
        {'id': '9', 'name': 'Plage'},
      ],
    });
    final scraped = toScraped(ScrapeKind.scene, {
      'studio': {
        'stored_id': null,
        'name': 'Nouveau studio',
        'urls': ['https://studio'],
        'remote_site_id': 'st-1',
        'parent': {'stored_id': '3', 'name': 'Réseau'},
      },
      'performers': [
        {
          'stored_id': null,
          'name': 'Chloé',
          'gender': 'Female',
          'height': '165 cm',
          'aliases': 'Clo, C.',
          'images': ['https://img/chloe.jpg'],
          'remote_site_id': 'p-1',
        },
      ],
      'tags': [
        {'stored_id': null, 'name': 'Nouveau tag', 'remote_site_id': 't-1'},
        {'stored_id': '9', 'name': 'Plage'},
      ],
    });

    test('created with the scraped data and linked', () async {
      final fields = sceneFields(scene);
      final created = <(RefKind, Map<String, dynamic>)>[];
      var next = 100;
      final (items, missing) = mergeItems(
        scraped,
        fields,
        create: (kind, input) async {
          created.add((kind, input));
          return TagRef(id: '${next++}', name: input['name'] as String);
        },
        stashBoxEndpoint: 'https://stashdb.org/graphql',
      );
      expect(items, isEmpty);
      expect(missing.map((m) => m.proposed), [
        'Nouveau studio',
        'Chloé',
        'Nouveau tag',
      ]);
      expect(missing.every((m) => m.checked), isTrue);

      for (final m in missing) {
        await m.apply();
      }
      expect(created.map((c) => c.$1), [
        RefKind.studios,
        RefKind.performers,
        RefKind.tags,
      ]);
      expect(created[1].$2, {
        'name': 'Chloé',
        'gender': 'FEMALE',
        'height_cm': 165,
        'alias_list': ['Clo', 'C.'],
        'image': 'https://img/chloe.jpg',
        'stash_ids': [
          {'endpoint': 'https://stashdb.org/graphql', 'stash_id': 'p-1'},
        ],
      });
      expect(created[0].$2['parent_id'], '3');
      expect(created[0].$2['urls'], ['https://studio']);

      expect(_field<RefEditField>(fields, 'studio_id').value?.id, '100');
      expect(
        _field<RefsEditField>(fields, 'performer_ids').items.single.id,
        '101',
      );
      expect(_field<RefsEditField>(fields, 'tag_ids').items.map((t) => t.id), [
        '9',
        '102',
      ]);
    });

    test('nothing is linked to a stash-box outside stash-box results', () {
      final input = createInput(
        RefKind.tags,
        ScrapedRef(name: 'T', raw: {'name': 'T', 'remote_site_id': 'x'}),
      );
      expect(input, {'name': 'T'});
      final unknownGender = createInput(
        RefKind.performers,
        ScrapedRef(name: 'P', raw: {'name': 'P', 'gender': 'Robot'}),
      );
      expect(unknownGender, {'name': 'P'});
    });

    test('without a creator nothing is ticked', () {
      final (_, missing) = mergeItems(scraped, sceneFields(scene));
      expect(missing.any((m) => m.checked), isFalse);
    });
  });
}
