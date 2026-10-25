import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';

class PerformerScreen extends StatelessWidget {
  const PerformerScreen({super.key, required this.performerId});
  final String performerId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Performer>(
      load: () => repo.findPerformer(performerId),
      builder: (context, p, _) {
        final entity = EntityFilter.performer(p.id);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.name),
              actions: [_FavoriteButton(performer: p)],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  const Tab(text: 'Infos'),
                  Tab(text: 'Scènes (${p.sceneCount})'),
                  Tab(text: 'Galeries (${p.galleryCount})'),
                  const Tab(text: 'Marqueurs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PerformerInfo(performer: p),
                sceneGrid(context, entity: entity),
                galleryGrid(context, entity: entity),
                markerGrid(context, entity: entity),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.performer});
  final Performer performer;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  late bool _favorite = widget.performer.favorite;

  Future<void> _toggle() async {
    final repo = context.read<AppState>().repo!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _favorite = !_favorite);
    try {
      await repo.setPerformerFavorite(widget.performer.id, _favorite);
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorite = !_favorite);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Favori',
    icon: Icon(
      _favorite ? Icons.favorite : Icons.favorite_border,
      color: _favorite ? Colors.redAccent : null,
    ),
    onPressed: _toggle,
  );
}

class _PerformerInfo extends StatelessWidget {
  const _PerformerInfo({required this.performer});
  final Performer performer;

  @override
  Widget build(BuildContext context) {
    final p = performer;
    final age = ageFrom(p.birthdate);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 220,
              height: 330,
              child: NetImage(
                p.imagePath,
                placeholderIcon: Icons.person,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        if (p.rating100 != null) ...[
          const SizedBox(height: 8),
          Center(child: StarRating(rating100: p.rating100)),
        ],
        Section(
          title: 'Informations',
          child: InfoTable([
            ('Désambiguïsation', p.disambiguation),
            ('Alias', p.aliases.join(', ')),
            ('Genre', genderLabel(p.gender)),
            (
              'Naissance',
              p.birthdate == null ? null : '${p.birthdate} ($age ans)',
            ),
            ('Pays', p.country),
            ('Origine', p.ethnicity),
            ('Taille', p.heightCm == null ? null : '${p.heightCm} cm'),
            ('Mensurations', p.measurements),
            ('Cheveux', p.hairColor),
            ('Yeux', p.eyeColor),
            ('Images', '${p.imageCount}'),
          ]),
        ),
        if (p.details != null && p.details!.isNotEmpty)
          Section(title: 'Description', child: SelectableText(p.details!)),
        if (p.tags.isNotEmpty)
          Section(
            title: 'Tags',
            child: RefChips(refs: p.tags, onTap: (r) => openTag(context, r.id)),
          ),
        if (p.urls.isNotEmpty) Section(title: 'Liens', child: UrlList(p.urls)),
      ],
    );
  }
}
