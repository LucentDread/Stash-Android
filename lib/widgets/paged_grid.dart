import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/downloads.dart';
import 'async_view.dart';
import 'data_refresh.dart';
import 'download_button.dart';
import 'insets.dart';

typedef PageFetcher<T> = Future<ResultPage<T>> Function(ListQuery query);

/// Space between grid tiles, and around the grid.
const gridSpacing = 8.0;

/// Tile width as computed by [SliverGridDelegateWithMaxCrossAxisExtent]
/// with [gridSpacing], for a grid [width] without its padding.
double gridTileWidth(double width, double maxCrossAxisExtent) {
  final count = (width / (maxCrossAxisExtent + gridSpacing)).ceil().clamp(
    1,
    1000,
  );
  return (width - gridSpacing * (count - 1)) / count;
}

/// Infinite-scrolling grid backed by a paginated Stash query, with an
/// optional search field and sort selector.
class PagedGrid<T> extends StatefulWidget {
  const PagedGrid({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.sortOptions = const [],
    this.initialSort,
    this.initialDescending = true,
    this.maxCrossAxisExtent = 220,
    this.childAspectRatio = 1,
    this.tileHeight,
    this.showToolbar = true,
    this.emptyText,
    this.countLabel,
    this.initialQuery = '',
    this.actions = const [],
    this.header,
    this.reloadKey,
    this.onQueryChanged,
    this.itemKey,
    this.downloadKind,
  }) : assert(downloadKind == null || itemKey != null);

  final PageFetcher<T> fetch;
  final Widget Function(BuildContext context, T item, int index, List<T> all)
  itemBuilder;
  final List<SortOption> sortOptions;
  final String? initialSort;
  final bool initialDescending;
  final double maxCrossAxisExtent;
  final double childAspectRatio;

  /// Exact tile height for a given tile width; overrides [childAspectRatio].
  final double Function(double tileWidth)? tileHeight;
  final bool showToolbar;
  final String? emptyText;

  /// Item count as shown above the grid, e.g. "12 scenes".
  final String Function(int count)? countLabel;
  final String initialQuery;

  /// Extra buttons shown next to the sort selector.
  final List<Widget> actions;

  /// Widget shown under the toolbar (e.g. active filter chips).
  final Widget? header;

  /// When this value changes, the list is reloaded from the first page.
  final Object? reloadKey;

  /// Called when the search text or the sort changes.
  final void Function(String q, String? sort, bool descending)? onQueryChanged;

  /// Identity of an item: an item already shown is not added again when
  /// the server data shifts between two pages.
  final Object Function(T item)? itemKey;

  /// Items that can be downloaded: a button selects several of them (by
  /// [itemKey], their id) to download at once.
  final OfflineKind? downloadKind;

  @override
  State<PagedGrid<T>> createState() => _PagedGridState<T>();
}

class _PagedGridState<T> extends State<PagedGrid<T>> with DataRefresh {
  static const _perPage = 40;

  final _items = <T>[];
  final _keys = <Object>{};

  /// Seed for the "random" sort. Plain `random` reshuffles on every request,
  /// so pages would overlap; `random_<seed>` keeps one order for all pages
  /// (as the web UI does). A new seed is drawn when the list reloads.
  int _seed = _newSeed();
  static int _newSeed() => Random().nextInt(100000000);
  final _scroll = ScrollController();
  late final _search = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;

  int _count = 0;
  int _page = 0;
  bool _loading = false;
  Object? _error;
  late String? _sort =
      widget.initialSort ?? widget.sortOptions.firstOrNull?.value;
  late bool _descending = widget.initialDescending;
  int _generation = 0;

  /// Ids of the selected items while selecting, else null.
  Set<String>? _selected;

  String _idOf(T item) => '${widget.itemKey!(item)}';

  void _toggle(T item) => setState(() {
    final id = _idOf(item);
    _selected!.contains(id) ? _selected!.remove(id) : _selected!.add(id);
  });

  Future<void> _downloadSelected() async {
    // In list order.
    final ids = [
      for (final item in _items)
        if (_selected!.contains(_idOf(item))) _idOf(item),
    ];
    if (await downloadAll(context, widget.downloadKind!, ids) && mounted) {
      setState(() => _selected = null);
    }
  }

