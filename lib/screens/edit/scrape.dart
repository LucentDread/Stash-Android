import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/stash_repository.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import 'edit_form.dart';

/// One proposed change: shown with a checkbox, applied to the form fields.
class MergeItem {
  MergeItem({
    required this.label,
    required this.current,
    required this.proposed,
    required this.apply,
    this.checked = true,
    this.image,
  });

  final String label;
  final String? current;
  final String proposed;

  /// Puts the value in the form. Creations first create the item in Stash.
  final FutureOr<void> Function() apply;
  bool checked;

  /// New cover (data URI or URL) to preview.
  final String? image;
}

/// A scraped record: raw data as returned by Stash (sent back as a
/// fragment for a full record) and its values keyed by edit field key.
class Scraped {
  Scraped(this.raw, this.values);
  final Map<String, dynamic> raw;
  final Map<String, Object?> values;

  String get title =>
      (values['title'] ?? values['name']) as String? ?? 'Sans titre';

  String? get preview =>
      (values['cover_image'] ?? values['image'] ?? values['front_image'])
          as String?;

  String get subtitle => [
    if (values['studio_id'] case final ScrapedRef s) s.name,
    if (values['disambiguation'] case final String d when d.isNotEmpty) d,
    if (values['date'] case final String d) d,
    if (values['birthdate'] case final String d) d,
    if (values['performer_ids'] case final List<ScrapedRef> p when p.isNotEmpty)
      p.map((e) => e.name).join(', '),
  ].join(' • ');
}

List<ScrapedRef> _refs(Object? v) => [
  for (final e in (v as List?) ?? const [])
    ScrapedRef.fromJson((e as Map).cast<String, dynamic>()),
];

ScrapedRef? _ref(Object? v) =>
    v == null ? null : ScrapedRef.fromJson((v as Map).cast<String, dynamic>());

List<String> _strings(Object? v) => (v as List?)?.cast<String>() ?? const [];

/// "170", "170 cm" → 170.
int? _number(Object? v) {
  final m = RegExp(r'\d+').firstMatch(v?.toString() ?? '');
  return m == null ? null : int.parse(m.group(0)!);
}

/// "Transgender Female" → TRANSGENDER_FEMALE, Stash's enum spelling.
String? _gender(Object? v) =>
    (v as String?)?.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');

/// Maps raw scraped data of [kind] onto the keys of its edit form.
Scraped toScraped(ScrapeKind kind, Map<String, dynamic> j) {
  final values = <String, Object?>{
    ...switch (kind) {
      ScrapeKind.scene => {
        'title': j['title'],
        'code': j['code'],
        'date': j['date'],
        'director': j['director'],
        'details': j['details'],
        'studio_id': _ref(j['studio']),
        'performer_ids': _refs(j['performers']),
        'tag_ids': _refs(j['tags']),
        'groups': _refs(j['groups']),
        'urls': _strings(j['urls']),
        'cover_image': j['image'],
      },
      ScrapeKind.performer => {
        'name': j['name'],
        'disambiguation': j['disambiguation'],
        'alias_list': [
          for (final a in (j['aliases'] as String? ?? '').split(','))
            if (a.trim().isNotEmpty) a.trim(),
        ],
        'gender': _gender(j['gender']),
        'birthdate': j['birthdate'],
        'death_date': j['death_date'],
        'country': j['country'],
        'ethnicity': j['ethnicity'],
        'hair_color': j['hair_color'],
        'eye_color': j['eye_color'],
        'height_cm': _number(j['height']),
        'weight': _number(j['weight']),
        'measurements': j['measurements'],
        'fake_tits': j['fake_tits'],
        'tattoos': j['tattoos'],
        'piercings': j['piercings'],
        'tag_ids': _refs(j['tags']),
        'urls': _strings(j['urls']),
        'details': j['details'],
        'image': _strings(j['images']).firstOrNull,
      },
      ScrapeKind.group => {
        'name': j['name'],
        'aliases': j['aliases'],
        'date': j['date'],
        'duration': TimeEditField.parse(j['duration'] as String? ?? '')
            ?.round(),
        'director': j['director'],
        'studio_id': _ref(j['studio']),
        'tag_ids': _refs(j['tags']),
        'urls': _strings(j['urls']),
        'synopsis': j['synopsis'],
        'front_image': j['front_image'],
        'back_image': j['back_image'],
      },
      ScrapeKind.gallery => {
        'title': j['title'],
        'code': j['code'],
        'date': j['date'],
        'photographer': j['photographer'],
        'studio_id': _ref(j['studio']),
        'performer_ids': _refs(j['performers']),
        'tag_ids': _refs(j['tags']),
        'urls': _strings(j['urls']),
        'details': j['details'],
      },
      ScrapeKind.studio => {
        'name': j['name'],
        'parent_id': _ref(j['parent']),
        'urls': _strings(j['urls']),
        'details': j['details'],
        'image': j['image'],
      },
    },
  };
  return Scraped(j, values);
}

