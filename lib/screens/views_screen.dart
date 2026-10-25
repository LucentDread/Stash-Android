import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scene_filter.dart';
import '../services/app_state.dart';
import 'browse_screens.dart';
import 'view_edit_screen.dart';

/// Lists saved views: open, choose those on the home page, edit, reorder,
/// delete.
class ViewsScreen extends StatelessWidget {
  const ViewsScreen({super.key});

  void _edit(BuildContext context, [SavedView? view]) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ViewEditScreen(view: view)));

  Future<void> _delete(BuildContext context, SavedView view) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${view.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) app.deleteView(view.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final views = app.views;
    final defaultHome = app.homeViews.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Vues enregistrées')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle vue'),
      ),
      body: ListView(
        // Room for the floating button.
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Créez une vue avec le bouton « Nouvelle vue », ou depuis '
              'l\'onglet Scènes (icône signet). Le menu ⋮ d\'une vue permet '
              'de modifier son filtre.',
            ),
          ),
          ListTile(
            leading: Icon(
              defaultHome ? Icons.dashboard : Icons.dashboard_outlined,
              color: defaultHome ? Theme.of(context).colorScheme.primary : null,
            ),
            title: const Text('Accueil par défaut'),
            subtitle: const Text(
              'Page d\'accueil standard, où les vues apparaissent en lignes',
            ),
            selected: defaultHome,
            onTap: app.clearHomeViews,
          ),
          if (views.isEmpty)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Aucune vue enregistrée'),
            ),
          if (views.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'L\'icône maison ajoute une vue à la page d\'accueil. '
                'Plusieurs vues s\'y empilent, dans l\'ordre de cette liste.',
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: app.reorderViews,
              children: [
                for (var i = 0; i < views.length; i++)
                  ListTile(
                    key: ValueKey(views[i].id),
                    leading: Builder(
                      builder: (context) {
                        final onHome = app.isHomeView(views[i].id);
                        return IconButton(
                          tooltip: onHome
                              ? 'Retirer de la page d\'accueil'
                              : 'Ajouter à la page d\'accueil',
                          icon: Icon(onHome ? Icons.home : Icons.home_outlined),
                          color: onHome
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          onPressed: () =>
                              app.setHomeView(views[i].id, !onHome),
                        );
                      },
                    ),
                    title: Text(views[i].name),
                    subtitle: Text(
                      views[i].filter.isEmpty
                          ? 'Sans filtre'
                          : views[i].filter.describe().join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ViewScreen(view: views[i]),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (a) => a == 'edit'
                              ? _edit(context, views[i])
                              : _delete(context, views[i]),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
