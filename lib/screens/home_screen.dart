import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/cards.dart';

/// Dashboard with horizontal rows, similar to the Android TV client.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppState>().repo!;
    final sceneWidth = (MediaQuery.sizeOf(context).shortestSide * 0.62).clamp(
      200.0,
      320.0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Stash')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _refresh++),
        child: ListView(
          key: ValueKey(_refresh),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _StatsRow(load: repo.stats),
            _Row<Scene>(
              title: 'Reprendre la lecture',
              hideWhenEmpty: true,
              load: () => repo.continueWatching(),
              itemWidth: sceneWidth,
              aspectRatio: sceneCardAspectRatio,
              builder: (s) => SceneCard(scene: s),
            ),
            _Row<Scene>(
              title: 'Ajoutées récemment',
              load: () async => (await repo.findScenes(
                const ListQuery(perPage: 20, sort: 'created_at'),
              )).items,
              itemWidth: sceneWidth,
              aspectRatio: sceneCardAspectRatio,
              builder: (s) => SceneCard(scene: s),
            ),
            _Row<Scene>(
              title: 'Sorties récentes',
              load: () async => (await repo.findScenes(
                const ListQuery(perPage: 20, sort: 'date'),
              )).items,
              itemWidth: sceneWidth,
              aspectRatio: sceneCardAspectRatio,
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
              aspectRatio: sceneCardAspectRatio,
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
    required this.title,
    required this.load,
    required this.builder,
    required this.itemWidth,
    required this.aspectRatio,
    this.hideWhenEmpty = false,
  });

  final String title;
  final Future<List<T>> Function() load;
  final Widget Function(T item) builder;
  final double itemWidth;
  final double aspectRatio;
  final bool hideWhenEmpty;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  late final Future<List<T>> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final height = widget.itemWidth / widget.aspectRatio;
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
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
