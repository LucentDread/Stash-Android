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
  final VoidCallback apply;
  bool checked;

  /// New cover (data URI or URL) to preview.
  final String? image;
}

/// Changes a scraped scene would bring to the scene edit [fields], plus the
/// names it found that do not exist in Stash (which cannot be linked).
(List<MergeItem>, List<String>) mergeItems(
  ScrapedScene r,
  List<EditField> fields,
) {
  T? field<T extends EditField>(String key) =>
      fields.whereType<T>().where((f) => f.key == key).firstOrNull;
  final items = <MergeItem>[];
  final missing = <String>[];

  void text(String key, String? value) {
    final f = field<TextEditField>(key);
    final v = value?.trim();
    if (f == null || v == null || v.isEmpty) return;
    final current = f.controller.text.trim();
    if (current == v) return;
    items.add(
      MergeItem(
        label: f.label,
        current: current.isEmpty ? null : current,
        proposed: v,
        // Fill empty fields by default; replacing needs a tick.
        checked: current.isEmpty,
        apply: () => f.controller.text = v,
      ),
    );
  }

  text('title', r.title);
  text('code', r.code);
  text('date', r.date);
  text('director', r.director);
  text('details', r.details);

  final studio = field<RefEditField>('studio_id');
  if (studio != null && r.studio != null) {
    final ref = r.studio!.ref;
    if (ref == null) {
      missing.add('Studio : ${r.studio!.name}');
    } else if (ref.id != studio.value?.id) {
      items.add(
        MergeItem(
          label: studio.label,
          current: studio.value?.name,
          proposed: ref.name,
          checked: studio.value == null,
          apply: () => studio.value = ref,
        ),
      );
    }
  }

  void refs(String key, List<ScrapedRef> scraped, String noun) {
    final f = field<RefsEditField>(key);
    if (f == null) return;
    final have = {for (final r in f.items) r.id};
    final add = [
      for (final s in scraped)
        if (s.ref case final ref? when !have.contains(ref.id)) ref,
    ];
    missing.addAll([
      for (final s in scraped)
        if (s.storedId == null) '$noun : ${s.name}',
    ]);
    if (add.isEmpty) return;
    items.add(
      MergeItem(
        label: f.label,
        current: f.items.isEmpty ? null : f.items.map((i) => i.name).join(', '),
        proposed: '+ ${add.map((a) => a.name).join(', ')}',
        apply: () => f.items.addAll(add),
      ),
    );
  }

  refs('performer_ids', r.performers, 'Performeur');
  refs('tag_ids', r.tags, 'Tag');
  refs('groups', r.groups, 'Groupe');

  final urls = field<StringListEditField>('urls');
  if (urls != null) {
    final add = [
      for (final u in r.urls)
        if (!urls.items.contains(u)) u,
    ];
    if (add.isNotEmpty) {
      items.add(
        MergeItem(
          label: urls.label,
          current: urls.items.isEmpty ? null : '${urls.items.length} lien(s)',
          proposed: '+ ${add.join('\n+ ')}',
          apply: () => urls.items.addAll(add),
        ),
      );
    }
  }

  final cover = field<ImageEditField>('cover_image');
  if (cover != null && r.image != null && r.image!.isNotEmpty) {
    items.add(
      MergeItem(
        label: cover.label,
        current: null,
        proposed: 'Nouvelle image',
        image: r.image,
        // Replacing the current cover is opt-in.
        checked: false,
        apply: () => cover.setImage(r.image!),
      ),
    );
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

/// Scrapes the scene and lets the user pick which values go into the edit
/// [fields]. Returns true when the form changed.
Future<bool> scrapeIntoFields(
  BuildContext context,
  String sceneId,
  List<EditField> fields,
) async {
  final repo = context.read<AppState>().repo!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final List<ScrapeSource> sources;
  try {
    sources = await _withProgress(context, repo.sceneScrapeSources());
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  }
  if (!context.mounted) return false;

  final sceneUrls =
      fields
          .whereType<StringListEditField>()
          .where((f) => f.key == 'urls')
          .firstOrNull
          ?.items ??
      const <String>[];
  final choice = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SourceSheet(sources: sources, urls: sceneUrls),
  );
  if (choice == null || !context.mounted) return false;

  List<ScrapedScene> results;
  try {
    if (choice is ScrapeSource) {
      results = choice.byFragment
          ? await _withProgress(context, repo.scrapeScene(choice, sceneId))
          : const [];
      if (results.isEmpty && choice.byName && context.mounted) {
        // Nothing from the scene itself: offer a search by name.
        final title = fields
            .whereType<TextEditField>()
            .where((f) => f.key == 'title')
            .firstOrNull
            ?.controller
            .text;
        final query = await _askQuery(context, choice, title ?? '');
        if (query == null || !context.mounted) return false;
        results = await _withProgress(
          context,
          repo.scrapeScene(choice, sceneId, query: query),
        );
      }
    } else {
      final r = await _withProgress(
        context,
        repo.scrapeSceneUrl(choice as String),
      );
      results = [?r];
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

  final picked = results.length == 1
      ? results.single
      : await navigator.push<ScrapedScene>(
          MaterialPageRoute(builder: (_) => _ResultsScreen(results: results)),
        );
  if (picked == null) return false;

  final (items, missing) = mergeItems(picked, fields);
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
  final List<String> urls;

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
              subtitle: const Text('Par empreinte, sinon par recherche'),
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
          header('Depuis une URL'),
          for (final u in urls)
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
          if (sources.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun scraper de scènes ni stash-box n\'est configuré sur le '
                'serveur (Paramètres > Métadonnées).',
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({required this.results});
  final List<ScrapedScene> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${results.length} résultats')),
    body: ListView(
      children: [
        for (final r in results)
          ListTile(
            leading: r.image == null ? null : _preview(r.image!, size: 40),
            title: Text(r.title ?? 'Sans titre'),
            subtitle: Text(
              [
                if (r.studio != null) r.studio!.name,
                if (r.date != null) r.date!,
                if (r.performers.isNotEmpty)
                  r.performers.map((p) => p.name).join(', '),
              ].join(' • '),
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
  final List<String> missing;

  @override
  State<_MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<_MergeScreen> {
  void _apply() {
    for (final i in widget.items) {
      if (i.checked) i.apply();
    }
    Navigator.pop(context, widget.items.any((i) => i.checked));
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
              onPressed: widget.items.isEmpty ? null : _apply,
              child: const Text('Appliquer'),
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
              'de modification : rien n\'est enregistré avant « Enregistrer ».',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Absents de Stash (non liés)',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Créez-les dans Stash pour pouvoir les lier : '
                '${widget.missing.join(' · ')}',
                style: dim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
