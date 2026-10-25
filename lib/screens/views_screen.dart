import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scene_filter.dart';
import '../services/app_state.dart';
import 'browse_screens.dart';
import 'view_edit_screen.dart';

/// Lists saved views: open, choose the home page, rename, reorder, delete.
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
    final homeId = app.homeView?.id;

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
          RadioGroup<String?>(
            groupValue: homeId,
            onChanged: (id) => app.homeViewId = id,
            child: Column(
              children: [
                const RadioListTile<String?>(
                  value: null,
                  title: Text('Accueil par défaut'),
                  subtitle: Text('Page d\'accueil standard'),
                ),
                if (views.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Aucune vue enregistrée'),
                  ),
              ],
            ),
          ),
          if (views.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Page d\'accueil ou ligne de l\'accueil par défaut'),
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
                    leading: IconButton(
                      tooltip: 'Page d\'accueil',
                      icon: Icon(
                        views[i].id == homeId
                            ? Icons.home
                            : Icons.home_outlined,
                      ),
                      color: views[i].id == homeId
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onPressed: () => app.homeViewId = views[i].id == homeId
                          ? null
                          : views[i].id,
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
