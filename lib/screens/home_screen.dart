import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/brand_title.dart';
import '../widgets/cards.dart';
import '../widgets/paged_grid.dart';
import '../widgets/view_list.dart';
import 'browse_screens.dart';

/// First tab: the saved views chosen as home page, or the dashboard.
/// A single view fills the page (and names it); several are stacked.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Filters saved in the web UI may have changed since last time.
    context.read<AppState>().refreshWebViews().catchError((Object _) => 0);
  }

  @override
  Widget build(BuildContext context) {
    final views = context.select<AppState, List<SavedView>>((s) => s.homeViews);
    if (views.isEmpty) return const HomeScreen();
    // Keyed on the views' content so that editing them reloads the page.
    final key = ValueKey([for (final v in views) v.toJson()].toString());
    return Scaffold(
      appBar: AppBar(
        title: BrandTitle(
          page: views.length == 1 ? views.single.name : 'Accueil',
        ),
        actions: [
          IconButton(
            tooltip: 'Accueil par défaut',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(standalone: true),
              ),
            ),
          ),
        ],
      ),
      body: views.length == 1
          ? ViewBrowser(key: key, view: views.single)
          : _StackedViews(key: key, views: views),
    );
  }
}

/// Several views one under the other, each with its first items and a
/// button loading more.
class _StackedViews extends StatefulWidget {
  const _StackedViews({super.key, required this.views});
  final List<SavedView> views;

  @override
  State<_StackedViews> createState() => _StackedViewsState();
}

class _StackedViewsState extends State<_StackedViews> {
  int _refresh = 0;

  /// Sort chosen on the home page for each view (by id), until the app
  /// closes; the saved views keep their own.
  final _sorts = <String, (String, bool)>{};

  /// [view] with the sort chosen here, if any.
  SavedView _sorted(SavedView view) {
    final s = _sorts[view.id];
    if (s == null) return view;
    return SavedView.fromJson(view.toJson())
      ..sort = s.$1
      ..descending = s.$2;
  }

  @override
  Widget build(BuildContext context) {
    final version = context.select<AppState, int>((s) => s.dataVersion);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _refresh++),
      child: CustomScrollView(
        // Rebuilt (and reloaded) on pull-to-refresh and after a scan.
        key: ValueKey('$_refresh-$version'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final v in widget.views.map(_sorted))
            _ViewSection(
              // Reloaded from the first page when its sort changes.
              key: ValueKey('${v.id}|${v.sort}|${v.descending}'),
              view: v,
              onSort: (sort, descending) =>
                  setState(() => _sorts[v.id] = (sort, descending)),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _ViewSection extends StatefulWidget {
  const _ViewSection({super.key, required this.view, required this.onSort});
  final SavedView view;
  final void Function(String sort, bool descending) onSort;

  @override
  State<_ViewSection> createState() => _ViewSectionState();
}

class _ViewSectionState extends State<_ViewSection> {
  /// Divisible by 1 to 4 columns, so that full rows are shown.
  static const _perPage = 12;

  final _items = <Object>[];
  final _ids = <Object>{};
  int _count = 0;
  int _page = 0;
  bool _loading = false;
  Object? _error;

  /// Same order on every page for the random sort (see PagedGrid).
  final _seed = Random().nextInt(100000000);

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    final view = widget.view;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<AppState>().repo!.findForView(
        view,
        ListQuery(
          q: view.query,
          page: _page + 1,
          perPage: _perPage,
          sort: view.sort == 'random' ? 'random_$_seed' : view.sort,
          descending: view.descending,
        ),
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _count = result.count;
        _items.addAll(result.items.where((i) => _ids.add(viewItemKey(i))));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  /// Sort of this view only, like the sort bar of the grids.
  Widget _sortBar(BuildContext context) {
    final view = widget.view;
    final options = sortsFor(view.kind);
    final current = options.where((o) => o.value == view.sort).firstOrNull;
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'Trier',
            initialValue: view.sort,
            onSelected: (v) => widget.onSort(v, view.descending),
            itemBuilder: (_) => [
              for (final o in options)
                PopupMenuItem(value: o.value, child: Text(o.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(current?.label ?? 'Trier', style: small),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: view.descending ? 'Décroissant' : 'Croissant',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              view.descending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
            ),
            onPressed: () => widget.onSort(view.sort, !view.descending),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ViewStyle.of(context, widget.view.kind);
    final extent = style.maxExtent;
    final width = MediaQuery.sizeOf(context).width - 2 * gridSpacing;
    final tileHeight = style.heightFor(context, gridTileWidth(width, extent));
    final more = _page > 0 && _items.length < _count;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: widget.view.name,
                      children: [
                        if (_page > 0)
                          TextSpan(
                            text: '  $_count',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewScreen(view: widget.view),
                    ),
                  ),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _sortBar(context)),
        if (_items.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(gridSpacing),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: extent,
                mainAxisExtent: tileHeight,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) => viewCard(_items[i]),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: _error != null
                  ? TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.refresh),
                      label: Text('Erreur : $_error', maxLines: 2),
                    )
                  : _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : _page > 0 && _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Rien pour le moment'),
                    )
                  : more
                  ? OutlinedButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: Text('Afficher plus (${_count - _items.length})'),
                    )
                  : null,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 24)),
      ],
    );
  }
}

