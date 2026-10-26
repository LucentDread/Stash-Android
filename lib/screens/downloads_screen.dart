import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../utils/format.dart';
import '../widgets/net_image.dart';
import 'image_viewer_screen.dart';
import 'player_screen.dart';

/// Scenes, groups, galleries and images kept on the phone, usable
/// offline.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    return Scaffold(
      appBar: AppBar(title: Text(tr.downloads)),
      body: FutureBuilder(
        future: downloads.init(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListenableBuilder(
            listenable: downloads,
            builder: (context, _) {
              if (downloads.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(tr.noDownloads, textAlign: TextAlign.center),
                  ),
                );
              }
              return ListView(
                children: [
                  for (final (kind, title) in [
                    (OfflineKind.scene, tr.scenes),
                    (OfflineKind.group, tr.groups),
                    (OfflineKind.gallery, tr.galleries),
                    (OfflineKind.image, tr.images),
                  ])
                    if (downloads.entries(kind).isNotEmpty) ...[
                      _Header(title),
                      for (final e in downloads.entries(kind))
                        DownloadTile(entry: e),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
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

class DownloadTile extends StatelessWidget {
  const DownloadTile({super.key, required this.entry});
  final OfflineEntry entry;

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

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    final (state, progress) = downloads.status(entry);
    final theme = Theme.of(context);
    final details = switch (entry.kind) {
      OfflineKind.scene => [if (entry.bytes != null) formatBytes(entry.bytes!)],
      OfflineKind.group => [tr.countScenes(entry.sceneIds.length)],
      OfflineKind.gallery => [tr.countImages(entry.files.length)],
      OfflineKind.image => <String>[],
    };
    final status = switch (state) {
      FileState.done => tr.notifDownloaded,
      FileState.failed => tr.downloadFailedRetry,
      FileState.paused => tr.notifPaused,
      FileState.queued => tr.downloadQueued,
      FileState.running =>
        progress == null
            ? tr.downloadRunning
            : tr.downloadProgress((progress * 100).floor()),
    };
    final done = state == FileState.done;

    return ListTile(
      // A group can be opened while some of its scenes still download.
      onTap: done || entry.kind == OfflineKind.group
          ? () => openOffline(context, entry)
          : null,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 88,
          height: 50,
          child: NetImage(
            downloads.coverPath(entry),
            placeholderIcon: switch (entry.kind) {
              OfflineKind.scene => Icons.movie,
              OfflineKind.group => Icons.video_library,
              OfflineKind.gallery => Icons.photo_library,
              OfflineKind.image => Icons.image,
            },
          ),
        ),
      ),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [...details, status].join(' · '),
            style: state == FileState.failed
                ? TextStyle(color: theme.colorScheme.error)
                : null,
          ),
          if (!done && state != FileState.failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(value: progress),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) =>
            v == 'retry' ? downloads.retry(entry) : _delete(context, downloads),
        itemBuilder: (_) => [
          if (state == FileState.failed)
            PopupMenuItem(value: 'retry', child: Text(tr.retry)),
          PopupMenuItem(value: 'delete', child: Text(tr.delete)),
        ],
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
        builder: (context, _) => ListView(
          children: [
            for (final id in group.sceneIds)
              if (downloads.entry(OfflineKind.scene, id) case final scene?)
                DownloadTile(entry: scene),
          ],
        ),
      ),
    );
  }
}
