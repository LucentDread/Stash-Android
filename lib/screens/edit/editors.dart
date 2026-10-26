import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/stash_repository.dart';
import '../../l10n/l10n.dart';
import '../../models/models.dart';
import '../../navigation.dart';
import '../../services/app_state.dart';
import '../../utils/format.dart';
import 'edit_form.dart';
import 'scrape.dart';

/// Opens an edit form; returns true when changes were saved.
///
/// With [closeOnDelete], [context] is the page of the item: once the item
/// is deleted, that page closes and the lists reload.
Future<bool> _open(
  BuildContext context, {
  required String title,
  required EditKind kind,
  required String id,
  required List<EditField> fields,
  Future<void> Function()? delete,
  String? deleteLabel,
  bool closeOnDelete = false,
  List<Widget> Function(BuildContext, VoidCallback)? extraActions,
}) async {
  final app = context.read<AppState>();
  final repo = app.repo!;
  var deleted = false;
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditScreen(
        title: title,
        fields: fields,
        save: (input) => repo.update(kind, id, input),
        delete: delete == null
            ? null
            : () async {
                await delete();
                deleted = true;
              },
        deleteLabel: deleteLabel,
        extraActions: extraActions,
      ),
    ),
  );
  if (deleted && closeOnDelete) {
    app.refreshData();
    if (context.mounted) Navigator.of(context).pop();
    return false;
  }
  return saved ?? false;
}

/// Delete action of an item's edit form: removes it from Stash.
Future<void> Function() _destroy(
  BuildContext context,
  EditKind kind,
  String id,
) {
  final repo = context.read<AppState>().repo!;
  return () => repo.destroy(kind, id);
}

Map<String?, String> get _genders => {
  null: '—',
  for (final g in const [
    'FEMALE',
    'MALE',
    'TRANSGENDER_FEMALE',
    'TRANSGENDER_MALE',
    'INTERSEX',
    'NON_BINARY',
  ])
    g: genderLabel(g),
};

/// Editable fields of a scene.
List<EditField> sceneFields(Scene s) => [
  ImageEditField('cover_image', tr.cover, s.screenshot),
  TextEditField('title', tr.sortTitle, s.title),
  TextEditField('code', tr.code, s.code),
  DateEditField('date', tr.date, s.date),
  TextEditField('director', tr.director, s.director),
  RatingEditField(s.rating100),
  BoolEditField('organized', tr.organized, s.organized),
  RefEditField('studio_id', tr.studio, RefKind.studios, s.studio),
  RefsEditField(
    'performer_ids',
    tr.performers,
    RefKind.performers,
    s.performers,
  ),
  RefsEditField('tag_ids', tr.tags, RefKind.tags, s.tags),
  RefsEditField(
    'groups',
    tr.groups,
    RefKind.groups,
    s.groups,
    // Keep each group's scene number; new groups get none.
    encode: (items) => {
      'groups': [
        for (final g in items)
          {'group_id': g.id, 'scene_index': s.groupIndexes[g.id]},
      ],
    },
  ),
  StringListEditField('urls', tr.links, s.urls, hint: 'https://…'),
  TextEditField('details', tr.description, s.details, multiline: true),
];

/// Opens an edit form with a "Scraper" button filling its [fields].
Future<bool> _openScrapable(
  BuildContext context, {
  required String title,
  required EditKind kind,
  required ScrapeKind scrapeKind,
  required String id,
  required List<EditField> fields,
  String? deleteLabel,
}) => _open(
  context,
  title: title,
  kind: kind,
  id: id,
  fields: fields,
  delete: deleteLabel == null ? null : _destroy(context, kind, id),
  deleteLabel: deleteLabel,
  closeOnDelete: true,
  extraActions: (context, refresh) => [
    IconButton(
      tooltip: tr.scrape,
      icon: const Icon(Icons.travel_explore),
      onPressed: () async {
        if (await scrapeIntoFields(context, scrapeKind, id, fields)) {
          refresh();
        }
      },
    ),
  ],
);

Future<bool> editScene(BuildContext context, Scene s) => _openScrapable(
  context,
  title: tr.editScene,
  kind: EditKind.scene,
  scrapeKind: ScrapeKind.scene,
  id: s.id,
  fields: sceneFields(s),
);

