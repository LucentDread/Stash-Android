import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../models/scene_filter.dart';
import '../services/app_state.dart';
import '../widgets/async_view.dart';

/// Edits a [SceneFilter]; pops with the new filter when applied.
class SceneFilterScreen extends StatefulWidget {
  const SceneFilterScreen({
    super.key,
    required this.initial,
    this.kind = ViewKind.scenes,
  });
  final SceneFilter initial;

  /// What is filtered: only its criteria are offered.
  final ViewKind kind;

  @override
  State<SceneFilterScreen> createState() => _SceneFilterScreenState();
}

class _SceneFilterScreenState extends State<SceneFilterScreen> {
  late final SceneFilter _f = widget.initial.copy();

  @override
  Widget build(BuildContext context) {
    final has = widget.kind.fields.contains;
    final kind = widget.kind;
    return Scaffold(
      appBar: AppBar(
        title: Text('Filtrer : ${kind.label.toLowerCase()}'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _f
                ..performers = null
                ..tags = null
                ..studios = null
                ..groups = null
                ..minStars = null
                ..minResolution = null
                ..minDurationMin = null
                ..maxDurationMin = null
                ..organized = null
                ..played = null
                ..hasMarkers = null
                ..performerFavorite = null
                ..favorite = null;
            }),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (has(FilterField.favorite))
            _TriState(
              title: 'Favoris',
              value: _f.favorite,
              onChanged: (v) => setState(() => _f.favorite = v),
            ),
          if (has(FilterField.performers))
            _EntitySection(
              title: 'Performeurs',
              kind: RefKind.performers,
              criterion: _f.performers,
              modes: EntityMode.values,
              onChanged: (c) => setState(() => _f.performers = c),
            ),
          if (has(FilterField.tags))
            _EntitySection(
              title: 'Tags',
              kind: RefKind.tags,
              criterion: _f.tags,
              modes: EntityMode.values,
              subLevelsLabel: 'Inclure les sous-tags',
              onChanged: (c) => setState(() => _f.tags = c),
            ),
          if (has(FilterField.studios))
            _EntitySection(
              title: kind == ViewKind.performers ? 'Studios' : 'Studio',
              kind: RefKind.studios,
              criterion: _f.studios,
              // A scene has a single studio: "all" makes no sense (a
              // performer may have several).
              modes: kind == ViewKind.performers
                  ? EntityMode.values
                  : EntityMode.values
                        .where((m) => m != EntityMode.all)
                        .toList(),
              subLevelsLabel: 'Inclure les sous-studios',
              onChanged: (c) => setState(() => _f.studios = c),
            ),
          if (has(FilterField.groups))
            _EntitySection(
              title: 'Groupes',
              kind: RefKind.groups,
              criterion: _f.groups,
              modes: EntityMode.values,
              subLevelsLabel: 'Inclure les sous-groupes',
              onChanged: (c) => setState(() => _f.groups = c),
            ),
          const Divider(),
          if (has(FilterField.rating))
            ListTile(
              title: const Text('Note minimale'),
              trailing: DropdownButton<int?>(
                value: _f.minStars,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  for (var i = 1; i <= 5; i++)
                    DropdownMenuItem(value: i, child: Text('≥ $i ★')),
                ],
                onChanged: (v) => setState(() => _f.minStars = v),
              ),
            ),
          if (has(FilterField.resolution))
            ListTile(
              title: const Text('Résolution minimale'),
              trailing: DropdownButton<String?>(
                value: _f.minResolution,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  for (final r in ResolutionChoice.all)
                    DropdownMenuItem(
                      value: r.aboveEnum,
                      child: Text('≥ ${r.label}'),
                    ),
                ],
                onChanged: (v) => setState(() => _f.minResolution = v),
              ),
            ),
          if (has(FilterField.duration))
            ListTile(
              title: const Text('Durée (minutes)'),
              subtitle: Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      label: 'Min',
                      value: _f.minDurationMin,
                      onChanged: (v) => _f.minDurationMin = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NumberField(
                      label: 'Max',
                      value: _f.maxDurationMin,
                      onChanged: (v) => _f.maxDurationMin = v,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          if (has(FilterField.played))
            _TriState(
              title: 'Lecture',
              value: _f.played,
              yes: kind == ViewKind.scenes ? 'Déjà vues' : 'Déjà vu',
              no: kind == ViewKind.scenes ? 'Jamais vues' : 'Jamais vu',
              onChanged: (v) => setState(() => _f.played = v),
            ),
          if (has(FilterField.organized))
            _TriState(
              title: kind == ViewKind.scenes ? 'Organisées' : 'Organisé',
              value: _f.organized,
              onChanged: (v) => setState(() => _f.organized = v),
            ),
          if (has(FilterField.hasMarkers))
            _TriState(
              title: 'Marqueurs',
              value: _f.hasMarkers,
              yes: 'Avec',
              no: 'Sans',
              onChanged: (v) => setState(() => _f.hasMarkers = v),
            ),
          if (has(FilterField.performerFavorite))
            _TriState(
              title: 'Performeur favori',
              value: _f.performerFavorite,
              onChanged: (v) => setState(() => _f.performerFavorite = v),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, _f),
        icon: const Icon(Icons.check),
        label: const Text('Appliquer'),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    // Rebuild the field when the value is reset from outside.
    key: ValueKey(value == null),
    initialValue: value?.toString() ?? '',
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, isDense: true),
    onChanged: (t) => onChanged(int.tryParse(t.trim())),
  );
}

