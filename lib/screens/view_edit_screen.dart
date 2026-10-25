import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/view_list.dart';
import 'scene_filter_screen.dart';

/// Creates or edits a saved view: what it lists, name, search text, sort
/// and filter.
class ViewEditScreen extends StatefulWidget {
  const ViewEditScreen({super.key, this.view});

  /// View to edit, or null to create one.
  final SavedView? view;

  @override
  State<ViewEditScreen> createState() => _ViewEditScreenState();
}

class _ViewEditScreenState extends State<ViewEditScreen> {
  late final _name = TextEditingController(text: widget.view?.name ?? '');
  late final _query = TextEditingController(text: widget.view?.query ?? '');
  late ViewKind _kind = widget.view?.kind ?? ViewKind.scenes;
  late SceneFilter _filter = widget.view?.filter.copy() ?? SceneFilter();
  late String _sort = widget.view?.sort ?? 'created_at';
  late bool _descending = widget.view?.descending ?? true;

  @override
  void dispose() {
    _name.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _editFilter() async {
    final f = await Navigator.of(context).push<SceneFilter>(
      MaterialPageRoute(
        builder: (_) => SceneFilterScreen(initial: _filter, kind: _kind),
      ),
    );
    if (f != null) setState(() => _filter = f);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Donnez un nom à la vue')));
      return;
    }
    context.read<AppState>().saveView(
      SavedView(
        id: widget.view?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        kind: _kind,
        filter: _filter,
        sort: sortsFor(_kind).any((o) => o.value == _sort)
            ? _sort
            : _kind.defaultSort,
        descending: _descending,
        query: _query.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criteria = _filter.describe(_kind);
    final sorts = sortsFor(_kind);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.view == null ? 'Nouvelle vue' : 'Modifier la vue'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ViewKind>(
            initialValue: _kind,
            decoration: const InputDecoration(
              labelText: 'Contenu',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final k in ViewKind.values)
                DropdownMenuItem(
                  value: k,
                  child: Row(
                    children: [
                      Icon(viewKindIcon(k), size: 20),
                      const SizedBox(width: 12),
                      Text(k.label),
                    ],
                  ),
                ),
            ],
            onChanged: (k) => setState(() {
              _kind = k!;
              // Criteria of another kind stay stored but unused.
              if (!sortsFor(k).any((o) => o.value == _sort)) {
                _sort = k.defaultSort;
                _descending = k.defaultDescending;
              }
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: widget.view == null,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              labelText: 'Recherche (optionnelle)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  // Rebuilt with the sorts of another kind.
                  key: ValueKey(_kind),
                  initialValue: sorts.any((o) => o.value == _sort)
                      ? _sort
                      : sorts.first.value,
                  decoration: const InputDecoration(
                    labelText: 'Tri',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final o in sorts)
                      DropdownMenuItem(value: o.value, child: Text(o.label)),
                  ],
                  onChanged: (v) => setState(() => _sort = v!),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: _descending ? 'Décroissant' : 'Croissant',
                icon: Icon(
                  _descending ? Icons.arrow_downward : Icons.arrow_upward,
                ),
                onPressed: () => setState(() => _descending = !_descending),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Filtre',
              border: OutlineInputBorder(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (criteria.isEmpty)
                  Text(
                    'Sans filtre (${_kind.label.toLowerCase()} : tout)',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in criteria)
                        Chip(
                          label: Text(c),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _editFilter,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Modifier le filtre'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
