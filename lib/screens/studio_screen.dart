import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key, required this.studioId});
  final String studioId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Studio>(
      load: () => repo.findStudio(studioId),
      builder: (context, s, _) {
        final entity = EntityFilter.studio(s.id);
        return DefaultTabController(
          length: 4,
          initialIndex: 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(s.name),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  const Tab(text: 'Infos'),
                  Tab(text: 'Scènes (${s.sceneCount})'),
                  Tab(text: 'Galeries (${s.galleryCount})'),
                  const Tab(text: 'Performeurs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 140,
                      child: NetImage(
                        s.imagePath,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.business,
                      ),
                    ),
                    if (s.parent != null)
                      Section(
                        title: 'Studio parent',
                        child: RefChips(
                          refs: [s.parent!],
                          icon: Icons.business,
                          onTap: (r) => openStudio(context, r.id),
                        ),
                      ),
                    if (s.details != null && s.details!.isNotEmpty)
                      Section(
                        title: 'Description',
                        child: SelectableText(s.details!),
                      ),
                    if (s.urls.isNotEmpty)
                      Section(title: 'Liens', child: UrlList(s.urls)),
                  ],
                ),
                sceneGrid(context, entity: entity),
                galleryGrid(context, entity: entity),
                performerGrid(context, entity: entity),
              ],
            ),
          ),
        );
      },
    );
  }
}
