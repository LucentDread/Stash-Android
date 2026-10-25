import '../models/models.dart';
import 'stash_client.dart';

/// Sort options offered in list screens. `value` is the Stash sort key.
class SortOption {
  const SortOption(this.value, this.label);
  final String value;
  final String label;
}

class SortOptions {
  static const scenes = [
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('date', 'Date de sortie'),
    SortOption('title', 'Titre'),
    SortOption('rating', 'Note'),
    SortOption('last_played_at', 'Dernière lecture'),
    SortOption('play_count', 'Nombre de lectures'),
    SortOption('o_counter', 'Compteur O'),
    SortOption('duration', 'Durée'),
    SortOption('filesize', 'Taille'),
    SortOption('random', 'Aléatoire'),
  ];
  static const performers = [
    SortOption('name', 'Nom'),
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('scenes_count', 'Nombre de scènes'),
    SortOption('rating', 'Note'),
    SortOption('birthdate', 'Date de naissance'),
    SortOption('random', 'Aléatoire'),
  ];
  static const studios = [
    SortOption('name', 'Nom'),
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('scenes_count', 'Nombre de scènes'),
    SortOption('rating', 'Note'),
    SortOption('random', 'Aléatoire'),
  ];
  static const tags = [
    SortOption('name', 'Nom'),
    SortOption('scenes_count', 'Nombre de scènes'),
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('random', 'Aléatoire'),
  ];
  static const galleries = [
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('date', 'Date'),
    SortOption('title', 'Titre'),
    SortOption('images_count', 'Nombre d\'images'),
    SortOption('rating', 'Note'),
    SortOption('random', 'Aléatoire'),
  ];
  static const markers = [
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('title', 'Titre'),
    SortOption('seconds', 'Position'),
    SortOption('random', 'Aléatoire'),
  ];
}

/// Common query parameters for paginated lists.
class ListQuery {
  const ListQuery({
    this.q,
    this.page = 1,
    this.perPage = 40,
    this.sort,
    this.descending = true,
  });

  final String? q;
  final int page;
  final int perPage;
  final String? sort;
  final bool descending;

  Map<String, dynamic> toFilter() => {
    if (q != null && q!.isNotEmpty) 'q': q,
    'page': page,
    'per_page': perPage,
    if (sort != null) 'sort': sort,
    'direction': descending ? 'DESC' : 'ASC',
  };
}

/// Restricts a list to items linked to a performer, studio, tag or gallery.
class EntityFilter {
  const EntityFilter.performer(this.id) : kind = 'performers';
  const EntityFilter.studio(this.id) : kind = 'studios';
  const EntityFilter.tag(this.id) : kind = 'tags';
  const EntityFilter.gallery(this.id) : kind = 'galleries';

  final String kind;
  final String id;

  bool get hierarchical => kind == 'studios' || kind == 'tags';

  Map<String, dynamic> toCriterion() => {
    kind: {
      'value': [id],
      'modifier': 'INCLUDES',
      if (hierarchical) 'depth': kind == 'studios' ? -1 : 0,
    },
  };
}

const _tagRef = 'id name';

const _sceneCard =
    '''
  id title date rating100 o_counter play_count resume_time organized
  files { path duration width height size }
  paths { screenshot preview }
  studio { $_tagRef }
  performers { $_tagRef }
''';

const _sceneFull =
    '''
  id title code details director date rating100 organized o_counter
  play_count resume_time last_played_at urls
  files {
    path size width height duration video_codec audio_codec frame_rate
    bit_rate format
  }
  paths { screenshot preview stream }
  studio { $_tagRef }
  performers { $_tagRef }
  tags { $_tagRef }
  galleries { id title }
  scene_markers {
    id title seconds end_seconds screenshot primary_tag { $_tagRef }
  }
''';

const _performerCard = '''
  id name disambiguation gender image_path favorite rating100 scene_count
''';

const _performerFull =
    '''
  id name disambiguation gender birthdate country ethnicity height_cm
  measurements hair_color eye_color details image_path favorite rating100
  scene_count image_count gallery_count alias_list urls tags { $_tagRef }
''';

const _studioFields =
    '''
  id name image_path details favorite urls
  scene_count image_count gallery_count
  parent_studio { $_tagRef }
''';

const _tagFields = '''
  id name description image_path favorite aliases
  scene_count scene_marker_count performer_count image_count gallery_count
''';

const _galleryFields =
    '''
  id title date details image_count
  paths { cover }
  folder { path }
  files { path }
  studio { $_tagRef }
  performers { $_tagRef }
  tags { $_tagRef }
''';

const _imageFields = '''
  id title
  paths { thumbnail preview image }
  visual_files {
    ... on ImageFile { width height }
    ... on VideoFile { width height }
  }
''';

