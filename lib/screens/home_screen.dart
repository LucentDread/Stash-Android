import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/home_section.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/brand_title.dart';
import '../widgets/cards.dart';
import '../widgets/paged_grid.dart';
import '../widgets/view_list.dart';
import 'browse_screens.dart';

/// First tab: the custom home page (views and dashboard sections, chosen
/// in Plus > Page d'accueil), or the dashboard. A single view fills the
/// page (and names it); anything else is stacked.
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
    final app = context.watch<AppState>();
    final layout = app.homeLayout;
    if (layout.isEmpty) return const HomeScreen();
    final single = layout.length == 1 ? app.viewById(layout.single) : null;
    // Keyed on the views' content so that editing them reloads the page.
    final key = ValueKey(
      [for (final id in layout) app.viewById(id)?.toJson() ?? id].toString(),
    );
    return Scaffold(
      appBar: AppBar(
        title: BrandTitle(page: single?.name ?? 'Accueil'),
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
      body: single != null
          ? ViewBrowser(key: key, view: single)
          : _StackedHome(key: key, ids: layout),
    );
  }
}

/// Views and dashboard sections one under the other; each view shows its
/// first items and a button loading more.
class _StackedHome extends StatefulWidget {
  const _StackedHome({super.key, required this.ids});

  /// View and [HomeSection] ids.
  final List<String> ids;

  @override
  State<_StackedHome> createState() => _StackedHomeState();
}

class _StackedHomeState extends State<_StackedHome> {
  int _refresh = 0;

  /// Sort chosen on the home page for each view (by id), until the app
  /// closes; the saved views keep their own.
  final _sorts = <String, (String, bool)>{};

  Widget _viewSection(SavedView v) => _ViewSection(
    // Reloaded from the first page when its sort changes.
    key: ValueKey('${v.id}|${v.sort}|${v.descending}'),
    view: v,
    onSort: (sort, descending) =>
        setState(() => _sorts[v.id] = (sort, descending)),
  );

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
    final app = context.read<AppState>();
    final version = context.select<AppState, int>((s) => s.dataVersion);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _refresh++),
      child: CustomScrollView(
        // Rebuilt (and reloaded) on pull-to-refresh and after a scan.
        key: ValueKey('$_refresh-$version'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final id in widget.ids)
            if (HomeSection.fromId(id) case final section?)
              SliverToBoxAdapter(
                key: ValueKey(id),
                child: HomeSectionRow(section),
              )
            else if (app.viewById(id) case final view?)
              _viewSection(_sorted(view)),
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
              itemBuilder: (_, i) => viewCard(_items[i], _items, i),
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
    final sceneWidth = homeSceneWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: widget.standalone
            ? const Text('Accueil par défaut')
            : const BrandTitle(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _refresh++),
        // A column rather than a lazy list: rows scrolled away are kept,
        // not rebuilt (and reloaded, changing height) when coming back up.
        child: SingleChildScrollView(
          // Rebuilt (and reloaded) on pull-to-refresh and after a scan.
          key: ValueKey('$_refresh-${app.dataVersion}'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final id in app.dashboardLayout)
                if (HomeSection.fromId(id) case final section?)
                  HomeSectionRow(section, key: ValueKey(id))
                else if (app.viewById(id) case final view?)
                  _viewRow(context, repo, view, sceneWidth),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width of scene cards in the horizontal rows.
double homeSceneWidth(BuildContext context) =>
    (MediaQuery.sizeOf(context).shortestSide * 0.62).clamp(200.0, 320.0);

/// A built-in section of the dashboard, also usable on the custom home.
class HomeSectionRow extends StatelessWidget {
  const HomeSectionRow(this.section, {super.key});
  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    final sceneWidth = homeSceneWidth(context);
    final sceneHeight = SceneCard.heightFor(context, sceneWidth);
    Widget scenes(Future<List<Scene>> Function() load, {bool hide = false}) =>
        _Row<Scene>(
          title: section.label,
          hideWhenEmpty: hide,
          load: load,
          itemWidth: sceneWidth,
          itemHeight: sceneHeight,
          builder: (s) => SceneCard(scene: s),
        );
    Future<List<Scene>> Function() sorted(String sort) =>
        () async =>
            (await repo.findScenes(ListQuery(perPage: 20, sort: sort))).items;

    return switch (section) {
      HomeSection.stats => _StatsRow(load: repo.stats),
      HomeSection.resume => scenes(repo.continueWatching, hide: true),
      HomeSection.recent => scenes(sorted('created_at')),
      HomeSection.releases => scenes(sorted('date')),
      HomeSection.random => scenes(
        sorted('random_${Random().nextInt(100000000)}'),
      ),
      HomeSection.favoritePerformers => _Row<Performer>(
        title: section.label,
        hideWhenEmpty: true,
        load: () async => (await repo.findPerformers(
          const ListQuery(perPage: 20, sort: 'random'),
          performerFilter: {'filter_favorites': true},
        )).items,
        itemWidth: 130,
        aspectRatio: PerformerCard.aspectRatio,
        builder: (p) => PerformerCard(performer: p),
      ),
      HomeSection.galleries => _Row<Gallery>(
        title: section.label,
        hideWhenEmpty: true,
        load: () async => (await repo.findGalleries(
          const ListQuery(perPage: 20, sort: 'created_at'),
        )).items,
        itemWidth: 170,
        aspectRatio: EntityCard.aspectRatio,
        builder: (g) => GalleryCard(gallery: g),
      ),
    };
  }
}

class _StatsRow extends StatefulWidget {
  const _StatsRow({required this.load});
  final Future<Stats> Function() load;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  // Loaded once: a new request on each rebuild changed the row's height
  // while loading, moving the page.
  late final Future<Stats> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Stats>(
      future: _future,
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
