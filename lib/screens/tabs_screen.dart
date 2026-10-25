import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'app_screens.dart';

/// Plus > Affichage > Onglets: which screens sit in the bottom bar, in
/// which order. The others are listed in Plus.
class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  late final AppState _app = context.read<AppState>();
  late final Set<AppScreen> _chosen = AppScreen.tabsOf(_app).toSet();

  /// Every screen: tabs first, in their order.
  late final List<AppScreen> _order = [
    ...AppScreen.tabsOf(_app),
    ...AppScreen.values.where((s) => !_chosen.contains(s)),
  ];

  void _save() {
    _app.tabNames = [
      for (final s in _order)
        if (_chosen.contains(s)) s.name,
    ];
  }

  void _toggle(AppScreen s, bool on) {
    setState(() => on ? _chosen.add(s) : _chosen.remove(s));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final full = _chosen.length >= AppScreen.maxTabs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onglets'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _chosen
                  ..clear()
                  ..addAll(AppScreen.defaultTabs);
                _order
                  ..clear()
                  ..addAll([
                    ...AppScreen.defaultTabs,
                    ...AppScreen.values.where(
                      (s) => !AppScreen.defaultTabs.contains(s),
                    ),
                  ]);
              });
              _app.tabNames = null;
            },
            child: const Text('Par défaut'),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Cochez jusqu\'à ${AppScreen.maxTabs} écrans pour la barre du '
              'bas (« Plus » y reste toujours, en dernier). Les autres sont '
              'dans Plus. Faites glisser pour changer l\'ordre ; le premier '
              'onglet s\'ouvre au lancement.\n'
              '${_chosen.length} / ${AppScreen.maxTabs} onglets',
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
                ListTile(
                  key: ValueKey(_order[i]),
                  leading: Checkbox(
                    value: _chosen.contains(_order[i]),
                    // At least one tab, at most maxTabs.
                    onChanged: _chosen.contains(_order[i])
                        ? (_chosen.length > 1
                              ? (v) => _toggle(_order[i], false)
                              : null)
                        : (full ? null : (v) => _toggle(_order[i], true)),
                  ),
                  title: Row(
                    children: [
                      Icon(_order[i].icon, size: 20),
                      const SizedBox(width: 12),
                      Text(_order[i].label),
                    ],
                  ),
                  subtitle: Text(
                    _chosen.contains(_order[i]) ? 'Onglet' : 'Dans Plus',
                  ),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