/// Dashboard with horizontal rows, similar to the Android TV client.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.standalone = false});

  /// Opened from a custom home page (shows a back button).
  final bool standalone;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _refresh = 0;

  /// A row of the dashboard for a view made in the app.
  Widget _viewRow(
    BuildContext context,
    StashRepository repo,
    SavedView view,
    double sceneWidth,
  ) {
    final style = ViewStyle.of(context, view.kind);
    final width = switch (view.kind) {
      ViewKind.scenes || ViewKind.markers => sceneWidth,
      ViewKind.performers || ViewKind.groups => 130.0,
      _ => 170.0,
    };
    final sort = view.sort == 'random'
        ? 'random_${Random().nextInt(100000000)}'
        : view.sort;
    return _Row<Object>(
      key: ValueKey('view-${view.toJson()}'),
      title: view.name,
      onSeeAll: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ViewScreen(view: view))),
      load: () async => (await repo.findForView(
        view,
        ListQuery(
          q: view.query,
          perPage: 20,
          sort: sort,
          descending: view.descending,
        ),
      )).items,
      itemWidth: width,
      itemHeight: style.heightFor(context, width),
      builder: viewCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final repo = app.repo!;
    final sceneWidth = (MediaQuery.sizeOf(context).shortestSide * 0.62).clamp(
      200.0,
      320.0,
    );
    final sceneHeight = SceneCard.heightFor(context, sceneWidth);

    return Scaffold(
      appBar: AppBar(
        title: widget.standalone
            ? const Text('Accueil par défaut')
            : const BrandTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _refresh++),
        child: ListView(
          // Rebuilt (and reloaded) on pull-to-refresh and after a scan.
          key: ValueKey('$_refresh-${app.dataVersion}'),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _StatsRow(load: repo.stats),
            _Row<Scene>(
              title: 'Reprendre la lecture',
              hideWhenEmpty: true,
              load: () => repo.continueWatching(),
              itemWidth: sceneWidth,
              itemHeight: sceneHeight,
              builder: (s) => SceneCard(scene: s),
            ),
            for (final view in app.views)
              _viewRow(context, repo, view, sceneWidth),
            _Row<Scene>(
              title: 'Ajoutées récemment',
              load: () async => (await repo.findScenes(
                const ListQuery(perPage: 20, sort: 'created_at'),
              )).items,
              itemWidth: sceneWidth,
              itemHeight: sceneHeight,
              builder: (s) => SceneCard(scene: s),
            ),
            _Row<Scene>(
              title: 'Sorties récentes',
              load: () async => (await repo.findScenes(
                const ListQuery(perPage: 20, sort: 'date'),
              )).items,
              itemWidth: sceneWidth,
              itemHeight: sceneHeight,
              builder: (s) => SceneCard(scene: s),
            ),
            _Row<Performer>(
              title: 'Performeurs favoris',
              hideWhenEmpty: true,
              load: () async => (await repo.findPerformers(
                const ListQuery(perPage: 20, sort: 'random'),
                performerFilter: {'filter_favorites': true},
              )).items,
              itemWidth: 130,
              aspectRatio: PerformerCard.aspectRatio,
              builder: (p) => PerformerCard(performer: p),
            ),
            _Row<Scene>(
              title: 'Au hasard',
              load: () async => (await repo.findScenes(
                const ListQuery(perPage: 20, sort: 'random'),
              )).items,
              itemWidth: sceneWidth,
              itemHeight: sceneHeight,
              builder: (s) => SceneCard(scene: s),
            ),
            _Row<Gallery>(
              title: 'Galeries récentes',
              hideWhenEmpty: true,
              load: () async => (await repo.findGalleries(
                const ListQuery(perPage: 20, sort: 'created_at'),
              )).items,
              itemWidth: 170,
              aspectRatio: EntityCard.aspectRatio,
              builder: (g) => GalleryCard(gallery: g),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.load});
  final Future<Stats> Function() load;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stats>(
      future: load(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Serveur injoignable : ${snap.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        final s = snap.data;
        if (s == null) return const SizedBox(height: 8);
        final chips = [
          ('${s.sceneCount}', 'scènes', Icons.movie),
          ('${(s.scenesDuration / 3600).round()}', 'heures', Icons.schedule),
          (formatBytes(s.scenesSize), '', Icons.storage),
          ('${s.performerCount}', 'performeurs', Icons.people),
          ('${s.studioCount}', 'studios', Icons.business),
          ('${s.imageCount}', 'images', Icons.image),
          ('${s.tagCount}', 'tags', Icons.label),
        ];
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (value, label, icon) = chips[i];
              return Chip(
                avatar: Icon(icon, size: 16),
                label: Text('$value $label'.trim()),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        );
      },
    );
  }
}

class _Row<T> extends StatefulWidget {
  const _Row({
    super.key,
    required this.title,
    this.onSeeAll,
    required this.load,
    required this.builder,
    required this.itemWidth,
    this.aspectRatio = 1,
    this.itemHeight,
    this.hideWhenEmpty = false,
  });

  final String title;
  final Future<List<T>> Function() load;
  final Widget Function(T item) builder;
  final double itemWidth;
  final double aspectRatio;

  /// Exact row height; defaults to itemWidth / aspectRatio.
  final double? itemHeight;
  final bool hideWhenEmpty;
  final VoidCallback? onSeeAll;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  late final Future<List<T>> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final height = widget.itemHeight ?? widget.itemWidth / widget.aspectRatio;
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        final items = snap.data;
        if (snap.hasError ||
            (widget.hideWhenEmpty && items != null && items.isEmpty)) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: widget.onSeeAll == null
                  ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                  : const EdgeInsets.fromLTRB(16, 6, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.onSeeAll != null)
                    TextButton(
                      onPressed: widget.onSeeAll,
                      child: const Text('Voir tout'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: height,
              child: items == null
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? const Center(child: Text('Rien pour le moment'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => SizedBox(
                        width: widget.itemWidth,
                        child: widget.builder(items[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
