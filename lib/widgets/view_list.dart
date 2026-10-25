import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import 'cards.dart';
import 'paged_grid.dart';

/// How the items of a kind of view are shown: card, grid size, sorts.
class ViewStyle {
  const ViewStyle._(
    this.maxExtent, {
    this.aspectRatio = 1,
    this.tileHeight,
    required this.sortOptions,
    required this.countLabel,
  });

  /// Max tile width in grids; the tile width in horizontal rows.
  final double maxExtent;
  final double aspectRatio;

  /// Exact tile height for a tile width, when not set by [aspectRatio].
  final double Function(BuildContext context, double width)? tileHeight;
  final List<SortOption> sortOptions;
  final String countLabel;

  static ViewStyle of(BuildContext context, ViewKind kind) => switch (kind) {
    ViewKind.scenes => ViewStyle._(
      sceneExtentOf(context),
      tileHeight: SceneCard.heightFor,
      sortOptions: SortOptions.scenes,
      countLabel: 'scènes',
    ),
    ViewKind.performers => const ViewStyle._(
      180,
      aspectRatio: PerformerCard.aspectRatio,
      sortOptions: SortOptions.performers,
      countLabel: 'performeurs',
    ),
    ViewKind.studios => const ViewStyle._(
      220,
      aspectRatio: EntityCard.aspectRatio,
      sortOptions: SortOptions.studios,
      countLabel: 'studios',
    ),
    ViewKind.groups => const ViewStyle._(
      180,
      aspectRatio: GroupCard.aspectRatio,
      sortOptions: SortOptions.groups,
      countLabel: 'groupes',
    ),
    ViewKind.galleries => const ViewStyle._(
      220,
      aspectRatio: EntityCard.aspectRatio,
      sortOptions: SortOptions.galleries,
      countLabel: 'galeries',
    ),
    ViewKind.tags => const ViewStyle._(
      220,
      aspectRatio: EntityCard.aspectRatio,
      sortOptions: SortOptions.tags,
      countLabel: 'tags',
    ),
    ViewKind.markers => ViewStyle._(
      sceneExtentOf(context),
      tileHeight: MarkerCard.heightFor,
      sortOptions: SortOptions.markers,
      countLabel: 'marqueurs',
    ),
  };

  double heightFor(BuildContext context, double width) =>
      tileHeight?.call(context, width) ?? width / aspectRatio;
}

/// Sorts offered for a kind of view.
List<SortOption> sortsFor(ViewKind kind) => switch (kind) {
  ViewKind.scenes => SortOptions.scenes,
  ViewKind.performers => SortOptions.performers,
  ViewKind.studios => SortOptions.studios,
  ViewKind.groups => SortOptions.groups,
  ViewKind.galleries => SortOptions.galleries,
  ViewKind.tags => SortOptions.tags,
  ViewKind.markers => SortOptions.markers,
};

/// Max scene card width, derived from the column setting.
double sceneExtentOf(BuildContext context) {
  final columns = context.watch<AppState>().gridColumns;
  // Based on the shortest side so landscape simply shows more columns.
  return MediaQuery.sizeOf(context).shortestSide / columns;
}

/// The card of a view item.
Widget viewCard(Object item) => switch (item) {
  Scene s => SceneCard(scene: s),
  Performer p => PerformerCard(performer: p),
  Studio s => StudioCard(studio: s),
  Group g => GroupCard(group: g),
  Gallery g => GalleryCard(gallery: g),
  Tag t => TagCard(tag: t),
  SceneMarker m => MarkerCard(marker: m),
  _ => const SizedBox.shrink(),
};

/// Stable id of a view item, to drop duplicates between pages.
Object viewItemKey(Object item) => switch (item) {
  Scene s => s.id,
  Performer p => p.id,
  Studio s => s.id,
  Group g => g.id,
  Gallery g => g.id,
  Tag t => t.id,
  SceneMarker m => m.id,
  _ => item,
};

IconData viewKindIcon(ViewKind kind) => switch (kind) {
  ViewKind.scenes => Icons.movie_outlined,
  ViewKind.performers => Icons.people_outline,
  ViewKind.studios => Icons.business,
  ViewKind.groups => Icons.video_library_outlined,
  ViewKind.galleries => Icons.photo_library_outlined,
  ViewKind.tags => Icons.label_outline,
  ViewKind.markers => Icons.bookmarks_outlined,
};

/// A saved view as a full grid. Its filter is locked (views are edited
/// from Plus > Vues enregistrées); search and sort can change.
class ViewBrowser extends StatelessWidget {
  const ViewBrowser({super.key, required this.view});
  final SavedView view;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    final style = ViewStyle.of(context, view.kind);
    return PagedGrid<Object>(
      itemKey: viewItemKey,
      fetch: (q) => repo.findForView(view, q),
      sortOptions: style.sortOptions,
      initialSort: view.sort,
      initialDescending: view.descending,
      initialQuery: view.query,
      maxCrossAxisExtent: style.maxExtent,
      childAspectRatio: style.aspectRatio,
      tileHeight: style.tileHeight == null
          ? null
          : (w) => style.heightFor(context, w),
      countLabel: style.countLabel,
      itemBuilder: (_, item, _, _) => viewCard(item),
    );
  }
}
