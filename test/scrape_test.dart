import 'package:flutter_test/flutter_test.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/screens/edit/edit_form.dart';
import 'package:stash_android/screens/edit/editors.dart';
import 'package:stash_android/screens/edit/scrape.dart';

void main() {
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
  final scraped = ScrapedScene.fromJson({
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

  test('merge proposes only new values, with sensible defaults', () {
    final fields = sceneFields(scene);
    final (items, missing) = mergeItems(scraped, fields);
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
    expect(missing, ['Performeur : Inconnue']);
  });

  test('applying the checked items fills the form', () {
    final fields = sceneFields(scene);
    final (items, _) = mergeItems(scraped, fields);
    for (final i in items) {
      if (i.checked) i.apply();
    }
    T field<T extends EditField>(String key) =>
        fields.whereType<T>().singleWhere((f) => f.key == key);

    expect(field<TextEditField>('title').controller.text, 'Titre local');
    expect(field<TextEditField>('date').controller.text, '2024-02-03');
    expect(field<RefEditField>('studio_id').value?.id, '7');
    expect(field<RefsEditField>('performer_ids').items.map((r) => r.id), [
      '1',
      '2',
    ]);
    expect(field<RefsEditField>('tag_ids').items.single.name, 'Plage');
    expect(field<StringListEditField>('urls').items, [
      'https://a',
      'https://b',
    ]);
    expect(field<ImageEditField>('cover_image').changed, isFalse);

    // Only the changed fields would be saved.
    final input = {
      for (final f in fields)
        if (f.changed) ...f.toInput(),
    };
    expect(
      input.keys,
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
}
