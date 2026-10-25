import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/stash_repository.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import 'edit_form.dart';

/// Opens an edit form; returns true when changes were saved.
Future<bool> _open(
  BuildContext context, {
  required String title,
  required EditKind kind,
  required String id,
  required List<EditField> fields,
  Future<void> Function()? delete,
  String deleteLabel = 'Supprimer',
}) async {
  final repo = context.read<AppState>().repo!;
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditScreen(
        title: title,
        fields: fields,
        save: (input) => repo.update(kind, id, input),
        delete: delete,
        deleteLabel: deleteLabel,
      ),
    ),
  );
  return saved ?? false;
}

const _genders = <String?, String>{
  null: '—',
  'FEMALE': 'Femme',
  'MALE': 'Homme',
  'TRANSGENDER_FEMALE': 'Femme trans',
  'TRANSGENDER_MALE': 'Homme trans',
  'INTERSEX': 'Intersexe',
  'NON_BINARY': 'Non-binaire',
};

/// Editable fields of a scene.
List<EditField> sceneFields(Scene s) => [
  ImageEditField('cover_image', 'Couverture', s.screenshot),
  TextEditField('title', 'Titre', s.title),
  TextEditField('code', 'Code', s.code),
  DateEditField('date', 'Date', s.date),
  TextEditField('director', 'Réalisateur', s.director),
  RatingEditField(s.rating100),
  BoolEditField('organized', 'Organisée', s.organized),
  RefEditField('studio_id', 'Studio', RefKind.studios, s.studio),
  RefsEditField(
    'performer_ids',
    'Performeurs',
    RefKind.performers,
    s.performers,
  ),
  RefsEditField('tag_ids', 'Tags', RefKind.tags, s.tags),
  RefsEditField(
    'groups',
    'Groupes',
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
  StringListEditField('urls', 'Liens', s.urls, hint: 'https://…'),
  TextEditField('details', 'Description', s.details, multiline: true),
];

Future<bool> editScene(BuildContext context, Scene s) => _open(
  context,
  title: 'Modifier la scène',
  kind: EditKind.scene,
  id: s.id,
  fields: sceneFields(s),
);

/// Editable fields of a performer.
List<EditField> performerFields(Performer p) => [
  ImageEditField('image', 'Photo', p.imagePath),
  TextEditField('name', 'Nom', p.name, required: true),
  TextEditField('disambiguation', 'Désambiguïsation', p.disambiguation),
  StringListEditField('alias_list', 'Alias', p.aliases),
  ChoiceEditField('gender', 'Genre', p.gender, _genders),
  DateEditField('birthdate', 'Date de naissance', p.birthdate),
  DateEditField('death_date', 'Date de décès', p.deathDate),
  TextEditField('country', 'Pays', p.country),
  TextEditField('ethnicity', 'Origine', p.ethnicity),
  TextEditField('hair_color', 'Cheveux', p.hairColor),
  TextEditField('eye_color', 'Yeux', p.eyeColor),
  IntEditField('height_cm', 'Taille', p.heightCm, suffix: 'cm'),
  IntEditField('weight', 'Poids', p.weight, suffix: 'kg'),
  TextEditField('measurements', 'Mensurations', p.measurements),
  TextEditField('fake_tits', 'Implants', p.fakeTits),
  TextEditField('tattoos', 'Tatouages', p.tattoos),
  TextEditField('piercings', 'Piercings', p.piercings),
  RatingEditField(p.rating100),
  BoolEditField('favorite', 'Favori', p.favorite),
  RefsEditField('tag_ids', 'Tags', RefKind.tags, p.tags),
  StringListEditField('urls', 'Liens', p.urls, hint: 'https://…'),
  TextEditField('details', 'Description', p.details, multiline: true),
];

Future<bool> editPerformer(BuildContext context, Performer p) => _open(
  context,
  title: 'Modifier le performeur',
  kind: EditKind.performer,
  id: p.id,
  fields: performerFields(p),
);

/// Editable fields of a studio.
List<EditField> studioFields(Studio s) => [
  ImageEditField('image', 'Logo', s.imagePath),
  TextEditField('name', 'Nom', s.name, required: true),
  RefEditField('parent_id', 'Studio parent', RefKind.studios, s.parent),
  RatingEditField(s.rating100),
  BoolEditField('favorite', 'Favori', s.favorite),
  StringListEditField('urls', 'Liens', s.urls, hint: 'https://…'),
  TextEditField('details', 'Description', s.details, multiline: true),
];

Future<bool> editStudio(BuildContext context, Studio s) => _open(
  context,
  title: 'Modifier le studio',
  kind: EditKind.studio,
  id: s.id,
  fields: studioFields(s),
);

/// Editable fields of a tag.
List<EditField> tagFields(Tag t) => [
  ImageEditField('image', 'Image', t.imagePath),
  TextEditField('name', 'Nom', t.name, required: true),
  StringListEditField('aliases', 'Alias', t.aliases),
  BoolEditField('favorite', 'Favori', t.favorite),
  RefsEditField('parent_ids', 'Tags parents', RefKind.tags, t.parents),
  TextEditField('description', 'Description', t.description, multiline: true),
];

Future<bool> editTag(BuildContext context, Tag t) => _open(
  context,
  title: 'Modifier le tag',
  kind: EditKind.tag,
  id: t.id,
  fields: tagFields(t),
);

/// Editable fields of a group.
List<EditField> groupFields(Group g) => [
  ImageEditField('front_image', 'Jaquette (recto)', g.frontImage),
  ImageEditField('back_image', 'Jaquette (verso)', g.backImage),
  TextEditField('name', 'Nom', g.name, required: true),
  TextEditField('aliases', 'Alias', g.aliases),
  DateEditField('date', 'Date', g.date),
  IntEditField('duration', 'Durée', g.duration, factor: 60, suffix: 'min'),
  TextEditField('director', 'Réalisateur', g.director),
  RefEditField('studio_id', 'Studio', RefKind.studios, g.studio),
  RatingEditField(g.rating100),
  RefsEditField('tag_ids', 'Tags', RefKind.tags, g.tags),
  StringListEditField('urls', 'Liens', g.urls, hint: 'https://…'),
  TextEditField('synopsis', 'Synopsis', g.synopsis, multiline: true),
];

Future<bool> editGroup(BuildContext context, Group g) => _open(
  context,
  title: 'Modifier le groupe',
  kind: EditKind.group,
  id: g.id,
  fields: groupFields(g),
);

/// "Edit" app bar button that reloads the screen after saving.
class EditButton extends StatelessWidget {
  const EditButton({super.key, required this.onEdit, required this.onSaved});
  final Future<bool> Function() onEdit;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Modifier',
    icon: const Icon(Icons.edit_outlined),
    onPressed: () async {
      if (await onEdit()) onSaved();
    },
  );
}