/// Creates an item in Stash and returns it (see StashRepository.createRef).
typedef RefCreator = Future<TagRef> Function(
  RefKind kind,
  Map<String, dynamic> input,
);

/// Input to create a scraped [ref] of [kind] in Stash, with its stash-box
/// link when it comes from [stashBoxEndpoint].
Map<String, dynamic> createInput(
  RefKind kind,
  ScrapedRef ref, {
  String? stashBoxEndpoint,
}) {
  final j = ref.raw;
  String? text(String key) {
    final v = (j[key] as String?)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  final urls = _strings(j['urls']);
  final remoteId = text('remote_site_id');
  final stashIds = stashBoxEndpoint != null && remoteId != null
      ? [
          {'endpoint': stashBoxEndpoint, 'stash_id': remoteId},
        ]
      : null;
  return switch (kind) {
    RefKind.performers => {
      'name': ref.name,
      'disambiguation': ?text('disambiguation'),
      if (_gender(j['gender']) case final g? when _genders.contains(g))
        'gender': g,
      if (urls.isNotEmpty) 'urls': urls,
      'birthdate': ?text('birthdate'),
      'death_date': ?text('death_date'),
      'country': ?text('country'),
      'ethnicity': ?text('ethnicity'),
      'hair_color': ?text('hair_color'),
      'eye_color': ?text('eye_color'),
      'height_cm': ?_number(j['height']),
      'weight': ?_number(j['weight']),
      'measurements': ?text('measurements'),
      'fake_tits': ?text('fake_tits'),
      'tattoos': ?text('tattoos'),
      'piercings': ?text('piercings'),
      'details': ?text('details'),
      if (_aliases(j['aliases']) case final a when a.isNotEmpty)
        'alias_list': a,
      'image': ?_strings(j['images']).firstOrNull,
      'stash_ids': ?stashIds,
    },
    RefKind.tags => {'name': ref.name, 'stash_ids': ?stashIds},
    RefKind.studios => {
      'name': ref.name,
      if (urls.isNotEmpty) 'urls': urls,
      'image': ?text('image'),
      'parent_id': ?_ref(j['parent'])?.storedId,
      'stash_ids': ?stashIds,
    },
    RefKind.groups => {
      'name': ref.name,
      'aliases': ?text('aliases'),
      'date': ?text('date'),
      'director': ?text('director'),
      'synopsis': ?text('synopsis'),
      if (urls.isNotEmpty) 'urls': urls,
      'duration': ?TimeEditField.parse(text('duration') ?? '')?.round(),
      'front_image': ?text('front_image'),
      'back_image': ?text('back_image'),
    },
  };
}

const _genders = {
  'MALE',
  'FEMALE',
  'TRANSGENDER_MALE',
  'TRANSGENDER_FEMALE',
  'INTERSEX',
  'NON_BINARY',
};

List<String> _aliases(Object? v) => [
  for (final a in (v as String? ?? '').split(','))
    if (a.trim().isNotEmpty) a.trim(),
];

/// Changes a scraped record would bring to the edit [fields], and the
/// items it names that do not exist in Stash: those can be created with
/// [create] and then linked (unticked ones are left out).
(List<MergeItem>, List<MergeItem>) mergeItems(
  Scraped r,
  List<EditField> fields, {
  RefCreator? create,
  String? stashBoxEndpoint,
}) {
  final items = <MergeItem>[];
  final missing = <MergeItem>[];

  /// Proposes to create [s] in Stash, then [link] it in the form.
  void missingRef(
    RefKind kind,
    String label,
    ScrapedRef s,
    void Function(TagRef created) link,
  ) {
    if (missing.any((m) => m.label == label && m.proposed == s.name)) return;
    missing.add(
      MergeItem(
        label: label,
        current: null,
        proposed: s.name,
        checked: create != null,
        apply: () async {
          if (create == null) return;
          link(
            await create(
              kind,
              createInput(kind, s, stashBoxEndpoint: stashBoxEndpoint),
            ),
          );
        },
      ),
    );
  }

  for (final f in fields) {
    final v = r.values[f.key];
    if (v == null) continue;
    switch (f) {
      case ImageEditField() when v is String && v.isNotEmpty:
        items.add(
          MergeItem(
            label: f.label,
            current: null,
            proposed: 'Nouvelle image',
            image: v,
            // Replacing the current image is opt-in.
            checked: false,
            apply: () => f.setImage(v),
          ),
        );
      case TextEditField() when v is String:
        final value = v.trim();
        final current = f.controller.text.trim();
        if (value.isEmpty || value == current) continue;
        items.add(
          MergeItem(
            label: f.label,
            current: current.isEmpty ? null : current,
            proposed: value,
            // Fill empty fields by default; replacing needs a tick.
            checked: current.isEmpty,
            apply: () => f.controller.text = value,
          ),
        );
      case IntEditField() when v is int:
        final value = '${(v / f.factor).round()}';
        final current = f.controller.text.trim();
        if (value == current) continue;
        final unit = f.suffix == null ? '' : ' ${f.suffix}';
        items.add(
          MergeItem(
            label: f.label,
            current: current.isEmpty ? null : '$current$unit',
            proposed: '$value$unit',
            checked: current.isEmpty,
            apply: () => f.controller.text = value,
          ),
        );
      case ChoiceEditField() when v is String:
        if (!f.options.containsKey(v) || v == f.value) continue;
        items.add(
          MergeItem(
            label: f.label,
            current: f.value == null ? null : f.options[f.value],
            proposed: f.options[v]!,
            checked: f.value == null,
            apply: () => f.value = v,
          ),
        );
      case RefEditField() when v is ScrapedRef:
        final ref = v.ref;
        if (ref == null) {
          missingRef(f.kind, f.label, v, (created) => f.value = created);
        } else if (ref.id != f.value?.id) {
          items.add(
            MergeItem(
              label: f.label,
              current: f.value?.name,
              proposed: ref.name,
              checked: f.value == null,
              apply: () => f.value = ref,
            ),
          );
        }
      case RefsEditField() when v is List<ScrapedRef>:
        final have = {for (final r in f.items) r.id};
        final add = [
          for (final s in v)
            if (s.ref case final ref? when !have.contains(ref.id)) ref,
        ];
        for (final s in v) {
          if (s.storedId == null) {
            missingRef(f.kind, f.label, s, (created) {
              if (!f.items.any((i) => i.id == created.id)) {
                f.items.add(created);
              }
            });
          }
        }
        if (add.isEmpty) continue;
        items.add(
          MergeItem(
            label: f.label,
            current: f.items.isEmpty
                ? null
                : f.items.map((i) => i.name).join(', '),
            proposed: '+ ${add.map((a) => a.name).join(', ')}',
            apply: () => f.items.addAll(add),
          ),
        );
      case StringListEditField() when v is List<String>:
        final add = [
          for (final s in v)
            if (!f.items.contains(s)) s,
        ];
        if (add.isEmpty) continue;
        items.add(
          MergeItem(
            label: f.label,
            current: f.items.isEmpty ? null : f.items.join(', '),
            proposed: '+ ${add.join('\n+ ')}',
            apply: () => f.items.addAll(add),
          ),
        );
      default:
        break;
    }
  }
  return (items, missing);
}

Widget _preview(String image, {double size = 72}) {
  final Widget img = image.startsWith('data:')
      ? Image.memory(UriData.parse(image).contentAsBytes(), fit: BoxFit.cover)
      : Image.network(image, fit: BoxFit.cover);
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(width: size * 16 / 9, height: size, child: img),
  );
}

