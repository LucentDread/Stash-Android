import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../screens/downloads_screen.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';

/// Shown in place of a page's content while the Stash server cannot be
/// reached: says so, and offers the downloads (which work without the
/// server) or to try again.
class OfflineNotice extends StatefulWidget {
  const OfflineNotice({super.key, this.onRetry});

  /// Also called when the server answers again (besides the app reloading
  /// its pages), e.g. to reload a page that failed.
  final VoidCallback? onRetry;

  /// Whether the app knows the server to be unreachable. False without an
  /// [AppState] above (some tests build pages on their own).
  static bool isOffline(BuildContext context) {
    try {
      return context.select<AppState, bool>((s) => s.offline);
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  State<OfflineNotice> createState() => _OfflineNoticeState();
}

class _OfflineNoticeState extends State<OfflineNotice> {
  bool _checking = false;

  Future<void> _retry() async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _checking = true);
    await app.checkServer();
    if (!mounted) return;
    setState(() => _checking = false);
    if (app.offline) {
      messenger?.showSnackBar(SnackBar(content: Text(tr.stillUnreachable)));
    } else {
      widget.onRetry?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = context.select<AppState, String?>((s) => s.serverUrl);
    // Scrollable so that it fits a small or landscape screen, and so that
    // a pull-to-refresh around it still works.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 56,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.serverUnreachableTitle,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.offlineMessage(url ?? ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          // First thing reached with a remote control
                          // (not on a phone: it would take the focus from
                          // a search being typed).
                          autofocus: SystemBridge.instance.isTv,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DownloadsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.download_for_offline_outlined),
                          label: Text(tr.downloads),
                        ),
                        OutlinedButton.icon(
                          onPressed: _checking ? null : _retry,
                          icon: _checking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(tr.retry),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
