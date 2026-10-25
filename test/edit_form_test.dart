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
import 'package:stash_android/screens/edit/edit_form.dart';
import 'package:stash_android/screens/edit/editors.dart';
import 'package:stash_android/services/app_state.dart';

Map<String, dynamic> _changes(List<EditField> fields) => {
  for (final f in fields)
    if (f.changed) ...f.toInput(),
};

void main() {
  test('only changed fields are sent', () {
    final title = TextEditField('title', 'Titre', 'Avant');
    final code = TextEditField('code', 'Code', 'X1');
    final details = TextEditField('details', 'Description', 'Texte');
    final fields = [title, code, details];
    expect(_changes(fields), isEmpty);

    title.controller.text = 'Après';
    details.controller.text = '  ';
    expect(_changes(fields), {'title': 'Après', 'details': null});
  });

  test('refs, single ref, ints and lists', () {
    final studio = RefEditField(
      'studio_id',
      'Studio',
      RefKind.studios,
      TagRef(id: '3', name: 'S'),
    );
    final tags = RefsEditField('tag_ids', 'Tags', RefKind.tags, [
      TagRef(id: '1', name: 'a'),
      TagRef(id: '2', name: 'b'),
    ]);
    final duration = IntEditField(
      'duration',
      'Durée',
      5400,
      factor: 60,
      suffix: 'min',
    );
    final urls = StringListEditField('urls', 'Liens', ['https://a']);
    final fields = [studio, tags, duration, urls];
    expect(duration.controller.text, '90');
    expect(_changes(fields), isEmpty);

    studio.value = null;
    tags.items.removeAt(0);
    duration.controller.text = '95';
    urls.controller.text = 'https://b';
    expect(_changes(fields), {
      'studio_id': null,
      'tag_ids': ['2'],
      'duration': 5700,
      'urls': ['https://a', 'https://b'],
    });
  });

  test('validation', () {
    expect(
      TextEditField('name', 'Nom', 'x', required: true).validate(),
      isNull,
    );
    final name = TextEditField('name', 'Nom', 'x', required: true)
      ..controller.text = ' ';
    expect(name.validate(), isNotNull);
    final date = DateEditField('date', 'Date', null);
    for (final ok in ['', '2024', '2024-05', '2024-05-01']) {
      date.controller.text = ok;
      expect(date.validate(), isNull, reason: ok);
    }
    date.controller.text = '01/05/2024';
    expect(date.validate(), isNotNull);
  });

  testWidgets('scene edit keeps group scene numbers and sends changes only', (
    tester,
  ) async {
    final sent = <Map<String, dynamic>>[];
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    // Route the app's repository through a fake server.
    app.repoOverride = StashRepository(
      StashClient(
        serverUrl: 'http://stash.test',
        client: MockClient((req) async {
          sent.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response('{"data":{"sceneUpdate":{"id":"7"}}}', 200);
        }),
      ),
    );
    final scene = Scene.fromJson({
      'id': '7',
      'title': 'Ancien titre',
      'paths': <String, dynamic>{},
      'groups': [
        {
          'group': {'id': '4', 'name': 'Saga'},
          'scene_index': 3,
        },
      ],
    });

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
    final result = editScene(ctx, scene);
    await tester.pumpAndSettle();

    // Nothing changed yet: the save button is disabled.
    final save = find.widgetWithText(FilledButton, 'Enregistrer');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Titre'), 'Nouveau');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(sent.single['variables'], {
      'input': {'id': '7', 'title': 'Nouveau'},
    });

    // The real scene groups field keeps the existing scene number.
    final groups = sceneFields(scene)
        .whereType<RefsEditField>()
        .singleWhere((f) => f.key == 'groups');
    groups.items.add(TagRef(id: '9', name: 'Autre'));
    expect(groups.toInput(), {
      'groups': [
        {'group_id': '4', 'scene_index': 3},
        {'group_id': '9', 'scene_index': null},
      ],
    });
  });
}