/// Scrapes item [id] of [kind] and lets the user pick which values go into
/// the edit [fields]. Returns true when the form changed.
Future<bool> scrapeIntoFields(
  BuildContext context,
  ScrapeKind kind,
  String id,
  List<EditField> fields,
) async {
  final repo = context.read<AppState>().repo!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  T? field<T extends EditField>(String key) =>
      fields.whereType<T>().where((f) => f.key == key).firstOrNull;

  final List<ScrapeSource> sources;
  try {
    sources = await _withProgress(context, repo.scrapeSources(kind));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  }
  if (!context.mounted) return false;

  // Studios cannot be scraped from a URL.
  final urls = kind == ScrapeKind.studio
      ? null
      : (field<StringListEditField>('urls')?.items ?? const <String>[]);
  final choice = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SourceSheet(sources: sources, urls: urls),
  );
  if (choice == null || !context.mounted) return false;

  var results = <Scraped>[];
  var searched = false;
  try {
    if (choice is ScrapeSource) {
      if (choice.byFragment) {
        results = [
          for (final r in await _withProgress(
            context,
            repo.scrape(kind, choice, id),
          ))
            toScraped(kind, r),
        ];
      }
      if (results.isEmpty && choice.byName && context.mounted) {
        final name =
            (field<TextEditField>('title') ?? field<TextEditField>('name'))
                ?.controller
                .text;
        final query = await _askQuery(context, choice, name ?? '');
        if (query == null || !context.mounted) return false;
        searched = true;
        results = [
          for (final r in await _withProgress(
            context,
            repo.scrape(kind, choice, id, query: query),
          ))
            toScraped(kind, r),
        ];
      }
    } else {
      final r = await _withProgress(
        context,
        repo.scrapeUrl(kind, choice as String),
      );
      if (r != null) results = [toScraped(kind, r)];
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  }
  if (!context.mounted) return false;
  if (results.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Aucun résultat')));
    return false;
  }

  var picked = results.length == 1
      ? results.single
      : await navigator.push<Scraped>(
          MaterialPageRoute(builder: (_) => _ResultsScreen(results: results)),
        );
  if (picked == null || !context.mounted) return false;

  // A scraper's search results are summaries: ask it for the full record,
  // as the web UI does. Stash-box results are already complete.
  if (searched &&
      choice is ScrapeSource &&
      !choice.isStashBox &&
      kind != ScrapeKind.studio) {
    try {
      final full = await _withProgress(
        context,
        repo.scrape(kind, choice, id, fragment: picked.raw),
      );
      if (full.isNotEmpty) picked = toScraped(kind, full.first);
    } catch (_) {
      // Keep the summary.
    }
  }

  final (items, missing) = mergeItems(
    picked!,
    fields,
    create: repo.createRef,
    stashBoxEndpoint: choice is ScrapeSource ? choice.stashBoxEndpoint : null,
  );
  if (items.isEmpty && missing.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Rien de nouveau dans ce résultat')),
    );
    return false;
  }
  final applied = await navigator.push<bool>(
    MaterialPageRoute(
      builder: (_) => _MergeScreen(items: items, missing: missing),
    ),
  );
  return applied ?? false;
}

