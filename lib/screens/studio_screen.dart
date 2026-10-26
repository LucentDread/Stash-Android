import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';
import 'edit/editors.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key, required this.studioId});
  final String studioId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Studio>(
      load: () => repo.findStudio(studioId),
      builder: (context, s, reload) {
        final entity = EntityFilter.studio(s.id);
        return DefaultTabController(
          length: 4,
          initialIndex: 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(s.name),
              actions: [
                EditButton(
                  onEdit: () => editStudio(context, s),
                  onSaved: reload,
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: tr.info),
                  Tab(text: '${tr.scenes} (${s.sceneCount})'),
                  Tab(text: '${tr.galleries} (${s.galleryCount})'),
                  Tab(text: tr.performers),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: withNavBar(context, const EdgeInsets.all(16)),
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
                        title: tr.parentStudio,
                        child: RefChips(
                          refs: [s.parent!],
                          icon: Icons.business,
                          onTap: (r) => openStudio(context, r.id),
                        ),
                      ),
                    if (s.details != null && s.details!.isNotEmpty)
                      Section(
                        title: tr.description,
                        child: SelectableText(s.details!),
                      ),
                    if (s.urls.isNotEmpty)
                      Section(title: tr.links, child: UrlList(s.urls)),
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
