import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../screens/downloads_screen.dart';
import '../services/app_state.dart';

/// Tells the user when the Stash server becomes unreachable (popup with a
/// shortcut to the downloads) and when it is back (snack bar). Sits above
/// the navigator, so it uses the app's navigator and messenger keys.
class OfflineWatcher extends StatefulWidget {
  const OfflineWatcher({
    super.key,
    required this.navigatorKey,
    required this.messengerKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<OfflineWatcher> createState() => _OfflineWatcherState();
}

class _OfflineWatcherState extends State<OfflineWatcher> {
  late final AppState _app = context.read<AppState>();
  // Set in initState: a lazy initializer would first run inside _changed,
  // after the switch, and hide it.
  late bool _offline;
  bool _dialogShown = false;

  /// The popup waits for the lock screen to go.
  bool _afterUnlock = false;

  @override
  void initState() {
    super.initState();
    _offline = _app.offline;
    _app.addListener(_changed);
    _app.lock.addListener(_lockChanged);
  }

  @override
  void dispose() {
    _app.removeListener(_changed);
    _app.lock.removeListener(_lockChanged);
    super.dispose();
  }

  void _lockChanged() {
    if (_app.lock.locked || !_afterUnlock) return;
    _afterUnlock = false;
    if (!_app.offline) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showOfflineDialog();
    });
  }

  void _changed() {
    if (_app.offline == _offline) return;
    _offline = _app.offline;
    // Not during the notifier's callback: wait for the next frame, and ask
    // for one (nothing else may be redrawing).
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_offline) {
        _showOfflineDialog();
      } else {
        widget.messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(tr.connectionRestored)),
        );
      }
    });
  }

  Future<void> _showOfflineDialog() async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || _dialogShown) return;
    // Not above the lock screen: its button would open the app.
    if (_app.lock.locked) {
      _afterUnlock = true;
      return;
    }
    _dialogShown = true;
    final openDownloads = await showDialog<bool>(
      context: navigator.overlay!.context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_off),
        title: Text(tr.offlineTitle),
        content: Text(tr.offlineMessage(_app.serverUrl ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.close),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(tr.downloads),
          ),
        ],
      ),
    );
    _dialogShown = false;
    if (openDownloads == true) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const DownloadsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
