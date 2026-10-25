import 'models.dart';

/// Criteria of [SceneFilter]; each [ViewKind] offers some of them.
enum FilterField {
  performers,
  tags,
  studios,
  groups,
  rating,
  resolution,
  duration,
  played,
  organized,
  hasMarkers,
  performerFavorite,
  favorite,
}

/// What a saved view lists.
enum ViewKind {
  scenes('Scènes', 'SCENES', 'created_at', {
    FilterField.performers,
    FilterField.tags,
    FilterField.studios,
    FilterField.groups,
    FilterField.rating,
    FilterField.resolution,
    FilterField.duration,
    FilterField.played,
    FilterField.organized,
    FilterField.hasMarkers,
    FilterField.performerFavorite,
  }),
  performers('Performeurs', 'PERFORMERS', 'name', {
    FilterField.tags,
    FilterField.studios,
    FilterField.rating,
    FilterField.played,
    FilterField.favorite,
  }),
  studios('Studios', 'STUDIOS', 'name', {
    FilterField.tags,
    FilterField.rating,
    FilterField.organized,
    FilterField.favorite,
  }),
  groups('Groupes', 'GROUPS', 'name', {
    FilterField.performers,
    FilterField.tags,
    FilterField.studios,
    FilterField.rating,
    FilterField.duration,
  }),
  galleries('Galeries', 'GALLERIES', 'created_at', {
    FilterField.performers,
    FilterField.tags,
    FilterField.studios,
    FilterField.rating,
    FilterField.organized,
    FilterField.performerFavorite,
  }),
  tags('Tags', 'TAGS', 'name', {FilterField.favorite}),
  markers('Marqueurs', 'SCENE_MARKERS', 'created_at', {
    FilterField.performers,
    FilterField.tags,
  });

  const ViewKind(this.label, this.filterMode, this.defaultSort, this.fields);
  final String label;

  /// Stash's `FilterMode`, used by the saved filters of the web UI.
  final String filterMode;
  final String defaultSort;
  final Set<FilterField> fields;

  /// Names sort A to Z, the rest newest first.
  bool get defaultDescending => defaultSort != 'name';

  static ViewKind? fromFilterMode(String? mode) => mode == 'MOVIES'
      ? groups
      : values.where((k) => k.filterMode == mode).firstOrNull;
}

/// How a list of performers / tags / studios / groups is matched.
enum EntityMode {
  any('Au moins un', 'INCLUDES'),
  all('Tous', 'INCLUDES_ALL'),
  exclude('Aucun de', 'EXCLUDES'),
  none('Vide', 'IS_NULL'),
  notNone('Non vide', 'NOT_NULL');

  const EntityMode(this.label, this.modifier);
  final String label;
  final String modifier;

  /// Modes that need a selection of items.
  bool get needsItems => this == any || this == all || this == exclude;
}

class EntityCriterion {
  EntityCriterion({
    this.mode = EntityMode.any,
    List<TagRef>? items,
    this.subLevels = false,
  }) : items = items ?? [];

  EntityMode mode;
  final List<TagRef> items;

  /// Include sub-tags / sub-studios / sub-groups.
  bool subLevels;

  bool get isActive => !mode.needsItems || items.isNotEmpty;

  Map<String, dynamic> toGraphQL({required bool hierarchical}) => {
    'modifier': mode.modifier,
    if (mode.needsItems) 'value': [for (final i in items) i.id],
    if (hierarchical && mode.needsItems) 'depth': subLevels ? -1 : 0,
  };

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'items': [
      for (final i in items) {'id': i.id, 'name': i.name},
    ],
    'sub': subLevels,
  };

  factory EntityCriterion.fromJson(Map<String, dynamic> j) => EntityCriterion(
    mode: EntityMode.values.firstWhere(
      (m) => m.name == j['mode'],
      orElse: () => EntityMode.any,
    ),
    items: [
      for (final i in (j['items'] as List? ?? const []))
        TagRef.fromJson((i as Map).cast<String, dynamic>()),
    ],
    subLevels: j['sub'] as bool? ?? false,
  );
}

/// Minimum resolution choices. Stash's GREATER_THAN on a resolution means
/// "above that resolution's range", so each entry uses the step below.
class ResolutionChoice {
  const ResolutionChoice(this.label, this.aboveEnum);
  final String label;
  final String aboveEnum;

  static const all = [
    ResolutionChoice('480p', 'R360P'),
    ResolutionChoice('720p', 'WEB_HD'),
    ResolutionChoice('1080p', 'STANDARD_HD'),
    ResolutionChoice('1440p', 'FULL_HD'),
    ResolutionChoice('4K', 'QUAD_HD'),
  ];
}

/// Scene search criteria, convertible to Stash's `SceneFilterType` and to
/// JSON for saved views.
class SceneFilter {
  SceneFilter({
    this.performers,
    this.tags,
    this.studios,
    this.groups,
    this.minStars,
    this.minResolution,
    this.minDurationMin,
    this.maxDurationMin,
    this.organized,
    this.played,
    this.hasMarkers,
    this.performerFavorite,
    this.favorite,
  });

