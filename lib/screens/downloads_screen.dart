import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../utils/format.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import '../widgets/paged_grid.dart';
import 'image_viewer_screen.dart';
import 'player_screen.dart';

/// Scenes, groups, galleries and images kept on the phone, usable
/// offline: one tab per kind, as grids of previews.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static String _title(OfflineKind kind) => switch (kind) {
    OfflineKind.scene => tr.scenes,
    OfflineKind.group => tr.groups,
    OfflineKind.gallery => tr.galleries,
    OfflineKind.image => tr.images,
  };

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    return FutureBuilder(
      future: downloads.init(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(tr.downloads)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return ListenableBuilder(
          listenable: downloads,
          builder: (context, _) {
            final kinds = [
              for (final k in OfflineKind.values)
                if (downloads.entries(k).isNotEmpty) k,
            ];
            if (kinds.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(tr.downloads)),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(tr.noDownloads, textAlign: TextAlign.center),
                  ),
                ),
              );
            }
            // Rebuilt when a kind appears or goes.
            return DefaultTabController(
              key: ValueKey(kinds.join()),
              length: kinds.length,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(tr.downloads),
                  bottom: TabBar(
                    isScrollable: kinds.length > 3,
                    tabAlignment: kinds.length > 3 ? TabAlignment.start : null,
                    tabs: [
                      for (final k in kinds)
                        Tab(
                          text: '${_title(k)} (${downloads.entries(k).length})',
                        ),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    for (final k in kinds)
                      DownloadGrid(entries: downloads.entries(k).toList()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Downloaded items of one kind as cards with their preview.
class DownloadGrid extends StatelessWidget {
  const DownloadGrid({super.key, required this.entries});
  final List<OfflineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final kind = entries.firstOrNull?.kind ?? OfflineKind.scene;
    final (maxWidth, aspect) = switch (kind) {
      OfflineKind.scene => (280.0, 16 / 9),
      OfflineKind.group => (160.0, 2 / 3),
      OfflineKind.gallery => (200.0, 1.0),
      OfflineKind.image => (130.0, 1.0),
    };
    // Images go without a caption: their titles are rarely set.
    final caption = kind != OfflineKind.image;
    return LayoutBuilder(
      builder: (context, box) {
        final width = gridTileWidth(box.maxWidth - 2 * gridSpacing, maxWidth);
        return GridView.builder(
          padding: withNavBar(context, const EdgeInsets.all(gridSpacing)),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxWidth,
            mainAxisSpacing: gridSpacing,
            crossAxisSpacing: gridSpacing,
            mainAxisExtent: width / aspect + (caption ? 56 : 0),
          ),
          itemCount: entries.length,
          itemBuilder: (_, i) => DownloadCard(
            key: ValueKey(entries[i].key),
            entry: entries[i],
            aspect: aspect,
            caption: caption,
          ),
        );
      },
    );
  }
}

/// Opens a downloaded entry: plays a scene, lists a group, shows a gallery.
void openOffline(BuildContext context, OfflineEntry e) {
  final downloads = context.read<AppState>().downloads;
  final page = switch (e.kind) {
    OfflineKind.scene => PlayerScreen(
      sceneId: e.id,
      offlinePath: downloads.videoPath(e),
      offlineData: e.data,
    ),
    OfflineKind.group => OfflineGroupScreen(group: e),
    OfflineKind.gallery => ImageViewerScreen(
      images: [
        for (final (i, path) in downloads.galleryImages(e).indexed)
          StashImage.offline('$i', path),
      ],
      initialIndex: 0,
      downloadable: false,
    ),
    OfflineKind.image => _offlineImages(downloads, e),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

/// Every downloaded image, starting at [e]: swiping goes to the others.
ImageViewerScreen _offlineImages(DownloadManager downloads, OfflineEntry e) {
  final images = <StashImage>[];
  var index = 0;
  for (final other in downloads.entries(OfflineKind.image)) {
    final path = downloads.galleryImages(other).firstOrNull;
    if (path == null) continue;
    if (other.id == e.id) index = images.length;
    images.add(StashImage.offline(other.id, path, title: other.title));
  }
  return ImageViewerScreen(
    images: images,
    initialIndex: index,
    downloadable: false,
  );
}

/// A downloaded item: its preview, with the download progress or failure
/// over it, and its title and details. A tap opens it; a long press (or
/// a tap while it cannot open) offers to retry or delete it.
class DownloadCard extends StatelessWidget {
  const DownloadCard({
    super.key,
    required this.entry,
    this.aspect = 16 / 9,
    this.caption = true,
  });
  final OfflineEntry entry;
  final double aspect;
  final bool caption;

  bool get _isClip =>
      entry.files.any((f) => f.path.endsWith(StashImage.clipExtension));

  Future<void> _delete(BuildContext context, DownloadManager downloads) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.deleteFromPhoneQuestion(entry.title)),
        content: entry.kind == OfflineKind.group
            ? Text(tr.groupScenesDeletedToo)
            : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (ok == true) await downloads.delete(entry);
  }

  Future<void> _actions(
    BuildContext context,
    DownloadManager downloads,
    FileState state,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (state == FileState.failed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(tr.retry),
                onTap: () => Navigator.pop(context, 'retry'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr.delete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'retry':
        await downloads.retry(entry);
      case 'delete':
        await _delete(context, downloads);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    final (state, progress) = downloads.status(entry);
    final theme = Theme.of(context);
    final details = switch (entry.kind) {
      OfflineKind.scene => [if (entry.bytes != null) formatBytes(entry.bytes!)],
      OfflineKind.group => [tr.countScenes(entry.sceneIds.length)],
      OfflineKind.gallery => [
        tr.countImages(downloads.galleryImageCount(entry)),
      ],
      OfflineKind.image => <String>[],
    };
    final done = state == FileState.done;
    final failed = state == FileState.failed;
    final status = switch (state) {
      FileState.done => null,
      FileState.failed => tr.downloadFailedRetry,
      FileState.paused => tr.notifPaused,
      FileState.queued => tr.downloadQueued,
      FileState.running =>
        progress == null
            ? tr.downloadRunning
            : tr.downloadProgress((progress * 100).floor()),
    };
    // A group can be opened while some of its scenes still download.
    final opens = done || entry.kind == OfflineKind.group;
    void actions() => _actions(context, downloads, state);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: opens ? () => openOffline(context, entry) : actions,
        onLongPress: actions,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    downloads.coverPath(entry),
                    cacheWidth: 480,
                    placeholderIcon: switch (entry.kind) {
                      OfflineKind.scene => Icons.movie,
                      OfflineKind.group => Icons.video_library,
                      OfflineKind.gallery => Icons.photo_library,
                      OfflineKind.image => Icons.image,
                    },
                  ),
                  if (_isClip)
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 36,
                        shadows: [Shadow(blurRadius: 6)],
                      ),
                    ),
                  if (failed)
                    ColoredBox(
                      color: Colors.black54,
                      child: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 36,
                      ),
                    )
                  else if (!done) ...[
                    const ColoredBox(color: Colors.black38),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(value: progress),
                    ),
                  ],
                  if (!caption && status != null)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (caption)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      [...details, ?status].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: failed
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Scenes of a downloaded group, in group order.
class OfflineGroupScreen extends StatelessWidget {
  const OfflineGroupScreen({super.key, required this.group});
  final OfflineEntry group;

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    return Scaffold(
      appBar: AppBar(title: Text(group.title)),
      body: ListenableBuilder(
        listenable: downloads,
        builder: (context, _) => DownloadGrid(
          entries: [
            for (final id in group.sceneIds)
              ?downloads.entry(OfflineKind.scene, id),
          ],
        ),
      ),
    );
  }
}