/// Runs [future] behind a modal progress indicator.
Future<T> _withProgress<T>(BuildContext context, Future<T> future) async {
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await future;
  } finally {
    navigator.pop();
  }
}

Future<String?> _askQuery(
  BuildContext context,
  ScrapeSource source,
  String initial,
) async {
  final controller = TextEditingController(text: initial);
  final query = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Rechercher sur ${source.label}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Titre, code…'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Rechercher'),
        ),
      ],
    ),
  );
  controller.dispose();
  return query == null || query.isEmpty ? null : query;
}

/// Lists stash-boxes, scrapers and the scene's URLs. Pops a [ScrapeSource]
/// or a URL string.
class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.sources, required this.urls});
  final List<ScrapeSource> sources;

  /// Item URLs to scrape, or null when URL scraping is not available.
  final List<String>? urls;

  Future<void> _otherUrl(BuildContext context) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scraper une URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Scraper'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url != null && url.isNotEmpty && context.mounted) {
      Navigator.pop(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = sources.where((s) => s.isStashBox).toList();
    final scrapers = sources.where((s) => !s.isStashBox).toList();
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Scraper avec…',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          if (boxes.isNotEmpty) header('Stash-box'),
          for (final s in boxes)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(s.label),
              subtitle: Text(
                s.byFragment
                    ? 'Par empreinte, sinon par recherche'
                    : 'Par recherche',
              ),
              onTap: () => Navigator.pop(context, s),
            ),
          if (scrapers.isNotEmpty) header('Scrapers'),
          for (final s in scrapers)
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: Text(s.label),
              subtitle: Text(
                [
                  if (s.byFragment) 'par la scène',
                  if (s.byName) 'par recherche',
                ].join(', '),
              ),
              onTap: () => Navigator.pop(context, s),
            ),
          if (urls != null) ...[
            header('Depuis une URL'),
            for (final u in urls!)
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(u, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(context, u),
              ),
            ListTile(
              leading: const Icon(Icons.add_link),
              title: const Text('Autre URL…'),
              onTap: () => _otherUrl(context),
            ),
          ],
          if (sources.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun scraper ni stash-box n\'est configuré pour ce type sur '
                'le serveur (Paramètres > Métadonnées).',
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({required this.results});
  final List<Scraped> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${results.length} résultats')),
    body: ListView(
      children: [
        for (final r in results)
          ListTile(
            leading: r.preview == null ? null : _preview(r.preview!, size: 40),
            title: Text(r.title),
            subtitle: Text(
              r.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.pop(context, r),
          ),
      ],
    ),
  );
}

