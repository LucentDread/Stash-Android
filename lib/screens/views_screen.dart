import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/view_list.dart';
import 'browse_screens.dart';
import 'view_edit_screen.dart';

/// Lists the views made in the app and the filters saved in Stash's web
/// UI: open, choose those on the home page, reorder; edit and delete the
/// app's own.
class ViewsScreen extends StatefulWidget {
  const ViewsScreen({super.key});

  @override
  State<ViewsScreen> createState() => _ViewsScreenState();
}

class _ViewsScreenState extends State<ViewsScreen> {
  bool _loadingWeb = true;
  Object? _webError;

  /// Web filters of kinds the app cannot list (images).
  int _unsupported = 0;

  @override
  void initState() {
    super.initState();
    _refreshWeb();
  }

  Future<void> _refreshWeb() async {
    setState(() {
      _loadingWeb = true;
      _webError = null;
    });
    try {
      final unsupported = await context.read<AppState>().refreshWebViews();
      if (mounted) setState(() => _unsupported = unsupported);
    } catch (e) {
      if (mounted) setState(() => _webError = e);
    } finally {
      if (mounted) setState(() => _loadingWeb = false);
    }
  }

  void _edit([SavedView? view]) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ViewEditScreen(view: view)));

  Future<void> _delete(SavedView view) async {
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

  String _describe(SavedView v) {
    if (v.remote) return 'Filtre de Stash (web) · ${v.kind.label}';
    final criteria = v.filter.describe(v.kind);
    return [
      v.kind.label,
      if (criteria.isEmpty) 'sans filtre' else ...criteria,
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final views = app.allViews;
    final defaultHome = app.homeViews.isEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vues enregistrées'),
        actions: [
          IconButton(
            tooltip: 'Relire les filtres de Stash',
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: _loadingWeb ? null : _refreshWeb,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle vue'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeb,
        child: ListView(
          // Room for the floating button.
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Créez une vue (scènes, performeurs, studios…) avec le bouton '
                '« Nouvelle vue », ou depuis l\'onglet Scènes (icône signet). '
                'Les filtres enregistrés dans l\'interface web de Stash '
                'apparaissent aussi (icône nuage) ; ils se modifient depuis '
                'le web.',
              ),
            ),
            if (_loadingWeb) const LinearProgressIndicator(minHeight: 2),
            if (_webError != null)
              ListTile(
                leading: Icon(Icons.cloud_off, color: theme.colorScheme.error),
                title: const Text('Filtres de Stash indisponibles'),
                subtitle: Text('$_webError', maxLines: 2),
                onTap: _refreshWeb,
              ),
            if (_unsupported > 0)
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(
                  _unsupported == 1
                      ? '1 filtre web d\'images n\'est pas repris'
                      : '$_unsupported filtres web d\'images ne sont pas repris',
                ),
              ),
            ListTile(
              leading: Icon(
                defaultHome ? Icons.dashboard : Icons.dashboard_outlined,
                color: defaultHome ? theme.colorScheme.primary : null,
              ),
              title: const Text('Accueil par défaut'),
              subtitle: const Text(
                'Page d\'accueil standard, où les vues de l\'app apparaissent '
                'en lignes',
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
                    _tile(context, app, views[i], i),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppState app, SavedView v, int index) {
    final onHome = app.isHomeView(v.id);
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      key: ValueKey(v.id),
      leading: IconButton(
        tooltip: onHome
            ? 'Retirer de la page d\'accueil'
            : 'Ajouter à la page d\'accueil',
        icon: Icon(onHome ? Icons.home : Icons.home_outlined),
        color: onHome ? primary : null,
        onPressed: () => app.setHomeView(v.id, !onHome),
      ),
      title: Row(
        children: [
          Icon(viewKindIcon(v.kind), size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(v.name, overflow: TextOverflow.ellipsis)),
          if (v.remote) ...[
            const SizedBox(width: 6),
            const Icon(Icons.cloud_outlined, size: 16),
          ],
        ],
      ),
      subtitle: Text(
        _describe(v),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ViewScreen(view: v))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!v.remote)
            PopupMenuButton<String>(
              onSelected: (a) => a == 'edit' ? _edit(v) : _delete(v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
  }
}
