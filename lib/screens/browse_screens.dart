import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/paged_grid.dart';

/// Max card width for scene grids, derived from the column setting.
double sceneExtent(BuildContext context) {
  final columns = context.watch<AppState>().gridColumns;
  // Based on the shortest side so landscape simply shows more columns.
  return MediaQuery.sizeOf(context).shortestSide / columns;
}

Widget sceneGrid(
  BuildContext context, {
  EntityFilter? entity,
  bool showToolbar = true,
}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<Scene>(
    fetch: (q) => repo.findScenes(q, entity: entity),
    sortOptions: SortOptions.scenes,
    initialSort: entity == null ? 'created_at' : 'date',
    maxCrossAxisExtent: sceneExtent(context),
    childAspectRatio: sceneCardAspectRatio,
    showToolbar: showToolbar,
    countLabel: 'scènes',
    itemBuilder: (_, s, _, _) => SceneCard(scene: s),
  );
}

Widget performerGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<Performer>(
    fetch: (q) => repo.findPerformers(q, entity: entity),
    sortOptions: SortOptions.performers,
    initialSort: entity == null ? 'name' : 'scenes_count',
    initialDescending: entity != null,
    maxCrossAxisExtent: 180,
    childAspectRatio: PerformerCard.aspectRatio,
    countLabel: 'performeurs',
    itemBuilder: (_, p, _, _) => PerformerCard(performer: p),
  );
}

Widget galleryGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<Gallery>(
    fetch: (q) => repo.findGalleries(q, entity: entity),
    sortOptions: SortOptions.galleries,
    maxCrossAxisExtent: 220,
    childAspectRatio: EntityCard.aspectRatio,
    countLabel: 'galeries',
    itemBuilder: (_, g, _, _) => GalleryCard(gallery: g),
  );
}

Widget markerGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<SceneMarker>(
    fetch: (q) => repo.findMarkers(q, entity: entity),
    sortOptions: SortOptions.markers,
    maxCrossAxisExtent: sceneExtent(context),
    childAspectRatio: sceneCardAspectRatio,
    countLabel: 'marqueurs',
    emptyText: 'Aucun marqueur',
    itemBuilder: (_, m, _, _) => MarkerCard(marker: m),
  );
}

class _BrowseScaffold extends StatelessWidget {
  const _BrowseScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );
}

class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: 'Scènes', child: sceneGrid(context));
}

class PerformersScreen extends StatelessWidget {
  const PerformersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: 'Performeurs', child: performerGrid(context));
}

class GalleriesScreen extends StatelessWidget {
  const GalleriesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: 'Galeries', child: galleryGrid(context));
}

class MarkersScreen extends StatelessWidget {
  const MarkersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: 'Marqueurs', child: markerGrid(context));
}

class StudiosScreen extends StatelessWidget {
  const StudiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: 'Studios',
      child: PagedGrid<Studio>(
        fetch: repo.findStudios,
        sortOptions: SortOptions.studios,
        initialDescending: false,
        maxCrossAxisExtent: 220,
        childAspectRatio: EntityCard.aspectRatio,
        countLabel: 'studios',
        itemBuilder: (_, s, _, _) => StudioCard(studio: s),
      ),
    );
  }
}

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: 'Tags',
      child: PagedGrid<Tag>(
        fetch: repo.findTags,
        sortOptions: SortOptions.tags,
        initialDescending: false,
        maxCrossAxisExtent: 220,
        childAspectRatio: EntityCard.aspectRatio,
        countLabel: 'tags',
        itemBuilder: (_, t, _, _) => TagCard(tag: t),
      ),
    );
  }
}