  EntityCriterion? performers;
  EntityCriterion? tags;
  EntityCriterion? studios;
  EntityCriterion? groups;
  int? minStars;
  String? minResolution;
  int? minDurationMin;
  int? maxDurationMin;
  bool? organized;
  bool? played;
  bool? hasMarkers;
  bool? performerFavorite;

  /// Favourite performers, studios or tags themselves.
  bool? favorite;

  int get activeCount => [
    performers?.isActive ?? false,
    tags?.isActive ?? false,
    studios?.isActive ?? false,
    groups?.isActive ?? false,
    minStars != null,
    minResolution != null,
    minDurationMin != null || maxDurationMin != null,
    organized != null,
    played != null,
    hasMarkers != null,
    performerFavorite != null,
    favorite != null,
  ].where((a) => a).length;

  bool get isEmpty => activeCount == 0;

  SceneFilter copy() => SceneFilter.fromJson(toJson());

  /// Stash's filter for scenes (`SceneFilterType`), or for [kind]
  /// (`PerformerFilterType`…). Criteria [kind] does not offer are left out.
  Map<String, dynamic> toGraphQL([ViewKind kind = ViewKind.scenes]) {
    final has = kind.fields.contains;
    final f = <String, dynamic>{};
    if (has(FilterField.performers) && (performers?.isActive ?? false)) {
      f['performers'] = performers!.toGraphQL(hierarchical: false);
    }
    if (has(FilterField.tags) && (tags?.isActive ?? false)) {
      f['tags'] = tags!.toGraphQL(hierarchical: true);
    }
    if (has(FilterField.studios) && (studios?.isActive ?? false)) {
      f['studios'] = studios!.toGraphQL(hierarchical: true);
    }
    if (has(FilterField.groups) && (groups?.isActive ?? false)) {
      f['groups'] = groups!.toGraphQL(hierarchical: true);
    }
    if (has(FilterField.rating) && minStars != null) {
      // Rating is 1-100; "at least N stars" = above N*20 - 1.
      f['rating100'] = {
        'value': minStars! * 20 - 1,
        'modifier': 'GREATER_THAN',
      };
    }
    if (has(FilterField.resolution) && minResolution != null) {
      f['resolution'] = {'value': minResolution, 'modifier': 'GREATER_THAN'};
    }
    final duration = has(FilterField.duration);
    final minS = !duration || minDurationMin == null
        ? null
        : minDurationMin! * 60;
    final maxS = !duration || maxDurationMin == null
        ? null
        : maxDurationMin! * 60;
    if (minS != null && maxS != null) {
      f['duration'] = {'value': minS, 'value2': maxS, 'modifier': 'BETWEEN'};
    } else if (minS != null) {
      f['duration'] = {'value': minS - 1, 'modifier': 'GREATER_THAN'};
    } else if (maxS != null) {
      f['duration'] = {'value': maxS + 1, 'modifier': 'LESS_THAN'};
    }
    if (has(FilterField.organized) && organized != null) {
      f['organized'] = organized;
    }
    if (has(FilterField.played) && played != null) {
      f['play_count'] = {
        'value': 0,
        'modifier': played! ? 'GREATER_THAN' : 'EQUALS',
      };
    }
    if (has(FilterField.hasMarkers) && hasMarkers != null) {
      f['has_markers'] = hasMarkers! ? 'true' : 'false';
    }
    if (has(FilterField.performerFavorite) && performerFavorite != null) {
      f['performer_favorite'] = performerFavorite;
    }
    if (has(FilterField.favorite) && favorite != null) {
      f[kind == ViewKind.performers ? 'filter_favorites' : 'favorite'] =
          favorite;
    }
    return f;
  }

  Map<String, dynamic> toJson() => {
    if (performers != null) 'performers': performers!.toJson(),
    if (tags != null) 'tags': tags!.toJson(),
    if (studios != null) 'studios': studios!.toJson(),
    if (groups != null) 'groups': groups!.toJson(),
    'minStars': ?minStars,
    'minResolution': ?minResolution,
    'minDuration': ?minDurationMin,
    'maxDuration': ?maxDurationMin,
    'organized': ?organized,
    'played': ?played,
    'hasMarkers': ?hasMarkers,
    'performerFavorite': ?performerFavorite,
    'favorite': ?favorite,
  };

  factory SceneFilter.fromJson(Map<String, dynamic> j) {
    EntityCriterion? c(String k) => j[k] == null
        ? null
        : EntityCriterion.fromJson((j[k] as Map).cast<String, dynamic>());
    return SceneFilter(
      performers: c('performers'),
      tags: c('tags'),
      studios: c('studios'),
      groups: c('groups'),
      minStars: j['minStars'] as int?,
      minResolution: j['minResolution'] as String?,
      minDurationMin: j['minDuration'] as int?,
      maxDurationMin: j['maxDuration'] as int?,
      organized: j['organized'] as bool?,
      played: j['played'] as bool?,
      hasMarkers: j['hasMarkers'] as bool?,
      performerFavorite: j['performerFavorite'] as bool?,
      favorite: j['favorite'] as bool?,
    );
  }