/// Editable fields of a gallery.
List<EditField> galleryFields(Gallery g) => [
  TextEditField('title', 'Titre', g.title),
  TextEditField('code', 'Code', g.code),
  DateEditField('date', 'Date', g.date),
  TextEditField('photographer', 'Photographe', g.photographer),
  RatingEditField(g.rating100),
  BoolEditField('organized', 'Organisée', g.organized),
  RefEditField('studio_id', 'Studio', RefKind.studios, g.studio),
  RefsEditField(
    'performer_ids',
    'Performeurs',
    RefKind.performers,
    g.performers,
  ),
  RefsEditField('tag_ids', 'Tags', RefKind.tags, g.tags),
  StringListEditField('urls', 'Liens', g.urls, hint: 'https://…'),
  TextEditField('details', 'Description', g.details, multiline: true),
];

Future<bool> editGallery(BuildContext context, Gallery g) => _open(
  context,
  title: 'Modifier la galerie',
  kind: EditKind.gallery,
  id: g.id,
  fields: galleryFields(g),
);

/// Fields of a marker; [m] is null when creating one at [at] seconds.
List<EditField> markerFields(SceneMarker? m, {double at = 0}) => [
  // Stash requires a title (possibly empty) and a primary tag.
  TextEditField('title', 'Titre', m?.title, emptyAsNull: false),
  TimeEditField('seconds', 'Début', m?.seconds ?? at, required: true),
  TimeEditField('end_seconds', 'Fin (optionnelle)', m?.endSeconds),
  RefEditField(
    'primary_tag_id',
    'Tag principal',
    RefKind.tags,
    m?.primaryTag,
    required: true,
  ),
  RefsEditField('tag_ids', 'Autres tags', RefKind.tags, m?.tags ?? const []),
];

Future<bool> editMarker(BuildContext context, SceneMarker m) {
  final repo = context.read<AppState>().repo!;
  return _open(
    context,
    title: 'Modifier le marqueur',
    kind: EditKind.marker,
    id: m.id,
    fields: markerFields(m),
    delete: () => repo.deleteMarker(m.id),
    deleteLabel: 'Supprimer le marqueur',
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
        title: 'Nouveau marqueur',
        fields: markerFields(null, at: at),
        create: true,
        save: (input) => repo.createMarker(sceneId, input),
      ),
    ),
  );
  return saved ?? false;
}
