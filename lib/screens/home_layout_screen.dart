import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/home_section.dart';
import '../services/app_state.dart';
import '../widgets/view_list.dart';

/// More > Home page: what the custom home page and the default
/// dashboard show, in which order: dashboard sections and saved views.
class HomeLayoutScreen extends StatelessWidget {
  const HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.homePage),
          bottom: TabBar(
            tabs: [
              Tab(text: tr.home),
              Tab(text: tr.defaultHome),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LayoutEditor(
              key: const PageStorageKey('home'),
              ids: app.homeLayout,
              onChanged: (ids) => app.homeLayout = ids,
              intro: tr.homeLayoutIntro,
            ),
            _LayoutEditor(
              key: const PageStorageKey('dashboard'),
              ids: app.dashboardLayout,
              onChanged: (ids) => app.dashboardLayout = ids,
              onReset: () => app.dashboardLayout = null,
              intro: tr.dashboardLayoutIntro,
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkable, reorderable list of every section and view; the checked
/// ones, in order, make the page.
class _LayoutEditor extends StatefulWidget {
  const _LayoutEditor({
    super.key,
    required this.ids,
    required this.onChanged,
    required this.intro,
    this.onReset,
  });

  final List<String> ids;
  final ValueChanged<List<String>> onChanged;
  final String intro;
  final VoidCallback? onReset;

  @override
  State<_LayoutEditor> createState() => _LayoutEditorState();
}

class _LayoutEditorState extends State<_LayoutEditor> {
  late Set<String> _chosen;
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Checked items first, in page order, then the others.
  void _load() {
    final app = context.read<AppState>();
    _chosen = widget.ids.toSet();
    _order = [
      ...widget.ids,
      for (final s in HomeSection.values)
        if (!_chosen.contains(s.id)) s.id,
      for (final v in app.allViews)
        if (!_chosen.contains(v.id)) v.id,
    ];
  }

  /// Checks or unchecks [id], moving it to the end of the checked ones
  /// (the page's last item), or just below them.
  void _toggle(String id, bool on) {
    setState(() {
      on ? _chosen.add(id) : _chosen.remove(id);
      _order
        ..remove(id)
        ..insert(_chosen.length - (on ? 1 : 0), id);
    });
    _save();
  }

  void _save() => widget.onChanged([
    for (final id in _order)
      if (_chosen.contains(id)) id,
  ]);

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(widget.intro),
        ),
        if (widget.onReset != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                widget.onReset!();
                setState(() {
                  // Same items as the widget will get after the reset.
                  _chosen = app.dashboardLayout.toSet();
                  _order = [
                    ...app.dashboardLayout,
                    for (final id in _order)
                      if (!_chosen.contains(id)) id,
                  ];
                });
              },
              icon: const Icon(Icons.restart_alt),
              label: Text(tr.defaultRows),
            ),
          ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            setState(() => _order.insert(to, _order.removeAt(from)));
            _save();
          },
          children: [
            for (var i = 0; i < _order.length; i++)
              if (_item(app, _order[i]) case (
                final icon,
                final title,
                final subtitle,
              ))
                ListTile(
                  key: ValueKey(_order[i]),
                  leading: Checkbox(
                    value: _chosen.contains(_order[i]),
                    onChanged: (on) => _toggle(_order[i], on == true),
                  ),
                  title: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(title, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle),
                  ),
                )
              else
                // A view deleted meanwhile.
                SizedBox.shrink(key: ValueKey(_order[i])),
          ],
        ),
      ],
    );
  }

  /// Icon, title and kind of an item, or null when it no longer exists.
  (IconData, String, String)? _item(AppState app, String id) {
    final section = HomeSection.fromId(id);
    if (section != null) {
      return (_sectionIcon(section), section.label, tr.homeSection);
    }
    final view = app.viewById(id);
    if (view == null) return null;
    return (
      viewKindIcon(view.kind),
      view.name,
      view.remote
          ? tr.webFilterOf(view.kind.label)
          : tr.viewOf(view.kind.label),
    );
  }

  static IconData _sectionIcon(HomeSection s) => switch (s) {
    HomeSection.stats => Icons.insights,
    HomeSection.resume => Icons.play_circle_outline,
    HomeSection.recent => Icons.new_releases_outlined,
    HomeSection.releases => Icons.event_outlined,
    HomeSection.favoritePerformers => Icons.favorite_border,
    HomeSection.random => Icons.shuffle,
    HomeSection.galleries => Icons.photo_library_outlined,
  };
}
