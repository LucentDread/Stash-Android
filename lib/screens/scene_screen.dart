import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/data_refresh.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/download_button.dart';
import '../widgets/net_image.dart';
import 'edit/editors.dart';

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key, required this.sceneId});
  final String sceneId;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> with DataRefresh {
  late final _repo = context.read<AppState>().repo!;
  Scene? _scene;
  Object? _error;
  int? _oCounter;
  int? _rating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await _repo.findScene(widget.sceneId);
      if (!mounted) return;
      setState(() {
        _scene = s;
        _oCounter = s.oCounter;
        _rating = s.rating100;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _play({double? start}) async {
    await playScene(context, widget.sceneId, start: start);
    // Refresh resume position and play count.
    if (mounted) _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    watchServerData(_load);
    final s = _scene;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _error != null
            ? ErrorView(error: _error!, onRetry: _load)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final f = s.file;
    final resume = s.resumeTime ?? 0;
    final canResume = resume > 5 && resume < s.duration - 5;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            actions: [
              DownloadButton(
                kind: OfflineKind.scene,
                id: s.id,
                sizeHint: s.file?.size,
              ),
              EditButton(onEdit: () => editScene(context, s), onSaved: _load),
            ],
            expandedHeight: MediaQuery.sizeOf(context).width * 9 / 16,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _play(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(s.screenshot, placeholderIcon: Icons.movie),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent],
                          stops: [0, 0.4],
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 72,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text(s.displayTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    if (s.date != null) Text(s.date!),
                    if (s.duration > 0) Text(formatDuration(s.duration)),
                    if (f != null && resolutionLabel(f.width, f.height) != null)
                      Text(resolutionLabel(f.width, f.height)!),
                    if (s.playCount > 0) Text('${s.playCount} lectures'),
                  ],
                ),
                if (s.studio != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => openStudio(context, s.studio!.id),
                    child: Text(
                      s.studio!.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _play(start: canResume ? null : 0),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          canResume
                              ? 'Reprendre à ${formatDuration(resume)}'
                              : 'Lire',
                        ),
                      ),
                    ),
                    if (canResume) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _play(start: 0),
                        child: const Text('Depuis le début'),
                      ),
                    ],
                    if (resume > 0)
                      IconButton(
                        tooltip: 'Oublier la position de reprise',
                        icon: const Icon(Icons.history_toggle_off),
                        onPressed: () => _run(() async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _repo.resetResume(s.id);
                          await _load();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Position de reprise effacée'),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StarRating(
                      rating100: _rating,
                      onChanged: (r) => _run(() async {
                        final old = _rating;
                        setState(() => _rating = r);
                        try {
                          await _repo.rateScene(s.id, r);
                        } catch (_) {
                          if (mounted) setState(() => _rating = old);
                          rethrow;
                        }
                      }),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _run(() async {
                        final c = await _repo.addO(s.id);
                        if (mounted) setState(() => _oCounter = c);
                      }),
                      // Long press undoes the last increment.
                      onLongPress: (_oCounter ?? 0) == 0
                          ? null
                          : () => _run(() async {
                              final c = await _repo.removeO(s.id);
                              if (mounted) setState(() => _oCounter = c);
                            }),
                      icon: const Icon(Icons.water_drop_outlined),
                      label: Text('${_oCounter ?? 0}'),
                    ),
                  ],
                ),
                if (s.performers.isNotEmpty)
                  Section(
                    title: 'Performeurs',
                    child: RefChips(
                      refs: s.performers,
                      icon: Icons.person,
                      onTap: (r) => openPerformer(context, r.id),
                    ),
                  ),
                if (s.markers.isNotEmpty)
                  Section(
                    title: 'Marqueurs',
                    child: SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: s.markers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final m = s.markers[i];
                          return SizedBox(
                            width: 160,
                            child: InkWell(
                              onTap: () => _play(start: m.seconds),
                              onLongPress: () async {
                                if (await editMarker(context, m)) _load();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: NetImage(
                                        m.screenshot,
                                        placeholderIcon: Icons.bookmark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatDuration(m.seconds)} • ${m.displayTitle}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (s.details != null && s.details!.isNotEmpty)
                  Section(
                    title: 'Description',
                    child: SelectableText(s.details!),
                  ),
                if (s.tags.isNotEmpty)
                  Section(
                    title: 'Tags',
                    child: RefChips(
                      refs: s.tags,
                      onTap: (r) => openTag(context, r.id),
                    ),
                  ),
                if (s.groups.isNotEmpty)
                  Section(
                    title: 'Groupes',
                    child: RefChips(
                      refs: s.groups,
                      icon: Icons.video_library_outlined,
                      onTap: (r) => openGroup(context, r.id),
                    ),
                  ),
                if (s.galleries.isNotEmpty)
                  Section(
                    title: 'Galeries',
                    child: RefChips(
                      refs: s.galleries,
                      icon: Icons.photo_library_outlined,
                      onTap: (r) => openGallery(context, r.id),
                    ),
                  ),
                Section(
                  title: 'Informations',
                  child: InfoTable([
                    ('Code', s.code),
                    ('Réalisateur', s.director),
                    if (f != null) ...[
                      ('Fichier', f.path),
                      ('Taille', formatBytes(f.size)),
                      ('Dimensions', '${f.width} × ${f.height}'),
                      ('Format', f.format),
                      ('Vidéo', f.videoCodec),
                      ('Audio', f.audioCodec),
                      ('Images/s', f.frameRate.toStringAsFixed(2)),
                      (
                        'Débit',
                        '${(f.bitRate / 1000000).toStringAsFixed(2)} Mb/s',
                      ),
                    ],
                    ('Dernière lecture', s.lastPlayedAt?.split('T').first),
                  ]),
                ),
                if (s.urls.isNotEmpty)
                  Section(title: 'Liens', child: UrlList(s.urls)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
