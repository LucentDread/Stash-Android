import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/insets.dart';
import '../widgets/view_list.dart';
import 'browse_screens.dart';
import 'home_layout_screen.dart';
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

  /// Web filters of kinds the app cannot list.
  int _unsupported = 0;

  /// Criteria left out of each web filter (by view id).
  Map<String, List<String>> _skipped = {};

  static const _warning = Color(0xFFFFB74D);

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
    await _checkCriteria();
  }

  /// Finds the web filters the app shows only partly.
  Future<void> _checkCriteria() async {
    final app = context.read<AppState>();
    final repo = app.repo;
    if (repo == null) return;
    final skipped = <String, List<String>>{};
    try {
      for (final v in app.webViews) {
        final s = await repo.skippedCriteria(v);
        if (s.isNotEmpty) skipped[v.id] = s;
      }
    } catch (_) {
      return; // schema unavailable: nothing to tell
    }
    if (mounted) setState(() => _skipped = skipped);
  }

  static String _criterionLabel(String key) => switch (key) {
    'folder' => tr.criterionFolder,
    'custom_fields' => tr.criterionCustomFields,
    _ => key.replaceAll('_', ' '),
  };

  void _edit([SavedView? view]) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ViewEditScreen(view: view)));

  Future<void> _delete(SavedView view) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.deleteNamedQuestion(view.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (ok == true) app.deleteView(view.id);
  }

  String _describe(SavedView v) {
    if (v.remote) return tr.webFilterOf(v.kind.label);
    final criteria = v.filter.describe(v.kind);
    return [
      v.kind.label,
      if (criteria.isEmpty) tr.noFilter else ...criteria,
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final views = app.allViews;
    final defaultHome = app.homeLayout.isEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.savedViews),
        actions: [
          IconButton(
            tooltip: tr.reloadWebFilters,
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: _loadingWeb ? null : _refreshWeb,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: Text(tr.newView),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWeb,
        child: ListView(
          // Room for the floating button.
          padding: withNavBar(context, const EdgeInsets.only(bottom: 88)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(tr.viewsIntro),
            ),
            if (_loadingWeb) const LinearProgressIndicator(minHeight: 2),
            if (_webError != null)
              ListTile(
                leading: Icon(Icons.cloud_off, color: theme.colorScheme.error),
                title: Text(tr.webFiltersUnavailable),
                subtitle: Text('$_webError', maxLines: 2),
                onTap: _refreshWeb,
              ),
            if (_unsupported > 0)
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(tr.unsupportedWebFilters(_unsupported)),
              ),
            if (_skipped.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.12),
                  border: Border.all(color: _warning),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr.skippedCriteriaWarning(_skipped.length),
                        style: const TextStyle(color: _warning),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(tr.composeHomePages),
              subtitle: Text(
                defaultHome
                    ? tr.homeIsDefault
                    : tr.homeItems(app.homeLayout.length),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HomeLayoutScreen()),
              ),
            ),
            if (views.isEmpty)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(tr.noSavedViews),
              ),
            if (views.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(tr.homeIconHint),
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
        tooltip: onHome ? tr.removeFromHome : tr.addToHome,
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_describe(v), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (_skipped[v.id] case final skipped?)
            Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: _warning,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' ${tr.ignored(skipped.map(_criterionLabel).join(', '))}',
                  ),
                ],
              ),
              style: const TextStyle(color: _warning),
            ),
        ],
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
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr.edit)),
                PopupMenuItem(value: 'delete', child: Text(tr.delete)),
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
