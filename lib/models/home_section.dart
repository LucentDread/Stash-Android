/// Built-in sections of the default dashboard. With the saved views, they
/// make up both home pages (Plus > Page d'accueil).
enum HomeSection {
  stats('Statistiques'),
  resume('Reprendre la lecture'),
  recent('Ajoutées récemment'),
  releases('Sorties récentes'),
  favoritePerformers('Performeurs favoris'),
  random('Au hasard'),
  galleries('Galeries récentes');

  const HomeSection(this.label);
  final String label;

  /// Id in the page layouts, beside view ids.
  String get id => 'section:$name';

  static HomeSection? fromId(String id) =>
      values.where((s) => s.id == id).firstOrNull;
}
