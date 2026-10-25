import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/setup_screen.dart';
import 'services/app_state.dart';
import 'widgets/scan_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const StashApp(),
    ),
  );
}

class StashApp extends StatelessWidget {
  const StashApp({super.key});

  // Stash's web UI uses a dark theme with a blue accent.
  static const _seed = Color(0xFF137CBD);

  @override
  Widget build(BuildContext context) {
    final configured = context.select<AppState, bool>((s) => s.isConfigured);
    final serverUrl = context.select<AppState, String?>((s) => s.serverUrl);
    return MaterialApp(
      title: 'Stash',
      debugShowCheckedModeBanner: false,
      // Scan progress stays visible above every page.
      builder: (context, child) => ScanBannerHost(child: child!),
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