/// "Any / yes / no" selector for optional boolean criteria.
class _TriState extends StatelessWidget {
  const _TriState({
    required this.title,
    required this.value,
    required this.onChanged,
    this.yes = 'Oui',
    this.no = 'Non',
  });

  final String title;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String yes;
  final String no;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: SegmentedButton<int>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [
          const ButtonSegment(value: 0, label: Text('Tous')),
          ButtonSegment(value: 1, label: Text(yes)),
          ButtonSegment(value: 2, label: Text(no)),
        ],
        selected: {value == null ? 0 : (value! ? 1 : 2)},
        onSelectionChanged: (s) => onChanged(switch (s.first) {
          1 => true,
          2 => false,
          _ => null,
        }),
      ),
    );
  }
}

class _EntitySection extends StatelessWidget {
  const _EntitySection({
    required this.title,
    required this.kind,
    required this.criterion,
    required this.modes,
    required this.onChanged,
    this.subLevelsLabel,
  });

  final String title;
  final RefKind kind;
  final EntityCriterion? criterion;
  final List<EntityMode> modes;
  final ValueChanged<EntityCriterion?> onChanged;
  final String? subLevelsLabel;

  Future<void> _pick(BuildContext context, EntityCriterion c) async {
    final picked = await Navigator.of(context).push<List<TagRef>>(
      MaterialPageRoute(
        builder: (_) =>
            RefPickerScreen(title: title, kind: kind, initial: c.items),
      ),
    );
    if (picked == null) return;
    onChanged(
      EntityCriterion(mode: c.mode, items: picked, subLevels: c.subLevels),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = criterion ?? EntityCriterion();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              DropdownButton<EntityMode>(
                value: c.mode,
                isDense: true,
                items: [
                  for (final m in modes)
                    DropdownMenuItem(value: m, child: Text(m.label)),
                ],
                onChanged: (m) => onChanged(
                  EntityCriterion(
                    mode: m!,
                    items: c.items,
                    subLevels: c.subLevels,
                  ),
                ),
              ),
            ],
          ),
          if (c.mode.needsItems) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in c.items)
                  InputChip(
                    label: Text(item.name),
                    onDeleted: () => onChanged(
                      EntityCriterion(
                        mode: c.mode,
                        items: c.items.where((i) => i.id != item.id).toList(),
                        subLevels: c.subLevels,
                      ),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Choisir'),
                  onPressed: () => _pick(context, c),
                ),
              ],
            ),
            if (subLevelsLabel != null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(subLevelsLabel!),
                value: c.subLevels,
                onChanged: (v) => onChanged(
                  EntityCriterion(
                    mode: c.mode,
                    items: c.items,
                    subLevels: v ?? false,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Searchable multi-select list of performers, tags, studios or groups.
class RefPickerScreen extends StatefulWidget {
  const RefPickerScreen({
    super.key,
    required this.title,
    required this.kind,
    required this.initial,
    this.single = false,
  });

  final String title;
  final RefKind kind;
  final List<TagRef> initial;

  /// Pick one item: tapping it returns immediately.
  final bool single;

  @override
  State<RefPickerScreen> createState() => _RefPickerScreenState();
}

class _RefPickerScreenState extends State<RefPickerScreen> {
  late final _repo = context.read<AppState>().repo!;
  late final List<TagRef> _selected = List.of(widget.initial);
  Timer? _debounce;
  late Future<List<TagRef>> _results = _repo.searchRefs(widget.kind, '');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _results = _repo.searchRefs(widget.kind, q.trim()));
    });
  }

  void _toggle(TagRef r) {
    if (widget.single) {
      Navigator.pop(context, [r]);
      return;
    }
    setState(() {
      final i = _selected.indexWhere((s) => s.id == r.id);
      i >= 0 ? _selected.removeAt(i) : _selected.add(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!widget.single)
            TextButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('Valider (${_selected.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              autofocus: true,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
              ),
            ),
          ),
          if (_selected.isNotEmpty && !widget.single)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in _selected)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(s.name),
                        onDeleted: () => _toggle(s),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<TagRef>>(
              future: _results,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error!);
                final items = snap.data;
                if (items == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return const Center(child: Text('Aucun résultat'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return CheckboxListTile(
                      title: Text(r.name),
                      value: _selected.any((s) => s.id == r.id),
                      onChanged: (_) => _toggle(r),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