class _MergeScreen extends StatefulWidget {
  const _MergeScreen({required this.items, required this.missing});
  final List<MergeItem> items;

  /// Items to create in Stash before linking them.
  final List<MergeItem> missing;

  @override
  State<_MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<_MergeScreen> {
  bool _busy = false;

  Future<void> _apply() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    for (final i in widget.items) {
      if (i.checked) await i.apply();
    }
    // Creations hit the server: show progress and keep going on failure.
    final toCreate = widget.missing.where((m) => m.checked).toList();
    final failed = <String>[];
    if (toCreate.isNotEmpty) {
      setState(() => _busy = true);
      for (final m in toCreate) {
        try {
          await m.apply();
        } catch (e) {
          failed.add('${m.proposed} ($e)');
        }
      }
    }
    final created = toCreate.length - failed.length;
    if (created > 0 || failed.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          duration: Duration(seconds: failed.isEmpty ? 4 : 10),
          content: Text(
            [
              if (created > 0)
                '$created élément${created > 1 ? 's' : ''} créé${created > 1 ? 's' : ''} dans Stash',
              if (failed.isNotEmpty) 'Échec : ${failed.join(', ')}',
            ].join('\n'),
          ),
        ),
      );
    }
    navigator.pop(widget.items.any((i) => i.checked) || created > 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du scraping'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed:
                  _busy || (widget.items.isEmpty && widget.missing.isEmpty)
                  ? null
                  : _apply,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Appliquer'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Cochez les valeurs à reprendre. Elles remplissent le formulaire '
              'de modification et ne sont enregistrées qu\'avec « Enregistrer » '
              '(sauf les éléments à créer, plus bas).',
            ),
          ),
          for (final i in widget.items)
            CheckboxListTile(
              value: i.checked,
              onChanged: (v) => setState(() => i.checked = v ?? false),
              title: Text(i.label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i.current != null)
                    Text(
                      'Actuel : ${i.current}',
                      style: dim,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (i.image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _preview(i.image!),
                    )
                  else
                    Text(
                      i.proposed,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          if (widget.missing.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Absents de Stash',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'Les éléments cochés sont créés dans Stash (avec les '
                'informations du scraper) dès « Appliquer », puis liés.',
                style: dim,
              ),
            ),
            for (final m in widget.missing)
              CheckboxListTile(
                value: m.checked,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => m.checked = v ?? false),
                secondary: const Icon(Icons.add_circle_outline),
                title: Text(m.proposed),
                subtitle: Text('Créer et lier · ${m.label}'),
              ),
          ],
        ],
      ),
    );
  }
}
