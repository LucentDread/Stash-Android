import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/download_button.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import '../widgets/paged_grid.dart';
import 'edit/editors.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.galleryId});
  final String galleryId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Gallery>(
      load: () => repo.findGallery(galleryId),
      builder: (context, g, reload) => Scaffold(
        appBar: AppBar(
          title: Text(g.displayTitle),
          actions: [
            IconButton(
              tooltip: tr.information,
              icon: const Icon(Icons.info_outline),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _GalleryInfo(gallery: g),
              ),
            ),
            DownloadButton(kind: OfflineKind.gallery, id: g.id),
            EditButton(onEdit: () => editGallery(context, g), onSaved: reload),
          ],
        ),
        body: PagedGrid<StashImage>(
          itemKey: (item) => item.id,
          showToolbar: false,
          fetch: (q) => repo.findImages(
            // Gallery order as defined in Stash (by path/title).
            ListQuery(
              page: q.page,
              perPage: q.perPage,
              sort: 'path',
              descending: false,
            ),
            entity: EntityFilter.gallery(g.id),
          ),
          maxCrossAxisExtent: 160,
          childAspectRatio: 1,
          emptyText: tr.emptyGallery,
          itemBuilder: (context, img, i, all) => InkWell(
            onTap: () => openImages(context, List.of(all), i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: NetImage(img.thumbnail),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryInfo extends StatelessWidget {
  const _GalleryInfo({required this.gallery});
  final Gallery gallery;

  @override
  Widget build(BuildContext context) {
    final g = gallery;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: withNavBar(context, const EdgeInsets.fromLTRB(16, 0, 16, 24)),
        children: [
          Text(g.displayTitle, style: Theme.of(context).textTheme.titleLarge),
          InfoTable([
            (tr.date, g.date),
            (tr.images, '${g.imageCount}'),
            (tr.path, g.folderPath),
          ]),
          if (g.studio != null)
            Section(
              title: tr.studio,
              child: RefChips(
                refs: [g.studio!],
                icon: Icons.business,
                onTap: (r) => openStudio(context, r.id),
              ),
            ),
          if (g.performers.isNotEmpty)
            Section(
              title: tr.performers,
              child: RefChips(
                refs: g.performers,
                icon: Icons.person,
                onTap: (r) => openPerformer(context, r.id),
              ),
            ),
          if (g.tags.isNotEmpty)
            Section(
              title: tr.tags,
              child: RefChips(
                refs: g.tags,
                onTap: (r) => openTag(context, r.id),
              ),
            ),
          if (g.details != null && g.details!.isNotEmpty)
            Section(title: tr.description, child: Text(g.details!)),
        ],
      ),
    );
  }
}
