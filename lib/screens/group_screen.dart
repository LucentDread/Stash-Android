import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../services/downloads.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/download_button.dart';
import '../widgets/insets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';
import 'edit/editors.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Group>(
      load: () => repo.findGroup(groupId),
      builder: (context, g, reload) => DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            title: Text(g.name),
            actions: [
              DownloadButton(kind: OfflineKind.group, id: g.id),
              EditButton(onEdit: () => editGroup(context, g), onSaved: reload),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: tr.info),
                Tab(text: '${tr.scenes} (${g.sceneCount})'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _GroupInfo(group: g),
              sceneGrid(context, entity: EntityFilter.group(g.id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupInfo extends StatelessWidget {
  const _GroupInfo({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    return ListView(
      padding: withNavBar(context, const EdgeInsets.all(16)),
      children: [
        SizedBox(
          height: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final img in [
                g.frontImage,
                if (g.backImage != null) g.backImage,
              ])
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: NetImage(
                          img,
                          placeholderIcon: Icons.video_library,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: LiveRating(
            initial: g.rating100,
            save: (r) =>
                context.read<AppState>().repo!.rate(EditKind.group, g.id, r),
          ),
        ),
        Section(
          title: tr.information,
          child: InfoTable([
            (tr.aliases, g.aliases),
            (tr.date, g.date),
            (
              tr.duration,
              g.duration == null
                  ? null
                  : formatDuration(g.duration!.toDouble()),
            ),
            (tr.director, g.director),
          ]),
        ),
        if (g.studio != null)
          Section(
            title: tr.studio,
            child: RefChips(
              refs: [g.studio!],
              icon: Icons.business,
              onTap: (r) => openStudio(context, r.id),
            ),
          ),
        if (g.synopsis != null && g.synopsis!.isNotEmpty)
          Section(title: tr.synopsis, child: SelectableText(g.synopsis!)),
        if (g.tags.isNotEmpty)
          Section(
            title: tr.tags,
            child: RefChips(refs: g.tags, onTap: (r) => openTag(context, r.id)),
          ),
        if (g.urls.isNotEmpty) Section(title: tr.links, child: UrlList(g.urls)),
      ],
    );
  }
}
