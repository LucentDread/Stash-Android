import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../screens/downloads_screen.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../utils/format.dart';

/// App bar button to keep a scene, group, gallery or image for offline
/// viewing.
/// Shows the download progress, then a "downloaded" state that opens the
/// downloads section.
class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.kind,
    required this.id,
    this.sizeHint,
  });

  final OfflineKind kind;
  final String id;

  /// Expected size in bytes, shown in the confirmation (scenes).
  final int? sizeHint;

  String _question(String size) => switch (kind) {
    OfflineKind.scene => tr.downloadSceneQuestion(size),
    OfflineKind.group => tr.downloadGroupQuestion(size),
    OfflineKind.gallery => tr.downloadGalleryQuestion(size),
    OfflineKind.image => tr.downloadImageQuestion(size),
  };

  Future<void> _start(BuildContext context, DownloadManager downloads) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.downloadTitle),
        content: Text(
          '${_question(sizeHint == null ? '' : ' (${formatBytes(sizeHint!)})')}'
          ' ${tr.downloadInBackground}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.download),
          ),
        ],
      ),
    );
    if (ok != true) return;
    messenger.showSnackBar(SnackBar(content: Text(tr.preparingDownload)));
    try {
      switch (kind) {
        case OfflineKind.scene:
          await downloads.downloadScene(id);
        case OfflineKind.group:
          await downloads.downloadGroup(id);
        case OfflineKind.gallery:
          await downloads.downloadGallery(id);
        case OfflineKind.image:
          await downloads.downloadImage(id);
      }
      messenger.showSnackBar(SnackBar(content: Text(tr.downloadStarted)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<AppState>().downloads;
    return ListenableBuilder(
      listenable: downloads,
      builder: (context, _) {
        final entry = downloads.entry(kind, id);
        if (entry == null) {
          return IconButton(
            tooltip: tr.download,
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _start(context, downloads),
          );
        }
        final (state, progress) = downloads.status(entry);
        void open() => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));
        return IconButton(
          tooltip: switch (state) {
            FileState.done => tr.notifDownloaded,
            FileState.failed => tr.notifDownloadFailed,
            _ => tr.downloadInProgress,
          },
          onPressed: open,
          icon: switch (state) {
            FileState.done => const Icon(Icons.download_done),
            FileState.failed => Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            _ => SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
              ),
            ),
          },
        );
      },
    );
  }
}