/// Editable fields of a performer; [p] is null when creating one.
List<EditField> performerFields(Performer? p) => [
  ImageEditField('image', tr.photo, p?.imagePath),
  TextEditField('name', tr.sortName, p?.name, required: true),
  TextEditField('disambiguation', tr.disambiguation, p?.disambiguation),
  StringListEditField('alias_list', tr.aliases, p?.aliases ?? const []),
  ChoiceEditField('gender', tr.gender, p?.gender, _genders),
  DateEditField('birthdate', tr.sortBirthdate, p?.birthdate),
  DateEditField('death_date', tr.deathDate, p?.deathDate),
  TextEditField('country', tr.country, p?.country),
  TextEditField('ethnicity', tr.ethnicity, p?.ethnicity),
  TextEditField('hair_color', tr.hairColor, p?.hairColor),
  TextEditField('eye_color', tr.eyeColor, p?.eyeColor),
  IntEditField('height_cm', tr.height, p?.heightCm, suffix: 'cm'),
  IntEditField('weight', tr.weight, p?.weight, suffix: 'kg'),
  TextEditField('measurements', tr.measurements, p?.measurements),
  TextEditField('fake_tits', tr.fakeTits, p?.fakeTits),
  TextEditField('tattoos', tr.tattoos, p?.tattoos),
  TextEditField('piercings', tr.piercings, p?.piercings),
  RatingEditField(p?.rating100),
  BoolEditField('favorite', tr.favorite, p?.favorite ?? false),
  RefsEditField('tag_ids', tr.tags, RefKind.tags, p?.tags ?? const []),
  StringListEditField('urls', tr.links, p?.urls ?? const [], hint: 'https://…'),
  TextEditField('details', tr.description, p?.details, multiline: true),
];

Future<bool> editPerformer(BuildContext context, Performer p) => _openScrapable(
  context,
  title: tr.editPerformer,
  kind: EditKind.performer,
  scrapeKind: ScrapeKind.performer,
  id: p.id,
  fields: performerFields(p),
  deleteLabel: tr.deletePerformer,
);

/// Editable fields of a studio; [s] is null when creating one.
List<EditField> studioFields(Studio? s) => [
  ImageEditField('image', tr.logo, s?.imagePath),
  TextEditField('name', tr.sortName, s?.name, required: true),
  RefEditField('parent_id', tr.parentStudio, RefKind.studios, s?.parent),
  RatingEditField(s?.rating100),
  BoolEditField('favorite', tr.favorite, s?.favorite ?? false),
  StringListEditField('urls', tr.links, s?.urls ?? const [], hint: 'https://…'),
  TextEditField('details', tr.description, s?.details, multiline: true),
];

Future<bool> editStudio(BuildContext context, Studio s) => _openScrapable(
  context,
  title: tr.editStudio,
  kind: EditKind.studio,
  scrapeKind: ScrapeKind.studio,
  id: s.id,
  fields: studioFields(s),
  deleteLabel: tr.deleteStudio,
);

/// Editable fields of a tag; [t] is null when creating one.
List<EditField> tagFields(Tag? t) => [
  ImageEditField('image', tr.image, t?.imagePath),
  TextEditField('name', tr.sortName, t?.name, required: true),
  StringListEditField('aliases', tr.aliases, t?.aliases ?? const []),
  BoolEditField('favorite', tr.favorite, t?.favorite ?? false),
  RefsEditField(
    'parent_ids',
    tr.parentTags,
    RefKind.tags,
    t?.parents ?? const [],
  ),
  TextEditField('description', tr.description, t?.description, multiline: true),
];

Future<bool> editTag(BuildContext context, Tag t) => _open(
  context,
  title: tr.editTag,
  kind: EditKind.tag,
  id: t.id,
  fields: tagFields(t),
  delete: _destroy(context, EditKind.tag, t.id),
  deleteLabel: tr.deleteTag,
  closeOnDelete: true,
);

/// Editable fields of a group; [g] is null when creating one.
List<EditField> groupFields(Group? g) => [
  ImageEditField('front_image', tr.frontCover, g?.frontImage),
  ImageEditField('back_image', tr.backCover, g?.backImage),
  TextEditField('name', tr.sortName, g?.name, required: true),
  TextEditField('aliases', tr.aliases, g?.aliases),
  DateEditField('date', tr.date, g?.date),
  IntEditField('duration', tr.duration, g?.duration, factor: 60, suffix: 'min'),
  TextEditField('director', tr.director, g?.director),
  RefEditField('studio_id', tr.studio, RefKind.studios, g?.studio),
  RatingEditField(g?.rating100),
  RefsEditField('tag_ids', tr.tags, RefKind.tags, g?.tags ?? const []),
  StringListEditField('urls', tr.links, g?.urls ?? const [], hint: 'https://…'),
  TextEditField('synopsis', tr.synopsis, g?.synopsis, multiline: true),
];

Future<bool> editGroup(BuildContext context, Group g) => _openScrapable(
  context,
  title: tr.editGroup,
  kind: EditKind.group,
  scrapeKind: ScrapeKind.group,
  id: g.id,
  fields: groupFields(g),
  deleteLabel: tr.deleteGroup,
);