const _markerFields =
    '''
  id title seconds end_seconds screenshot
  primary_tag { $_tagRef }
  scene { id title }
''';

class StashRepository {
  StashRepository(this.client);
  final StashClient client;

  Future<String> version() async {
    final d = await client.query('query { version { version } }');
    return (d['version'] as Map?)?['version'] as String? ?? '?';
  }

  Future<Stats> stats() async {
    final d = await client.query('''
      query {
        stats {
          scene_count scenes_size scenes_duration image_count gallery_count
          performer_count studio_count tag_count
        }
      }''');
    return Stats.fromJson(d['stats'] as Map<String, dynamic>);
  }

  Future<ResultPage<Scene>> findScenes(
    ListQuery q, {
    EntityFilter? entity,
    Map<String, dynamic>? sceneFilter,
  }) async {
    final d = await client.query(
      '''
      query FindScenes(\$filter: FindFilterType, \$scene_filter: SceneFilterType) {
        findScenes(filter: \$filter, scene_filter: \$scene_filter) {
          count
          scenes { $_sceneCard }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'scene_filter': {...?sceneFilter, ...?entity?.toCriterion()},
      },
    );
    final r = d['findScenes'] as Map<String, dynamic>;
    return ResultPage(_items(r['scenes'], Scene.fromJson), r['count'] as int);
  }

  /// Scenes started but not finished, most recent first.
  Future<List<Scene>> continueWatching({int limit = 20}) async {
    final page = await findScenes(
      ListQuery(perPage: limit, sort: 'last_played_at'),
      sceneFilter: {
        'resume_time': {'value': 0, 'modifier': 'GREATER_THAN'},
      },
    );
    return page.items;
  }

  Future<Scene> findScene(String id) async {
    final d = await client.query(
      '''
      query FindScene(\$id: ID!) {
        findScene(id: \$id) { $_sceneFull }
      }''',
      variables: {'id': id},
    );
    final s = d['findScene'];
    if (s == null) throw StashException('Scène introuvable');
    return Scene.fromJson(s as Map<String, dynamic>);
  }

  Future<List<StreamEndpoint>> sceneStreams(String id) async {
    final d = await client.query(
      '''
      query SceneStreams(\$id: ID!) {
        sceneStreams(id: \$id) { url mime_type label }
      }''',
      variables: {'id': id},
    );
    return _items(d['sceneStreams'], StreamEndpoint.fromJson);
  }

  Future<void> saveActivity(
    String id, {
    double? resumeTime,
    double? playDuration,
  }) async {
    await client.query(
      '''
      mutation SaveActivity(\$id: ID!, \$resume: Float, \$duration: Float) {
        sceneSaveActivity(id: \$id, resume_time: \$resume, playDuration: \$duration)
      }''',
      variables: {'id': id, 'resume': resumeTime, 'duration': playDuration},
    );
  }

  Future<int> addPlay(String id) async {
    final d = await client.query(
      '''
      mutation AddPlay(\$id: ID!) { sceneAddPlay(id: \$id) { count } }''',
      variables: {'id': id},
    );
    return (d['sceneAddPlay'] as Map)['count'] as int;
  }

  Future<int> addO(String id) async {
    final d = await client.query(
      '''
      mutation AddO(\$id: ID!) { sceneAddO(id: \$id) { count } }''',
      variables: {'id': id},
    );
    return (d['sceneAddO'] as Map)['count'] as int;
  }

  Future<int> removeO(String id) async {
    final d = await client.query(
      '''
      mutation DeleteO(\$id: ID!) { sceneDeleteO(id: \$id) { count } }''',
      variables: {'id': id},
    );
    return (d['sceneDeleteO'] as Map)['count'] as int;
  }

  /// [rating100] is 1-100, or null to clear the rating.
  Future<void> rateScene(String id, int? rating100) async {
    await client.query(
      '''
      mutation RateScene(\$input: SceneUpdateInput!) {
        sceneUpdate(input: \$input) { id }
      }''',
      variables: {
        'input': {'id': id, 'rating100': rating100},
      },
    );
  }

  Future<ResultPage<Performer>> findPerformers(
    ListQuery q, {
    EntityFilter? entity,
    Map<String, dynamic>? performerFilter,
  }) async {
    final d = await client.query(
      '''
      query FindPerformers(\$filter: FindFilterType, \$pf: PerformerFilterType) {
        findPerformers(filter: \$filter, performer_filter: \$pf) {
          count
          performers { $_performerCard }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'pf': {...?performerFilter, ...?entity?.toCriterion()},
      },
    );
    final r = d['findPerformers'] as Map<String, dynamic>;
    return ResultPage(
      _items(r['performers'], Performer.fromJson),
      r['count'] as int,
    );
  }

  Future<Performer> findPerformer(String id) async {
    final d = await client.query(
      '''
      query FindPerformer(\$id: ID!) {
        findPerformer(id: \$id) { $_performerFull }
      }''',
      variables: {'id': id},
    );
    final p = d['findPerformer'];
    if (p == null) throw StashException('Performeur introuvable');
    return Performer.fromJson(p as Map<String, dynamic>);
  }

  Future<void> setPerformerFavorite(String id, bool favorite) async {
    await client.query(
      '''
      mutation Fav(\$input: PerformerUpdateInput!) {
        performerUpdate(input: \$input) { id }
      }''',
      variables: {
        'input': {'id': id, 'favorite': favorite},
      },
    );
  }

  Future<ResultPage<Studio>> findStudios(ListQuery q) async {
    final d = await client.query(
      '''
      query FindStudios(\$filter: FindFilterType) {
        findStudios(filter: \$filter) {
          count
          studios { $_studioFields }
        }
      }''',
      variables: {'filter': q.toFilter()},
    );
    final r = d['findStudios'] as Map<String, dynamic>;
    return ResultPage(_items(r['studios'], Studio.fromJson), r['count'] as int);
  }

  Future<Studio> findStudio(String id) async {
    final d = await client.query(
      '''
      query FindStudio(\$id: ID!) {
        findStudio(id: \$id) { $_studioFields }
      }''',
      variables: {'id': id},
    );
    final s = d['findStudio'];
    if (s == null) throw StashException('Studio introuvable');
    return Studio.fromJson(s as Map<String, dynamic>);
  }

  Future<ResultPage<Tag>> findTags(ListQuery q) async {
    final d = await client.query(
      '''
      query FindTags(\$filter: FindFilterType) {
        findTags(filter: \$filter) {
          count
          tags { $_tagFields }
        }
      }''',
      variables: {'filter': q.toFilter()},
    );
    final r = d['findTags'] as Map<String, dynamic>;
    return ResultPage(_items(r['tags'], Tag.fromJson), r['count'] as int);
  }

  Future<Tag> findTag(String id) async {
    final d = await client.query(
      '''
      query FindTag(\$id: ID!) {
        findTag(id: \$id) { $_tagFields }
      }''',
      variables: {'id': id},
    );
    final t = d['findTag'];
    if (t == null) throw StashException('Tag introuvable');
    return Tag.fromJson(t as Map<String, dynamic>);
  }

  Future<ResultPage<Gallery>> findGalleries(
    ListQuery q, {
    EntityFilter? entity,
  }) async {
    final d = await client.query(
      '''
      query FindGalleries(\$filter: FindFilterType, \$gf: GalleryFilterType) {
        findGalleries(filter: \$filter, gallery_filter: \$gf) {
          count
          galleries { $_galleryFields }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'gf': {...?entity?.toCriterion()},
      },
    );
    final r = d['findGalleries'] as Map<String, dynamic>;
    return ResultPage(
      _items(r['galleries'], Gallery.fromJson),
      r['count'] as int,
    );
  }

  Future<Gallery> findGallery(String id) async {
    final d = await client.query(
      '''
      query FindGallery(\$id: ID!) {
        findGallery(id: \$id) { $_galleryFields }
      }''',
      variables: {'id': id},
    );
    final g = d['findGallery'];
    if (g == null) throw StashException('Galerie introuvable');
    return Gallery.fromJson(g as Map<String, dynamic>);
  }

  Future<ResultPage<StashImage>> findImages(
    ListQuery q, {
    EntityFilter? entity,
  }) async {
    final d = await client.query(
      '''
      query FindImages(\$filter: FindFilterType, \$imf: ImageFilterType) {
        findImages(filter: \$filter, image_filter: \$imf) {
          count
          images { $_imageFields }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'imf': {...?entity?.toCriterion()},
      },
    );
    final r = d['findImages'] as Map<String, dynamic>;
    return ResultPage(
      _items(r['images'], StashImage.fromJson),
      r['count'] as int,
    );
  }

  Future<ResultPage<SceneMarker>> findMarkers(
    ListQuery q, {
    EntityFilter? entity,
  }) async {
    final d = await client.query(
      '''
      query FindMarkers(\$filter: FindFilterType, \$mf: SceneMarkerFilterType) {
        findSceneMarkers(filter: \$filter, scene_marker_filter: \$mf) {
          count
          scene_markers { $_markerFields }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'mf': {...?entity?.toCriterion()},
      },
    );
    final r = d['findSceneMarkers'] as Map<String, dynamic>;
    return ResultPage(
      _items(r['scene_markers'], SceneMarker.fromJson),
      r['count'] as int,
    );
  }

  static List<T> _items<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
      (v as List? ?? const [])
          .map((e) => f(e as Map<String, dynamic>))
          .toList();
}
