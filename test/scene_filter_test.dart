import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/models/scene_filter.dart';
import 'package:stash_android/services/app_state.dart';

void main() {
  test('scenes without any group', () {
    final f = SceneFilter(groups: EntityCriterion(mode: EntityMode.none));
    expect(f.toGraphQL(), {
      'groups': {'modifier': 'IS_NULL'},
    });
    expect(f.describe(), ['Sans groupe']);
    expect(f.activeCount, 1);
  });

  test('entity criteria need items unless checking presence', () {
    final f = SceneFilter(tags: EntityCriterion());
    expect(f.isEmpty, isTrue);
    expect(f.toGraphQL(), isEmpty);

    f.tags = EntityCriterion(
      mode: EntityMode.all,
      items: [TagRef(id: '4', name: 'Outdoor')],
      subLevels: true,
    );
    expect(f.toGraphQL(), {
      'tags': {
        'modifier': 'INCLUDES_ALL',
        'value': ['4'],
        'depth': -1,
      },
    });
  });

  test('numeric criteria', () {
    final f = SceneFilter(
      minStars: 4,
      minResolution: 'STANDARD_HD',
      minDurationMin: 10,
      played: false,
    );
    expect(f.toGraphQL(), {
      'rating100': {'value': 79, 'modifier': 'GREATER_THAN'},
      'resolution': {'value': 'STANDARD_HD', 'modifier': 'GREATER_THAN'},
      'duration': {'value': 599, 'modifier': 'GREATER_THAN'},
      'play_count': {'value': 0, 'modifier': 'EQUALS'},
    });
    expect(f.describe(), ['≥ 4 ★', '≥ 1080p', '≥ 10 min', 'Jamais vues']);
  });

  test('JSON round trip keeps every criterion', () {
    final f = SceneFilter(
      performers: EntityCriterion(
        mode: EntityMode.exclude,
        items: [TagRef(id: '1', name: 'A')],
      ),
      studios: EntityCriterion(mode: EntityMode.notNone),
      minDurationMin: 5,
      maxDurationMin: 20,
      hasMarkers: true,
      organized: false,
    );
    expect(f.copy().toGraphQL(), f.toGraphQL());
    expect(f.copy().describe(), f.describe());
  });

  test('AppState stores views and the home view', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final view = SavedView(
      id: 'v1',
      name: 'Hors groupe',
      filter: SceneFilter(groups: EntityCriterion(mode: EntityMode.none)),
      sort: 'date',
    );
    app.saveView(view);
    app.setHomeView('v1', true);
    expect(app.homeViews.single.name, 'Hors groupe');
    expect(app.homeViews.single.filter.toGraphQL(), {
      'groups': {'modifier': 'IS_NULL'},
    });

    app.saveView(view..name = 'Renommée');
    expect(app.views.single.name, 'Renommée');

    app.deleteView('v1');
    expect(app.views, isEmpty);
    expect(app.homeViews, isEmpty);
  });

  test('several home views, in the order of the views list', () async {
    // Before 1.9, a single home view under "home_view".
    SharedPreferences.setMockInitialValues({'home_view': 'b'});
    final app = AppState(await SharedPreferences.getInstance());
    for (final id in ['a', 'b', 'c']) {
      app.saveView(SavedView(id: id, name: id, filter: SceneFilter()));
    }
    expect([for (final v in app.homeViews) v.id], ['b']);

    app.setHomeView('c', true);
    app.setHomeView('a', true);
    expect([for (final v in app.homeViews) v.id], ['a', 'b', 'c']);
    app.reorderViews(2, 0);
    expect([for (final v in app.homeViews) v.id], ['c', 'a', 'b']);

    app.setHomeView('a', false);
    app.deleteView('b');
    expect([for (final v in app.homeViews) v.id], ['c']);
    expect(app.isHomeView('c'), isTrue);

    app.clearHomeViews();
    expect(app.homeViews, isEmpty);
    expect(app.prefs.getString('home_view'), isNull);
  });
}
