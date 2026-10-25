import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/setup_screen.dart';
import 'services/app_state.dart';
import 'services/system_bridge.dart';
import 'widgets/app_gate.dart';
import 'widgets/offline_watcher.dart';
import 'widgets/scan_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final app = AppState(prefs);
  // Picks up downloads that progressed while the app was closed.
  app.downloads.init().ignore();
  // Also applied natively at startup; this follows later changes.
  SystemBridge.instance.setSecure(app.hideInRecents).ignore();
  runApp(ChangeNotifierProvider.value(value: app, child: const StashApp()));
}

class StashApp extends StatelessWidget {
  const StashApp({super.key});

  // Stash's web UI uses a dark theme with a blue accent.
  static const _seed = Color(0xFF137CBD);

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final configured = context.select<AppState, bool>((s) => s.isConfigured);
    final serverUrl = context.select<AppState, String?>((s) => s.serverUrl);
    return MaterialApp(
      title: 'Stash',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      // Scan progress and the offline popup work above every page.
      builder: (context, child) => AppGate(
        navigatorKey: navigatorKey,
        child: OfflineWatcher(
          navigatorKey: navigatorKey,
          messengerKey: messengerKey,
          child: ScanBannerHost(child: child!),
        ),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      // Rebuild the whole tree when the server changes so caches reset.
      home: configured
          ? HomeShell(key: ValueKey(serverUrl))
          : const SetupScreen(),
    );
  }
}
