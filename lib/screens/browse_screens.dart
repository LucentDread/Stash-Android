import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/paged_grid.dart';
import 'scene_filter_screen.dart';

/// Max card width for scene grids, derived from the column setting.
double sceneExtent(BuildContext context) {
  final columns = context.watch<AppState>().gridColumns;
  // Based on the shortest side so landscape simply shows more columns.
  return MediaQuery.sizeOf(context).shortestSide / columns;
}

Widget sceneGrid(BuildContext context, {EntityFilter? entity}) {
  if (entity?.kind == 'groups') {
    return ScenesBrowser(
      entity: entity,
      sortOptions: SortOptions.groupScenes,
      initialSort: 'group_scene_number',
      initialDescending: false,
    );
  }
  return ScenesBrowser(
    entity: entity,
    initialSort: entity == null ? 'created_at' : 'date',
  );
}

/// Scene grid with search, sort, filters and saved views.
class ScenesBrowser extends StatefulWidget {
  const ScenesBrowser({
    super.key,
    this.entity,
    this.view,
    this.sortOptions = SortOptions.scenes,
    this.initialSort,
    this.initialDescending = true,
  });

  final EntityFilter? entity;

  /// Saved view to start from; its filter and sort are applied.
  final SavedView? view;
  final List<SortOption> sortOptions;
  final String? initialSort;
  final bool initialDescending;

  @override
  State<ScenesBrowser> createState() => _ScenesBrowserState();
}

class _ScenesBrowserState extends State<ScenesBrowser> {
  late SceneFilter _filter = widget.view?.filter.copy() ?? SceneFilter();
  late String _query = widget.view?.query ?? '';
  late String? _sort = widget.view?.sort ?? widget.initialSort;
  late bool _descending = widget.view?.descending ?? widget.initialDescending;
  int _filterVersion = 0;

  void _setFilter(SceneFilter f) => setState(() {
    _filter = f;
    _filterVersion++;
  });

  Future<void> _editFilter() async {
    final f = await Navigator.of(context).push<SceneFilter>(
      MaterialPageRoute(builder: (_) => SceneFilterScreen(initial: _filter)),
    );
    if (f != null) _setFilter(f);
  }

  SavedView _currentView({required String id, required String name}) =>
      SavedView(
        id: id,
        name: name,
        filter: _filter.copy(),
        sort: _sort ?? 'created_at',
        descending: _descending,
        query: _query,
      );

  Future<void> _saveAsNew() async {
    final app = context.read<AppState>();
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (_) => const _SaveViewDialog(),
    );
    if (result == null || !mounted) return;
    final (name, asHome) = result;
    final view = _currentView(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    app.saveView(view);
    if (asHome) app.homeViewId = view.id;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Vue « $name » enregistrée')));
  }

  void _updateView() {
    final v = widget.view!;
    context.read<AppState>().saveView(_currentView(id: v.id, name: v.name));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Vue « ${v.name} » mise à jour')));
  }

  Widget? _chips() {
    if (_filter.isEmpty) return null;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          for (final d in _filter.describe())
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(d),
                visualDensity: VisualDensity.compact,
                onPressed: _editFilter,
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.clear, size: 16),
            label: const Text('Effacer'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _setFilter(SceneFilter()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    final count = _filter.activeCount;
    return PagedGrid<Scene>(
      fetch: (q) => repo.findScenes(
        q,
        entity: widget.entity,
        sceneFilter: _filter.toGraphQL(),
      ),
      sortOptions: widget.sortOptions,
      initialSort: _sort,
      initialDescending: _descending,
      initialQuery: _query,
      onQueryChanged: (q, sort, desc) {
        _query = q;
        _sort = sort;
        _descending = desc;
      },
      reloadKey: _filterVersion,
      maxCrossAxisExtent: sceneExtent(context),
      childAspectRatio: sceneCardAspectRatio,
      countLabel: 'scènes',
      header: _chips(),
      actions: [
        IconButton(
          tooltip: 'Filtres',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _editFilter,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.bookmark_add_outlined),
          tooltip: 'Vues',
          onSelected: (v) => switch (v) {
            'update' => _updateView(),
            _ => _saveAsNew(),
          },
          itemBuilder: (_) => [
            if (widget.view != null)
              PopupMenuItem(
                value: 'update',
                child: Text('Mettre à jour « ${widget.view!.name} »'),
              ),
            const PopupMenuItem(
              value: 'new',
              child: Text('Enregistrer comme nouvelle vue…'),
            ),
          ],
        ),
      ],
      itemBuilder: (_, s, _, _) => SceneCard(scene: s),
    );
  }
}

class _SaveViewDialog extends StatefulWidget {
  const _SaveViewDialog();

  @override
  State<_SaveViewDialog> createState() => _SaveViewDialogState();
}

class _SaveViewDialogState extends State<_SaveViewDialog> {
  final _name = TextEditingController();
  bool _asHome = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, (name, _asHome));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer la vue'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom'),
            onSubmitted: (_) => _submit(),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Utiliser comme page d\'accueil'),
            value: _asHome,
            onChanged: (v) => setState(() => _asHome = v ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
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

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: 'Groupes',
      child: PagedGrid<Group>(
        fetch: repo.findGroups,
        sortOptions: SortOptions.groups,
        initialDescending: false,
        maxCrossAxisExtent: 180,
        childAspectRatio: GroupCard.aspectRatio,
        countLabel: 'groupes',
        itemBuilder: (_, g, _, _) => GroupCard(group: g),
      ),
    );
  }
}

/// Scenes of a saved view, full screen.
class ViewScreen extends StatelessWidget {
  const ViewScreen({super.key, required this.view});
  final SavedView view;

  @override
  Widget build(BuildContext context) => _BrowseScaffold(
    title: view.name,
    child: ScenesBrowser(view: view),
  );
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
