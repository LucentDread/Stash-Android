import 'package:flutter/material.dart';

import '../services/system_bridge.dart';
import '../services/updater.dart';
import '../utils/format.dart';

/// Looks for a new version and offers it. With [manual], also says when
/// the app is up to date or the check failed.
Future<void> checkForUpdates(
  BuildContext context, {
  Updater? updater,
  bool manual = false,
}) async {
  final u = updater ?? Updater();
  final messenger = ScaffoldMessenger.maybeOf(context);
  UpdateInfo? info;
  try {
    info = await u.check();
  } catch (e) {
    if (manual) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Recherche impossible : $e')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  if (info == null) {
    if (manual) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('L\'application est à jour')),
      );
    }
    return;
  }
  await showUpdateDialog(context, info, u);
}

/// Shows the release notes of every version since the installed one, then
/// downloads and installs the latest on request.
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo info,
  Updater updater,
) async {
  final install = await showDialog<bool>(
    context: context,
    builder: (context) => _UpdateDialog(info: info),
  );
  if (install != true || !context.mounted) return;
  final path = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _DownloadDialog(release: info.latest, updater: updater),
  );
  if (path == null) return;
  try {
    await SystemBridge.instance.installApk(path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Installation impossible : $e')));
    }
  }
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.info});
  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = info.latest;
    return AlertDialog(
      icon: const Icon(Icons.system_update),
      title: Text('Version ${latest.version} disponible'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final r in info.newer) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Nouveautés de la ${r.version}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              for (final item in Updater.noteItems(r.notes))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            latest.apkSize > 0
                ? 'Installer (${formatBytes(latest.apkSize)})'
                : 'Installer',
          ),
        ),
      ],
    );
  }
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.release, required this.updater});
  final Release release;
  final Updater updater;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _progress = null;
    });
    try {
      final file = await widget.updater.download(
        widget.release,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    return AlertDialog(
      title: Text('Téléchargement de la ${widget.release.version}'),
      content: _error != null
          ? Text('Échec : $_error')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: p),
                const SizedBox(height: 8),
                Text(p == null ? '…' : '${(p * 100).round()} %'),
                const SizedBox(height: 8),
                const Text(
                  'Android demandera ensuite de confirmer l\'installation '
                  '(et, la première fois, d\'autoriser Stash à installer '
                  'des applications).',
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (_error != null)
          FilledButton(onPressed: _start, child: const Text('Réessayer')),
      ],
    );
  }
}
