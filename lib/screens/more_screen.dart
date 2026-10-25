import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/brand_title.dart';
import 'browse_screens.dart';
import 'setup_screen.dart';
import 'views_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmScan(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner la bibliothèque ?'),
        content: const Text(
          'Stash va parcourir vos dossiers avec ses options de scan par '
          'défaut (Paramètres > Tâches). Le suivi s\'affiche en bas de '
          'l\'écran ; les pages se rechargeront à la fin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Scanner'),
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
    return Scaffold(
      appBar: AppBar(title: const BrandTitle(page: 'Plus')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bookmarks),
            title: const Text('Vues enregistrées'),
            subtitle: Text(
              app.homeView == null
                  ? 'Accueil : par défaut'
                  : 'Accueil : ${app.homeView!.name}',
            ),
            onTap: () => _push(context, const ViewsScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galeries'),
            onTap: () => _push(context, const GalleriesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Studios'),
            onTap: () => _push(context, const StudiosScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Tags'),
            onTap: () => _push(context, const TagsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.bookmarks_outlined),
            title: const Text('Marqueurs'),
            onTap: () => _push(context, const MarkersScreen()),
          ),
          const Divider(),
          const _Header('Affichage'),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Colonnes de scènes (portrait)'),
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
            title: const Text('Aperçu vidéo par appui long'),
            subtitle: const Text('Lit l\'aperçu d\'une scène en la maintenant'),
            value: app.playPreviews,
            onChanged: (v) => app.playPreviews = v,
          ),
          const Divider(),
          const _Header('Serveur'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Serveur Stash'),
            subtitle: Text(app.serverUrl ?? ''),
            onTap: () => _push(context, const SetupScreen(popOnSuccess: true)),
          ),
          FutureBuilder<String>(
            future: app.repo?.version(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version du serveur'),
              subtitle: Text(snap.data ?? (snap.hasError ? '—' : '…')),
            ),
          ),
          ListenableBuilder(
            listenable: app.scan,
            builder: (context, _) => ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Scanner la bibliothèque'),
              subtitle: Text(
                app.scan.running
                    ? 'Scan en cours (suivi en bas de l\'écran)'
                    : 'Détecte les fichiers ajoutés, modifiés ou supprimés',
              ),
              enabled: !app.scan.running,
              onTap: () => _confirmScan(context, app),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text(
                    'L\'adresse du serveur et la clé API seront oubliées.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              );
              if (ok == true) await app.disconnect();
            },
          ),
          const Divider(),
          const _Header('Application'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Version de l\'application'),
              subtitle: Text(
                snap.hasData
                    ? '${snap.data!.version} (build ${snap.data!.buildNumber})'
                    : (snap.hasError ? '—' : '…'),
              ),
            ),
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
