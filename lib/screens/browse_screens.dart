import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/cards.dart';
import '../widgets/brand_title.dart';
import '../widgets/paged_grid.dart';
import '../widgets/view_list.dart';
import 'scene_filter_screen.dart';

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
    this.sortOptions = SortOptions.scenes,
    this.initialSort,
    this.initialDescending = true,
  });

  final EntityFilter? entity;
  final List<SortOption> sortOptions;
  final String? initialSort;
  final bool initialDescending;

  @override
  State<ScenesBrowser> createState() => _ScenesBrowserState();
}

class _ScenesBrowserState extends State<ScenesBrowser> {
  SceneFilter _filter = SceneFilter();
  String _query = '';
  late String? _sort = widget.initialSort;
  late bool _descending = widget.initialDescending;
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
    if (asHome) app.setHomeView(view.id, true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr.viewSaved(name))));
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
            label: Text(tr.clear),
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
      itemKey: (item) => item.id,
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
      maxCrossAxisExtent: sceneExtentOf(context),
      tileHeight: (w) => SceneCard.heightFor(context, w),
      countLabel: tr.countScenes,
      header: _chips(),
      actions: [
        IconButton(
          tooltip: tr.filters,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _editFilter,
        ),
        IconButton(
          tooltip: tr.saveAsNewView,
          icon: const Icon(Icons.bookmark_add_outlined),
          onPressed: _saveAsNew,
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
      title: Text(tr.saveView),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: tr.sortName),
            onSubmitted: (_) => _submit(),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr.showOnHome),
            value: _asHome,
            onChanged: (v) => setState(() => _asHome = v ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(tr.save)),
      ],
    );
  }
}

Widget performerGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<Performer>(
    itemKey: (item) => item.id,
    fetch: (q) => repo.findPerformers(q, entity: entity),
    sortOptions: SortOptions.performers,
    initialSort: entity == null ? 'name' : 'scenes_count',
    initialDescending: entity != null,
    maxCrossAxisExtent: 180,
    childAspectRatio: PerformerCard.aspectRatio,
    countLabel: tr.countPerformers,
    itemBuilder: (_, p, _, _) => PerformerCard(performer: p),
  );
}

Widget galleryGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<Gallery>(
    itemKey: (item) => item.id,
    fetch: (q) => repo.findGalleries(q, entity: entity),
    sortOptions: SortOptions.galleries,
    maxCrossAxisExtent: 220,
    childAspectRatio: EntityCard.aspectRatio,
    countLabel: tr.countGalleries,
    itemBuilder: (_, g, _, _) => GalleryCard(gallery: g),
  );
}

Widget markerGrid(BuildContext context, {EntityFilter? entity}) {
  final repo = context.read<AppState>().repo!;
  return PagedGrid<SceneMarker>(
    itemKey: (item) => item.id,
    fetch: (q) => repo.findMarkers(q, entity: entity),
    sortOptions: SortOptions.markers,
    maxCrossAxisExtent: sceneExtentOf(context),
    tileHeight: (w) => MarkerCard.heightFor(context, w),
    countLabel: tr.countMarkers,
    emptyText: tr.noMarkers,
    itemBuilder: (_, m, _, _) => MarkerCard(marker: m),
  );
}

class _BrowseScaffold extends StatelessWidget {
  const _BrowseScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: BrandTitle(page: title)),
    body: child,
  );
}

class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: tr.scenes, child: sceneGrid(context));
}

class PerformersScreen extends StatelessWidget {
  const PerformersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: tr.performers, child: performerGrid(context));
}

class GalleriesScreen extends StatelessWidget {
  const GalleriesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: tr.galleries, child: galleryGrid(context));
}

/// Every image of the library, whatever its gallery.
class ImagesScreen extends StatelessWidget {
  const ImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: tr.images,
      child: PagedGrid<StashImage>(
        itemKey: (item) => item.id,
        fetch: repo.findImages,
        sortOptions: SortOptions.images,
        maxCrossAxisExtent: 160,
        countLabel: tr.countImages,
        emptyText: tr.noImages,
        itemBuilder: (_, img, i, all) =>
            ImageTile(image: img, all: all, index: i),
      ),
    );
  }
}

class MarkersScreen extends StatelessWidget {
  const MarkersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      _BrowseScaffold(title: tr.markers, child: markerGrid(context));
}

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: tr.groups,
      child: PagedGrid<Group>(
        itemKey: (item) => item.id,
        fetch: repo.findGroups,
        sortOptions: SortOptions.groups,
        initialDescending: false,
        maxCrossAxisExtent: 180,
        childAspectRatio: GroupCard.aspectRatio,
        countLabel: tr.countGroups,
        itemBuilder: (_, g, _, _) => GroupCard(group: g),
      ),
    );
  }
}

/// A saved view, full screen.
class ViewScreen extends StatelessWidget {
  const ViewScreen({super.key, required this.view});
  final SavedView view;

  @override
  Widget build(BuildContext context) => _BrowseScaffold(
    title: view.name,
    child: ViewBrowser(view: view),
  );
}

class StudiosScreen extends StatelessWidget {
  const StudiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return _BrowseScaffold(
      title: tr.studios,
      child: PagedGrid<Studio>(
        itemKey: (item) => item.id,
        fetch: repo.findStudios,
        sortOptions: SortOptions.studios,
        initialDescending: false,
        maxCrossAxisExtent: 220,
        childAspectRatio: EntityCard.aspectRatio,
        countLabel: tr.countStudios,
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
      title: tr.tags,
      child: PagedGrid<Tag>(
        itemKey: (item) => item.id,
        fetch: repo.findTags,
        sortOptions: SortOptions.tags,
        initialDescending: false,
        maxCrossAxisExtent: 220,
        childAspectRatio: EntityCard.aspectRatio,
        countLabel: tr.countTags,
        itemBuilder: (_, t, _, _) => TagCard(tag: t),
      ),
    );
  }
}
