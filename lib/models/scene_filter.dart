import 'models.dart';

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
  ].where((a) => a).length;

  bool get isEmpty => activeCount == 0;

  SceneFilter copy() => SceneFilter.fromJson(toJson());

  Map<String, dynamic> toGraphQL() {
    final f = <String, dynamic>{};
    if (performers?.isActive ?? false) {
      f['performers'] = performers!.toGraphQL(hierarchical: false);
    }
    if (tags?.isActive ?? false) {
      f['tags'] = tags!.toGraphQL(hierarchical: true);
    }
    if (studios?.isActive ?? false) {
      f['studios'] = studios!.toGraphQL(hierarchical: true);
    }
    if (groups?.isActive ?? false) {
      f['groups'] = groups!.toGraphQL(hierarchical: true);
    }
    if (minStars != null) {
      // Rating is 1-100; "at least N stars" = above N*20 - 1.
      f['rating100'] = {
        'value': minStars! * 20 - 1,
        'modifier': 'GREATER_THAN',
      };
    }
    if (minResolution != null) {
      f['resolution'] = {'value': minResolution, 'modifier': 'GREATER_THAN'};
    }
    final minS = minDurationMin == null ? null : minDurationMin! * 60;
    final maxS = maxDurationMin == null ? null : maxDurationMin! * 60;
    if (minS != null && maxS != null) {
      f['duration'] = {'value': minS, 'value2': maxS, 'modifier': 'BETWEEN'};
    } else if (minS != null) {
      f['duration'] = {'value': minS - 1, 'modifier': 'GREATER_THAN'};
    } else if (maxS != null) {
      f['duration'] = {'value': maxS + 1, 'modifier': 'LESS_THAN'};
    }
    if (organized != null) f['organized'] = organized;
    if (played != null) {
      f['play_count'] = {
        'value': 0,
        'modifier': played! ? 'GREATER_THAN' : 'EQUALS',
      };
    }
    if (hasMarkers != null) f['has_markers'] = hasMarkers! ? 'true' : 'false';
    if (performerFavorite != null) f['performer_favorite'] = performerFavorite;
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
    );
  }

  /// Short human-readable descriptions of the active criteria.
  List<String> describe() {
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
    return [
      if (performers?.isActive ?? false)
        entity(performers!, 'Performeurs', 'performeur'),
      if (tags?.isActive ?? false) entity(tags!, 'Tags', 'tag'),
      if (studios?.isActive ?? false) entity(studios!, 'Studio', 'studio'),
      if (groups?.isActive ?? false) entity(groups!, 'Groupe', 'groupe'),
      if (minStars != null) '≥ $minStars ★',
      if (res != null) '≥ ${res.label}',
      if (minDurationMin != null && maxDurationMin != null)
        '$minDurationMin–$maxDurationMin min'
      else if (minDurationMin != null)
        '≥ $minDurationMin min'
      else if (maxDurationMin != null)
        '≤ $maxDurationMin min',
      if (organized != null) organized! ? 'Organisées' : 'Non organisées',
      if (played != null) played! ? 'Déjà vues' : 'Jamais vues',
      if (hasMarkers != null) hasMarkers! ? 'Avec marqueurs' : 'Sans marqueurs',
      if (performerFavorite != null)
        performerFavorite! ? 'Performeur favori' : 'Sans performeur favori',
    ];
  }
}

/// A named scene filter + sort, shown on the home page or as a row.
class SavedView {
  SavedView({
    required this.id,
    required this.name,
    required this.filter,
    this.sort = 'created_at',
    this.descending = true,
    this.query = '',
  });

  final String id;
  String name;
  SceneFilter filter;
  String sort;
  bool descending;
  String query;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filter': filter.toJson(),
    'sort': sort,
    'descending': descending,
    'query': query,
  };

  factory SavedView.fromJson(Map<String, dynamic> j) => SavedView(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    filter: SceneFilter.fromJson(
      (j['filter'] as Map? ?? const {}).cast<String, dynamic>(),
    ),
    sort: j['sort'] as String? ?? 'created_at',
    descending: j['descending'] as bool? ?? true,
    query: j['query'] as String? ?? '',
  );
}
