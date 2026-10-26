import '../l10n/l10n.dart';

/// Built-in sections of the default dashboard. With the saved views, they
/// make up both home pages (Plus > Page d'accueil).
enum HomeSection {
  stats,
  resume,
  recent,
  releases,
  favoritePerformers,
  random,
  galleries;

  String get label => switch (this) {
    stats => tr.sectionStats,
    resume => tr.sectionResume,
    recent => tr.sectionRecent,
    releases => tr.sectionReleases,
    favoritePerformers => tr.sectionFavoritePerformers,
    random => tr.sectionRandom,
    galleries => tr.sectionGalleries,
  };

  /// Id in the page layouts, beside view ids.
  String get id => 'section:$name';

  static HomeSection? fromId(String id) =>
      values.where((s) => s.id == id).firstOrNull;
}