  /// Short human-readable descriptions of the active criteria [kind]
  /// offers.
  List<String> describe([ViewKind kind = ViewKind.scenes]) {
    final has = kind.fields.contains;
    String entity(EntityCriterion c, String label, String noun) {
      final names = c.items.map((i) => i.name).join(', ');
      return switch (c.mode) {
        EntityMode.any => '$label : $names',
        EntityMode.all => '$label (tous) : $names',
        EntityMode.exclude => '$label sauf : $names',
        EntityMode.none => 'Sans $noun',
        EntityMode.notNone => 'Avec $noun',
      };
    }

    final res = ResolutionChoice.all
        .where((r) => r.aboveEnum == minResolution)
        .firstOrNull;
    final duration = has(FilterField.duration);
    // "Scènes" is feminine plural.
    final e = kind == ViewKind.scenes ? 'es' : '';
    return [
      if (has(FilterField.performers) && (performers?.isActive ?? false))
        entity(performers!, 'Performeurs', 'performeur'),
      if (has(FilterField.tags) && (tags?.isActive ?? false))
        entity(tags!, 'Tags', 'tag'),
      if (has(FilterField.studios) && (studios?.isActive ?? false))
        entity(studios!, 'Studio', 'studio'),
      if (has(FilterField.groups) && (groups?.isActive ?? false))
        entity(groups!, 'Groupe', 'groupe'),
      if (has(FilterField.rating) && minStars != null) '≥ $minStars ★',
      if (has(FilterField.resolution) && res != null) '≥ ${res.label}',
      if (duration && minDurationMin != null && maxDurationMin != null)
        '$minDurationMin–$maxDurationMin min'
      else if (duration && minDurationMin != null)
        '≥ $minDurationMin min'
      else if (duration && maxDurationMin != null)
        '≤ $maxDurationMin min',
      if (has(FilterField.organized) && organized != null)
        organized! ? 'Organisé$e' : 'Non organisé$e',
      if (has(FilterField.played) && played != null)
        played! ? 'Déjà vu$e' : 'Jamais vu$e',
      if (has(FilterField.hasMarkers) && hasMarkers != null)
        hasMarkers! ? 'Avec marqueurs' : 'Sans marqueurs',
      if (has(FilterField.performerFavorite) && performerFavorite != null)
        performerFavorite! ? 'Performeur favori' : 'Sans performeur favori',
      if (has(FilterField.favorite) && favorite != null)
        favorite! ? 'Favoris' : 'Hors favoris',
    ];
  }
}

/// A named list of scenes, performers, studios… (filter + sort), shown on
/// the home page or as a row of the default dashboard.
///
/// Views are made in the app, or come from the filters saved in Stash's web
/// UI ([remote]); those keep the web UI's own filter format
/// ([serverFilter]) and cannot be edited here.
class SavedView {
  SavedView({
    required this.id,
    required this.name,
    required this.filter,
    this.kind = ViewKind.scenes,
    this.sort = 'created_at',
    this.descending = true,
    this.query = '',
    this.serverFilter,
  });

  /// Id of a filter saved in the web UI, as a view.
  static String remoteId(String serverId) => 'web:$serverId';

  final String id;
  String name;
  ViewKind kind;
  SceneFilter filter;
  String sort;
  bool descending;
  String query;

  /// `object_filter` of a web UI saved filter.
  final Map<String, dynamic>? serverFilter;

  bool get remote => id.startsWith('web:');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'filter': filter.toJson(),
    'sort': sort,
    'descending': descending,
    'query': query,
    'serverFilter': ?serverFilter,
  };

  factory SavedView.fromJson(Map<String, dynamic> j) => SavedView(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    kind:
        ViewKind.values.where((k) => k.name == j['kind']).firstOrNull ??
        ViewKind.scenes,
    filter: SceneFilter.fromJson(
      (j['filter'] as Map? ?? const {}).cast<String, dynamic>(),
    ),
    sort: j['sort'] as String? ?? 'created_at',
    descending: j['descending'] as bool? ?? true,
    query: j['query'] as String? ?? '',
    serverFilter: (j['serverFilter'] as Map?)?.cast<String, dynamic>(),
  );

  /// A filter saved in the web UI (`SavedFilter`), or null for the kinds
  /// the app does not list (images).
  static SavedView? fromServer(Map<String, dynamic> j) {
    final kind = ViewKind.fromFilterMode(j['mode'] as String?);
    if (kind == null) return null;
    final find = (j['find_filter'] as Map?)?.cast<String, dynamic>() ?? {};
    var sort = find['sort'] as String? ?? kind.defaultSort;
    // A fixed random order is reshuffled by the app.
    if (sort.startsWith('random_')) sort = 'random';
    return SavedView(
      id: remoteId('${j['id']}'),
      name: j['name'] as String? ?? '',
      kind: kind,
      filter: SceneFilter(),
      sort: sort,
      descending: find['direction'] != 'ASC',
      query: find['q'] as String? ?? '',
      serverFilter:
          (j['object_filter'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
