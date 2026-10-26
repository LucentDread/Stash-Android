import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';
import 'edit/editors.dart';

class PerformerScreen extends StatelessWidget {
  const PerformerScreen({super.key, required this.performerId});
  final String performerId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Performer>(
      load: () => repo.findPerformer(performerId),
      builder: (context, p, reload) {
        final entity = EntityFilter.performer(p.id);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.name),
              actions: [
                _FavoriteButton(key: ValueKey(p.favorite), performer: p),
                EditButton(
                  onEdit: () => editPerformer(context, p),
                  onSaved: reload,
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: tr.info),
                  Tab(text: '${tr.scenes} (${p.sceneCount})'),
                  Tab(text: '${tr.galleries} (${p.galleryCount})'),
                  Tab(text: tr.markers),
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
  const _FavoriteButton({super.key, required this.performer});
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
    tooltip: tr.favorite,
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
      padding: withNavBar(context, const EdgeInsets.all(16)),
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
          title: tr.information,
          child: InfoTable([
            (tr.disambiguation, p.disambiguation),
            (tr.aliases, p.aliases.join(', ')),
            (tr.gender, genderLabel(p.gender)),
            (
              tr.birth,
              p.birthdate == null
                  ? null
                  : '${p.birthdate} (${tr.yearsOld(age ?? 0)})',
            ),
            (tr.country, p.country),
            (tr.ethnicity, p.ethnicity),
            (tr.height, p.heightCm == null ? null : '${p.heightCm} cm'),
            (tr.measurements, p.measurements),
            (tr.hairColor, p.hairColor),
            (tr.eyeColor, p.eyeColor),
            (tr.images, '${p.imageCount}'),
          ]),
        ),
        if (p.details != null && p.details!.isNotEmpty)
          Section(title: tr.description, child: SelectableText(p.details!)),
        if (p.tags.isNotEmpty)
          Section(
            title: tr.tags,
            child: RefChips(refs: p.tags, onTap: (r) => openTag(context, r.id)),
          ),
        if (p.urls.isNotEmpty) Section(title: tr.links, child: UrlList(p.urls)),
      ],
    );
  }
}
