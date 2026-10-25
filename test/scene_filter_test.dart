import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stash_android/models/home_section.dart';
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

  test('custom home: views and sections, in its own order', () async {
    // Before 1.9, a single home view under "home_view".
    SharedPreferences.setMockInitialValues({'home_view': 'b'});
    final app = AppState(await SharedPreferences.getInstance());
    for (final id in ['a', 'b', 'c']) {
      app.saveView(SavedView(id: id, name: id, filter: SceneFilter()));
    }
    expect([for (final v in app.homeViews) v.id], ['b']);

    // The house icon adds at the end; the views list order is separate.
    app.setHomeView('c', true);
    app.setHomeView('a', true);
    app.reorderViews(2, 0);
    expect(app.homeLayout, ['b', 'c', 'a']);

    app.homeLayout = ['a', HomeSection.resume.id, 'b', 'gone'];
    expect(app.homeLayout, ['a', 'section:resume', 'b']);
    expect([for (final v in app.homeViews) v.id], ['a', 'b']);

    app.setHomeView('a', false);
    app.deleteView('b');
    expect(app.homeLayout, ['section:resume']);
    expect(app.homeViews, isEmpty);

    app.clearHomeViews();
    expect(app.homeLayout, isEmpty);
    expect(app.prefs.getString('home_view'), isNull);
  });

  test('home views of 1.9 to 1.11 keep their order', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    for (final id in ['a', 'b', 'c']) {
      app.saveView(SavedView(id: id, name: id, filter: SceneFilter()));
    }
    // They were shown in the order of the views list.
    await app.prefs.setStringList('home_views', ['c', 'a']);
    expect(app.homeLayout, ['a', 'c']);
  });

  test('dashboard rows: sections around the views until chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    app.saveView(SavedView(id: 'v', name: 'v', filter: SceneFilter()));
    expect(app.dashboardLayout, [
      'section:stats',
      'section:resume',
      'v',
      'section:recent',
      'section:releases',
      'section:favoritePerformers',
      'section:random',
      'section:galleries',
    ]);
    app.saveView(SavedView(id: 'w', name: 'w', filter: SceneFilter()));
    expect(app.dashboardLayout, contains('w'), reason: 'still the default');

    app.dashboardLayout = ['w', 'section:random', 'v'];
    app.saveView(SavedView(id: 'x', name: 'x', filter: SceneFilter()));
    expect(app.dashboardLayout, ['w', 'section:random', 'v']);
    app.deleteView('w');
    expect(app.dashboardLayout, ['section:random', 'v']);
    app.dashboardLayout = null;
    expect(app.dashboardLayout, contains('x'));
  });
}
