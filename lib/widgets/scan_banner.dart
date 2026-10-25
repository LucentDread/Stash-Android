import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/scan_tracker.dart';
import '../services/system_bridge.dart';

/// Shows [child] with the scan progress banner under it while a library
/// scan runs (and briefly after it ends). Placed above the navigator so it
/// stays visible on every page.
class ScanBannerHost extends StatelessWidget {
  const ScanBannerHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scan = context.read<AppState>().scan;
    final pip = SystemBridge.instance.inPip;
    return ListenableBuilder(
      listenable: Listenable.merge([scan, pip]),
      builder: (context, _) {
        // Nothing but the video in the small window.
        if (scan.phase == ScanPhase.idle || pip.value) return child;
        return Column(
          children: [
            Expanded(
              // The banner takes the bottom inset instead of the pages.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            ScanBanner(scan: scan),
          ],
        );
      },
    );
  }
}

class ScanBanner extends StatelessWidget {
  const ScanBanner({super.key, required this.scan});
  final ScanTracker scan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final job = scan.job;
    final progress = job?.progress;

    final (IconData icon, Color color, String title) = switch (scan.phase) {
      ScanPhase.running => (
        Icons.sync,
        scheme.primary,
        progress == null
            ? 'Scan de la bibliothèque…'
            : 'Scan de la bibliothèque · ${(progress * 100).floor()} %',
      ),
      ScanPhase.failed => (Icons.error_outline, scheme.error, 'Échec du scan'),
      _ when job?.status == 'CANCELLED' => (
        Icons.stop_circle_outlined,
        scheme.onSurfaceVariant,
        'Scan arrêté · données actualisées',
      ),
      _ => (
        Icons.check_circle_outline,
        Colors.green,
        'Scan terminé · données actualisées',
      ),
    };

    final item = scan.running ? scan.currentItem : null;
    final slash = item?.lastIndexOf(RegExp(r'[\\/]')) ?? -1;
    final file = item?.substring(slash + 1);
    final folder = slash > 0 ? item!.substring(0, slash) : null;
    final detail = scan.phase == ScanPhase.failed ? scan.error : null;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (scan.running)
              LinearProgressIndicator(value: progress, minHeight: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (file != null)
                          Text(
                            file,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        if (folder != null)
                          Text(
                            folder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (detail != null && detail.isNotEmpty)
                          Text(
                            detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // No tooltips here: the banner sits outside the navigator,
                  // where there is no Overlay to show them.
                  if (scan.running)
                    IconButton(
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        semanticLabel: 'Arrêter le scan',
                      ),
                      onPressed: scan.stop,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, semanticLabel: 'Fermer'),
                      onPressed: scan.dismiss,
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
