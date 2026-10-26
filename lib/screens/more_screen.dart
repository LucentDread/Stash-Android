import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_state.dart';
import '../widgets/brand_title.dart';
import 'app_screens.dart';
import 'downloads_screen.dart';
import 'home_layout_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'tabs_screen.dart';
import 'views_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmScan(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.scanLibraryQuestion),
        content: Text(tr.scanConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.scan),
          ),
        ],
      ),
    );
    if (ok == true) await app.scan.start();
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final home = app.homeLayout;
    final tabs = AppScreen.tabsOf(app);
    return Scaffold(
      appBar: AppBar(title: BrandTitle(page: tr.more)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(tr.homePage),
            subtitle: Text(switch (home.length) {
              0 => tr.defaultHome,
              1 when app.homeViews.length == 1 => app.homeViews.single.name,
              final n => tr.customHomeItems(n),
            }),
            onTap: () => _push(context, const HomeLayoutScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.bookmarks),
            title: Text(tr.savedViews),
            subtitle: Text(
              app.allViews.isEmpty
                  ? tr.noViews
                  : tr.countViews(app.allViews.length),
            ),
            onTap: () => _push(context, const ViewsScreen()),
          ),
          const Divider(),
          // The screens that are not bottom bar tabs.
          for (final s in AppScreen.values)
            if (!tabs.contains(s))
              ListTile(
                leading: Icon(s.icon),
                title: Text(s.label),
                onTap: () => _push(context, s.build()),
              ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(tr.downloads),
            subtitle: Text(tr.downloadsSubtitle),
            onTap: () => _push(context, const DownloadsScreen()),
          ),
          const Divider(),
          _Header(tr.displayHeader),
          ListTile(
            leading: const Icon(Icons.tab_outlined),
            title: Text(tr.tabsTitle),
            subtitle: Text(
              [...tabs.map((t) => t.label), tr.more].join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _push(context, const TabsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: Text(tr.sceneColumns),
            trailing: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {app.gridColumns},
              onSelectionChanged: (s) => app.gridColumns = s.first,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.slideshow_outlined),
            title: Text(tr.longPressPreview),
            subtitle: Text(tr.longPressPreviewSubtitle),
            value: app.playPreviews,
            onChanged: (v) => app.playPreviews = v,
          ),
          const Divider(),
          _Header(tr.serverHeader),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(tr.stashServer),
            subtitle: Text(app.serverUrl ?? ''),
            onTap: () => _push(context, const SetupScreen(popOnSuccess: true)),
          ),
          FutureBuilder<String>(
            future: app.serverVersion,
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(tr.serverVersion),
              subtitle: Text(snap.data ?? (snap.hasError ? '—' : '…')),
            ),
          ),
          ListenableBuilder(
            listenable: app.scan,
            builder: (context, _) => ListTile(
              leading: const Icon(Icons.sync),
              title: Text(tr.scanLibrary),
              subtitle: Text(
                app.scan.running ? tr.scanInProgressSubtitle : tr.scanSubtitle,
              ),
              enabled: !app.scan.running,
              onTap: () => _confirmScan(context, app),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(tr.logout),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr.logoutQuestion),
                  content: Text(tr.logoutMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr.logout),
                    ),
                  ],
                ),
              );
              if (ok == true) await app.disconnect();
            },
          ),
          const Divider(),
          _Header(tr.applicationHeader),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(tr.appVersion),
              subtitle: Text(
                snap.hasData
                    ? '${snap.data!.version} (build ${snap.data!.buildNumber})'
                    : (snap.hasError ? '—' : '…'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(tr.settings),
            subtitle: Text(tr.settingsSubtitle),
            onTap: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