/// "Edit" app bar button that reloads the screen after saving.
class EditButton extends StatelessWidget {
  const EditButton({super.key, required this.onEdit, required this.onSaved});
  final Future<bool> Function() onEdit;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tr.edit,
    icon: const Icon(Icons.edit_outlined),
    onPressed: () async {
      if (await onEdit()) onSaved();
    },
  );
}

/// Editable fields of a gallery; [g] is null when creating one (Stash
/// then requires a title).
List<EditField> galleryFields(Gallery? g) => [
  TextEditField('title', tr.sortTitle, g?.title, required: g == null),
  TextEditField('code', tr.code, g?.code),
  DateEditField('date', tr.date, g?.date),
  TextEditField('photographer', tr.photographer, g?.photographer),
  RatingEditField(g?.rating100),
  BoolEditField('organized', tr.organized, g?.organized ?? false),
  RefEditField('studio_id', tr.studio, RefKind.studios, g?.studio),
  RefsEditField(
    'performer_ids',
    tr.performers,
    RefKind.performers,
    g?.performers ?? const [],
  ),
  RefsEditField('tag_ids', tr.tags, RefKind.tags, g?.tags ?? const []),
  StringListEditField('urls', tr.links, g?.urls ?? const [], hint: 'https://…'),
  TextEditField('details', tr.description, g?.details, multiline: true),
];

Future<bool> editGallery(BuildContext context, Gallery g) => _openScrapable(
  context,
  title: tr.editGallery,
  kind: EditKind.gallery,
  scrapeKind: ScrapeKind.gallery,
  id: g.id,
  fields: galleryFields(g),
  // Galleries of a folder or a zip come back at the next scan.
  deleteLabel: (g.folderPath?.isNotEmpty ?? false) ? null : tr.deleteGallery,
);

/// Fields of a marker; [m] is null when creating one at [at] seconds.
List<EditField> markerFields(SceneMarker? m, {double at = 0}) => [
  // Stash requires a title (possibly empty) and a primary tag.
  TextEditField('title', tr.sortTitle, m?.title, emptyAsNull: false),
  TimeEditField('seconds', tr.start, m?.seconds ?? at, required: true),
  TimeEditField('end_seconds', tr.endOptional, m?.endSeconds),
  RefEditField(
    'primary_tag_id',
    tr.primaryTag,
    RefKind.tags,
    m?.primaryTag,
    required: true,
  ),
  RefsEditField('tag_ids', tr.otherTags, RefKind.tags, m?.tags ?? const []),
];

Future<bool> editMarker(BuildContext context, SceneMarker m) {
  final repo = context.read<AppState>().repo!;
  return _open(
    context,
    title: tr.editMarker,
    kind: EditKind.marker,
    id: m.id,
    fields: markerFields(m),
    delete: () => repo.deleteMarker(m.id),
    deleteLabel: tr.deleteMarker,
  );
}

/// Creation form for a marker on [sceneId], starting at [at] seconds.
Future<bool> createMarker(
  BuildContext context,
  String sceneId, {
  required double at,
}) async {
  final repo = context.read<AppState>().repo!;
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditScreen(
        title: tr.newMarker,
        fields: markerFields(null, at: at),
        create: true,
        save: (input) => repo.createMarker(sceneId, input),
      ),
    ),
  );
  return saved ?? false;
}

/// Creation form of a performer, studio, tag, group or gallery; opens the
/// new item once saved.
Future<void> _createEntity(
  BuildContext context, {
  required String title,
  required EditKind kind,
  required List<EditField> fields,
  required void Function(BuildContext context, String id) open,
}) async {
  final app = context.read<AppState>();
  String? id;
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditScreen(
        title: title,
        fields: fields,
        create: true,
        save: (input) async => id = await app.repo!.create(kind, input),
      ),
    ),
  );
  if (saved != true || id == null) return;
  app.refreshData(); // lists show the new item
  if (context.mounted) open(context, id!);
}

Future<void> createPerformer(BuildContext context) => _createEntity(
  context,
  title: tr.newPerformer,
  kind: EditKind.performer,
  fields: performerFields(null),
  open: openPerformer,
);

Future<void> createStudio(BuildContext context) => _createEntity(
  context,
  title: tr.newStudio,
  kind: EditKind.studio,
  fields: studioFields(null),
  open: openStudio,
);

Future<void> createTag(BuildContext context) => _createEntity(
  context,
  title: tr.newTag,
  kind: EditKind.tag,
  fields: tagFields(null),
  open: openTag,
);

Future<void> createGroup(BuildContext context) => _createEntity(
  context,
  title: tr.newGroup,
  kind: EditKind.group,
  fields: groupFields(null),
  open: openGroup,
);

Future<void> createGallery(BuildContext context) => _createEntity(
  context,
  title: tr.newGallery,
  kind: EditKind.gallery,
  fields: galleryFields(null),
  open: openGallery,
);