  /// Replaces the toolbar while selecting.
  Widget _selectionBar(BuildContext context) {
    final selected = _selected!;
    final all = _items.isNotEmpty && selected.length >= _items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: tr.cancel,
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selected = null),
          ),
          Expanded(
            child: Text(
              tr.countSelected(selected.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => setState(
              () => all ? selected.clear() : selected.addAll(_items.map(_idOf)),
            ),
            child: Text(all ? tr.selectNone : tr.selectAll),
          ),
          IconButton.filledTonal(
            tooltip: tr.download,
            icon: const Icon(Icons.download_outlined),
            onPressed: selected.isEmpty ? null : _downloadSelected,
          ),
        ],
      ),
    );
  }

  Widget get _selectButton => IconButton(
    tooltip: tr.select,
    icon: const Icon(Icons.checklist),
    onPressed: () => setState(() => _selected = {}),
  );

  /// [tile] covered, while selecting, by a layer that toggles it.
  Widget _selectable(T item, Widget tile) {
    final selected = _selected;
    if (selected == null) return tile;
    final on = selected.contains(_idOf(item));
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        tile,
        Positioned.fill(
          child: Material(
            color: on
                ? scheme.primary.withValues(alpha: 0.25)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: on
                  ? BorderSide(color: scheme.primary, width: 3)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _toggle(item),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    on ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: on ? scheme.primary : Colors.white,
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasMore => _page == 0 || _items.length < _count;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void didUpdateWidget(PagedGrid<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) {
      // Reset after this build: didUpdateWidget runs inside the parent's.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reset();
      });
    }
  }

  void _notifyQuery() =>
      widget.onQueryChanged?.call(_search.text.trim(), _sort, _descending);

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 800) _loadMore();
  }

  Future<void> _reset() async {
    _generation++;
    setState(() {
      _items.clear();
      _keys.clear();
      _seed = _newSeed();
      _count = 0;
      _page = 0;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _error != null) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final result = await widget.fetch(
        ListQuery(
          q: _search.text.trim(),
          page: _page + 1,
          perPage: _perPage,
          sort: _sort == 'random' ? 'random_$_seed' : _sort,
          descending: _descending,
        ),
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _page++;
        _count = result.count;
        final key = widget.itemKey;
        _items.addAll(
          key == null
              ? result.items
              : result.items.where((item) => _keys.add(key(item))),
        );
        _loading = false;
      });
      // Fill the screen if the first page did not make it scrollable.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scroll.hasClients &&
            _scroll.position.extentAfter < 800) {
          _loadMore();
        }
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _notifyQuery();
      _reset();
    });
  }

  Widget _toolbar(BuildContext context) {
    final current = widget.sortOptions
        .where((o) => o.value == _sort)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _notifyQuery();
                        _reset();
                      },
                    ),
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _page == 0
                      ? ''
                      : (widget.countLabel ?? tr.countItems)(_count),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (widget.sortOptions.isNotEmpty) ...[
                PopupMenuButton<String>(
                  initialValue: _sort,
                  onSelected: (v) {
                    _sort = v;
                    _notifyQuery();
                    _reset();
                  },
                  itemBuilder: (_) => [
                    for (final o in widget.sortOptions)
                      PopupMenuItem(value: o.value, child: Text(o.label)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 4),
                        Text(current?.label ?? tr.sort),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _descending ? tr.descending : tr.ascending,
                  icon: Icon(
                    _descending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                  ),
                  onPressed: () {
                    _descending = !_descending;
                    _notifyQuery();
                    _reset();
                  },
                ),
              ],
              ...widget.actions,
              if (widget.downloadKind != null) _selectButton,
            ],
          ),
        ],
      ),
    );
  }

  static const _spacing = gridSpacing;
  static const _padding = gridSpacing;

  double _tileWidth(double gridWidth) =>
      gridTileWidth(gridWidth - 2 * _padding, widget.maxCrossAxisExtent);

  Widget _body(BuildContext context) {
    if (_items.isEmpty) {
      if (_error != null) {
        return ErrorView(error: _error!, onRetry: _reset);
      }
      if (_loading || _page == 0) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(widget.emptyText ?? tr.noResults)),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, box) => GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: withNavBar(context, const EdgeInsets.all(_padding)),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: widget.maxCrossAxisExtent,
          childAspectRatio: widget.childAspectRatio,
          mainAxisExtent: widget.tileHeight?.call(_tileWidth(box.maxWidth)),
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
        ),
        itemCount: _items.length + (_hasMore || _error != null ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            if (_error != null) {
              return Center(
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _error = null);
                    _loadMore();
                  },
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          return _selectable(
            _items[i],
            widget.itemBuilder(context, _items[i], i, _items),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchServerData(_reset);
    return PopScope(
      // Back leaves the selection first.
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Column(
        children: [
          if (_selected != null)
            _selectionBar(context)
          else if (widget.showToolbar)
            _toolbar(context)
          else if (widget.downloadKind != null)
            Align(alignment: Alignment.centerRight, child: _selectButton),
          ?widget.header,
          Expanded(
            child: RefreshIndicator(onRefresh: _reset, child: _body(context)),
          ),
        ],
      ),
    );
  }
}
