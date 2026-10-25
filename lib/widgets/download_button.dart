import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  String get _what => switch (kind) {
    OfflineKind.scene => 'cette scène',
    OfflineKind.group => 'toutes les scènes de ce groupe',
    OfflineKind.gallery => 'toutes les images de cette galerie',
    OfflineKind.image => 'cette image',
  };

  Future<void> _start(BuildContext context, DownloadManager downloads) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Télécharger ?'),
        content: Text(
          'Télécharger $_what pour la regarder hors ligne'
          '${sizeHint == null ? '' : ' (${formatBytes(sizeHint!)})'} ? '
          'Le téléchargement continue en arrière-plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Préparation du téléchargement…')),
    );
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Téléchargement lancé (Plus > Téléchargements)'),
        ),
      );
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
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _start(context, downloads),
          );
        }
        final (state, progress) = downloads.status(entry);
        void open() => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));
        return IconButton(
          tooltip: switch (state) {
            FileState.done => 'Téléchargé',
            FileState.failed => 'Échec du téléchargement',
            _ => 'Téléchargement en cours',
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
