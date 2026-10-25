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
  static const groups = [
    SortOption('name', 'Nom'),
    SortOption('created_at', 'Date d\'ajout'),
    SortOption('date', 'Date'),
    SortOption('scenes_count', 'Nombre de scènes'),
    SortOption('rating', 'Note'),
    SortOption('duration', 'Durée'),
    SortOption('random', 'Aléatoire'),
  ];
  static const groupScenes = [
    SortOption('group_scene_number', 'Ordre dans le groupe'),
    ...scenes,
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
  const EntityFilter.group(this.id) : kind = 'groups';

  final String kind;
  final String id;

  bool get hierarchical =>
      kind == 'studios' || kind == 'tags' || kind == 'groups';

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
  id title date details created_at rating100 o_counter play_count
  resume_time organized
  files { path duration width height size video_codec frame_rate }
  paths { screenshot preview }
  studio { $_tagRef image_path }
  performers { $_tagRef }
  tags { $_tagRef }
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
  groups { group { $_tagRef } scene_index }
  scene_markers {
    id title seconds end_seconds screenshot primary_tag { $_tagRef }
    tags { $_tagRef }
  }
''';

const _performerCard = '''
  id name disambiguation gender birthdate image_path favorite rating100
  scene_count o_counter
''';

const _performerFull =
    '''
  id name disambiguation gender birthdate country ethnicity height_cm
  measurements hair_color eye_color details image_path favorite rating100
  death_date weight fake_tits tattoos piercings
  scene_count image_count gallery_count alias_list urls tags { $_tagRef }
''';

const _studioFields =
    '''
  id name image_path details favorite rating100 urls
  scene_count image_count gallery_count
  parent_studio { $_tagRef }
''';

const _tagFields =
    '''
  id name description image_path favorite aliases
  scene_count scene_marker_count performer_count image_count gallery_count
  parents { $_tagRef }
''';

const _galleryFields =
    '''
  id title code date details photographer rating100 organized urls
  image_count
  paths { cover }
  folder { path }
  files { path }
  studio { $_tagRef }
  performers { $_tagRef }
  tags { $_tagRef }
''';

const _groupFields =
    '''
  id name aliases date duration director synopsis rating100 urls
  front_image_path back_image_path scene_count
  studio { $_tagRef }
  tags { $_tagRef }
''';

/// Kinds of entities that can be picked in the scene filter.
enum RefKind { performers, tags, studios, groups }

/// Kinds of items that can be scraped.
enum ScrapeKind { scene, performer, group, gallery, studio }

/// Where to scrape data from: a scraper or a stash-box endpoint.
class ScrapeSource {
  const ScrapeSource({
    required this.label,
    this.scraperId,
    this.stashBoxEndpoint,
    this.byFragment = true,
    this.byName = false,
  });

  final String label;
  final String? scraperId;
  final String? stashBoxEndpoint;

  /// Can identify the item from its own data (or fingerprints).
  final bool byFragment;

  /// Can search by a text query.
  final bool byName;

  bool get isStashBox => stashBoxEndpoint != null;

  Map<String, dynamic> toInput() => {
    'scraper_id': ?scraperId,
    'stash_box_endpoint': ?stashBoxEndpoint,
  };
}

const _scrapedRef = 'stored_id name';

/// Scraped fields requested for each kind, plus the GraphQL names used to
/// scrape it.
const _scrapeFields = <ScrapeKind, String>{
  ScrapeKind.scene:
      '''
    title code details director date image urls remote_site_id
    studio { $_scrapedRef }
    performers { $_scrapedRef }
    tags { $_scrapedRef }
    groups { $_scrapedRef }
  ''',
  ScrapeKind.performer:
      '''
    name disambiguation gender urls birthdate death_date ethnicity country
    eye_color hair_color height weight measurements fake_tits tattoos
    piercings aliases details images remote_site_id
    tags { $_scrapedRef }
  ''',
  ScrapeKind.group:
      '''
    name aliases duration date director urls synopsis front_image back_image
    studio { $_scrapedRef }
    tags { $_scrapedRef }
  ''',
  ScrapeKind.gallery:
      '''
    title code details photographer urls date
    studio { $_scrapedRef }
    performers { $_scrapedRef }
    tags { $_scrapedRef }
  ''',
  ScrapeKind.studio:
      '''
    stored_id name urls image details
    parent { $_scrapedRef }
  ''',
};

/// Fields a scraper accepts back as a fragment (`<kind>_input`) to turn a
/// search result into a full record.
const _fragmentKeys = <ScrapeKind, Set<String>>{
  ScrapeKind.scene: {
    'title',
    'code',
    'details',
    'director',
    'urls',
    'date',
    'remote_site_id',
  },
  ScrapeKind.performer: {
    'name',
    'disambiguation',
    'gender',
    'urls',
    'birthdate',
    'death_date',
    'ethnicity',
    'country',
    'eye_color',
    'hair_color',
    'height',
    'weight',
    'measurements',
    'fake_tits',
    'tattoos',
    'piercings',
    'aliases',
    'details',
    'remote_site_id',
  },
  ScrapeKind.group: {
    'name',
    'aliases',
    'duration',
    'date',
    'director',
    'urls',
    'synopsis',
  },
  ScrapeKind.gallery: {
    'title',
    'code',
    'details',
    'photographer',
    'urls',
    'date',
  },
};

String _capitalized(ScrapeKind k) =>
    k.name[0].toUpperCase() + k.name.substring(1);

/// Kinds of entities that can be edited.
enum EditKind { scene, performer, studio, tag, group, gallery, marker }

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
  tags { $_tagRef }
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

  Future<Scene> findScene(String id) async =>
      Scene.fromJson(await sceneJson(id));

  /// Raw scene data, kept as is for offline copies.
  Future<Map<String, dynamic>> sceneJson(String id) async {
    final d = await client.query(
      '''
      query FindScene(\$id: ID!) {
        findScene(id: \$id) { $_sceneFull }
      }''',
      variables: {'id': id},
    );
    final s = d['findScene'];
    if (s == null) throw StashException('Scène introuvable');
    return s as Map<String, dynamic>;
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

  Future<ResultPage<Group>> findGroups(
    ListQuery q, {
    EntityFilter? entity,
  }) async {
    final d = await client.query(
      '''
      query FindGroups(\$filter: FindFilterType, \$gf: GroupFilterType) {
        findGroups(filter: \$filter, group_filter: \$gf) {
          count
          groups { $_groupFields }
        }
      }''',
      variables: {
        'filter': q.toFilter(),
        'gf': {...?entity?.toCriterion()},
      },
    );
    final r = d['findGroups'] as Map<String, dynamic>;
    return ResultPage(_items(r['groups'], Group.fromJson), r['count'] as int);
  }

  Future<Group> findGroup(String id) async =>
      Group.fromJson(await groupJson(id));

  Future<Map<String, dynamic>> groupJson(String id) async {
    final d = await client.query(
      '''
      query FindGroup(\$id: ID!) {
        findGroup(id: \$id) { $_groupFields }
      }''',
      variables: {'id': id},
    );
    final g = d['findGroup'];
    if (g == null) throw StashException('Groupe introuvable');
    return g as Map<String, dynamic>;
  }

  /// Applies a partial update. Only the keys present in [input] are
  /// changed by Stash; the others keep their current value.
  Future<void> update(
    EditKind kind,
    String id,
    Map<String, dynamic> input,
  ) async {
    final (mutation, type) = switch (kind) {
      EditKind.scene => ('sceneUpdate', 'SceneUpdateInput'),
      EditKind.performer => ('performerUpdate', 'PerformerUpdateInput'),
      EditKind.studio => ('studioUpdate', 'StudioUpdateInput'),
      EditKind.tag => ('tagUpdate', 'TagUpdateInput'),
      EditKind.group => ('groupUpdate', 'GroupUpdateInput'),
      EditKind.gallery => ('galleryUpdate', 'GalleryUpdateInput'),
      EditKind.marker => ('sceneMarkerUpdate', 'SceneMarkerUpdateInput'),
    };
    await client.query(
      '''
      mutation Update(\$input: $type!) {
        $mutation(input: \$input) { id }
      }''',
      variables: {
        'input': {'id': id, ...input},
      },
    );
  }

  Future<void> createMarker(String sceneId, Map<String, dynamic> input) async {
    await client.query(
      '''
      mutation CreateMarker(\$input: SceneMarkerCreateInput!) {
        sceneMarkerCreate(input: \$input) { id }
      }''',
      variables: {
        'input': {'scene_id': sceneId, ...input},
      },
    );
  }

  Future<void> deleteMarker(String id) async {
    await client.query(
      '''
      mutation DeleteMarker(\$id: ID!) { sceneMarkerDestroy(id: \$id) }''',
      variables: {'id': id},
    );
  }

  /// Asks Stash to regenerate the scene cover from the frame at [seconds].
  /// Runs as a background job on the server.
  Future<void> generateCover(String sceneId, double seconds) async {
    await client.query(
      '''
      mutation Cover(\$id: ID!, \$at: Float) {
        sceneGenerateScreenshot(id: \$id, at: \$at)
      }''',
      variables: {'id': sceneId, 'at': seconds},
    );
  }

  /// Starts a library scan with the default options set in Stash
  /// (Settings > Tasks), like the web UI does. Returns the job id.
  Future<String> startScan() async {
    final d = await client.query('''
      query { configuration { defaults { scan {
        rescan scanGenerateCovers scanGeneratePreviews
        scanGenerateImagePreviews scanGenerateSprites scanGeneratePhashes
        scanGenerateImagePhashes scanGenerateThumbnails
        scanGenerateClipPreviews
      } } } }''');
    final options =
        ((d['configuration'] as Map?)?['defaults'] as Map?)?['scan'];
    final r = await client.query(
      '''
      mutation Scan(\$input: ScanMetadataInput!) {
        metadataScan(input: \$input)
      }''',
      variables: {
        'input': {
          if (options is Map)
            for (final e in options.entries)
              if (e.value != null) e.key as String: e.value,
        },
      },
    );
    return r['metadataScan'] as String;
  }

  /// State of a background job, or null once Stash has dropped it.
  Future<Job?> findJob(String id) async {
    final d = await client.query(
      '''
      query FindJob(\$id: ID!) {
        findJob(input: {id: \$id}) {
          id status subTasks description progress error
        }
      }''',
      variables: {'id': id},
    );
    final j = d['findJob'];
    return j == null ? null : Job.fromJson(j as Map<String, dynamic>);
  }

  Future<void> stopJob(String id) async {
    await client.query(
      '''
      mutation StopJob(\$id: ID!) { stopJob(job_id: \$id) }''',
      variables: {'id': id},
    );
  }

  /// Stash-box endpoints and scrapers configured on the server for [kind].
  /// Stash-boxes handle scenes, performers and studios; scrapers handle
  /// scenes, performers, groups and galleries.
  Future<List<ScrapeSource>> scrapeSources(ScrapeKind kind) async {
    final withBoxes =
        kind == ScrapeKind.scene ||
        kind == ScrapeKind.performer ||
        kind == ScrapeKind.studio;
    final withScrapers = kind != ScrapeKind.studio;
    final type = kind.name.toUpperCase();
    final d = await client.query('''
      query {
        ${withBoxes ? 'configuration { general { stashBoxes { endpoint name } } }' : ''}
        ${withScrapers ? 'listScrapers(types: [$type]) { id name ${kind.name} { supported_scrapes } }' : ''}
      }''');
    final boxes =
        ((d['configuration'] as Map?)?['general'] as Map?)?['stashBoxes']
            as List? ??
        const [];
    final scrapers = d['listScrapers'] as List? ?? const [];
    return [
      for (final b in boxes.cast<Map>())
        ScrapeSource(
          label: (b['name'] as String?)?.isNotEmpty == true
              ? b['name'] as String
              : b['endpoint'] as String,
          stashBoxEndpoint: b['endpoint'] as String,
          // Only scenes are matched by fingerprint; the rest by name.
          byFragment: kind == ScrapeKind.scene,
          byName: true,
        ),
      for (final s in scrapers.cast<Map>())
        if (((s[kind.name] as Map?)?['supported_scrapes'] as List?)
            case final kinds?
            when kinds.contains('FRAGMENT') || kinds.contains('NAME'))
          ScrapeSource(
            label: s['name'] as String,
            scraperId: s['id'] as String,
            byFragment: kinds.contains('FRAGMENT'),
            byName: kinds.contains('NAME'),
          ),
    ];
  }

  /// Scrapes item [id] of [kind] from its own data, by [query], or from a
  /// search result [fragment] (to get the full record). Returns raw results.
  Future<List<Map<String, dynamic>>> scrape(
    ScrapeKind kind,
    ScrapeSource source,
    String id, {
    String? query,
    Map<String, dynamic>? fragment,
  }) async {
    final name = _capitalized(kind);
    final Map<String, dynamic> input;
    if (fragment != null) {
      final keys = _fragmentKeys[kind] ?? const <String>{};
      input = {
        '${kind.name}_input': {
          for (final e in fragment.entries)
            if (keys.contains(e.key) && e.value != null) e.key: e.value,
        },
      };
    } else if (query != null || kind == ScrapeKind.studio) {
      input = {'query': query ?? id};
    } else {
      input = {'${kind.name}_id': id};
    }
    final d = await client.query(
      '''
      query Scrape(\$source: ScraperSourceInput!, \$input: ScrapeSingle${name}Input!) {
        scrapeSingle$name(source: \$source, input: \$input) { ${_scrapeFields[kind]} }
      }''',
      variables: {'source': source.toInput(), 'input': input},
    );
    return (d['scrapeSingle$name'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// Scrapes a page URL with the scraper that handles its site (scenes,
  /// performers, groups and galleries).
  Future<Map<String, dynamic>?> scrapeUrl(ScrapeKind kind, String url) async {
    final field = 'scrape${_capitalized(kind)}URL';
    final d = await client.query(
      '''
      query ScrapeUrl(\$url: String!) {
        $field(url: \$url) { ${_scrapeFields[kind]} }
      }''',
      variables: {'url': url},
    );
    return d[field] as Map<String, dynamic>?;
  }

  /// Name search used by the filter pickers. Without a query, returns the
  /// entities with the most scenes first.
  Future<List<TagRef>> searchRefs(RefKind kind, String q) async {
    final (query, field) = switch (kind) {
      RefKind.performers => ('findPerformers', 'performers'),
      RefKind.tags => ('findTags', 'tags'),
      RefKind.studios => ('findStudios', 'studios'),
      RefKind.groups => ('findGroups', 'groups'),
    };
    final d = await client.query(
      '''
      query SearchRefs(\$filter: FindFilterType) {
        $query(filter: \$filter) { $field { id name } }
      }''',
      variables: {
        'filter': {
          if (q.isNotEmpty) 'q': q,
          'per_page': 50,
          'sort': q.isEmpty ? 'scenes_count' : 'name',
          'direction': q.isEmpty ? 'DESC' : 'ASC',
        },
      },
    );
    return _items((d[query] as Map)[field], TagRef.fromJson);
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

  Future<Gallery> findGallery(String id) async =>
      Gallery.fromJson(await galleryJson(id));

  Future<Map<String, dynamic>> galleryJson(String id) async {
    final d = await client.query(
      '''
      query FindGallery(\$id: ID!) {
        findGallery(id: \$id) { $_galleryFields }
      }''',
      variables: {'id': id},
    );
    final g = d['findGallery'];
    if (g == null) throw StashException('Galerie introuvable');
    return g as Map<String, dynamic>;
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
